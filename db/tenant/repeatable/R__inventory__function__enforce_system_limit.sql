-- module: db.tenant.inventory
-- purpose: Enforce per-tenant system count limits.
-- exports:
--   - function: inventory.enforce_system_limit()
-- patterns:
--   - flyway_repeatable
--   - limits

create or replace function inventory.enforce_system_limit()
returns trigger
language plpgsql
as $$
declare
  v_limit integer;
  v_count integer;
  v_is_activation boolean;
begin
  if new.is_active is not true then
    return new;
  end if;

  v_is_activation :=
    (tg_op = 'INSERT') or
    (tg_op = 'UPDATE' and (old.is_active is not true));

  if not v_is_activation then
    return new;
  end if;

  v_limit := inventory.resolve_limit_value(new.tenant_id, null, 'systems');
  if v_limit is null then
    return new;
  end if;

  select count(*)
    into v_count
  from inventory.system s
  where s.tenant_id = new.tenant_id
    and s.is_active = true;

  if v_count >= v_limit then
    raise exception 'System limit exceeded for tenant % (limit=%)', new.tenant_id, v_limit
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;
