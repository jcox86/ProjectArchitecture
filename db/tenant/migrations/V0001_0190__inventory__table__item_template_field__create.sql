-- module: db.tenant.inventory
-- purpose: Create the inventory.item_template_field table for template-defined fields.
-- exports:
--   - table: inventory.item_template_field
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Supports field types: text, number, boolean, date, json.

create table if not exists inventory.item_template_field (
  tenant_id uuid not null default core.current_tenant_id(),
  field_id uuid not null default gen_random_uuid(),
  template_id uuid not null,
  name text not null,
  data_type text not null,
  is_required boolean not null default false,
  default_value_json jsonb null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint item_template_field_pk primary key (tenant_id, field_id),
  constraint item_template_field_template_fk foreign key (tenant_id, template_id)
    references inventory.item_template (tenant_id, template_id)
    on delete cascade,
  constraint item_template_field_data_type_check check (
    data_type in ('text', 'number', 'boolean', 'date', 'json')
  ),
  constraint item_template_field_name_unique unique (tenant_id, template_id, name)
);

alter table inventory.item_template_field enable row level security;
alter table inventory.item_template_field force row level security;

create trigger item_template_field_set_updated_at
before update on inventory.item_template_field
for each row
execute function core.set_updated_at();
