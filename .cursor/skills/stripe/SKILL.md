---
name: stripe
description: Integrate Stripe billing in this template (API, webhooks, customers, subscriptions). Use when adding Stripe API calls, webhook handlers, checkout, or syncing plans/prices with the catalog billing schema.
module: cursor.skills.stripe
purpose: Guide Stripe usage so secrets stay in Key Vault, webhooks are idempotent, and catalog DB stays the source of truth.
exports:
  - workflow: stripe_api_webhooks
  - conventions: secrets_env_keyvault_idempotency
patterns:
  - billing_catalog
  - key_vault_secrets
  - idempotency
notes:
  - Never commit Stripe API keys or webhook signing secrets; use Key Vault + env/App Configuration.
  - Webhook handlers must be idempotent (use Stripe event id or idempotency keys).
---

# Stripe (billing integration)

## Where Stripe lives in this repo

- **Catalog DB (billing schema)**:
  - `billing.stripe_customer` — tenant ↔ Stripe customer id.
  - `billing.stripe_metadata` — snapshots of Stripe object metadata (products, prices).
  - Lookups: `billing.stripe_customer_status`, seed in `db/catalog/seed/R__billing__seed__*`.
- **Secrets**: Webhook signing secret is referenced in `catalog.key_vault_ref` (e.g. `stripe_webhook_secret`). Resolve at runtime from Key Vault; do not hardcode.
- **Admin UI**: Billing/pricing pages reference plans and sync with Stripe; see `src/AdminUi/src/api/adminApi.ts` and `src/AdminUi/src/pages/PricingPage.vue`.

## Conventions

1. **No secrets in repo**  
   Stripe API keys and webhook secrets come from Key Vault (or env in dev). Use the same pattern as other secrets (e.g. Postgres): config key or Key Vault reference, never the value.

2. **Webhook handlers**  
   - Verify signature using the secret from Key Vault.  
   - Handle events idempotently (e.g. by `event.id` or idempotency key).  
   - Return 2xx quickly; do heavy work in a queue/worker if needed.  
   - Prefer idempotency keys for any outbound Stripe API calls from webhooks.

3. **Catalog as source of truth**  
   Plans/prices are defined in the catalog DB; Stripe is the payment provider. Sync direction: catalog → Stripe for product/price metadata when needed; Stripe → catalog for customer/subscription state and webhook-driven updates.

4. **Tenant context**  
   Map Stripe `customer` / `subscription` to tenant via `billing.stripe_customer`. Always resolve tenant before applying billing changes.

## When to use this skill

- Adding or changing Stripe API calls (customers, subscriptions, checkout, invoices).
- Implementing or changing webhook endpoints (e.g. `customer.subscription.updated`, `invoice.paid`).
- Syncing plans/prices between catalog and Stripe.
- Adding new Key Vault refs or config for Stripe-related secrets.

## Quick checks

- [ ] No Stripe keys or webhook secrets in code or config files (use Key Vault / env).
- [ ] Webhook handler verifies signature and is idempotent.
- [ ] Tenant is resolved from Stripe customer/metadata and used for RLS/catalog updates.
- [ ] New DB or config changes follow `db-change-flyway` and module-header conventions.

## References

- Stripe API: https://docs.stripe.com/api
- Webhooks: https://docs.stripe.com/webhooks (signature verification, idempotency)
- This repo: `db/catalog/migrations/*stripe*`, `db/catalog/seed/R__billing__seed__stripe_metadata.sql`, `R__catalog__seed__key_vault_refs.sql`
