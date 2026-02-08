-- module: db.tenant.inventory
-- purpose: Add audit and status columns to inventory.item.
-- exports:
--   - table: inventory.item
-- patterns:
--   - flyway_versioned
-- notes:
--   - Adds created_by, updated_by, and is_active for audit/history support.

alter table inventory.item
  add column if not exists created_by uuid null,
  add column if not exists updated_by uuid null,
  add column if not exists is_active boolean not null default true;
