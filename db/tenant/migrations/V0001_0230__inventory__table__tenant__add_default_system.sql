-- module: db.tenant.inventory
-- purpose: Add default_system_id to inventory.tenant for per-tenant default systems.
-- exports:
--   - table: inventory.tenant
-- patterns:
--   - flyway_versioned
-- notes:
--   - Default system is created via a trigger in repeatable scripts.

alter table inventory.tenant
  add column if not exists default_system_id uuid null;

alter table inventory.tenant
  add constraint tenant_default_system_fk
  foreign key (tenant_id, default_system_id)
  references inventory.system (tenant_id, system_id)
  on delete set null;
