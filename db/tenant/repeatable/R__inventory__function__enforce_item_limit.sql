-- module: db.tenant.inventory
-- purpose: Enforce per-tenant item count limits.
-- exports:
--   - function: inventory.enforce_item_limit()
-- patterns:
--   - flyway_repeatable
--   - limits

create or replace function inventory.enforce_item_limit()
returns trigger
language plpgsql
as $$
declare
  v_limit integer;
  v_limit_text text;
  v_use_system_scope boolean := false;
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

  select l.limits_json ->> 'items'
    into v_limit_text
  from inventory.limits l
  where l.tenant_id = new.tenant_id
    and l.system_id = new.system_id
    and l.is_active = true
  order by l.created_at desc
  limit 1;

  if v_limit_text is not null and v_limit_text <> '' then
    v_use_system_scope := true;
  else
    select l.limits_json ->> 'items'
      into v_limit_text
    from inventory.limits l
    where l.tenant_id = new.tenant_id
      and l.system_id is null
      and l.is_active = true
    order by l.created_at desc
    limit 1;
  end if;

  if v_limit_text is null or v_limit_text = '' then
    return new;
  end if;

  begin
    v_limit := v_limit_text::integer;
  exception when invalid_text_representation then
    return new;
  end;

  if v_limit < 0 then
    return new;
  end if;

  if v_use_system_scope then
    select count(*)
      into v_count
    from inventory.item i
    where i.tenant_id = new.tenant_id
      and i.system_id = new.system_id
      and i.is_active = true;
  else
    select count(*)
      into v_count
    from inventory.item i
    where i.tenant_id = new.tenant_id
      and i.is_active = true;
  end if;

  if v_count >= v_limit then
    raise exception 'Item limit exceeded for tenant % (limit=%)', new.tenant_id, v_limit
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;
