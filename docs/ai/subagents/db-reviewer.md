<!--
module: docs.ai.subagents.dbReviewer
purpose: Checklist to review PostgreSQL + Flyway changes for safety, correctness, and operability.
exports:
  - checklist: db_review
patterns:
  - flyway
  - postgres_rls
-->

# DB reviewer — checklist (Postgres + Flyway)

## Migration structure (Flyway, planned repo layout)

- [ ] Versioned migrations use the agreed naming convention (`V...__...sql`)
- [ ] Repeatables (`R__...sql`) use `create or replace` for authoritative definitions
- [ ] Seed scripts are idempotent (safe to re-run)

## Safety guardrails

- [ ] No accidental destructive DDL (DROP, rewrites, breaking type changes)
- [ ] Breaking changes follow **expand/contract**
- [ ] Drift detection is supported (`flyway validate` must pass)

## RLS invariants (tenant data)

- [ ] Tenant-scoped tables include `tenant_id`
- [ ] RLS is enabled and **FORCE**d on tenant-scoped tables
- [ ] Policies bind to a single tenant context (e.g., `current_setting('app.tenant_id', true)`)

## Runtime roles

- [ ] Migration owner vs runtime user separation is preserved (planned)
- [ ] Least-privilege grants for runtime role

