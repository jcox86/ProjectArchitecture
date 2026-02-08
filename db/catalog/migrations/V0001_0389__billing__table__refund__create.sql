-- module: db.catalog.billing
-- purpose: Create billing.refund for payment refund records.
-- exports:
--   - table: billing.refund
-- patterns:
--   - flyway_versioned

create table if not exists billing.refund (
  refund_id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references billing.payment(payment_id) on delete cascade,
  external_refund_key text null,
  amount_cents int not null,
  currency_code text not null,
  refund_status_id smallint not null references billing.refund_status(refund_status_id),
  processed_at timestamptz null,
  reason text null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint refund_currency_check check (char_length(currency_code) = 3),
  constraint refund_amount_check check (amount_cents >= 0),
  constraint refund_external_key_unique unique (external_refund_key)
);
