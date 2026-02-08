---
name: db-change-flyway
description: Create and validate Flyway migrations/repeatables/seed scripts for PostgreSQL in this repo. Use when adding or changing DB objects, RLS policies, functions/views, or reference data.
module: cursor.skills.dbChangeFlyway
purpose: Provide a repeatable workflow for safe Postgres schema changes using Flyway conventions defined by the template plan.
exports:
  - workflow: create_versioned_migration
  - workflow: create_repeatable_script
  - workflow: create_seed_script
patterns:
  - flyway
  - sql_first
  - postgres_rls
notes:
  - Destructive changes require explicit approval/ADR in production (template guardrail).
---

# DB change (PostgreSQL + Flyway)

## Target layout (planned)

- `db/catalog/` (control plane)
- `db/tenant/` (data plane)

Each has:

- `migrations/` (versioned `V...__...sql`)
- `repeatable/` (repeatable `R__...sql`)
- `seed/` (repeatable + idempotent reference data)

## Decide what to create

### Versioned migration (`V...`)

Use for:

- new schemas/tables/types/indexes
- additive columns
- data backfills that must run once

### Repeatable (`R__...`)

Use for authoritative definitions that should be “definition as truth”:

- functions/procedures (`create or replace`)
- views
- policies (where feasible to define idempotently)

### Seed (`seed/`)

Use for:

- reference data that is safe to re-run (idempotent upserts/inserts)

## Naming conventions (default)

- Versioned:
  - `V0001_0001__<module>__<objectType>__<name>__<intent>.sql`
  - Example: `V0001_0010__inventory__table__shop__create.sql`
- Repeatable:
  - `R__<module>__<objectType>__<name>.sql`
  - Example: `R__inventory__function__get_shop.sql`

## Module header (required)

Every `*.sql` starts with a module header in `--` YAML lines (see `docs/ai/module-headers.md`).

## RLS invariants (tenant DB)

For every tenant-scoped table:

- include `tenant_id`
- enable + force RLS
- add policies bound to a single tenant context (e.g., `current_setting('app.tenant_id', true)`)

## Safety guardrails

- Avoid destructive DDL by default (DROP, rewrites, breaking type changes).
- Use **expand/contract** for breaking changes:
  - expand (additive + backwards compatible)
  - deploy app that reads/writes both shapes
  - contract later (cleanup)
- Prefer online-safe patterns (add columns nullable, backfill, then constrain).

## Quick skeletons

### Versioned migration skeleton

```sql
-- module: db.tenant.inventory
-- purpose: Create inventory.shop table with tenant isolation.
-- exports:
--   - table: inventory.shop
-- patterns:
--   - flyway_versioned
--   - rls

create schema if not exists inventory;

create table if not exists inventory.shop (
  shop_id uuid primary key,
  tenant_id uuid not null,
  name text not null
);

alter table inventory.shop enable row level security;
alter table inventory.shop force row level security;
```

### Repeatable function skeleton

```sql
-- module: db.tenant.inventory
-- purpose: Authoritative definition of inventory.get_shop.
-- exports:
--   - function: inventory.get_shop(uuid)
-- patterns:
--   - flyway_repeatable

create or replace function inventory.get_shop(p_shop_id uuid)
returns table (shop_id uuid, tenant_id uuid, name text)
language sql
as $$
  select s.shop_id, s.tenant_id, s.name
  from inventory.shop s
  where s.shop_id = p_shop_id;
$$;
```

## Validation expectations (planned CI)

- `flyway info` (for visibility)
- `flyway validate` (drift/checksum mismatch is a blocker)

