-- module: db.catalog.audit
-- purpose: Create audit.event_severity lookup for audit severity levels.
-- exports:
--   - table: audit.event_severity
-- patterns:
--   - flyway_versioned

create table if not exists audit.event_severity (
  event_severity_id smallint primary key,
  severity_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint event_severity_key_unique unique (severity_key)
);
