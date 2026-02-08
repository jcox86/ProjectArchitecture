-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.system_attachment rows via RLS.
-- exports:
--   - policy: inventory.system_attachment_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists system_attachment_tenant_isolation
  on inventory.system_attachment;

create policy system_attachment_tenant_isolation
on inventory.system_attachment
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
