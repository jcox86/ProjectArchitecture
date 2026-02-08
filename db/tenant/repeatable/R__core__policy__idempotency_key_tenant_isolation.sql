-- module: db.tenant.core
-- purpose: Enforce tenant isolation for core.idempotency_key rows via RLS.
-- exports:
--   - policy: core.idempotency_key_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists idempotency_key_tenant_isolation on core.idempotency_key;

create policy idempotency_key_tenant_isolation
on core.idempotency_key
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
