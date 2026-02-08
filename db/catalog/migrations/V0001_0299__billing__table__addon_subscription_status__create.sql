-- module: db.catalog.billing
-- purpose: Create billing.addon_subscription_status lookup for tenant add-on status.
-- exports:
--   - table: billing.addon_subscription_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.addon_subscription_status (
  addon_subscription_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint addon_subscription_status_key_unique unique (status_key)
);
