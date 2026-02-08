-- module: db.catalog.catalog
-- purpose: Seed a system tenant for local/dev usage when enabled.
-- exports:
--   - seed: catalog.tenant
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into catalog.tenant (
      tenant_id,
      tenant_key,
      display_name,
      tenant_tier_id,
      tenant_status_id,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000001',
      'system',
      'System',
      (select tenant_tier_id from catalog.tenant_tier where tier_key = 'shared'),
      (select tenant_status_id from catalog.tenant_status where status_key = 'active'),
      now(),
      now()
    )
    on conflict (tenant_key) do update
    set display_name = excluded.display_name,
        tenant_tier_id = excluded.tenant_tier_id,
        tenant_status_id = excluded.tenant_status_id,
        updated_at = now();
  end if;
end $$;
