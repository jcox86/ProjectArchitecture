/*
module: src.application.messaging
purpose: Define the contract for handling queue messages pulled by the worker.
exports:
  - interface: IQueueMessageHandler
patterns:
  - storage_queues
  - idempotency
*/
namespace ProjectArchitecture.Application.Messaging;

public interface IQueueMessageHandler
{
    string MessageType { get; }

    Task HandleAsync(QueueEnvelope envelope, CancellationToken cancellationToken);
}
