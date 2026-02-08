<!--
module: docs.adr.databaseAsCode
purpose: Decide how database schema is authored, versioned, and deployed for PostgreSQL in this template.
exports:
  - decision: postgres_sql_first_with_flyway
patterns:
  - adr
  - flyway
  - sql_first
-->

# ADR 0001: Database as code with PostgreSQL + Flyway

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

This template is **SQL-first** on **PostgreSQL** (Azure PostgreSQL Flexible Server). We need:

- A clear, reviewable history of schema changes
- Deterministic, repeatable deployments across environments
- A workflow that supports multiple databases (catalog + tenant)
- A format that is **LLM-friendly** (small, focused diffs; one object/target per script when practical)

`.sqlproj`/DACPAC workflows are not a fit for PostgreSQL. We need a migration tool that works well with raw SQL and supports repeatable definitions for functions/views/policies.

## Decision

Use **Flyway** to manage PostgreSQL schema changes.

- **Two Flyway projects**:
  - `db/catalog/` for the control-plane catalog database
  - `db/tenant/` for the data-plane tenant schema (shared DB and dedicated DBs share the same schema)
- **Versioned migrations** for additive/structural changes:
  - `db/*/migrations/V....sql`
  - Naming convention: `V0001_0001__<module>__<objectType>__<name>__<intent>.sql`
- **Repeatable scripts** for authoritative object definitions that benefit from `create or replace`:
  - `db/*/repeatable/R__<module>__<objectType>__<name>.sql`
  - Typical: functions, views, policies, triggers
- **Seed scripts** for idempotent reference data:
  - `db/*/seed/` (repeatable + safe to re-run)
- **Guardrails**:
  - CI (and deployments) must run `flyway validate` to detect drift/checksum mismatch.
  - Destructive DDL in production requires explicit review/approval (prefer expand/contract patterns).
  - Keep scripts scoped (one object/target per file) when practical to keep diffs small and reviews precise.

## Decision drivers

- PostgreSQL-first and SQL-first persistence
- Deterministic deployments and drift detection
- LLM-forward repository practices (small diffs, clear intent)
- Ability to manage functions/policies as “definition is truth” via repeatables

## Consequences

### Positive

- Clear, auditable DB history and repeatable, automated deployments
- Drift detection becomes a deployment gate (`flyway validate`)
- Repeatables keep function/policy definitions authoritative and reviewable

### Negative / trade-offs

- Requires migration discipline (expand/contract for breaking changes)
- No “auto drop” convenience; destructive operations must be explicit and gated
- Multiple DBs increase operational surface area (catalog + tenant)

### Neutral / follow-ups

- Wire Flyway validate/migrate into CI/CD pipelines and local tooling.
- Add tests that assert tenant-scoped tables have RLS enabled and correct policies.

## Alternatives considered

- **EF Core migrations**: not aligned with SQL-first approach; harder to keep Postgres-specific features (RLS, functions) as primary artifacts.
- **Liquibase**: viable, but Flyway is simpler for raw SQL + repeatables.
- **Sqitch**: viable, but Flyway aligns better with the current repo layout and CI gate expectations.
- **DACPAC / `.sqlproj`**: not viable for PostgreSQL in the desired workflow.

## References

- `PLAN.md`
- `db/catalog/README.md`
- `db/tenant/README.md`
- `docs/ai/module-headers.md`

