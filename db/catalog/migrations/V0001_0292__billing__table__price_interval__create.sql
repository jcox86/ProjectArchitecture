-- module: db.catalog.billing
-- purpose: Create billing.price_interval lookup for billing intervals.
-- exports:
--   - table: billing.price_interval
-- patterns:
--   - flyway_versioned

create table if not exists billing.price_interval (
  price_interval_id smallint primary key,
  interval_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint price_interval_key_unique unique (interval_key)
);
