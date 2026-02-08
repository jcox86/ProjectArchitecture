-- module: db.tenant.inventory
-- purpose: Create the inventory.item_template table for reusable item templates.
-- exports:
--   - table: inventory.item_template
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Templates can be linked to a system for scoped reuse.

create table if not exists inventory.item_template (
  tenant_id uuid not null default core.current_tenant_id(),
  template_id uuid not null default gen_random_uuid(),
  system_id uuid null,
  name text not null,
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint item_template_pk primary key (tenant_id, template_id),
  constraint item_template_system_fk foreign key (tenant_id, system_id)
    references inventory.system (tenant_id, system_id)
    on delete set null
);

create index if not exists item_template_tenant_system_ix
  on inventory.item_template (tenant_id, system_id);

alter table inventory.item_template enable row level security;
alter table inventory.item_template force row level security;

create trigger item_template_set_updated_at
before update on inventory.item_template
for each row
execute function core.set_updated_at();
