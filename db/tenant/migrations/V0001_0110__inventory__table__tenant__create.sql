-- module: db.tenant.inventory
-- purpose: Create the inventory.tenant table to represent tenant-level inventory metadata.
-- exports:
--   - table: inventory.tenant
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Enforces tenant isolation via RLS policies bound to core.current_tenant_id().

create table if not exists inventory.tenant (
  tenant_id uuid not null default core.current_tenant_id(),
  name text not null,
  slug citext not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_pk primary key (tenant_id),
  constraint tenant_slug_unique unique (slug)
);

alter table inventory.tenant enable row level security;
alter table inventory.tenant force row level security;

create trigger tenant_set_updated_at
before update on inventory.tenant
for each row
execute function core.set_updated_at();
