-- module: db.catalog.billing
-- purpose: Create billing.payment_method lookup for payment methods.
-- exports:
--   - table: billing.payment_method
-- patterns:
--   - flyway_versioned

create table if not exists billing.payment_method (
  payment_method_id smallint primary key,
  method_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint payment_method_key_unique unique (method_key)
);
