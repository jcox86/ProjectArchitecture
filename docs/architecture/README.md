<!--
module: docs.architecture.index
purpose: Entry point for system architecture documentation (views, flows, and key constraints).
exports:
  - doc: architecture_overview
patterns:
  - docs_skeleton
  - clean_architecture
-->

# Architecture

This folder documents the architecture of the template: system views, core flows, and the decisions that shape implementation.

## Recommended structure (add as needed)

- **System context / container view** (C4): major actors, services, data stores, and external dependencies.
- **Key flows**: tenant resolution, request handling, background work, and deploy/migrate flow.
- **Data architecture**: catalog vs tenant DBs, RLS approach, migration strategy.
- **Data access conventions**: Dapper + stored-function usage (see `docs/architecture/data-access-dapper.md`).
- **Deployment architecture**: Azure Container Apps + Front Door routing, environments, and CI/CD.
- **Tenant safety guardrails**: RLS + subscription limits (see `docs/architecture/tenant-safety-guardrails.md`).
- **Authentication & authorization**: split product/admin auth schemes, ABAC policy evaluation, and cache invalidation.

## Key decisions

Most major decisions live in ADRs. Start here:

- `docs/adr/0001-database-as-code-postgresql-flyway.md`
- `docs/adr/0002-hybrid-multi-tenancy-and-tenant-resolution.md`
- `docs/adr/0003-authentication-and-authorization-product-vs-admin.md`
- `docs/adr/0004-messaging-storage-queues-outbox-idempotency.md`
- `docs/adr/0005-edge-routing-front-door-and-optional-gateway.md`

