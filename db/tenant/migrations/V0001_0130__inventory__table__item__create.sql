-- module: db.tenant.inventory
-- purpose: Create the inventory.item table for tenant-scoped inventory items.
-- exports:
--   - table: inventory.item
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Items are scoped to a tenant and linked to a system within the same tenant.

create table if not exists inventory.item (
  tenant_id uuid not null default core.current_tenant_id(),
  item_id uuid not null default gen_random_uuid(),
  system_id uuid not null,
  name text not null,
  sku text null,
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint item_pk primary key (tenant_id, item_id),
  constraint item_system_fk foreign key (tenant_id, system_id)
    references inventory.system (tenant_id, system_id)
    on delete cascade
);

alter table inventory.item enable row level security;
alter table inventory.item force row level security;

create trigger item_set_updated_at
before update on inventory.item
for each row
execute function core.set_updated_at();
