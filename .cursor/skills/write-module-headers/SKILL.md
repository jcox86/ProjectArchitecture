---
name: write-module-headers
description: Generate or update module headers (YAML-in-comment) for new/edited files in this repo. Use when adding files, moving/renaming files, or standardizing headers to comply with docs/ai/module-headers.md.
module: cursor.skills.writeModuleHeaders
purpose: Provide a repeatable workflow and templates for adding the required module header to comment-capable files.
exports:
  - workflow: add_or_update_module_header
patterns:
  - module_header
notes:
  - Module prefixes are validated by docs/ai/module-map.yml (path → module prefix).
---

# Write module headers

## Quick start

When you create or edit a comment-capable file:

1. Determine the **module prefix** from the file path using `docs/ai/module-map.yml`.
2. Choose a concrete `module:` value that starts with that prefix.
3. Add the header as the **first non-empty content**, using the wrapper for the file type.
4. Keep `purpose` to 1–2 sentences; list real `exports` and `patterns`.

## Required keys (all headers)

- `module`
- `purpose`
- `exports` (list)
- `patterns` (list)

Optional: `notes`, `owner`, `security`, `perf`, `observability`.

## Wrappers by file type

Use the first non-empty content in the file:

- `*.bicep`, `*.bicepparam`, `*.cs`, `*.ts`, `*.tsx`:

```text
/*
module: ...
purpose: ...
exports:
  - ...
patterns:
  - ...
*/
```

- `*.ps1`, `*.psm1`:

```text
<#
module: ...
purpose: ...
exports:
  - ...
patterns:
  - ...
#>
```

- `*.md`, `*.vue`:

```text
<!--
module: ...
purpose: ...
exports:
  - ...
patterns:
  - ...
-->
```

- `*.sql`:

```text
-- module: ...
-- purpose: ...
-- exports:
--   - ...
-- patterns:
--   - ...
```

- `*.yml`, `*.yaml`:

```text
# module: ...
# purpose: ...
# exports:
#   - ...
# patterns:
#   - ...
```

## Special case: files that require YAML frontmatter

Do **not** add a second header. Instead, put module header keys in the same frontmatter block:

- `.cursor/rules/*.mdc`
- `.cursor/skills/*/SKILL.md`

Example:

```yaml
---
name: example-skill
description: ...
module: cursor.skills.example
purpose: ...
exports:
  - workflow: ...
patterns:
  - module_header
---
```

## Choosing `module:`

Rules of thumb:

- **Prefix must match the file path mapping** in `docs/ai/module-map.yml`.
- Use dot-separated names; keep them stable.
- If you move a file across mapped path prefixes, **update `module:`** accordingly.

Examples:

- `infra/bicep/main.rg.bicep` → `module: infra.bicep.mainRg`
- `infra/bicep/modules/containerApp.api.bicep` → `module: infra.bicep.modules.containerAppApi`
- `scripts/infra/deploy.ps1` → `module: scripts.infra.deploy`

