-- module: db.tenant.inventory
-- purpose: Create the inventory.item_property_definition table for user-defined item fields.
-- exports:
--   - table: inventory.item_property_definition
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Property definitions can be template-scoped or tenant-wide.

create table if not exists inventory.item_property_definition (
  tenant_id uuid not null default core.current_tenant_id(),
  property_definition_id uuid not null default gen_random_uuid(),
  template_id uuid null,
  name text not null,
  description text null,
  data_type text not null,
  is_required boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint item_property_definition_pk primary key (tenant_id, property_definition_id),
  constraint item_property_definition_template_fk foreign key (tenant_id, template_id)
    references inventory.item_template (tenant_id, template_id)
    on delete cascade,
  constraint item_property_definition_data_type_check check (
    data_type in ('text', 'number', 'boolean', 'date', 'json')
  )
);

create index if not exists item_property_definition_tenant_template_ix
  on inventory.item_property_definition (tenant_id, template_id);

alter table inventory.item_property_definition enable row level security;
alter table inventory.item_property_definition force row level security;

create trigger item_property_definition_set_updated_at
before update on inventory.item_property_definition
for each row
execute function core.set_updated_at();
