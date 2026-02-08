-- module: db.catalog.billing
-- purpose: Create billing.payment_status lookup for payment lifecycle.
-- exports:
--   - table: billing.payment_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.payment_status (
  payment_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint payment_status_key_unique unique (status_key)
);
