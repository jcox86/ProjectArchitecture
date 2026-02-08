-- module: db.catalog.catalog
-- purpose: Create catalog.announcement_status lookup for announcement lifecycle.
-- exports:
--   - table: catalog.announcement_status
-- patterns:
--   - flyway_versioned

create table if not exists catalog.announcement_status (
  announcement_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint announcement_status_key_unique unique (status_key)
);
