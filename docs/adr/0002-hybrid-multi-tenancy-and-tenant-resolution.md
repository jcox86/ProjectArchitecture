<!--
module: docs.adr.tenancy
purpose: Record the decision for hybrid multi-tenancy (shared tier via RLS + isolated tier via dedicated DB) and tenant resolution strategy.
exports:
  - decision: tenant_resolution_by_subdomain
  - decision: hybrid_tenancy_shared_rls_and_dedicated_db
patterns:
  - adr
  - multi_tenancy
  - rls
-->

# ADR 0002: Hybrid multi-tenancy and tenant resolution

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

The template targets a SaaS product that must support:

- Many tenants at low cost (shared infrastructure)
- Optional stronger isolation for high-value tenants (dedicated resources)
- A straightforward request-routing model (tenant identified early)
- A tenant boundary that is enforced at the database layer (defense in depth)

## Decision

Adopt a **hybrid multi-tenant** model with:

1. **Tenant resolution by subdomain**
   - Primary tenant identity comes from the request host: `tenantSlug.<rootDomain>`
   - Admin console uses a distinct host: `admin.<rootDomain>`

2. **Control plane vs data plane**
   - **Catalog DB (control plane)**: stores tenant registry and routing/tier metadata.
   - **Tenant DB schema (data plane)**:
     - **Shared tier**: tenant data stored in a shared tenant database protected by **PostgreSQL Row Level Security (RLS)**.
     - **Isolated tier**: dedicated database per tenant using the **same schema** as shared tier, with **RLS still enabled**.

3. **RLS enforcement via session setting**
   - RLS policies bind tenant scoping to `current_setting('app.tenant_id', true)` (or a helper function wrapping it).
   - The application sets `app.tenant_id` for every request/operation that touches tenant-scoped data.

## Decision drivers

- Cost-effective default (shared tier) with an upgrade path (isolated tier)
- Strong tenant boundary via Postgres RLS (not solely application filtering)
- Simple and explicit tenant resolution (subdomain-first)
- Schema parity across tiers to keep migrations and code paths consistent

## Consequences

### Positive

- Shared-tier isolation enforced at the database layer
- Isolated-tier tenants can be onboarded without forking schema/code
- Tenant routing is explicit and early, simplifying auth and data access

### Negative / trade-offs

- Connection pooling requires care: `app.tenant_id` must be set/reset correctly to avoid cross-tenant leakage.
- Dedicated DBs add provisioning/migration overhead for isolated-tier tenants.
- Local development/testing must validate RLS correctness (policies exist, FORCE RLS enabled).

### Neutral / follow-ups

- Implement a consistent tenant-resolution component used by API/Worker.
- Add automated tests that assert:
  - RLS is enabled/forced for tenant-scoped tables
  - Policies exist and reference the tenant setting/function

## Alternatives considered

- **Schema-per-tenant in one DB**: operationally heavy at scale; hard to manage/search; migrations become noisy.
- **DB-per-tenant only**: higher cost and operational overhead; not suitable as default for many small tenants.
- **App-level filtering only**: weaker isolation; easier to accidentally leak data.
- **Tenant by request header**: easier to spoof; subdomain keeps routing and boundary more explicit (still validate).

## References

- `PLAN.md`
- `db/tenant/README.md`
- `db/tenant/repeatable/R__core__function__current_tenant_id.sql`

