-- module: db.tenant.inventory
-- purpose: Create the inventory.system table for grouping items within a tenant.
-- exports:
--   - table: inventory.system
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Systems belong to a tenant and are isolated via RLS.

create table if not exists inventory.system (
  tenant_id uuid not null default core.current_tenant_id(),
  system_id uuid not null default gen_random_uuid(),
  name text not null,
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint system_pk primary key (tenant_id, system_id),
  constraint system_tenant_fk foreign key (tenant_id)
    references inventory.tenant (tenant_id)
    on delete cascade
);

alter table inventory.system enable row level security;
alter table inventory.system force row level security;

create trigger system_set_updated_at
before update on inventory.system
for each row
execute function core.set_updated_at();
