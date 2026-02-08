-- module: db.catalog.catalog
-- purpose: Add audit columns to catalog.announcement_tenant_override.
-- exports:
--   - table: catalog.announcement_tenant_override (audit columns)
-- patterns:
--   - flyway_versioned

alter table catalog.announcement_tenant_override
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
