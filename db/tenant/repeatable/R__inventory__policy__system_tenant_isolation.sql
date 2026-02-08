-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.system rows via RLS.
-- exports:
--   - policy: inventory.system_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists system_tenant_isolation on inventory.system;

create policy system_tenant_isolation
on inventory.system
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
