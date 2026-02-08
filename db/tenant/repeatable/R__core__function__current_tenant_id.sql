-- module: db.tenant.core
-- purpose: Define a shared helper to read the current tenant id from session settings for RLS policies.
-- exports:
--   - function: core.current_tenant_id()
-- patterns:
--   - flyway_repeatable
--   - rls
-- notes:
--   - Uses `current_setting('app.tenant_id', true)` so missing tenant context yields NULL (safe default).

create or replace function core.current_tenant_id()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('app.tenant_id', true), '')::uuid;
$$;

