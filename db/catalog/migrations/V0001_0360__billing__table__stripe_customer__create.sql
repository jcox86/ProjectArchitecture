-- module: db.catalog.billing
-- purpose: Create billing.stripe_customer to map tenants to Stripe customers.
-- exports:
--   - table: billing.stripe_customer
-- patterns:
--   - flyway_versioned

create table if not exists billing.stripe_customer (
  stripe_customer_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  customer_id text not null,
  stripe_customer_status_id smallint not null references billing.stripe_customer_status(stripe_customer_status_id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stripe_customer_tenant_unique unique (tenant_id),
  constraint stripe_customer_id_unique unique (customer_id)
);
