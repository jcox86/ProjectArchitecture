/*
module: src.application.messaging
purpose: Represent an outbox entry to be persisted alongside business data changes.
exports:
  - record: OutboxMessage
patterns:
  - outbox
*/
namespace ProjectArchitecture.Application.Messaging;

public sealed record OutboxMessage(
    Guid TenantId,
    string QueueName,
    string MessageType,
    string Payload,
    string? CorrelationId,
    string? IdempotencyKey,
    DateTimeOffset? AvailableAt);
