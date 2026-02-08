-- module: db.catalog.identity
-- purpose: Seed lookup tables for identity providers, roles, and statuses.
-- exports:
--   - seed: identity.subject_provider
--   - seed: identity.membership_role
--   - seed: identity.membership_status
-- patterns:
--   - flyway_seed

insert into identity.subject_provider (subject_provider_id, provider_key, name, is_active)
values
  (1, 'entra', 'Entra ID', true),
  (2, 'b2c', 'Azure B2C', true),
  (3, 'system', 'System', true),
  (4, 'api', 'API Client', true)
on conflict (provider_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into identity.membership_role (membership_role_id, role_key, name, is_active)
values
  (1, 'platform_admin', 'Platform Admin', true),
  (2, 'tenant_admin', 'Tenant Admin', true),
  (3, 'billing_admin', 'Billing Admin', true)
on conflict (role_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into identity.membership_status (membership_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'suspended', 'Suspended', true),
  (3, 'revoked', 'Revoked', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
