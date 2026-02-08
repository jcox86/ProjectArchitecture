-- module: db.catalog.billing
-- purpose: Create billing.plan_price for price points per plan.
-- exports:
--   - table: billing.plan_price
-- patterns:
--   - flyway_versioned

create table if not exists billing.plan_price (
  plan_price_id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references billing.plan(plan_id) on delete cascade,
  currency_code text not null,
  amount_cents int not null,
  price_interval_id smallint not null references billing.price_interval(price_interval_id),
  price_status_id smallint not null references billing.price_status(price_status_id),
  external_price_key text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint plan_price_currency_check check (char_length(currency_code) = 3),
  constraint plan_price_amount_check check (amount_cents >= 0),
  constraint plan_price_unique unique (plan_id, currency_code, price_interval_id)
);
