/*
module: infra.bicep
purpose: Infrastructure as Code (Bicep) entrypoint and conventions for provisioning Azure resources for the SaaS template.
exports:
  - main.rg.bicep: Resource-group scoped deployment entrypoint
  - main.subscription.bicep: Optional subscription-scoped bootstrap entrypoint
patterns:
  - idempotent_deployments: Declarative, repeatable deployments with what-if validation
  - module_per_concern: Use small modules with explicit inputs/outputs
notes:
  - Keep secrets out of parameters; use Key Vault + RBAC and outputs for non-secret IDs/URIs.
  - Do not add Private Link/VNet by default; provide optional modules and document tradeoffs.
*/

# `infra/bicep` — Full IaC Project (Bicep)

This folder contains a **full Infrastructure-as-Code project** for provisioning and updating Azure resources for this SaaS template.

## Entry points

- `main.rg.bicep`: deploys an environment into an existing Resource Group.
- `main.subscription.bicep`: optional bootstrap entrypoint (creates RG, applies locks, and sets baseline role assignments).

## Parameters

Environment-specific parameters live in `params/` as `.bicepparam` files:

- `params/dev.bicepparam`
- `params/staging.bicepparam`
- `params/prod.bicepparam`

`appConfigName` defaults in `main.rg.bicep` to a globally unique value per resource group (`appcs-${appName}-${environmentName}-${uniqueString(resourceGroup().id)}`). Omit it in param files unless you need a fixed name.

### Secrets / secure parameters

`main.rg.bicep` requires `postgresAdminPassword` (secure). This must **not** be committed in `.bicepparam` files.

Optionally, you can provide a separate application runtime password:

- `postgresAppPassword` (secure): password for the `postgresAppLogin` user (default: `appuser`). If omitted, it defaults to `postgresAdminPassword` (convenient for early dev, but not recommended for hardened deployments).

- **Local**: set `POSTGRES_ADMIN_PASSWORD` in your environment, or pass `-PostgresAdminPassword` to `scripts/infra/deploy.ps1`.
- **Local (optional)**: set `POSTGRES_APP_PASSWORD` to override the default app password (otherwise it defaults to the admin password).
- **CI**: store `POSTGRES_ADMIN_PASSWORD` as a GitHub Environment secret (dev/staging/prod) and pass it via workflow env.

The deployment also stores several runtime secrets in **Key Vault** (for Container Apps Key Vault secret references), including:

- `postgres-admin-password`
- `postgres-app-password`
- `redis-primary-key`
- `storage-connection-string` (used for Worker queue autoscaling)
- `appinsights-connection-string`

## CI/CD

Infra workflows should:

- run `bicep build` + lint
- run `az deployment group validate`
- run `az deployment group what-if`
- block deletes/replacements unless explicitly approved

## Deployment scripts

See `scripts/infra/` for repeatable deploy/what-if/destroy commands. **Destroy** purges soft-deleted App Configuration stores so the same names can be reused on redeploy; **deploy** purges conflicting soft-deleted App Config stores before creating resources (both idempotent).

