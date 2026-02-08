-- module: db.catalog.audit
-- purpose: Create audit.change_action lookup for change log actions.
-- exports:
--   - table: audit.change_action
-- patterns:
--   - flyway_versioned

create table if not exists audit.change_action (
  change_action_id smallint primary key,
  action_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint change_action_key_unique unique (action_key)
);
