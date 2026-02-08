-- module: db.catalog.billing
-- purpose: Create billing.addon_status lookup for add-on lifecycle.
-- exports:
--   - table: billing.addon_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.addon_status (
  addon_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint addon_status_key_unique unique (status_key)
);
