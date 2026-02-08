-- module: db.tenant.inventory
-- purpose: Resolve effective limit values for a tenant/system pair.
-- exports:
--   - function: inventory.resolve_limit_value(uuid, uuid, text)
-- patterns:
--   - flyway_repeatable
-- notes:
--   - Returns NULL when no limit is configured or value is invalid.

create or replace function inventory.resolve_limit_value(
  p_tenant_id uuid,
  p_system_id uuid,
  p_key text
)
returns integer
language plpgsql
stable
as $$
declare
  v_limit_text text;
  v_limit integer;
begin
  if p_tenant_id is null or p_key is null then
    return null;
  end if;

  select l.limits_json ->> p_key
    into v_limit_text
  from inventory.limits l
  where l.tenant_id = p_tenant_id
    and l.system_id = p_system_id
    and l.is_active = true
  order by l.created_at desc
  limit 1;

  if v_limit_text is null and p_system_id is not null then
    select l.limits_json ->> p_key
      into v_limit_text
    from inventory.limits l
    where l.tenant_id = p_tenant_id
      and l.system_id is null
      and l.is_active = true
    order by l.created_at desc
    limit 1;
  end if;

  if v_limit_text is null or v_limit_text = '' then
    return null;
  end if;

  begin
    v_limit := v_limit_text::integer;
  exception when invalid_text_representation then
    return null;
  end;

  if v_limit < 0 then
    return null;
  end if;

  return v_limit;
end;
$$;
