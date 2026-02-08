<!--
module: docs.requirements.index
purpose: Entry point for product and quality requirements documentation for this template.
exports:
  - doc: requirements_overview
patterns:
  - docs_skeleton
  - requirements_docs
-->

# Requirements

This folder captures the **functional requirements** and **non-functional requirements (NFRs)** for the template and for any product built from it.

## What to put here

- **Functional requirements**: end-user and admin capabilities, permissions, workflows.
- **NFRs / quality attributes**: availability, performance, security, compliance, cost budgets.
- **Quality scenarios**: concrete “stimulus → response” scenarios (latency, incident recovery, scaling, etc.).
- **Constraints**: “locked-in” decisions and platform constraints that shape the solution.

## References

- `PLAN.md` (root): current implementation plan and locked-in decisions.
- `docs/adr/`: architecture decisions and their rationale.
- `docs/ai/repo-map.md`: high-signal repo orientation.

