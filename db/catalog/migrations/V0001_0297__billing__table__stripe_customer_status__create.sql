-- module: db.catalog.billing
-- purpose: Create billing.stripe_customer_status lookup for Stripe customer lifecycle.
-- exports:
--   - table: billing.stripe_customer_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.stripe_customer_status (
  stripe_customer_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint stripe_customer_status_key_unique unique (status_key)
);
