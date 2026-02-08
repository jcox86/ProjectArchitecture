-- module: db.catalog.billing
-- purpose: Create billing.invoice_line_item for detailed invoice breakdowns.
-- exports:
--   - table: billing.invoice_line_item
-- patterns:
--   - flyway_versioned

create table if not exists billing.invoice_line_item (
  invoice_line_item_id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references billing.invoice(invoice_id) on delete cascade,
  invoice_line_type_id smallint not null references billing.invoice_line_type(invoice_line_type_id),
  description text not null,
  quantity int not null default 1,
  unit_amount_cents int not null,
  amount_total_cents int not null,
  currency_code text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoice_line_currency_check check (char_length(currency_code) = 3),
  constraint invoice_line_quantity_check check (quantity > 0),
  constraint invoice_line_unit_amount_check check (unit_amount_cents >= 0),
  constraint invoice_line_total_amount_check check (amount_total_cents >= 0)
);
