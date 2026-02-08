-- module: db.catalog.billing
-- purpose: Create billing.stripe_metadata for storing Stripe object metadata snapshots.
-- exports:
--   - table: billing.stripe_metadata
-- patterns:
--   - flyway_versioned

create table if not exists billing.stripe_metadata (
  stripe_metadata_id uuid primary key default gen_random_uuid(),
  tenant_id uuid null references catalog.tenant(tenant_id) on delete cascade,
  object_type text not null,
  object_id text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint stripe_metadata_object_unique unique (object_type, object_id)
);
