-- module: db.catalog.catalog
-- purpose: Add audit columns to catalog.key_vault_ref.
-- exports:
--   - table: catalog.key_vault_ref (audit columns)
-- patterns:
--   - flyway_versioned

alter table catalog.key_vault_ref
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
