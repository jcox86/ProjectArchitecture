-- module: db.catalog.billing
-- purpose: Create billing.tenant_addon for per-tenant add-on subscriptions.
-- exports:
--   - table: billing.tenant_addon
-- patterns:
--   - flyway_versioned

create table if not exists billing.tenant_addon (
  tenant_addon_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  addon_id uuid not null references billing.addon(addon_id),
  quantity int not null default 1,
  addon_subscription_status_id smallint not null references billing.addon_subscription_status(addon_subscription_status_id),
  external_subscription_item_key text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_addon_quantity_check check (quantity > 0),
  constraint tenant_addon_unique unique (tenant_id, addon_id)
);
