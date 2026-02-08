<!--
module: docs.adr.readme
purpose: Describe how Architecture Decision Records (ADRs) are created and maintained in this repo.
exports:
  - process: adr_workflow
  - template: 0000-template
patterns:
  - adr
  - docs_skeleton
-->

# Architecture Decision Records (ADRs)

ADRs capture **significant architectural decisions**, including context, the decision itself, and consequences. They help future contributors understand *why* the system looks the way it does.

## When to write an ADR

Write an ADR when you make a decision that is:

- Hard to reverse (database topology, tenancy model, identity provider)
- Cross-cutting (auth, messaging, observability, edge routing)
- Likely to be revisited (gateway strategy, tenancy tiering)

## How to add a new ADR

1. Copy `docs/adr/0000-template.md`
2. Choose the next number (e.g., `0007-...`)
3. Fill it out and set **Status** to `Proposed`
4. When accepted, update **Status** to `Accepted` (or `Superseded` when replaced)

## Naming convention

- `NNNN-short-decision-title.md` (example: `0005-edge-routing-front-door-and-optional-gateway.md`)

