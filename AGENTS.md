<!--
module: repo.agents
purpose: Canonical AI router/entrypoint for working in this repo.
exports:
  - routing: key docs + task entrypoints
patterns:
  - ai_router
-->

# AGENTS.md — AI router (Cursor/OpenCode/Claude/Copilot Chat)

Start here. This file is the canonical entrypoint for any AI assistant working in this repo.

## Read first

- `docs/ai/repo-map.md`
- `docs/ai/module-headers.md`
- `docs/ai/module-map.yml`

## Non-negotiable conventions (LLM-forward)

- **Module headers**: every authored, comment-capable file should start with a module header (see `docs/ai/module-headers.md`).
- **No secrets**: never commit secrets. Use GitHub environment secrets + Azure Key Vault references.
- **Idempotent infra**: IaC and scripts must be safe to re-run.

## Where to go (common tasks)

- **Infra (Bicep)**: `infra/bicep/README.md`, `infra/bicep/main.rg.bicep`, `infra/bicep/modules/*.bicep`
- **Infra scripts**: `scripts/infra/deploy.ps1`, `scripts/infra/whatif.ps1`, `scripts/infra/destroy.ps1`
- **CI (infra)**: `.github/workflows/infra-validate.yml`, `.github/workflows/infra-deploy.yml`
- **Define/update module headers**: `.cursor/skills/write-module-headers/SKILL.md`
- **DB change (Flyway, planned)**: `.cursor/skills/db-change-flyway/SKILL.md`
- **Add a domain module end-to-end (planned)**: `.cursor/skills/add-module/SKILL.md`
- **Incident triage (planned)**: `.cursor/skills/incident-triage/SKILL.md`

## Review playbooks (checklists)

Use these when reviewing changes or asking the assistant to “act as” a specialist:

- `docs/ai/subagents/pr-reviewer.md`
- `docs/ai/subagents/architecture-enforcer.md`
- `docs/ai/subagents/security-reviewer.md`
- `docs/ai/subagents/performance-reviewer.md`
- `docs/ai/subagents/db-reviewer.md`
- `docs/ai/subagents/test-harness-coverage.md` — single pane of glass for test harness and coverage (unit, integration, e2e, infra, DB) across APIs and UIs.

