<!--
module: docs.ai.routingSnippets
purpose: Copy/paste snippets that quickly route an AI assistant to the right conventions and files in this repo.
exports:
  - snippet: short_router
  - snippet: compressed_router
patterns:
  - ai_router
-->

# Routing snippets (copy/paste)

## Short router (recommended)

Paste this at the start of an AI session:

```text
You are working in the ProjectArchitecture repo.

Read:
- AGENTS.md
- docs/ai/repo-map.md
- docs/ai/module-headers.md
- docs/ai/module-map.yml

Conventions:
- Add a module header (YAML-in-comment) to every new/edited comment-capable file (see docs/ai/module-headers.md).
- No secrets committed; use Key Vault + GitHub environment secrets.
- Infra changes must be idempotent and reviewed with what-if.

Routing:
- Infra (Bicep): infra/bicep/README.md → infra/bicep/main.rg.bicep → infra/bicep/modules/*
- Infra scripts: scripts/infra/*
- CI (infra): .github/workflows/infra-validate.yml and infra-deploy.yml
```

## Compressed router (token-minimal)

```text
ProjectArchitecture repo: start AGENTS.md, then docs/ai/repo-map.md + docs/ai/module-headers.md + docs/ai/module-map.yml.
Always add module header to new/edited comment-capable files; no secrets in repo; infra changes must be idempotent + validated/what-if.
```

