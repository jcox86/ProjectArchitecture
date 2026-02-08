-- module: db.catalog.audit
-- purpose: Seed a bootstrap audit event for local/dev when enabled.
-- exports:
--   - seed: audit.event
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into audit.event (
      event_id,
      occurred_at,
      tenant_id,
      subject_id,
      action,
      entity_type,
      entity_id,
      event_severity_id,
      data
    )
    values (
      '00000000-0000-0000-0000-000000000030',
      now(),
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000002',
      'seed_defaults',
      'catalog',
      'bootstrap',
      (select event_severity_id from audit.event_severity where severity_key = 'info'),
      jsonb_build_object('source', 'flyway', 'note', 'Seed defaults applied')
    )
    on conflict (event_id) do nothing;
  end if;
end $$;
