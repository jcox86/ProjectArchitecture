/*
module: src.application.messaging
purpose: Represent a pending outbox record ready for dispatch.
exports:
  - record: OutboxRecord
patterns:
  - outbox
*/
namespace ProjectArchitecture.Application.Messaging;

public sealed record OutboxRecord(
    Guid OutboxId,
    Guid TenantId,
    string QueueName,
    string MessageType,
    string Payload,
    string? CorrelationId,
    string? IdempotencyKey,
    DateTimeOffset OccurredAt,
    int Attempts);
