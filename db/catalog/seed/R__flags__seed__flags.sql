-- module: db.catalog.flags
-- purpose: Seed baseline feature flags for local/dev when enabled.
-- exports:
--   - seed: flags.flag
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into flags.flag (
      flag_id,
      flag_key,
      name,
      description,
      flag_scope_id,
      flag_status_id,
      is_enabled,
      config,
      created_at,
      updated_at
    )
    values
      (
        '00000000-0000-0000-0000-000000000060',
        'enable_admin_ui',
        'Enable Admin UI',
        'Toggle admin console availability',
        (select flag_scope_id from flags.flag_scope where scope_key = 'global'),
        (select flag_status_id from flags.flag_status where status_key = 'active'),
        true,
        '{}'::jsonb,
        now(),
        now()
      ),
      (
        '00000000-0000-0000-0000-000000000061',
        'enable_beta_features',
        'Enable Beta Features',
        'Toggle beta feature set',
        (select flag_scope_id from flags.flag_scope where scope_key = 'global'),
        (select flag_status_id from flags.flag_status where status_key = 'active'),
        false,
        '{}'::jsonb,
        now(),
        now()
      )
    on conflict (flag_key) do update
    set name = excluded.name,
        description = excluded.description,
        flag_scope_id = excluded.flag_scope_id,
        flag_status_id = excluded.flag_status_id,
        is_enabled = excluded.is_enabled,
        config = excluded.config,
        updated_at = now();
  end if;
end $$;
