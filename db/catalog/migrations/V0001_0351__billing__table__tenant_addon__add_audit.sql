-- module: db.catalog.billing
-- purpose: Add audit columns to billing.tenant_addon.
-- exports:
--   - table: billing.tenant_addon (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.tenant_addon
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
