-- module: db.catalog.identity
-- purpose: Create identity.membership_role lookup for admin roles.
-- exports:
--   - table: identity.membership_role
-- patterns:
--   - flyway_versioned

create table if not exists identity.membership_role (
  membership_role_id smallint primary key,
  role_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint membership_role_key_unique unique (role_key)
);
