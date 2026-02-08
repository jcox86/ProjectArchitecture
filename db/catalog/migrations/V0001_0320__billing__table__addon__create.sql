-- module: db.catalog.billing
-- purpose: Create billing.addon for optional subscription add-ons.
-- exports:
--   - table: billing.addon
-- patterns:
--   - flyway_versioned

create table if not exists billing.addon (
  addon_id uuid primary key default gen_random_uuid(),
  addon_key text not null,
  name text not null,
  description text null,
  addon_status_id smallint not null references billing.addon_status(addon_status_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint addon_key_unique unique (addon_key)
);
