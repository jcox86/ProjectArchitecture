-- module: db.catalog.billing
-- purpose: Create billing.subscription_status lookup for tenant subscriptions.
-- exports:
--   - table: billing.subscription_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.subscription_status (
  subscription_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint subscription_status_key_unique unique (status_key)
);
