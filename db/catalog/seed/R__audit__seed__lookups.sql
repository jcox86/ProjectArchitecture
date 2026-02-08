-- module: db.catalog.audit
-- purpose: Seed lookup tables for audit severity.
-- exports:
--   - seed: audit.event_severity
-- patterns:
--   - flyway_seed

insert into audit.event_severity (event_severity_id, severity_key, name, is_active)
values
  (1, 'info', 'Info', true),
  (2, 'warning', 'Warning', true),
  (3, 'error', 'Error', true)
on conflict (severity_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
