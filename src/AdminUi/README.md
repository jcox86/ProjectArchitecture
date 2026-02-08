<!--
module: src.adminUi.readme
purpose: Explain how to run and configure the Vue admin UI.
exports:
  - docs: setup and environment variables
patterns:
  - vite
  - naive_ui
-->
# Admin UI (Vue + Vite)

## Requirements

- Node.js 20+
- npm 10+

## Quick start

```bash
npm install
npm run dev
```

## Running with multiple environments

Vite loads `.env`, `.env.local`, and mode-specific files like `.env.development`,
`.env.staging`, and `.env.production`. Use a mode-specific script to switch
environments.

```bash
npm run dev:local
npm run dev:staging
```

## Linting

```bash
npm run lint
```

## Testing

```bash
npm run test
```

## Environment variables

Copy `.env.example` to `.env.local` and fill in values as needed.

| Variable | Description |
| --- | --- |
| `VITE_ENTRA_CLIENT_ID` | Entra ID app registration client ID. |
| `VITE_ENTRA_TENANT_ID` | Entra tenant ID. |
| `VITE_ENTRA_REDIRECT_URI` | Redirect URI for the admin UI (default: window origin). |
| `VITE_ADMIN_API_BASE_URL` | Base URL for admin API (default: `/api/admin`). |
| `VITE_ADMIN_API_SCOPE` | API scope for admin API access token. |
| `VITE_ADMIN_API_PROXY_TARGET` | Proxy target for admin API during dev (e.g. `https://localhost:7001`). |
| `VITE_ADMIN_API_PROXY_SECURE` | Validate proxy TLS certs (default: `true`). |
| `VITE_DEV_HTTPS` | Run the Vite dev server over HTTPS (default: `false`). |
| `VITE_DEV_HTTPS_CERT` | Path to HTTPS certificate for the dev server. |
| `VITE_DEV_HTTPS_KEY` | Path to HTTPS private key for the dev server. |
