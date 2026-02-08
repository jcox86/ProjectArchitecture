-- module: db.catalog.billing
-- purpose: Add audit columns to billing.plan_price.
-- exports:
--   - table: billing.plan_price (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.plan_price
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
