-- module: db.catalog.billing
-- purpose: Create billing.tenant_subscription for per-tenant plan selection.
-- exports:
--   - table: billing.tenant_subscription
-- patterns:
--   - flyway_versioned

create table if not exists billing.tenant_subscription (
  tenant_subscription_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  plan_id uuid not null references billing.plan(plan_id),
  subscription_status_id smallint not null references billing.subscription_status(subscription_status_id),
  trial_ends_at timestamptz null,
  current_period_start timestamptz null,
  current_period_end timestamptz null,
  cancel_at timestamptz null,
  cancel_at_period_end boolean not null default false,
  external_subscription_key text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_subscription_tenant_unique unique (tenant_id)
);
