-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.limits rows via RLS.
-- exports:
--   - policy: inventory.limits_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists limits_tenant_isolation
  on inventory.limits;

create policy limits_tenant_isolation
on inventory.limits
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
