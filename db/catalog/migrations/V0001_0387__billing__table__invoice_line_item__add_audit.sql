-- module: db.catalog.billing
-- purpose: Add audit columns to billing.invoice_line_item.
-- exports:
--   - table: billing.invoice_line_item (audit columns)
-- patterns:
--   - flyway_versioned

alter table billing.invoice_line_item
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
