-- module: db.catalog.catalog
-- purpose: Create catalog.tenant table for tenant registry and lifecycle status.
-- exports:
--   - table: catalog.tenant
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant (
  tenant_id uuid primary key default gen_random_uuid(),
  tenant_key citext not null,
  display_name text not null,
  tenant_tier_id smallint not null references catalog.tenant_tier(tenant_tier_id),
  tenant_status_id smallint not null references catalog.tenant_status(tenant_status_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_key_unique unique (tenant_key)
);
