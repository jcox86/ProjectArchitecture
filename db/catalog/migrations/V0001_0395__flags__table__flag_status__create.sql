-- module: db.catalog.flags
-- purpose: Create flags.flag_status lookup for feature flag status.
-- exports:
--   - table: flags.flag_status
-- patterns:
--   - flyway_versioned

create table if not exists flags.flag_status (
  flag_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint flag_status_key_unique unique (status_key)
);
