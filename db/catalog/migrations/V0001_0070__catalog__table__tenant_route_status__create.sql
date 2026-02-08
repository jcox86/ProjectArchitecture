-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_route_status lookup for tenant route state.
-- exports:
--   - table: catalog.tenant_route_status
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_route_status (
  tenant_route_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint tenant_route_status_key_unique unique (status_key)
);
