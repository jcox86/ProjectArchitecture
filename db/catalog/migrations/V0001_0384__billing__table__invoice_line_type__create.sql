-- module: db.catalog.billing
-- purpose: Create billing.invoice_line_type lookup for invoice line categorization.
-- exports:
--   - table: billing.invoice_line_type
-- patterns:
--   - flyway_versioned

create table if not exists billing.invoice_line_type (
  invoice_line_type_id smallint primary key,
  type_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint invoice_line_type_key_unique unique (type_key)
);
