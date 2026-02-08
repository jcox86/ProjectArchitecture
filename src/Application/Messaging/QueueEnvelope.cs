/*
module: src.application.messaging
purpose: Define the queue message envelope shared across producers and consumers.
exports:
  - record: QueueEnvelope
patterns:
  - queue_contracts
*/
namespace ProjectArchitecture.Application.Messaging;

public sealed record QueueEnvelope(
    Guid OutboxId,
    Guid TenantId,
    string MessageType,
    string Payload,
    string? CorrelationId,
    string? IdempotencyKey,
    DateTimeOffset OccurredAt,
    int SchemaVersion = 1);
