<!--
module: docs.operations.index
purpose: Entry point for operations documentation (runbooks, monitoring, deployments, DR).
exports:
  - doc: operations_overview
patterns:
  - docs_skeleton
  - operational_runbooks
-->

# Operations

This folder contains operational guidance: how to deploy, observe, troubleshoot, and recover.

## Topics

- **Deployment runbook**: [deployment-runbook.md](deployment-runbook.md) — step-by-step Azure + GitHub setup, first deploy, CI/CD, and Admin UI sign-in.
- **Build verification**: run `scripts/verify/verify-builds.ps1` to execute all four builds (.NET, Admin UI, Bicep, RepoLinter) and report pass/fail.
- **Environment model**: dev/staging/prod isolation, access controls, locks.
- **Deployments**: Container Apps revisions (blue/green), DB migrations (expand/contract).
- **Observability**: logs/traces/metrics, dashboards, alerting, SLOs. See `docs/operations/observability.md`.
- **Runbooks**: common incidents (API errors, stuck queues, degraded Postgres/Redis, Front Door issues).
- **Backups & DR**: restore procedures and drill cadence.
- **Capacity & cost**: scale rules, limits/quotas, budgets.
- **Tenant safety guardrails**: RLS + subscription limits (see `docs/operations/tenant-safety-guardrails.md`).

## Key decisions

- `docs/adr/0004-messaging-storage-queues-outbox-idempotency.md`
- `docs/adr/0005-edge-routing-front-door-and-optional-gateway.md`
- `docs/adr/0001-database-as-code-postgresql-flyway.md`

