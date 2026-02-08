-- module: db.catalog.identity
-- purpose: Seed a system admin subject and membership for local/dev when enabled.
-- exports:
--   - seed: identity.subject
--   - seed: identity.membership
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into identity.subject (
      subject_id,
      subject_provider_id,
      external_id,
      display_name,
      email,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000002',
      (select subject_provider_id from identity.subject_provider where provider_key = 'system'),
      'system-admin',
      'System Admin',
      'admin@system.local',
      now(),
      now()
    )
    on conflict (subject_provider_id, external_id) do update
    set display_name = excluded.display_name,
        email = excluded.email,
        updated_at = now();

    insert into identity.membership (
      membership_id,
      tenant_id,
      subject_id,
      membership_role_id,
      membership_status_id,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000003',
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000002',
      (select membership_role_id from identity.membership_role where role_key = 'platform_admin'),
      (select membership_status_id from identity.membership_status where status_key = 'active'),
      now(),
      now()
    )
    on conflict (tenant_id, subject_id, membership_role_id) do update
    set membership_status_id = excluded.membership_status_id,
        updated_at = now();
  end if;
end $$;
