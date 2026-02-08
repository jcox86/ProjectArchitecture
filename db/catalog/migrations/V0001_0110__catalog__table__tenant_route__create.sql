-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_route to map hosts to tenants for routing.
-- exports:
--   - table: catalog.tenant_route
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_route (
  route_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  host_name citext not null,
  is_primary boolean not null default true,
  tenant_route_status_id smallint not null references catalog.tenant_route_status(tenant_route_status_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_route_host_unique unique (host_name),
  constraint tenant_route_tenant_host_unique unique (tenant_id, host_name)
);
