---
name: add-module
description: Add a new domain module end-to-end (DB + API + Worker + Admin UI + tests + docs) following this template’s conventions. Use when introducing a new bounded context/module.
module: cursor.skills.addModule
purpose: Provide a repeatable checklist for introducing a new module consistently across schema, services, UI, and documentation.
exports:
  - workflow: add_new_module_end_to_end
patterns:
  - ddd
  - clean_architecture
  - sql_first
notes:
  - Reuse the db-change-flyway and write-module-headers skills.
---

# Add a module (end-to-end)

This is a checklist-style workflow. Keep each step small and commit in logical increments.

## 0) Choose module identity

- Pick a **module name** (stable, lowercase, dot-separated if needed).
- Ensure file paths align with `docs/ai/module-map.yml` prefixes. If you introduce a new top-level path prefix, update `docs/ai/module-map.yml`.

## 1) Database (SQL-first)

Decide:

- Does this module live in **catalog DB** (control plane), **tenant DB** (data plane), or both?
- Which Postgres **schemas** will namespace it? (e.g., `inventory`, `billing`)

Do:

- Add Flyway scripts using `.cursor/skills/db-change-flyway/SKILL.md`.
- Add/verify RLS for tenant-scoped tables (tenant DB).

## 2) Domain/Application/Infrastructure (planned structure)

- Add Domain model and invariants (no infra dependencies).
- Add Application services/use-cases (orchestrate domain + persistence).
- Add Infrastructure implementations (data access, external services).

## 3) API surface (minimal APIs)

- Map endpoints via a single entrypoint per feature area (e.g., `*.Map(...)`).
- Enforce tenant context and auth boundaries.
- Implement idempotency for write endpoints where needed.

## 4) Worker (background processing)

- Use queue-first patterns: retries + poison + idempotency.
- Integrate transactional outbox for side effects.

## 5) Admin UI (Vue + Naive UI)

- Add admin pages/components with consistent API client usage.
- Keep admin and admin API same-origin routing where possible (avoid CORS).

## 6) Tests + docs

- Add unit/integration tests for critical invariants (especially RLS assumptions).
- Update `docs/` as needed (architecture/requirements/ops).

## 7) Module headers (required)

For every new/edited comment-capable file, add/update the module header using:

- `.cursor/skills/write-module-headers/SKILL.md`

