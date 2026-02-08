<!--
module: docs.ai.subagents.securityReviewer
purpose: Checklist to review changes for common security risks in this template (Azure + app + DB).
exports:
  - checklist: security_review
patterns:
  - secrets_hygiene
  - least_privilege
-->

# Security reviewer — checklist

## Secrets & sensitive data

- [ ] No secrets committed (including sample `.env` with real values)
- [ ] Secrets come from **Key Vault** or CI secret store (not params files)
- [ ] Logs do not print secrets, tokens, connection strings, or PII

## Identity & access (Azure)

- [ ] Managed identity is used where possible (no shared keys unless required)
- [ ] RBAC is least-privilege and scoped (resource group / resource)
- [ ] Key Vault access is minimal (specific secrets, not broad “list all”)

## Network & edge

- [ ] Public ingress is intentional; WAF/Front Door rules are not weakened accidentally
- [ ] CORS / same-origin assumptions are explicit for Admin UI vs API (planned)

## Input validation & abuse resistance

- [ ] External inputs are validated (scripts, pipelines, APIs)
- [ ] Rate limiting / throttling concerns are noted for edge-exposed endpoints (planned)

## Supply chain

- [ ] New dependencies are justified and pinned appropriately
- [ ] CI/workflows do not introduce untrusted script execution

