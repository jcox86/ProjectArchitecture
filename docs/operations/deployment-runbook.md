<!--
module: docs.operations.deploymentRunbook
purpose: Step-by-step guide to configure Azure, run first deploy, enable CI/CD, and sign in to Admin UI.
exports:
  - doc: deployment_runbook
  - secrets_checklist: GitHub + Entra secrets
patterns:
  - operational_runbook
  - idempotent_infra
notes:
  - Keep in sync with infra/bicep/README.md, .github/workflows/*.yml, and src/AdminUi/README.md.
-->

# Deployment runbook — end-to-end

This runbook walks through: (1) configuring Azure and GitHub for CI/CD, (2) first manual deployment, (3) automated infra and app deploys, and (4) signing in to the Admin UI and working with data.

## 1. Prerequisites

- **Azure subscription** with permissions to create resource groups, Container Apps, Postgres, Redis, Key Vault, ACR, Storage, App Configuration, Front Door, and Log Analytics.
- **GitHub repo** with this codebase; you will configure **Environments** (dev, staging, prod) and **secrets**.
- **Azure CLI** (`az`) installed and logged in for local/manual runs.
- **PowerShell** (pwsh or Windows PowerShell) for running `scripts/infra/*.ps1` and `scripts/deploy/*.ps1`.
- **Node.js 20+** and **npm 10+** for building Admin UI locally and for any front-end checks.

## 2. Local validation (before deploying)

Run all four builds and verify outcomes in one go:

```powershell
./scripts/verify/verify-builds.ps1
```

Optional: `-SkipBicep` if Azure CLI is not installed; `-SkipRepoLinter` to skip header lint; `-RepoRoot <path>` to override repo root.

Or run individually:

| Check | Command |
|-------|--------|
| .NET build | `dotnet build ProjectArchitecture.slnx` |
| Admin UI build | `cd src/AdminUi; npm run build` |
| Bicep compile | `bicep build infra/bicep/main.rg.bicep` (requires Bicep CLI) |
| RepoLinter | `dotnet run --project tools/RepoLinter -- --all` |
| Infra what-if (dev) | `./scripts/infra/whatif.ps1 -Environment dev -ResourceGroupName <RG_DEV> -PostgresAdminPassword <pwd>` (optional; needs Azure login and RG) |

## 3. Azure and GitHub configuration

### 3.1 Resource groups and naming

- Create one **resource group per environment** (e.g. `rg-saastpl-dev`, `rg-saastpl-staging`, `rg-saastpl-prod`) in your chosen region (e.g. `eastus`), or use `main.subscription.bicep` to bootstrap them.
- Ensure **globally unique** names in `infra/bicep/params/*.bicepparam` for: `storageAccountName`, `keyVaultName`, `acrName`, `appConfigName` (and optionally `dnsRoot` for Front Door custom domains).

### 3.2 GitHub OIDC (federated credential) for infra and app pipelines

Use the **Microsoft Entra admin center** at [entra.microsoft.com](https://entra.microsoft.com/). Federated credentials are **not** a top-level menu item; they live under **Certificates & secrets**.

1. **Create the app registration**
   - Go to **Identity** → **Applications** → **App registrations** → **New registration** (e.g. `github-oidc-projectarchitecture`).
   - Note **Application (client) ID** and **Directory (tenant) ID** from the app’s **Overview**.
   - Do **not** create a client secret; OIDC uses federated credentials instead.

2. **Grant the app access to Azure**
   - In **Azure Portal** → **Subscriptions** → select your subscription → **Access control (IAM)** → **Add role assignment**.
   - Assign **Contributor** (or a custom role that can deploy to the resource groups) to the app’s **service principal** (search by the app name or client ID).

3. **Add a federated credential (GitHub Actions)**
   - Open the app registration in the Entra admin center.
   - In the left navigation, select **Certificates & secrets**.
   - On that page, open the **Federated credentials** tab (alongside "Client secrets" and "Certificates").
   - Select **Add credential** (or **+ Add credential**).
   - In **Federated credential scenario**, choose **GitHub actions deploying Azure resources**.
   - Fill in:
     - **Organization**: your GitHub org (e.g. `myorg`).
     - **Repository**: repo name (e.g. `ProjectArchitecture`).
     - **Entity type**: **Environment** (recommended for environment-specific approval and secrets). Then set **GitHub environment name** to e.g. `dev`.
     - **Name**: a unique label for this credential (e.g. `fic-dev`). The name cannot be changed later.
   - **Issuer**, **Audiences**, and **Subject identifier** are filled automatically; keep the default audience `api://AzureADTokenExchange`.
   - Select **Add** to save.

4. **Repeat for other environments**
   - Add a separate federated credential for each GitHub environment your workflows use (e.g. `staging`, `prod`), each with **Entity type** = **Environment** and the matching **GitHub environment name**.

**Reference:** [Configure an app to trust an external identity provider - GitHub Actions](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions) (Microsoft Learn). If you use **Branch** instead of Environment, the entity value must exactly match the branch name (e.g. `main`); pattern matching is not supported.

### 3.3 GitHub Environment secrets

Configure **GitHub** → **Settings** → **Environments** → create `dev`, `staging`, `prod`. For each environment, add **Environment secrets**:

| Secret | Description | Used by |
|--------|-------------|--------|
| `AZURE_CLIENT_ID` | Application (client) ID of the OIDC app registration | infra-validate, infra-deploy, app-deploy |
| `AZURE_TENANT_ID` | Directory (tenant) ID | Same |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Same |
| `AZURE_RG_DEV` | Resource group name for dev (e.g. `rg-saastpl-dev`) | infra-validate, infra-deploy, app-deploy (dev) |
| `AZURE_RG_STAGING` | Resource group name for staging | infra-deploy, app-deploy (staging) |
| `AZURE_RG_PROD` | Resource group name for prod | infra-deploy, app-deploy (prod) |
| `AZURE_LOCATION` | Region (e.g. `eastus`) | infra-deploy |
| `POSTGRES_ADMIN_PASSWORD` | Strong password for PostgreSQL admin (not committed) | infra-validate, infra-deploy |
| `POSTGRES_APP_PASSWORD` | (Optional) Password for app user; if omitted, infra uses admin password | infra-deploy |
| `ACR_NAME` | Name of the ACR (must match `acrName` in params, e.g. `acrsaastpldev1234`) | app-deploy |
| `APP_NAME` | Short app name used in container app names (e.g. `saastpl`) | app-deploy |

Use the **same** `AZURE_*` and `POSTGRES_*` values across environments if you use one OIDC app and one subscription; use different `AZURE_RG_*` and optionally different `POSTGRES_*` per environment.

### 3.4 Entra ID app registration for Admin UI (admin staff auth)

Admin UI uses **Entra ID** (see `docs/adr/0003-authentication-and-authorization-product-vs-admin.md`). Create a separate app registration for the Admin SPA and API scope:

1. **App registrations** → **New registration** (e.g. `ProjectArchitecture-AdminUi`).
2. **Supported account types**: “Accounts in this organizational directory only”.
3. **Redirect URI**: **Single-page application (SPA)** → add:
   - Local: `http://localhost:5173` (or your Vite dev port).
   - Deployed: `https://admin.<your-front-door-host>` or your actual Admin UI origin (Front Door or Container App URL).
4. **Certificates & secrets**: no client secret needed for SPA.
5. **Expose an API**:
   - **Application ID URI**: e.g. `api://<client-id>/api` (or your chosen scope URI).
   - **Scopes**: add scope e.g. `api` (full access) or finer scopes; note the full scope value (e.g. `api://<client-id>/api`).
6. **API permissions**: add **Microsoft Graph** if you need user profile; add your **own API** (this app) with the scope you defined.
7. **Token configuration** (optional): add claims you need (e.g. `email`, `preferred_username`).

Use these values in Admin UI:

- **Client ID**: Application (client) ID of this app.
- **Tenant ID**: Directory (tenant) ID (same tenant as the app).
- **Redirect URI**: must match exactly what you registered (including trailing slash or not).
- **API scope**: the full scope string (e.g. `api://<client-id>/api`).

Your API (backend) must be configured to validate tokens for this audience and scope (Entra admin scheme).

## 4. First manual deployment

### 4.1 Deploy infrastructure (dev)

From the repo root, with Azure CLI already logged in (`az login`):

```powershell
$env:POSTGRES_ADMIN_PASSWORD = '<strong-password>'   # or use -PostgresAdminPassword
./scripts/infra/deploy.ps1 -Environment dev -ResourceGroupName 'rg-saastpl-dev' -Location 'eastus'
```

If the resource group does not exist, the script creates it. Bicep deploys Postgres, Redis, Key Vault, ACR, Storage, App Config, Container Apps Environment, Front Door, and placeholder Container Apps (API, Worker, Admin UI) with default images.

### 4.2 Deploy application images (optional manual step)

The app-deploy workflow builds and pushes images to ACR, then runs blue/green for API and Admin UI and updates the Worker. For manual deploys you can:

- Build and push API/Worker/Admin UI images to the ACR name in your params.
- Run the blue/green script manually, e.g.:

```powershell
./scripts/deploy/aca-bluegreen.ps1 -ResourceGroupName 'rg-saastpl-dev' -ContainerAppName 'saastpl-api-dev' -Image '<acr>.azurecr.io/saastpl-api:latest'
```

(Repeat for Admin UI and Worker as needed.)

## 5. Automated CI/CD

### 5.1 Infra pipeline

- **infra-validate** (PR): runs on PRs that touch `infra/bicep/**` or `scripts/infra/**`. Runs `bicep build`, `az deployment group validate`, and `scripts/infra/whatif.ps1` for **dev** with `-FailOnDeleteOrReplace`. Requires `dev` environment secrets.
- **infra-deploy** (push to `main` or manual): deploys **dev** → **staging** → **prod** in sequence; for **prod** it runs what-if with fail-on-delete before deploying. Configure **dev**, **staging**, and **prod** environment secrets as in §3.3.

### 5.2 App pipeline

- **app-deploy**: runs on push to `main` that touches `src/**` or `scripts/deploy/**`, or on `workflow_dispatch`. It:
  - Logs in with OIDC, resolves ACR.
  - Builds and pushes API, Worker, and Admin UI images to ACR via `az acr build` (using `src/Api/Dockerfile`, `src/Worker/Dockerfile`, `src/AdminUi/Dockerfile`).
  - Runs blue/green for API and Admin UI via `scripts/deploy/aca-bluegreen.ps1`.
  - Deploys Worker via `scripts/deploy/aca-worker-update.ps1` (simple image update; no traffic shifting).

Each push to `main` (with app changes) deploys new revisions to dev. Add jobs or environments for staging/prod as needed.

## 6. Admin UI: sign-in and working with data

### 6.1 Local development

1. Copy `src/AdminUi/.env.example` to `src/AdminUi/.env.local` or use `.env.development`.
2. Set:
   - `VITE_ENTRA_CLIENT_ID` = Admin app registration client ID.
   - `VITE_ENTRA_TENANT_ID` = Tenant ID.
   - `VITE_ENTRA_REDIRECT_URI` = `http://localhost:5173` (must match SPA redirect in Entra).
   - `VITE_ADMIN_API_SCOPE` = e.g. `api://<client-id>/api`.
   - `VITE_ADMIN_API_BASE_URL` = `/api/admin` (or your API base path).
   - `VITE_ADMIN_API_PROXY_TARGET` = your local API URL (e.g. `https://localhost:7149`) so Vite proxies API calls.
3. Start API (e.g. from solution or AppHost) and run `npm run dev` (or `npm run dev:local`) in `src/AdminUi`.
4. Open the dev URL; you should be redirected to Entra to sign in, then back to the app. API calls go through the proxy to your local backend.

### 6.2 Deployed Admin UI

- The deployed Admin UI URL is the Front Door admin origin (e.g. `https://admin.<front-door-host>`) or the Container App FQDN if not using Front Door.
- Ensure the **Redirect URI** in Entra for this app includes that exact origin (e.g. `https://admin.<your-domain>/`).
- Admin UI is built as a static SPA; at runtime it only needs `VITE_*` build-time variables pointing to the correct API base path and Entra config (baked at build time). For multi-environment builds, use different Vite modes or build args so the deployed bundle has the right API URL and scope.

### 6.3 Working with data

- **Catalog DB** and **tenant DB(s)** are created/migrated by Flyway (see `db/` and `docs/adr/0001-database-as-code-postgresql-flyway.md`). Ensure migrations have been run against the deployed Postgres (catalog + tenant_shared or per-tenant DBs).
- **Admin staff** sign in with Entra; the API authorizes admin routes using the admin auth scheme and ABAC (see ADR 0003). Ensure your API is configured with the same Entra tenant, audience, and scope so tokens from the Admin UI are accepted.
- For **seed/reference data**, use Flyway or documented scripts in `db/`; do not commit secrets.

## 7. Smoke test checklist

After first deploy (or after any infra/app change), verify:

| Item | How |
|------|-----|
| Infra outputs | After `deploy.ps1`, check Azure portal or `az deployment group show` for outputs (Key Vault URI, ACR, Postgres FQDN, Front Door host). |
| API health | GET the API health/ready endpoint (via Front Door or direct Container App URL). |
| Admin UI loads | Open Admin UI URL; redirect to Entra login then back to app. |
| Admin UI → API | In Admin UI, trigger a call that hits the admin API (e.g. a protected page); confirm no CORS or 401. |
| Worker | If you have queues, submit a job and confirm the worker processes it (logs or side effects). |
| DB connectivity | API and Worker use Key Vault-backed Postgres password; check app logs for connection errors. |

## 8. References

- **Infra**: `infra/bicep/README.md`, `infra/bicep/main.rg.bicep`, `scripts/infra/deploy.ps1`, `scripts/infra/whatif.ps1`
- **CI**: `.github/workflows/infra-validate.yml`, `.github/workflows/infra-deploy.yml`, `.github/workflows/app-deploy.yml`
- **App deploy**: `scripts/deploy/aca-bluegreen.ps1`
- **Admin UI**: `src/AdminUi/README.md`, `.env.example`
- **Auth**: `docs/adr/0003-authentication-and-authorization-product-vs-admin.md`
- **Operations**: `docs/operations/README.md`, `docs/operations/observability.md`
- **Azure OIDC (Microsoft Learn)**: [Configure federated credential for GitHub Actions](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions), [Authenticate to Azure from GitHub Actions by OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
