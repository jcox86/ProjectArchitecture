-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.item_property_definition rows via RLS.
-- exports:
--   - policy: inventory.item_property_definition_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists item_property_definition_tenant_isolation
  on inventory.item_property_definition;

create policy item_property_definition_tenant_isolation
on inventory.item_property_definition
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
