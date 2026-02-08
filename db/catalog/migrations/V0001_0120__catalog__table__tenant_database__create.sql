-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_database to store data-plane database mapping per tenant.
-- exports:
--   - table: catalog.tenant_database
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_database (
  tenant_database_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  database_name text not null,
  server_name text null,
  tenant_database_tier_id smallint not null references catalog.tenant_database_tier(tenant_database_tier_id),
  tenant_database_status_id smallint not null references catalog.tenant_database_status(tenant_database_status_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_database_tenant_unique unique (tenant_id)
);
