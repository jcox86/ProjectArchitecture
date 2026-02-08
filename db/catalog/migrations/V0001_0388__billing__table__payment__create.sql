-- module: db.catalog.billing
-- purpose: Create billing.payment for payment records and reconciliation.
-- exports:
--   - table: billing.payment
-- patterns:
--   - flyway_versioned

create table if not exists billing.payment (
  payment_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  invoice_id uuid null references billing.invoice(invoice_id) on delete set null,
  external_payment_key text null,
  amount_cents int not null,
  currency_code text not null,
  payment_method_id smallint not null references billing.payment_method(payment_method_id),
  payment_status_id smallint not null references billing.payment_status(payment_status_id),
  processed_at timestamptz null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_currency_check check (char_length(currency_code) = 3),
  constraint payment_amount_check check (amount_cents >= 0),
  constraint payment_external_key_unique unique (external_payment_key)
);
