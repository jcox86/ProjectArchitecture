/*
module: src.application.messaging
purpose: Publish messages to a queue backend for asynchronous processing.
exports:
  - interface: IQueuePublisher
patterns:
  - queue_contracts
*/
namespace ProjectArchitecture.Application.Messaging;

public interface IQueuePublisher
{
    Task EnqueueAsync(string queueName, QueueEnvelope message, CancellationToken cancellationToken);
}
