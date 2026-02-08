<!--
module: docs.ai.subagents.prReviewer
purpose: Checklist for reviewing pull requests in this repo (quality + safety + conventions).
exports:
  - checklist: pr_review
patterns:
  - review_checklist
-->

# PR reviewer — checklist

Use this when reviewing any change set.

## Repo contract

- [ ] New/edited comment-capable files start with a **module header** (`docs/ai/module-headers.md`)
- [ ] Header `module:` prefix matches `docs/ai/module-map.yml`
- [ ] No secrets committed (tokens, passwords, connection strings, certs)

## Change safety

- [ ] Changes are **idempotent** where expected (IaC/scripts)
- [ ] Risky operations are guarded (deletes/replacements/destructive DDL)
- [ ] Defaults are safe (prod-friendly where applicable; avoid cost explosions)

## Correctness & maintainability

- [ ] Naming is consistent; intent is clear
- [ ] Inputs are validated (especially scripts and pipeline params)
- [ ] Outputs/exports are minimal and purposeful
- [ ] Docs updated where behavior changed

## Test/validation evidence

- [ ] CI workflow updates include a clear rationale
- [ ] Infra updates have validate/what-if coverage
- [ ] Any “manual step” is documented with exact commands

## Review output format (suggested)

- **Blocking**: must fix before merge
- **Non-blocking**: recommended improvements
- **Questions**: clarify intent / future follow-up

