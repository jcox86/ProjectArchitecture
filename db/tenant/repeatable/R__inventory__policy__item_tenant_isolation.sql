-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.item rows via RLS.
-- exports:
--   - policy: inventory.item_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists item_tenant_isolation on inventory.item;

create policy item_tenant_isolation
on inventory.item
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
