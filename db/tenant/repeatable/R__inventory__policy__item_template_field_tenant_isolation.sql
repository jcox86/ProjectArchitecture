-- module: db.tenant.inventory
-- purpose: Enforce tenant isolation for inventory.item_template_field rows via RLS.
-- exports:
--   - policy: inventory.item_template_field_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists item_template_field_tenant_isolation
  on inventory.item_template_field;

create policy item_template_field_tenant_isolation
on inventory.item_template_field
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
