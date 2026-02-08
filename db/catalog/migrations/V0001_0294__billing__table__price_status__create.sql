-- module: db.catalog.billing
-- purpose: Create billing.price_status lookup for price status.
-- exports:
--   - table: billing.price_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.price_status (
  price_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint price_status_key_unique unique (status_key)
);
