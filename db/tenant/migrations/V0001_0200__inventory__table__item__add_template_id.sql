-- module: db.tenant.inventory
-- purpose: Add optional template reference to inventory.item.
-- exports:
--   - table: inventory.item
-- patterns:
--   - flyway_versioned
-- notes:
--   - Links an item to a reusable template when applicable.

alter table inventory.item
  add column if not exists template_id uuid null;

alter table inventory.item
  add constraint item_template_fk
  foreign key (tenant_id, template_id)
  references inventory.item_template (tenant_id, template_id)
  on delete set null;
