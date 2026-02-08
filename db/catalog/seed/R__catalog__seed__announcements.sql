-- module: db.catalog.catalog
-- purpose: Seed a default announcement for local/dev when enabled.
-- exports:
--   - seed: catalog.announcement
--   - seed: catalog.announcement_tenant_override
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into catalog.announcement (
      announcement_id,
      announcement_key,
      announcement_type_id,
      announcement_status_id,
      title,
      message_html,
      starts_at,
      ends_at,
      is_dismissible,
      priority,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000070',
      'welcome',
      (select announcement_type_id from catalog.announcement_type where type_key = 'announcement'),
      (select announcement_status_id from catalog.announcement_status where status_key = 'active'),
      'Welcome',
      '<p>Welcome to the system.</p>',
      now(),
      null,
      true,
      0,
      now(),
      now()
    )
    on conflict (announcement_key) do update
    set title = excluded.title,
        message_html = excluded.message_html,
        announcement_type_id = excluded.announcement_type_id,
        announcement_status_id = excluded.announcement_status_id,
        starts_at = excluded.starts_at,
        ends_at = excluded.ends_at,
        is_dismissible = excluded.is_dismissible,
        priority = excluded.priority,
        updated_at = now();

    insert into catalog.announcement_tenant_override (
      announcement_tenant_override_id,
      announcement_id,
      tenant_id,
      announcement_status_id,
      title,
      message_html,
      starts_at,
      ends_at,
      is_dismissible,
      priority,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000071',
      '00000000-0000-0000-0000-000000000070',
      '00000000-0000-0000-0000-000000000001',
      (select announcement_status_id from catalog.announcement_status where status_key = 'active'),
      'Welcome, System Tenant',
      '<p>System tenant announcement override.</p>',
      now(),
      null,
      true,
      1,
      now(),
      now()
    )
    on conflict (tenant_id, announcement_id) do update
    set announcement_status_id = excluded.announcement_status_id,
        title = excluded.title,
        message_html = excluded.message_html,
        starts_at = excluded.starts_at,
        ends_at = excluded.ends_at,
        is_dismissible = excluded.is_dismissible,
        priority = excluded.priority,
        updated_at = now();
  end if;
end $$;
