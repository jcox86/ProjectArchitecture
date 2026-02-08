-- module: db.catalog.billing
-- purpose: Add audit columns to billing.refund.
-- exports:
--   - table: billing.refund (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.refund
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
