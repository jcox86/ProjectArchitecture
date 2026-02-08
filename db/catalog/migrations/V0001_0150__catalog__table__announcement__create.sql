-- module: db.catalog.catalog
-- purpose: Create catalog.announcement for system announcements and notifications.
-- exports:
--   - table: catalog.announcement
-- patterns:
--   - flyway_versioned

create table if not exists catalog.announcement (
  announcement_id uuid primary key default gen_random_uuid(),
  announcement_key text not null,
  announcement_type_id smallint not null references catalog.announcement_type(announcement_type_id),
  announcement_status_id smallint not null references catalog.announcement_status(announcement_status_id),
  title text not null,
  message_html text not null,
  starts_at timestamptz null,
  ends_at timestamptz null,
  is_dismissible boolean not null default true,
  priority smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcement_key_unique unique (announcement_key)
);
