-- module: db.catalog.flags
-- purpose: Create flags.flag_scope lookup for flag scope values.
-- exports:
--   - table: flags.flag_scope
-- patterns:
--   - flyway_versioned

create table if not exists flags.flag_scope (
  flag_scope_id smallint primary key,
  scope_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint flag_scope_key_unique unique (scope_key)
);
