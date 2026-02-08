-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.tenant rows via RLS.
-- exports:
--   - policy: inventory.tenant_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists tenant_tenant_isolation on inventory.tenant;

create policy tenant_tenant_isolation
on inventory.tenant
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
