-- module: db.tenant.inventory
-- purpose: Create the inventory.system_user_assignment table for per-user system access.
-- exports:
--   - table: inventory.system_user_assignment
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Stores user-to-system access within a tenant.

create table if not exists inventory.system_user_assignment (
  tenant_id uuid not null default core.current_tenant_id(),
  system_id uuid not null,
  user_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint system_user_assignment_pk primary key (tenant_id, system_id, user_id),
  constraint system_user_assignment_system_fk foreign key (tenant_id, system_id)
    references inventory.system (tenant_id, system_id)
    on delete cascade
);

create index if not exists system_user_assignment_tenant_user_ix
  on inventory.system_user_assignment (tenant_id, user_id);

alter table inventory.system_user_assignment enable row level security;
alter table inventory.system_user_assignment force row level security;

create trigger system_user_assignment_set_updated_at
before update on inventory.system_user_assignment
for each row
execute function core.set_updated_at();
