-- module: db.catalog.billing
-- purpose: Seed Stripe metadata placeholders for local/dev when enabled.
-- exports:
--   - seed: billing.stripe_metadata
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into billing.stripe_metadata (
      stripe_metadata_id,
      tenant_id,
      object_type,
      object_id,
      payload,
      created_at
    )
    values (
      '00000000-0000-0000-0000-000000000040',
      '00000000-0000-0000-0000-000000000001',
      'plan',
      'pro',
      jsonb_build_object('stripe_product_id', 'prod_placeholder', 'stripe_price_id', 'price_placeholder'),
      now()
    )
    on conflict (object_type, object_id) do update
    set payload = excluded.payload,
        tenant_id = excluded.tenant_id;
  end if;
end $$;
