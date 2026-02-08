-- module: db.tenant.inventory
-- purpose: Create the inventory schema for tenant-scoped inventory data.
-- exports:
--   - schema: inventory
-- patterns:
--   - flyway_versioned
-- notes:
--   - Inventory objects live under the inventory schema.

create schema if not exists inventory;
