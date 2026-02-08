-- module: db.catalog.billing
-- purpose: Add audit columns to billing.stripe_customer.
-- exports:
--   - table: billing.stripe_customer (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.stripe_customer
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
