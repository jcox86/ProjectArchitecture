/*
module: src.infrastructure.messaging
purpose: Publish outbox messages to Azure Storage Queues with JSON envelopes.
exports:
  - class: StorageQueuePublisher
patterns:
  - storage_queues
  - queue_contracts
*/
using System.Text.Json;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Messaging;

namespace ProjectArchitecture.Infrastructure.Messaging;

public sealed class StorageQueuePublisher : IQueuePublisher
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);
    private readonly QueueOptions _options;
    private readonly QueueServiceClient _serviceClient;
    private readonly ILogger<StorageQueuePublisher> _logger;

    public StorageQueuePublisher(IOptions<QueueOptions> options, ILogger<StorageQueuePublisher> logger)
    {
        _options = options.Value;
        _logger = logger;

        var clientOptions = new QueueClientOptions { MessageEncoding = QueueMessageEncoding.Base64 };
        _serviceClient = new QueueServiceClient(_options.ConnectionString, clientOptions);
    }

    public async Task EnqueueAsync(string queueName, QueueEnvelope message, CancellationToken cancellationToken)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(_options.ConnectionString))
            {
                throw new InvalidOperationException("Storage queue connection string is not configured.");
            }

            var normalizedName = queueName.Trim().ToLowerInvariant();
            var fullName = string.IsNullOrWhiteSpace(_options.Prefix)
                ? normalizedName
                : $"{_options.Prefix}-{normalizedName}";

            var client = _serviceClient.GetQueueClient(fullName);
            await client.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

            var payload = JsonSerializer.Serialize(message, SerializerOptions);
            await client.SendMessageAsync(payload, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to enqueue message to queue {QueueName}.", queueName);
            throw;
        }
    }
}
