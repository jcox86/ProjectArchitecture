<!--
module: docs.security.index
purpose: Entry point for security documentation (identity, authorization, secrets, and threat modeling).
exports:
  - doc: security_overview
patterns:
  - docs_skeleton
  - security_baseline
-->

# Security

This folder documents the security posture and guardrails for the template.

## Topics to cover

- **Identity**: product users vs admin staff, token validation, local/dev auth.
- **Authorization**: ABAC policy evaluation, attribute sources, caching strategy.
- **Secrets management**: Key Vault + managed identity; no secrets in the repo.
- **Data protection**: tenant isolation (RLS), encryption-at-rest/in-transit, PII handling.
- **Threat modeling**: baseline threats and mitigations (OWASP, tenant boundary risks, supply chain).
- **Logging**: redaction rules; do not log tokens/secrets/PII.

## Key decisions

- `docs/adr/0003-authentication-and-authorization-product-vs-admin.md`
- `docs/adr/0002-hybrid-multi-tenancy-and-tenant-resolution.md`

