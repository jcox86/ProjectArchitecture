<!--
module: docs.adr.llmForward
purpose: Record the decision to adopt an LLM-forward repo contract (module headers, focused rules/skills) and enforce it via tooling.
exports:
  - decision: module_headers_required
  - decision: cursor_rules_and_skills_as_conventions
  - decision: repo_linter_enforced_in_hooks_and_ci
patterns:
  - adr
  - module_header
  - repo_contract
-->

# ADR 0006: LLM-forward repo contract and enforcement

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

This template is designed to be edited and extended with AI assistance over time. To keep AI-assisted changes safe and consistent, the repo needs:

- High-signal orientation artifacts (so assistants know “where to start”)
- Lightweight, persistent conventions close to the code
- Automated enforcement to prevent drift and “reward hacking”

## Decision

Adopt an **LLM-forward repository contract** and enforce it in local hooks and CI:

1. **Module headers are required**
   - Every authored, comment-capable file begins with a YAML-in-comment module header.
   - The module prefix must match the file’s location via `docs/ai/module-map.yml`.

2. **Conventions live as focused rules and skills**
   - Cursor rules in `.cursor/rules/` encode file-type and area-specific conventions.
   - Project skills in `.cursor/skills/` encode repeatable workflows (DB changes, module headers, add-module, incident triage).
   - `AGENTS.md` and `docs/ai/repo-map.md` act as router/orientation entrypoints.

3. **Enforcement via tooling**
   - A small `tools/RepoLinter` validates the contract (header presence + module mapping + exclusions).
   - Run it in:
     - local pre-commit hooks (fast feedback)
     - CI as a required check

4. **Safety guardrails**
   - “No secrets in repo” (use GitHub secrets + Key Vault references).
   - Idempotent infra/scripts (safe to re-run; no snowflake portal changes).

## Decision drivers

- Reduce time-to-context for humans and AI assistants
- Enforce consistent boundaries and conventions early (before the repo grows)
- Catch policy violations before they land on `main`
- Keep the template maintainable and auditable

## Consequences

### Positive

- Faster onboarding and safer AI-assisted edits
- Fewer “mystery files” and less architectural drift
- Automated checks create a consistent bar for quality

### Negative / trade-offs

- Slightly higher upfront friction: every new file needs a header and correct module name
- Requires maintaining `docs/ai/module-map.yml` as new top-level areas are added

### Neutral / follow-ups

- Keep rules small and specific; prefer multiple focused rules over one monolithic document.
- Expand repo linter checks carefully to avoid false positives and slow hooks.

## Alternatives considered

- **No headers, rely on docs/wiki**: less friction, but slower to orient and easier for drift to accumulate.
- **Huge single “CONTRIBUTING.md”**: becomes stale and is rarely read; rules/skills are more actionable in the editor.
- **No automated enforcement**: conventions erode quickly without tooling.

## References

- `AGENTS.md`
- `docs/ai/module-headers.md`
- `docs/ai/module-map.yml`
- `.cursor/rules/`
- `.cursor/skills/`
- `tools/RepoLinter/`

