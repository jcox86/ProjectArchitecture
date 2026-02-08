-- module: db.catalog.flags
-- purpose: Add audit columns to flags.flag_tenant_override.
-- exports:
--   - table: flags.flag_tenant_override (audit columns)
-- patterns:
--   - flyway_versioned

alter table flags.flag_tenant_override
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
