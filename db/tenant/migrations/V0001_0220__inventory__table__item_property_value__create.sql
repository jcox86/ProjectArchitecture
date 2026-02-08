-- module: db.tenant.inventory
-- purpose: Create the inventory.item_property_value table for item custom values.
-- exports:
--   - table: inventory.item_property_value
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Values are stored in type-specific columns.

create table if not exists inventory.item_property_value (
  tenant_id uuid not null default core.current_tenant_id(),
  item_id uuid not null,
  property_definition_id uuid not null,
  value_text text null,
  value_number numeric null,
  value_boolean boolean null,
  value_date date null,
  value_json jsonb null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint item_property_value_pk primary key (tenant_id, item_id, property_definition_id),
  constraint item_property_value_item_fk foreign key (tenant_id, item_id)
    references inventory.item (tenant_id, item_id)
    on delete cascade,
  constraint item_property_value_definition_fk foreign key (tenant_id, property_definition_id)
    references inventory.item_property_definition (tenant_id, property_definition_id)
    on delete cascade
);

alter table inventory.item_property_value enable row level security;
alter table inventory.item_property_value force row level security;

create trigger item_property_value_set_updated_at
before update on inventory.item_property_value
for each row
execute function core.set_updated_at();
