-- module: db.catalog.catalog
-- purpose: Create catalog.announcement_type lookup for system announcements and notifications.
-- exports:
--   - table: catalog.announcement_type
-- patterns:
--   - flyway_versioned

create table if not exists catalog.announcement_type (
  announcement_type_id smallint primary key,
  type_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint announcement_type_key_unique unique (type_key)
);
