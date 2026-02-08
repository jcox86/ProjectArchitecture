-- module: db.catalog.billing
-- purpose: Create billing.addon_price for add-on price points.
-- exports:
--   - table: billing.addon_price
-- patterns:
--   - flyway_versioned

create table if not exists billing.addon_price (
  addon_price_id uuid primary key default gen_random_uuid(),
  addon_id uuid not null references billing.addon(addon_id) on delete cascade,
  currency_code text not null,
  amount_cents int not null,
  price_interval_id smallint not null references billing.price_interval(price_interval_id),
  price_status_id smallint not null references billing.price_status(price_status_id),
  external_price_key text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint addon_price_currency_check check (char_length(currency_code) = 3),
  constraint addon_price_amount_check check (amount_cents >= 0),
  constraint addon_price_unique unique (addon_id, currency_code, price_interval_id)
);
