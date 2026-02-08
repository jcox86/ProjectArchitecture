/*
module: src.worker
purpose: Receive and dispatch Azure Storage Queue messages with retries and poison handling.
exports:
  - class: StorageQueueProcessor
patterns:
  - storage_queues
  - poison_queue
  - retries
  - open_telemetry
*/
using System.Diagnostics;
using System.Text.Json;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Messaging;
using ProjectArchitecture.Infrastructure.Messaging;

namespace ProjectArchitecture.Worker;

public sealed class StorageQueueProcessor(
    IOptions<QueueProcessorOptions> options,
    IOptions<QueueOptions> queueOptions,
    IEnumerable<IQueueMessageHandler> handlers,
    IHostEnvironment hostEnvironment,
    ILogger<StorageQueueProcessor> logger) : BackgroundService
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);
    private readonly QueueProcessorOptions _options = options.Value;
    private readonly QueueOptions _queueOptions = queueOptions.Value;
    private readonly IReadOnlyDictionary<string, IQueueMessageHandler> _handlersByType = BuildHandlerMap(handlers, logger);
    private readonly ActivitySource _activitySource = new(hostEnvironment.ApplicationName);
    private QueueServiceClient? _serviceClient;
    private bool _loggedMissingConnection;
    private bool _loggedNoQueues;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var delay = TimeSpan.FromSeconds(Math.Max(1, _options.PollDelaySeconds));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessQueuesAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Queue processing cycle failed.");
            }

            await Task.Delay(delay, stoppingToken);
        }
    }

    private async Task ProcessQueuesAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_queueOptions.ConnectionString))
        {
            if (!_loggedMissingConnection)
            {
                _loggedMissingConnection = true;
                logger.LogWarning("Storage queue connection string is not configured; queue processor is idle.");
            }

            return;
        }

        if (_options.Queues.Length == 0)
        {
            if (!_loggedNoQueues)
            {
                _loggedNoQueues = true;
                logger.LogWarning("No storage queues configured for processing.");
            }

            return;
        }

        var serviceClient = GetServiceClient();
        if (serviceClient is null)
        {
            return;
        }

        foreach (var queueName in _options.Queues)
        {
            var normalizedName = NormalizeQueueName(queueName);
            if (string.IsNullOrWhiteSpace(normalizedName))
            {
                continue;
            }

            await ProcessQueueAsync(serviceClient, normalizedName, cancellationToken);
        }
    }

    private async Task ProcessQueueAsync(QueueServiceClient serviceClient, string queueName, CancellationToken cancellationToken)
    {
        try
        {
            var fullName = GetFullQueueName(queueName);
            var client = serviceClient.GetQueueClient(fullName);
            await client.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

            using var activity = _activitySource.StartActivity("queue.receive", ActivityKind.Consumer);
            activity?.SetTag("messaging.system", "azure.storage.queues");
            activity?.SetTag("messaging.destination", "queue");
            activity?.SetTag("messaging.destination.name", fullName);
            activity?.SetTag("messaging.operation", "receive");

            var maxMessages = Math.Clamp(_options.BatchSize, 1, 32);
            var visibilityTimeout = TimeSpan.FromSeconds(Math.Max(1, _options.VisibilityTimeoutSeconds));
            var response = await client.ReceiveMessagesAsync(maxMessages, visibilityTimeout, cancellationToken);

            foreach (var message in response.Value)
            {
                await ProcessMessageAsync(serviceClient, client, queueName, message, cancellationToken);
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to process queue {QueueName}.", queueName);
        }
    }

    private async Task ProcessMessageAsync(
        QueueServiceClient serviceClient,
        QueueClient client,
        string queueName,
        QueueMessage message,
        CancellationToken cancellationToken)
    {
        using var scope = logger.BeginScope(new Dictionary<string, object?>
        {
            ["QueueName"] = queueName,
            ["QueueMessageId"] = message.MessageId,
            ["QueueDequeueCount"] = message.DequeueCount
        });

        using var activity = _activitySource.StartActivity("queue.process", ActivityKind.Consumer);
        activity?.SetTag("messaging.system", "azure.storage.queues");
        activity?.SetTag("messaging.destination", "queue");
        activity?.SetTag("messaging.destination.name", GetFullQueueName(queueName));
        activity?.SetTag("messaging.operation", "process");
        activity?.SetTag("messaging.message.id", message.MessageId);

        var payload = message.Body.ToString();
        if (message.DequeueCount >= _options.MaxDequeueCount)
        {
            await MoveToPoisonAsync(serviceClient, client, queueName, payload, message, "max_dequeue_count", cancellationToken);
            return;
        }

        if (!TryDeserializeEnvelope(payload, out var envelope))
        {
            logger.LogError("Failed to deserialize queue message; moving to poison queue.");
            await MoveToPoisonAsync(serviceClient, client, queueName, payload, message, "deserialize_failed", cancellationToken);
            return;
        }

        using var messageScope = logger.BeginScope(new Dictionary<string, object?>
        {
            ["TenantId"] = envelope.TenantId,
            ["OutboxId"] = envelope.OutboxId,
            ["MessageType"] = envelope.MessageType,
            ["CorrelationId"] = envelope.CorrelationId
        });

        activity?.SetTag("messaging.message.payload_size", payload.Length);
        activity?.SetTag("queue.message_type", envelope.MessageType);
        activity?.SetTag("tenant.id", envelope.TenantId);
        activity?.SetTag("correlation.id", envelope.CorrelationId);

        if (!_handlersByType.TryGetValue(envelope.MessageType, out var handler))
        {
            logger.LogError(
                "No queue handler registered for message type {MessageType}; moving to poison queue.",
                envelope.MessageType);
            await MoveToPoisonAsync(serviceClient, client, queueName, payload, message, "handler_missing", cancellationToken);
            return;
        }

        try
        {
            await handler.HandleAsync(envelope, cancellationToken);
            await client.DeleteMessageAsync(message.MessageId, message.PopReceipt, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Queue handler failed for message type {MessageType}.", envelope.MessageType);
        }
    }

    private async Task MoveToPoisonAsync(
        QueueServiceClient serviceClient,
        QueueClient originalClient,
        string queueName,
        string payload,
        QueueMessage message,
        string reason,
        CancellationToken cancellationToken)
    {
        try
        {
            var poisonName = $"{queueName}-poison";
            var fullPoisonName = GetFullQueueName(poisonName);
            var poisonClient = serviceClient.GetQueueClient(fullPoisonName);
            await poisonClient.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

            var ttlDays = Math.Clamp(_options.PoisonMessageTtlDays, 1, 7);
            await poisonClient.SendMessageAsync(
                payload,
                timeToLive: TimeSpan.FromDays(ttlDays),
                cancellationToken: cancellationToken);
            await originalClient.DeleteMessageAsync(message.MessageId, message.PopReceipt, cancellationToken);

            logger.LogWarning(
                "Moved queue message {QueueMessageId} to poison queue due to {Reason}.",
                message.MessageId,
                reason);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to move message {QueueMessageId} to poison queue.", message.MessageId);
        }
    }

    private QueueServiceClient? GetServiceClient()
    {
        if (_serviceClient is not null)
        {
            return _serviceClient;
        }

        try
        {
            var clientOptions = new QueueClientOptions { MessageEncoding = QueueMessageEncoding.Base64 };
            _serviceClient = new QueueServiceClient(_queueOptions.ConnectionString, clientOptions);
            return _serviceClient;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to create storage queue service client.");
            return null;
        }
    }

    private static bool TryDeserializeEnvelope(string payload, out QueueEnvelope envelope)
    {
        try
        {
            envelope = JsonSerializer.Deserialize<QueueEnvelope>(payload, SerializerOptions)!;
            return envelope is not null;
        }
        catch
        {
            envelope = null!;
            return false;
        }
    }

    private string GetFullQueueName(string queueName)
    {
        var normalizedName = NormalizeQueueName(queueName);
        return string.IsNullOrWhiteSpace(_queueOptions.Prefix)
            ? normalizedName
            : $"{_queueOptions.Prefix}-{normalizedName}";
    }

    private static string NormalizeQueueName(string queueName)
        => queueName.Trim().ToLowerInvariant();

    private static IReadOnlyDictionary<string, IQueueMessageHandler> BuildHandlerMap(
        IEnumerable<IQueueMessageHandler> handlers,
        ILogger logger)
    {
        var map = new Dictionary<string, IQueueMessageHandler>(StringComparer.OrdinalIgnoreCase);

        foreach (var handler in handlers)
        {
            if (string.IsNullOrWhiteSpace(handler.MessageType))
            {
                logger.LogWarning(
                    "Queue handler {HandlerType} has an empty message type and will be ignored.",
                    handler.GetType().Name);
                continue;
            }

            if (!map.TryAdd(handler.MessageType, handler))
            {
                logger.LogError(
                    "Duplicate queue handler registration for message type {MessageType}.",
                    handler.MessageType);
            }
        }

        return map;
    }
}
