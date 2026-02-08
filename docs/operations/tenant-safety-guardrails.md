<!--
module: docs.operations.tenantSafetyGuardrails
purpose: Operational guidance for RLS and subscription limit enforcement.
exports:
  - doc: tenant_safety_guardrails_ops
patterns:
  - rls
  - limits_enforcement
  - observability
-->

# Tenant safety guardrails (operations)

RLS and limits are operational safeguards that must be monitored and validated.

## RLS operational checks
- Verify tenant context is set for every request/transaction.
- Monitor for errors indicating missing tenant context.
- Keep RLS enabled and forced on tenant tables.

## Limits operational checks
- Keep `inventory.limits` entries current with plan changes.
- Monitor limit violations (trigger exceptions) as product health signals.
- Audit changes to limits via `created_by`/`updated_by`.

## Observability
- Emit structured logs on limit violations (tenant_id, limit_key, limit_value).
- Track metrics for:
  - limit violations per tenant
  - active systems/users/items per tenant
  - latency added by limit enforcement (should be minimal)

## Incident response
- If many tenants hit limits simultaneously, validate plan changes and usage spikes.
- If limits are too strict, update `inventory.limits` and re-evaluate tier defaults.
