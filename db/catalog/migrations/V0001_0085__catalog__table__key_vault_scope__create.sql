-- module: db.catalog.catalog
-- purpose: Create catalog.key_vault_scope lookup for key vault reference scope.
-- exports:
--   - table: catalog.key_vault_scope
-- patterns:
--   - flyway_versioned

create table if not exists catalog.key_vault_scope (
  key_vault_scope_id smallint primary key,
  scope_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint key_vault_scope_key_unique unique (scope_key)
);
