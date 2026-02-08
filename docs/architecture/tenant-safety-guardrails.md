<!--
module: docs.architecture.tenantSafetyGuardrails
purpose: Describe architectural guardrails for tenant isolation and SaaS limits enforcement.
exports:
  - doc: tenant_safety_guardrails
patterns:
  - rls
  - limits_enforcement
-->

# Tenant safety guardrails (RLS + limits)

Multi-tenant safety is a **core architectural requirement** for this template. Two guardrails are non-negotiable:

1) **Row-Level Security (RLS)** on all tenant-scoped tables
- Enforced with `tenant_id` + `core.current_tenant_id()`.
- RLS is **enabled and forced** on tenant data in both shared and isolated tiers.
- The app must set tenant context per-transaction (`SET LOCAL app.tenant_id = ...`).

2) **Subscription/tier limits** enforced at the database layer
- Limits are stored in `inventory.limits` as JSON:
  - `limits_json` (counts: systems, users, items)
  - `rate_limits_json` (throttles)
  - `flags_json` (feature toggles)
- Enforcement happens via triggers to ensure consistency across all code paths.

These guardrails enable a self-sustaining SaaS product that is:
- **Resilient**: invariants held even under failure or concurrency.
- **Scalable**: predictable isolation and fair resource usage.
- **Flexible**: JSON-based limits evolve without migrations.
- **Observable**: violations surface as DB errors and can be instrumented.
- **Performant**: constraints are enforced near the data with minimal overhead.
