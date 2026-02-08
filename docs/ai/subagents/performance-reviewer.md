<!--
module: docs.ai.subagents.performanceReviewer
purpose: Checklist to review performance/cost/scaling implications (apps, DB, and Azure infra).
exports:
  - checklist: performance_review
patterns:
  - scalability
  - cost_guardrails
-->

# Performance reviewer — checklist

## Scaling + cost guardrails

- [ ] Autoscaling triggers are appropriate (HTTP concurrency, queue depth, etc.)
- [ ] Scale **caps** exist to avoid runaway cost
- [ ] Default sizes align with environment (dev vs prod)

## Latency and throughput (app-level, planned)

- [ ] Hot paths avoid unnecessary allocations/roundtrips
- [ ] Caching is used intentionally (e.g., Redis for ABAC attributes, routing cache)
- [ ] Timeouts and retries are bounded (no retry storms)

## Database performance (Postgres, planned)

- [ ] Queries are indexed appropriately; avoid N+1 patterns
- [ ] Migrations avoid table rewrites or are explicitly gated
- [ ] RLS policies are efficient and tested

## Observability for performance

- [ ] Metrics exist for queue lag, error rate, and latency percentiles (planned)
- [ ] Logs/traces include correlation IDs and tenant context (planned)

