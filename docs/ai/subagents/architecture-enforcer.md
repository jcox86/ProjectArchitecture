<!--
module: docs.ai.subagents.architectureEnforcer
purpose: Checklist to enforce the template’s architectural boundaries and core patterns.
exports:
  - checklist: architecture_review
patterns:
  - clean_architecture
  - ddd
-->

# Architecture enforcer — checklist

## Boundaries (Clean Architecture)

- [ ] Dependencies flow inward (Domain → Application → Infrastructure → Hosts)
- [ ] Domain has no infrastructure concerns (Azure SDK, HTTP, DB drivers, etc.)
- [ ] Host projects (Api/Worker/AdminUi) are thin composition roots

## Module discipline (DDD)

- [ ] New code belongs to a clear module (module name is explicit)
- [ ] Cross-module coupling is minimized (no “god” shared utilities)
- [ ] Shared primitives live in an intentional shared module (not ad-hoc)

## Tenancy assumptions

- [ ] Tenant resolution is explicit and validated at boundaries
- [ ] Tenant-scoped data access is protected (RLS in DB; tenant context in app)
- [ ] Dedicated tenant DBs keep schema parity with shared tier (planned)

## Reliability patterns

- [ ] Background work is queue-driven with retries + poison handling
- [ ] Outbox + idempotency patterns are followed where relevant
- [ ] Observability hooks exist (logs/metrics/traces) for critical flows

