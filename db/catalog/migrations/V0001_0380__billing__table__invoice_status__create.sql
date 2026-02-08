-- module: db.catalog.billing
-- purpose: Create billing.invoice_status lookup for invoice lifecycle.
-- exports:
--   - table: billing.invoice_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.invoice_status (
  invoice_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint invoice_status_key_unique unique (status_key)
);
