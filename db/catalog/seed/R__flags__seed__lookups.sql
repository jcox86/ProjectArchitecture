-- module: db.catalog.flags
-- purpose: Seed lookup tables for feature flag scopes and statuses.
-- exports:
--   - seed: flags.flag_scope
--   - seed: flags.flag_status
-- patterns:
--   - flyway_seed

insert into flags.flag_scope (flag_scope_id, scope_key, name, is_active)
values
  (1, 'global', 'Global', true),
  (2, 'tenant', 'Tenant', true)
on conflict (scope_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into flags.flag_status (flag_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true),
  (3, 'deprecated', 'Deprecated', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
