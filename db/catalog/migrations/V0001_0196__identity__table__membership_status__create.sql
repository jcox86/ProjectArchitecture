-- module: db.catalog.identity
-- purpose: Create identity.membership_status lookup for membership status.
-- exports:
--   - table: identity.membership_status
-- patterns:
--   - flyway_versioned

create table if not exists identity.membership_status (
  membership_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint membership_status_key_unique unique (status_key)
);
