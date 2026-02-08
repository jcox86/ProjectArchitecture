-- module: db.catalog.catalog
-- purpose: Seed a default tenant route for the system tenant when enabled.
-- exports:
--   - seed: catalog.tenant_route
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into catalog.tenant_route (
      route_id,
      tenant_id,
      host_name,
      is_primary,
      tenant_route_status_id,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000004',
      '00000000-0000-0000-0000-000000000001',
      'system.local',
      true,
      (select tenant_route_status_id from catalog.tenant_route_status where status_key = 'active'),
      now(),
      now()
    )
    on conflict (host_name) do update
    set tenant_id = excluded.tenant_id,
        is_primary = excluded.is_primary,
        tenant_route_status_id = excluded.tenant_route_status_id,
        updated_at = now();
  end if;
end $$;
