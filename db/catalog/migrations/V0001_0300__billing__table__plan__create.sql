-- module: db.catalog.billing
-- purpose: Create billing.plan catalog for subscription tiers.
-- exports:
--   - table: billing.plan
-- patterns:
--   - flyway_versioned

create table if not exists billing.plan (
  plan_id uuid primary key default gen_random_uuid(),
  plan_key text not null,
  name text not null,
  description text null,
  plan_status_id smallint not null references billing.plan_status(plan_status_id),
  trial_days int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint plan_key_unique unique (plan_key)
);
