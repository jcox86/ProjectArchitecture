-- module: db.catalog.flags
-- purpose: Compute effective flag values for the current tenant context.
-- exports:
--   - function: flags.effective_flags()
-- patterns:
--   - flyway_repeatable

create or replace function flags.effective_flags()
returns table (flag_key text, is_enabled boolean, config jsonb, flag_scope_id smallint)
language sql
stable
as $$
  select
    f.flag_key,
    coalesce(o.is_enabled, f.is_enabled) as is_enabled,
    coalesce(o.config, f.config) as config,
    f.flag_scope_id
  from flags.flag f
  left join flags.flag_tenant_override o
    on o.flag_id = f.flag_id
   and o.tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid
  join flags.flag_status fs on fs.flag_status_id = f.flag_status_id
  where fs.status_key = 'active';
$$;
