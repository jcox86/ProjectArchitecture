-- module: db.catalog.billing
-- purpose: Add audit columns to billing.payment.
-- exports:
--   - table: billing.payment (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.payment
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
