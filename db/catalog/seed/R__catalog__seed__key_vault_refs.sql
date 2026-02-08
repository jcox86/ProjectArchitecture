-- module: db.catalog.catalog
-- purpose: Seed baseline Key Vault references for local/dev when enabled.
-- exports:
--   - seed: catalog.key_vault_ref
-- patterns:
--   - flyway_seed
-- notes:
--   - Inserts only when app.seed_defaults = 'true'.

do $$
begin
  if coalesce(nullif(current_setting('app.seed_defaults', true), ''), 'false') = 'true' then
    insert into catalog.key_vault_ref (
      key_vault_ref_id,
      tenant_id,
      key_vault_scope_id,
      name,
      purpose,
      secret_uri,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000050',
      null,
      (select key_vault_scope_id from catalog.key_vault_scope where scope_key = 'global'),
      'stripe_webhook_secret',
      'Stripe webhook signing secret',
      'https://example.vault.azure.net/secrets/stripe-webhook',
      now(),
      now()
    )
    on conflict (key_vault_scope_id, name, tenant_id) do update
    set secret_uri = excluded.secret_uri,
        purpose = excluded.purpose,
        updated_at = now();
  end if;
end $$;
