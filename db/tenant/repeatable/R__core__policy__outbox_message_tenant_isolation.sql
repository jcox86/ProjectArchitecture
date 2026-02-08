-- module: db.tenant.core
-- purpose: Enforce tenant isolation for core.outbox_message rows via RLS.
-- exports:
--   - policy: core.outbox_message_tenant_isolation
-- patterns:
--   - flyway_repeatable
--   - rls

drop policy if exists outbox_message_tenant_isolation on core.outbox_message;

create policy outbox_message_tenant_isolation
on core.outbox_message
using (tenant_id = core.current_tenant_id())
with check (tenant_id = core.current_tenant_id());
