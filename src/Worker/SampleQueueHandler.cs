/*
module: src.worker
purpose: Provide a sample queue handler demonstrating message dispatch and logging.
exports:
  - class: SampleQueueHandler
patterns:
  - storage_queues
  - idempotency
*/
using ProjectArchitecture.Application.Messaging;

namespace ProjectArchitecture.Worker;

public sealed class SampleQueueHandler(ILogger<SampleQueueHandler> logger) : IQueueMessageHandler
{
    public string MessageType => "sample";

    public async Task HandleAsync(QueueEnvelope envelope, CancellationToken cancellationToken)
    {
        try
        {
            logger.LogInformation(
                "Handled sample message {OutboxId} for tenant {TenantId}.",
                envelope.OutboxId,
                envelope.TenantId);

            await Task.CompletedTask;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to handle sample message {OutboxId}.", envelope.OutboxId);
        }
    }
}
