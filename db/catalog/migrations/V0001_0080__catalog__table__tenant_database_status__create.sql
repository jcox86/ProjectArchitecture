-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_database_status lookup for data-plane status.
-- exports:
--   - table: catalog.tenant_database_status
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_database_status (
  tenant_database_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint tenant_database_status_key_unique unique (status_key)
);
