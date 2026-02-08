-- module: db.catalog.billing
-- purpose: Seed baseline plans and add-ons for local/dev when enabled.
-- exports:
--   - seed: billing.plan
--   - seed: billing.plan_price
--   - seed: billing.addon
--   - seed: billing.addon_price
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into billing.plan (
      plan_id,
      plan_key,
      name,
      description,
      plan_status_id,
      trial_days,
      created_at,
      updated_at
    )
    values
      (
        '00000000-0000-0000-0000-000000000010',
        'free',
        'Free',
        'Starter plan',
        (select plan_status_id from billing.plan_status where status_key = 'active'),
        0,
        now(),
        now()
      ),
      (
        '00000000-0000-0000-0000-000000000011',
        'pro',
        'Pro',
        'Professional plan',
        (select plan_status_id from billing.plan_status where status_key = 'active'),
        14,
        now(),
        now()
      )
    on conflict (plan_key) do update
    set name = excluded.name,
        description = excluded.description,
        plan_status_id = excluded.plan_status_id,
        trial_days = excluded.trial_days,
        updated_at = now();

    insert into billing.plan_price (
      plan_price_id,
      plan_id,
      currency_code,
      amount_cents,
      price_interval_id,
      price_status_id,
      external_price_key,
      created_at,
      updated_at
    )
    values
      (
        '00000000-0000-0000-0000-000000000012',
        '00000000-0000-0000-0000-000000000010',
        'USD',
        0,
        (select price_interval_id from billing.price_interval where interval_key = 'month'),
        (select price_status_id from billing.price_status where status_key = 'active'),
        null,
        now(),
        now()
      ),
      (
        '00000000-0000-0000-0000-000000000013',
        '00000000-0000-0000-0000-000000000011',
        'USD',
        4900,
        (select price_interval_id from billing.price_interval where interval_key = 'month'),
        (select price_status_id from billing.price_status where status_key = 'active'),
        null,
        now(),
        now()
      )
    on conflict (plan_id, currency_code, price_interval_id) do update
    set amount_cents = excluded.amount_cents,
        price_status_id = excluded.price_status_id,
        external_price_key = excluded.external_price_key,
        updated_at = now();

    insert into billing.addon (
      addon_id,
      addon_key,
      name,
      description,
      addon_status_id,
      created_at,
      updated_at
    )
    values
      (
        '00000000-0000-0000-0000-000000000020',
        'extra-storage',
        'Extra Storage',
        'Additional storage add-on',
        (select addon_status_id from billing.addon_status where status_key = 'active'),
        now(),
        now()
      )
    on conflict (addon_key) do update
    set name = excluded.name,
        description = excluded.description,
        addon_status_id = excluded.addon_status_id,
        updated_at = now();

    insert into billing.addon_price (
      addon_price_id,
      addon_id,
      currency_code,
      amount_cents,
      price_interval_id,
      price_status_id,
      external_price_key,
      created_at,
      updated_at
    )
    values
      (
        '00000000-0000-0000-0000-000000000021',
        '00000000-0000-0000-0000-000000000020',
        'USD',
        500,
        (select price_interval_id from billing.price_interval where interval_key = 'month'),
        (select price_status_id from billing.price_status where status_key = 'active'),
        null,
        now(),
        now()
      )
    on conflict (addon_id, currency_code, price_interval_id) do update
    set amount_cents = excluded.amount_cents,
        price_status_id = excluded.price_status_id,
        external_price_key = excluded.external_price_key,
        updated_at = now();
  end if;
end $$;
