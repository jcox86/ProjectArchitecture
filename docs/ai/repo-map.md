<!--
module: docs.ai.repoMap
purpose: High-signal orientation for humans and AI assistants working in this repo.
exports:
  - overview: structure + routing
patterns:
  - ai_repo_map
-->

# Repo map (high-signal) — Cloud-native SaaS template (Azure/.NET)

This document is the fast orientation for humans and AI assistants.

## What this repo is

A cloud-native SaaS template emphasizing:

- **Azure-first** runtime (Container Apps + Front Door)
- **PostgreSQL-first** persistence (SQL-first, Flyway migrations)
- **Hybrid multi-tenancy** (shared DB via RLS + optional dedicated DB per tenant)
- **LLM-forward** repo contract (module headers + focused Cursor rules/skills)

## Current structure (today)

- `.github/workflows/`: CI workflows (infra validate/deploy, etc.)
- `.cursor/`: AI rules + skills
- `docs/`: architecture, requirements, security, operations, ADRs
- `db/`: Flyway migrations for catalog + tenant DBs
- `infra/bicep/`: Bicep IaC project (entrypoints + modules + params)
- `scripts/infra/`: repeatable infra commands (deploy/what-if/destroy)
- `scripts/deploy/`: app deployment helpers (ACA blue/green, Worker update); container images built via `src/Api/Dockerfile`, `src/Worker/Dockerfile`, `src/AdminUi/Dockerfile`
- `src/`: .NET solution (Api/Worker/AdminUi + Clean Architecture layers)
  - `src/AdminUi/`: Vue (Vite + TS + Naive UI) admin portal
- `src/Api.SmokeTests/`: minimal smoke tests for the API host
- `tools/`: repo tooling (repo linter, DB tooling, Aspire AppHost)

## Locked-in platform choices (summary)

- **Runtime/edge**: Azure Container Apps + Azure Front Door (Standard/Premium parameterized)
- **Database**: Azure Database for PostgreSQL Flexible Server
- **Cache**: Azure Cache for Redis
- **Messaging**: Azure Storage Queues (KEDA scale for workers)
- **Secrets**: Azure Key Vault + managed identity + RBAC (no secrets in repo)
- **Observability**: OpenTelemetry + Azure Monitor exporter; Serilog

## Repo contract (LLM-forward)

### Module headers (required in comment-capable authored files)

Every authored file that supports comments should begin with a short YAML header in the language’s comment syntax.

See:

- `docs/ai/module-headers.md` (spec + examples)
- `docs/ai/module-map.yml` (path → module prefix mapping)

### Cursor rules + skills

- `.cursor/rules/`: focused rules applied by file type (architecture, headers, SQL/Flyway, etc.)
- `.cursor/skills/`: repeatable workflows (module headers, DB changes, add-module, incident triage)

## Common routing (where to look first)

- **First deploy / CI/CD / Admin UI sign-in**: `docs/operations/deployment-runbook.md`
- **Change infra**: `infra/bicep/README.md` → `infra/bicep/main.rg.bicep` → `infra/bicep/modules/*`
- **Verify all builds**: `scripts/verify/verify-builds.ps1` ( .NET, Admin UI, Bicep, RepoLinter)
- **Validate/what-if**: `.github/workflows/infra-validate.yml` + `scripts/infra/whatif.ps1`
- **Deploy infra**: `scripts/infra/deploy.ps1` + `.github/workflows/infra-deploy.yml`
- **Blue/green app deploy**: `scripts/deploy/aca-bluegreen.ps1`

