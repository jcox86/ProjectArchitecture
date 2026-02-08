<!--
module: db.catalog
purpose: Define Flyway structure and conventions for the control-plane (catalog) database.
exports:
  - docs: db/catalog/README.md
  - config: db/catalog/flyway.conf
patterns:
  - flyway
  - sql_first
notes:
  - Use versioned migrations for one-time DDL/data moves; use repeatables for authoritative definitions (functions/views/policies).
  - Seed scripts must be idempotent and safe to re-run.
-->

# Catalog DB (control plane) — Flyway

This folder contains Flyway migrations for the **catalog** database (control plane).

The catalog DB stores cross-tenant/control-plane data such as:
- tenants and routing/tier metadata
- plans/add-ons and billing metadata
- global feature flags
- audit events (control plane)
- admin staff identity/membership metadata

## Folder structure

- `migrations/`
  - Versioned migrations (`V...__...sql`) that run **once** in order.
- `repeatable/`
  - Repeatable migrations (`R__...sql`) for “definition as truth” objects.
- `seed/`
  - Repeatable, **idempotent** reference-data scripts (safe to re-run).
- `flyway.conf`
  - Shared Flyway settings (no secrets).

## Naming conventions

### Versioned migrations (`migrations/`)

Format:

`V0001_0001__<module>__<objectType>__<name>__<intent>.sql`

Examples:
- `V0001_0001__catalog__bootstrap__initial_schema.sql` (bootstrap may group multiple statements)
- `V0001_0100__billing__table__invoice__create.sql`
- `V0002_0010__catalog__table__tenant__add_tier.sql`

Conventions:
- **`<module>`**: the owning module/schema (lowercase; usually equals the Postgres schema name).
- **`<objectType>`**: use a small vocabulary: `schema`, `table`, `type`, `enum`, `index`, `view`, `function`, `procedure`, `trigger`, `policy`, `grant`, `extension`, `data`.
- **`<name>`**: object name (snake_case preferred).
- **`<intent>`**: short verb phrase: `create`, `add_<x>`, `alter_<x>`, `backfill_<x>`, `drop_<x>` (avoid destructive by default).

### Repeatables (`repeatable/`)

Format:

`R__<module>__<objectType>__<name>.sql`

Examples:
- `R__identity__function__get_admin_user.sql`
- `R__flags__view__effective_flags.sql`

Repeatables should be:
- **idempotent** where feasible
- authored using `create or replace ...` (functions/views)
- safe to re-apply when the file changes (Flyway re-runs when checksum changes)

### Seed scripts (`seed/`)

Seed scripts are repeatables placed in `seed/` for clarity.

Guidelines:
- **Idempotent only**: use `insert ... on conflict ... do update` / `do nothing`.
- Avoid deleting rows automatically; if a seed needs to remove rows, treat it as an intentional change with a clear migration and review.
- Prefer stable natural keys (e.g., `code`) or stable UUIDs committed in the script.

Example (pattern only):

```sql
insert into catalog.plan (plan_id, code, display_name)
values
  ('00000000-0000-0000-0000-000000000001', 'free', 'Free'),
  ('00000000-0000-0000-0000-000000000002', 'pro', 'Pro')
on conflict (code) do update
set display_name = excluded.display_name;
```

## Postgres module schemas (catalog DB)

By convention, each module owns a schema of the same name:
- `catalog` — tenants, routing, tiers, global settings
- `identity` — admin staff memberships/roles (control plane)
- `billing` — plans, invoices, Stripe metadata
- `flags` — global feature flags / toggles
- `audit` — control-plane audit logs

Reserved:
- `flyway` — schema for Flyway’s history table (configured in `flyway.conf`)

## Safety standards

- Prefer **expand/contract** for breaking changes.
- Avoid destructive DDL by default (`DROP`, table rewrites, type changes). Require explicit intent and review when needed.
- Keep migrations small and reviewable; **one object per script** where practical, except for the initial bootstrap migration which may establish multiple schemas/extensions in one atomic step.

