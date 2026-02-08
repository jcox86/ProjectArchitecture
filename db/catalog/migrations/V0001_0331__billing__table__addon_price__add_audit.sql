-- module: db.catalog.billing
-- purpose: Add audit columns to billing.addon_price.
-- exports:
--   - table: billing.addon_price (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.addon_price
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
