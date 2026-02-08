-- module: db.catalog.catalog
-- purpose: Add audit columns to catalog.announcement.
-- exports:
--   - table: catalog.announcement (audit columns)
-- patterns:
--   - flyway_versioned

alter table catalog.announcement
  add column if not exists created_by uuid null references identity.subject(subject_id),
  add column if not exists updated_by uuid null references identity.subject(subject_id);
