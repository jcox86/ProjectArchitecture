<!--
module: docs.ai.subagents.testHarnessCoverage
purpose: Single pane of glass for test harness and coverage across APIs, UIs, and infra (unit, integration, e2e, infra, DB).
exports:
  - checklist: test_harness_coverage
  - routing: where tests live and how to run them
patterns:
  - test_pyramid
  - coverage_aggregation
-->

# Test harness & coverage — single pane of glass

Use this when designing or implementing a unified test harness and coverage view for the entire app (multiple API projects, UI projects, infra, and database).

## Goal

- **Single pane of glass**: One place to see what tests exist, how to run them, and aggregated coverage (and gaps) across stacks.
- **Multi-stack**: .NET (Api, Worker, optional extra APIs), Vue/TS (AdminUi), Bicep/infra, DB (Flyway/migrations).
- **All test types**: Unit, integration, e2e, infra validation, database (migrations/RLS).

## Repo test landscape (current)

| Area | Stack | Test type | Where | How to run |
|------|--------|-----------|--------|------------|
| API | .NET | Smoke / integration | `src/Api.SmokeTests/` | `dotnet test src/Api.SmokeTests/` |
| API / App | .NET | Unit (planned) | `src/**/*.Tests/` or per-layer | `dotnet test` |
| Admin UI | Vue + TS | Unit / component | `src/AdminUi/` (Vitest) | `npm run test` (from AdminUi) |
| Admin UI | Vue + TS | E2E (planned) | e.g. Playwright in AdminUi or separate | TBD |
| Infra | Bicep | Validate / what-if | `infra/bicep/`, `.github/workflows/infra-validate.yml` | `./scripts/infra/whatif.ps1`, CI |
| DB | Flyway / Postgres | Migrations / RLS (planned) | `db/`, `flyway validate` | DB tooling / CI |
| Deploy | Scripts | Smoke / health (planned) | `scripts/deploy/aca-bluegreen.ps1` | Gate before traffic switch |

## Checklist — building the pane of glass

### Discovery and inventory

- [ ] **Inventory all test projects** per stack (e.g. `**/*.Tests.csproj`, `**/vitest.config.*`, e2e dirs, infra validate job).
- [ ] **Document run commands** for each (e.g. `dotnet test`, `npm run test`, `./scripts/infra/whatif.ps1`, `flyway validate`).
- [ ] **Map test type** (unit / integration / e2e / infra / DB) per project or workflow.

### Single entrypoint (orchestration)

- [ ] **One script or workflow** that runs all test suites (or clearly documented matrix: backend, frontend, infra, DB).
- [ ] **Fail-fast vs full run** strategy (e.g. unit first, then integration, then e2e/infra).
- [ ] **CI integration**: Ensure each suite is represented in CI (e.g. app-test job, infra-validate, db-migrate/validate).

### Coverage aggregation

- [ ] **Backend**: Coverage tool (e.g. coverlet) and report format (e.g. Cobertura/OpenCover) for `dotnet test`.
- [ ] **Frontend**: Vitest coverage (e.g. v8/istanbul) and output (e.g. `coverage/`).
- [ ] **Single report or dashboard**: Merge backend + frontend (and optional infra/DB) into one place (e.g. CI artifact, or Sonar/Codecov-style dashboard).
- [ ] **Gaps**: Identify modules or layers with no or low coverage and track in backlog.

### Cross-stack consistency

- [ ] **Naming**: Consistent test naming (e.g. `*.Tests`, `*.Spec`, `*.e2e`) and folder layout per stack.
- [ ] **Env/secrets**: Tests that need env (e.g. DB, Azure) are documented and use same patterns (e.g. `.env.example`, Key Vault in CI).
- [ ] **No flake**: Critical paths (e.g. smoke, deploy gate) are stable and not flaky.

## Routing (where to look)

- **.NET tests**: `src/**/*.csproj`, `tools/**/*.csproj`; run with `dotnet test` (optionally with coverage).
- **AdminUi tests**: `src/AdminUi/package.json` (`test`, `test:watch`, `test:ui`); Vitest config in `src/AdminUi/`.
- **API smoke**: `src/Api.SmokeTests/` (in-memory host).
- **Infra**: `.github/workflows/infra-validate.yml`, `scripts/infra/whatif.ps1`.
- **DB (planned)**: `db/`, Flyway; `.cursor/skills/db-change-flyway/SKILL.md`.
- **Deploy gate**: `scripts/deploy/aca-bluegreen.ps1` (TODO: wire smoke + metrics).

## Output format (suggested)

When acting as this subagent, provide:

- **Inventory**: Table or list of test projects/workflows, stack, type, and run command.
- **Gaps**: Missing unit/integration/e2e/infra/DB coverage and suggested next steps.
- **Single-pane proposal**: Concrete steps (e.g. root `scripts/test-all.ps1` or CI job matrix) to get to one view.
- **Blocking / non-blocking**: What must be in place before release vs nice-to-have.
