-- module: db.catalog.billing
-- purpose: Create billing.invoice for reporting and auditing of invoices.
-- exports:
--   - table: billing.invoice
-- patterns:
--   - flyway_versioned

create table if not exists billing.invoice (
  invoice_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  plan_id uuid null references billing.plan(plan_id),
  external_invoice_key text null,
  currency_code text not null,
  amount_subtotal_cents int not null,
  amount_tax_cents int not null default 0,
  amount_total_cents int not null,
  issued_at timestamptz not null,
  due_at timestamptz null,
  paid_at timestamptz null,
  invoice_status_id smallint not null references billing.invoice_status(invoice_status_id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoice_currency_check check (char_length(currency_code) = 3),
  constraint invoice_amount_subtotal_check check (amount_subtotal_cents >= 0),
  constraint invoice_amount_tax_check check (amount_tax_cents >= 0),
  constraint invoice_amount_total_check check (amount_total_cents >= 0),
  constraint invoice_external_key_unique unique (external_invoice_key)
);
