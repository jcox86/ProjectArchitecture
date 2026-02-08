<!--
module: docs.adr.messaging
purpose: Record the decision to use Azure Storage Queues with an outbox and idempotency keys for reliable async processing.
exports:
  - decision: storage_queues_for_async_work
  - decision: transactional_outbox
  - decision: idempotency_keys
patterns:
  - adr
  - outbox
  - at_least_once
-->

# ADR 0004: Messaging with Storage Queues + outbox + idempotency

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

The platform needs background processing for tasks like email, billing, provisioning, and long-running workflows. The baseline should be:

- Low operational overhead
- Easy to scale with Azure Container Apps
- Reliable under retries and failures (at-least-once delivery)

Azure Storage Queues is a simple, cost-effective queue with strong Azure integration and KEDA-based scaling for workers.

## Decision

1. **Queue technology**
   - Use **Azure Storage Queues** for asynchronous work distribution.
   - Scale the Worker via **KEDA** based on queue depth.

2. **Delivery reliability**
   - Use a **transactional outbox** in PostgreSQL for publishing work/messages tied to business state changes.
   - The Worker drains the outbox and enqueues work (or processes directly) with retry semantics.

3. **Idempotency**
   - Use **idempotency keys** for externally-triggered commands (especially HTTP endpoints) so clients can safely retry without duplicating side effects.
   - Ensure Worker handlers are idempotent for at-least-once delivery.

4. **Poison handling**
   - After a bounded number of dequeue attempts, move messages to a `*-poison` queue and emit an alert/metric.

## Decision drivers

- Operational simplicity (queues available everywhere, minimal management)
- Built-in scaling with Container Apps (KEDA triggers)
- Correctness under retry and failure (outbox + idempotency)
- Cost-conscious default suitable for the template baseline

## Consequences

### Positive

- Clear, durable async pipeline with predictable retry behavior
- Easy worker scaling without introducing heavy messaging infrastructure
- Idempotency reduces duplicate work and makes APIs safer for real-world clients

### Negative / trade-offs

- Storage Queues is at-least-once; exactly-once delivery is not guaranteed
- Outbox adds schema and operational complexity (tables, cleanup, monitoring)
- Message size/format constraints require careful payload design

### Neutral / follow-ups

- Define message envelope conventions (correlation IDs, tenant ID, schema version).
- Add metrics/alerts: queue depth, poison count, outbox lag, handler failures.

## Alternatives considered

- **Azure Service Bus**: richer features (topics, sessions), but higher cost/ops footprint for a baseline template.
- **Event Grid**: good for eventing, but not ideal for durable work queues and at-least-once processing semantics for arbitrary jobs.
- **In-process background jobs**: simpler, but couples work to API lifecycle and complicates scaling/reliability.

## References

- `PLAN.md`
- `docs/operations/README.md`

