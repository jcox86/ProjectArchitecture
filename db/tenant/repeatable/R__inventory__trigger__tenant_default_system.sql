-- module: db.tenant.inventory
-- purpose: Ensure each tenant gets a default system on creation.
-- exports:
--   - trigger: inventory.tenant_default_system
-- patterns:
--   - flyway_repeatable
-- notes:
--   - Trigger inserts a default system and sets tenant.default_system_id.

create or replace function inventory.create_default_system_for_tenant()
returns trigger
language plpgsql
as $$
declare
  v_system_id uuid;
begin
  if new.default_system_id is not null then
    return new;
  end if;

  v_system_id := gen_random_uuid();

  insert into inventory.system (
    tenant_id,
    system_id,
    name,
    description,
    created_at,
    updated_at,
    created_by,
    updated_by,
    is_active
  )
  values (
    new.tenant_id,
    v_system_id,
    'Default',
    'Default system',
    now(),
    now(),
    new.created_by,
    new.updated_by,
    true
  );

  new.default_system_id := v_system_id;
  return new;
end;
$$;

drop trigger if exists tenant_default_system on inventory.tenant;

create trigger tenant_default_system
before insert on inventory.tenant
for each row
execute function inventory.create_default_system_for_tenant();
