-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.system_user_assignment rows via RLS.
-- exports:
--   - policy: inventory.system_user_assignment_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists system_user_assignment_tenant_isolation
  on inventory.system_user_assignment;

create policy system_user_assignment_tenant_isolation
on inventory.system_user_assignment
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
