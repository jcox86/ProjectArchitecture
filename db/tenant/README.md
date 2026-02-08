<!--
module: db.tenant
purpose: Define Flyway structure and conventions for tenant (data-plane) databases, including RLS standards and seed strategy.
exports:
  - docs: db/tenant/README.md
  - config: db/tenant/flyway.conf
patterns:
  - flyway
  - sql_first
  - rls
notes:
  - Tenant DB schema is used for both shared-tier (RLS) and isolated-tier (dedicated DB) tenants; RLS remains enabled in both.
-->

# Tenant DB (data plane) — Flyway

This folder contains Flyway migrations for the **tenant database schema** (data plane).

The tenant schema is applied to:
- **Shared tier**: a shared tenant DB protected by **PostgreSQL RLS**.
- **Isolated tier**: a dedicated DB per tenant using the **same schema**, with **RLS still enabled**.

Why these standards exist:
- RLS and limit enforcement are foundational to a **self-sustaining SaaS** experience.
- They enable predictable multi-tenant behavior (security + fairness), support scalability,
  and keep the product flexible without sacrificing reliability, observability, or performance.

## Folder structure

- `migrations/`
  - Versioned migrations (`V...__...sql`) that run **once** in order.
- `repeatable/`
  - Repeatable migrations (`R__...sql`) for “definition as truth” objects (functions/views/policies).
- `seed/`
  - Repeatable, **idempotent** reference-data scripts (safe to re-run).
- `flyway.conf`
  - Shared Flyway settings (no secrets).

## Naming conventions

### Versioned migrations (`migrations/`)

Format:

`V0001_0001__<module>__<objectType>__<name>__<intent>.sql`

Examples:
- `V0001_0001__tenant__bootstrap__initial_schema.sql`
- `V0001_0100__inventory__table__shop__create.sql`
- `V0002_0010__inventory__table__shop__add_timezone.sql`

### Repeatables (`repeatable/`)

Format:

`R__<module>__<objectType>__<name>.sql`

Examples:
- `R__core__function__current_tenant_id.sql`
- `R__inventory__function__get_shop.sql`
- `R__inventory__policy__shop_tenant_isolation.sql`

### Seed scripts (`seed/`)

Seed scripts are repeatables placed in `seed/` for clarity.

Guidelines:
- **Idempotent only**: use upserts (`insert ... on conflict ... do update/do nothing`).
- Prefer stable natural keys (`code`, `slug`) or stable UUIDs committed to the script.
- Avoid deletes in seeds; if rows must be removed, do it in an explicit migration with a clear intent and review.

## Postgres module schemas (tenant DB)

By convention, each module owns a schema of the same name:
- `core` — shared primitives + helper functions used across modules (tenant context, common triggers)
- `inventory`, `billing`, `audit`, ... — module schemas created as the template grows

Reserved:
- `flyway` — schema for Flyway’s history table (configured in `flyway.conf`)

## RLS standards (tenant-scoped data)

### Invariants

For every tenant-scoped table:
- Include `tenant_id uuid not null`
- Enable and force RLS:
  - `alter table ... enable row level security;`
  - `alter table ... force row level security;`
- Policies must bind access to a **single tenant context** (do not join to other tables to “find” tenant).

### Tenant context binding

RLS policies should reference a single tenant context value, preferably via:
- `core.current_tenant_id()` (defined in `repeatable/`)

This function reads `current_setting('app.tenant_id', true)` and returns a `uuid` (or `null` when not set).

### Policy pattern (recommended)

Use a single policy that covers reads and writes:

```sql
create policy shop_tenant_isolation
on inventory.shop
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
```

Notes:
- When tenant context is missing (`null`), the predicate evaluates to `null`/false → rows are not visible and writes are rejected.
- Consider a default value to reduce application mistakes:
  - `tenant_id uuid not null default core.current_tenant_id()`
 - RLS is non-optional for tenant data; it is part of the product's core multi-tenant safety model.

### How the app should set tenant context

Set tenant context **per transaction** to be safe with connection pooling:

```sql
set local app.tenant_id = '00000000-0000-0000-0000-000000000000';
```

In application code, the recommended pattern is:
- open connection
- begin transaction
- `SET LOCAL app.tenant_id = ...`
- run queries
- commit/rollback transaction

## Auditing and history standards

For most tenant-scoped tables, include:
- `created_by uuid null`
- `updated_by uuid null`
- `is_active boolean not null default true`

Notes:
- These columns support audit/history reporting and soft-state filtering.
- Exceptions should be rare (e.g., pure join tables with no meaningful lifecycle).

## Subscription limits (tenant/system)

Use `inventory.limits` to store plan and tier limits:
- `limits_json` for counts (e.g., `{"systems":5,"users":50,"items":10000}`)
- `rate_limits_json` for throttles (e.g., `{"api_reads_per_min":1000}`)
- `flags_json` for boolean policies (e.g., `{"allow_export": true}`)

The database enforces limits for systems, items, and user assignments via triggers.

Why enforce limits in the DB:
- Ensures tier/plan constraints are respected across all code paths.
- Supports predictable, fair usage for tenants and resilient operations at scale.

## Safety standards

- Prefer **expand/contract** for breaking changes.
- Avoid destructive DDL by default (`DROP`, table rewrites, type changes). Require explicit intent and review when needed.
- Keep migrations small and reviewable; **one object per script** where practical, except for the initial bootstrap migration which may establish multiple schemas/extensions in one atomic step.

