-- module: db.catalog.billing
-- purpose: Create billing.refund_status lookup for refund lifecycle.
-- exports:
--   - table: billing.refund_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.refund_status (
  refund_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint refund_status_key_unique unique (status_key)
);
