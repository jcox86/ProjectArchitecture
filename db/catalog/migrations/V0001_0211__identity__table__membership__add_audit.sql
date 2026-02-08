-- module: db.catalog.identity
-- purpose: Add audit columns to identity.membership.
-- exports:
--   - table: identity.membership (audit columns)
-- patterns:
--   - flyway_versioned

alter table identity.membership
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
