<!--
module: docs.ai.moduleHeaders
purpose: Define the required module header standard (YAML-in-comment) and language-specific wrappers.
exports:
  - standard: required keys + examples
patterns:
  - module_header
notes:
  - Existing files may be missing headers; add/update headers when touching a file.
-->

# Module headers — standard (LLM-forward)

This repo uses a short **YAML header embedded in a file comment** as the first non-empty content of every authored, comment-capable file. The goal is fast orientation + consistent AI-assisted edits.

## Required keys

- `module`: module name for the file (validated by path prefix rules in `docs/ai/module-map.yml`)
- `purpose`: 1–2 sentences on what this file does
- `exports`: list of public entrypoints (outputs, functions, commands, endpoints, types)
- `patterns`: list of required/important patterns used in this file

## Optional keys

- `notes`: gotchas (security/perf/reliability); prefer a list
- `owner`: team or individual owner
- `security`, `perf`, `observability`: additional lists for review focus

## Formatting rules

- The header must be the **first non-empty content** (allow a shebang/BOM if required by the runtime).
- The payload is valid YAML if you remove the comment delimiters/prefixes.
- Keys are **lowercase**.
- Indent with **2 spaces** (no tabs).
- If unknown, use empty lists: `exports: []`, `patterns: []`.

## Language-specific wrappers

- **C# / TypeScript / Bicep**: `/* ... */`
- **PowerShell**: `<# ... #>`
- **Markdown / Vue (`.md`, `.vue`)**: `<!-- ... -->` (HTML comment)
- **SQL**: `-- ` prefixed lines (one YAML line per comment line)
- **YAML (`.yml`, `.yaml`)**: `# ` prefixed lines (one YAML line per comment line)

## Special case: files that require YAML frontmatter

Some repo files must start with YAML frontmatter for their own tooling. In those cases, include the module header keys **inside the same frontmatter block** (do not add a second header).

Applies to:

- `.cursor/rules/*.mdc`
- `.cursor/skills/*/SKILL.md`

Example (`.cursor/rules/module-headers.mdc`):

```markdown
---
description: Require module headers for authored files
globs: "**/*.{bicep,bicepparam,ps1,psm1,cs,ts,tsx,vue,sql,md}"
alwaysApply: false
module: cursor.rules.moduleHeaders
purpose: Ensure new/edited files start with the standard module header.
exports:
  - rule: module header required
patterns:
  - module_header
---
```

## Module naming

Use **dot-separated** names. The **prefix must match** the file’s location per `docs/ai/module-map.yml`.

Examples:

- `infra.bicep.mainRg`
- `infra.bicep.modules.containerAppApi`
- `scripts.infra.deploy`
- `db.catalog.identity` (planned)
- `inventory` / `billing` / `audit` (planned domain modules)

## Examples

### Bicep (`*.bicep`)

```bicep
/*
module: infra.bicep.modules.containerAppApi
purpose: Provision the API Azure Container App with external ingress and multiple revisions enabled (blue/green ready).
exports:
  - outputs.ingressFqdn
patterns:
  - multiple_revisions
notes:
  - Image tag is updated by the app pipeline (ACR).
*/
```

### PowerShell (`*.ps1`)

```powershell
<#
module: scripts.infra.deploy
purpose: Idempotently deploy (or update) an environment's Azure infrastructure via Bicep.
exports:
  - Deploy-Infrastructure
patterns:
  - repeatable_scripts
notes:
  - Requires Azure CLI (`az`) login (or CI OIDC).
#>
```

### C# (`*.cs`)

```csharp
/*
module: inventory
purpose: HTTP endpoints for inventory operations.
exports:
  - InventoryEndpoints.Map(IEndpointRouteBuilder)
patterns:
  - minimal_api
  - idempotency_key
notes:
  - Validate tenant resolution before accessing the tenant DB.
*/
```

### Vue (`*.vue`)

```vue
<!--
module: adminui.users
purpose: Admin console users list page.
exports:
  - UsersPage
patterns:
  - naive_ui
  - query_caching
-->
```

### SQL (`*.sql`)

```sql
-- module: db.tenant.inventory
-- purpose: Inventory schema objects for tenant DBs.
-- exports:
--   - table: inventory.shop
--   - policy: inventory.shop_tenant_isolation
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Every tenant-scoped table must FORCE RLS and bind to app.tenant_id.
```

