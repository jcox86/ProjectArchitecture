-- module: db.catalog.catalog
-- purpose: Seed lookup tables for catalog tenant and routing metadata.
-- exports:
--   - seed: catalog.tenant_tier
--   - seed: catalog.tenant_status
--   - seed: catalog.tenant_route_status
--   - seed: catalog.tenant_database_tier
--   - seed: catalog.tenant_database_status
--   - seed: catalog.key_vault_scope
-- patterns:
--   - flyway_seed

insert into catalog.tenant_tier (tenant_tier_id, tier_key, name, is_active)
values
  (1, 'shared', 'Shared', true),
  (2, 'isolated', 'Isolated', true)
on conflict (tier_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.tenant_status (tenant_status_id, status_key, name, is_active)
values
  (1, 'provisioning', 'Provisioning', true),
  (2, 'active', 'Active', true),
  (3, 'suspended', 'Suspended', true),
  (4, 'deleted', 'Deleted', false)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.tenant_route_status (tenant_route_status_id, status_key, name, is_active)
values
  (1, 'pending', 'Pending', true),
  (2, 'active', 'Active', true),
  (3, 'disabled', 'Disabled', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.tenant_database_tier (tenant_database_tier_id, tier_key, name, is_active)
values
  (1, 'shared', 'Shared', true),
  (2, 'isolated', 'Isolated', true)
on conflict (tier_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.tenant_database_status (tenant_database_status_id, status_key, name, is_active)
values
  (1, 'provisioning', 'Provisioning', true),
  (2, 'active', 'Active', true),
  (3, 'archived', 'Archived', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.key_vault_scope (key_vault_scope_id, scope_key, name, is_active)
values
  (1, 'global', 'Global', true),
  (2, 'tenant', 'Tenant', true),
  (3, 'billing', 'Billing', true),
  (4, 'identity', 'Identity', true)
on conflict (scope_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.announcement_status (announcement_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true),
  (3, 'archived', 'Archived', false)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into catalog.announcement_type (announcement_type_id, type_key, name, is_active)
values
  (1, 'announcement', 'Announcement', true),
  (2, 'notification', 'Notification', true)
on conflict (type_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
