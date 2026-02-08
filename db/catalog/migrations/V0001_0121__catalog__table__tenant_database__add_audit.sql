-- module: db.catalog.catalog
-- purpose: Add audit columns to catalog.tenant_database.
-- exports:
--   - table: catalog.tenant_database (audit columns)
-- patterns:
--   - flyway_versioned

alter table catalog.tenant_database
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
