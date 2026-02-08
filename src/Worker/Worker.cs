/*
module: src.worker
purpose: Dispatch transactional outbox messages to storage queues.
exports:
  - class: Worker
patterns:
  - background_service
  - outbox
  - storage_queues
*/
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Messaging;
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Worker;

public sealed class Worker(
    ITenantCatalogReader tenantCatalogReader,
    IOutboxStore outboxStore,
    IQueuePublisher queuePublisher,
    IOptions<OutboxDispatcherOptions> options,
    ILogger<Worker> logger) : BackgroundService
{
    private readonly OutboxDispatcherOptions _options = options.Value;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var delay = TimeSpan.FromSeconds(Math.Max(1, _options.PollDelaySeconds));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var tenants = await tenantCatalogReader.GetActiveTenantsAsync(stoppingToken);
                foreach (var tenant in tenants)
                {
                    var pending = await outboxStore.DequeuePendingAsync(tenant, _options.BatchSize, stoppingToken);
                    foreach (var message in pending)
                    {
                        await DispatchAsync(tenant, message, stoppingToken);
                    }
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Outbox dispatch cycle failed.");
            }

            await Task.Delay(delay, stoppingToken);
        }
    }

    private async Task DispatchAsync(TenantCatalogEntry tenant, OutboxRecord record, CancellationToken cancellationToken)
    {
        try
        {
            var queueName = record.QueueName;
            if (record.Attempts >= _options.MaxAttempts)
            {
                queueName = $"{queueName}-poison";
                logger.LogWarning(
                    "Outbox message {OutboxId} exceeded max attempts; moving to poison queue.",
                    record.OutboxId);
            }

            var envelope = new QueueEnvelope(
                record.OutboxId,
                record.TenantId,
                record.MessageType,
                record.Payload,
                record.CorrelationId,
                record.IdempotencyKey,
                record.OccurredAt);

            await queuePublisher.EnqueueAsync(queueName, envelope, cancellationToken);
            await outboxStore.MarkDispatchedAsync(tenant, record.OutboxId, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to dispatch outbox message {OutboxId}.", record.OutboxId);
            await outboxStore.MarkFailedAsync(
                tenant,
                record.OutboxId,
                ex.Message,
                TimeSpan.FromSeconds(Math.Max(1, _options.RetryDelaySeconds)),
                cancellationToken);
        }
    }
}
