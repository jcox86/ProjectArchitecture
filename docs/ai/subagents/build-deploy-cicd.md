<!--
module: docs.ai.subagents.buildDeployCicd
purpose: Configure and test compiling, deployment scripts, and packages so everything is ready to deploy and automated in CI/CD.
exports:
  - checklist: build_deploy_cicd_readiness
  - routing: where builds, scripts, and workflows live
patterns:
  - build_verification
  - deploy_automation
  - cicd_gates
-->

# Build, deploy & CI/CD — readiness subagent

Use this when configuring or validating that **compiling**, **deployment scripts**, and **packages** are correct and that **CI/CD** is automated and ready to deploy.

## Goal

- **Compile**: All build steps (backend, frontend, Bicep, linter) succeed locally and in CI.
- **Packages**: Docker images and dependencies are consistent, versioned, and build cleanly.
- **Deploy**: Scripts are idempotent, tested, and wired into pipelines.
- **CI/CD**: Workflows run the right gates (build, validate, deploy) with no manual steps required for a normal release.

## Repo build & deploy landscape

| Area | What | Where | How to run / trigger |
|------|------|--------|----------------------|
| **All builds** | Single verification script | `scripts/verify/verify-builds.ps1` | `./scripts/verify/verify-builds.ps1` |
| .NET | Solution build | `ProjectArchitecture.slnx` | `dotnet build ProjectArchitecture.slnx` |
| Admin UI | npm build | `src/AdminUi/` | `npm run build` (from AdminUi) |
| Bicep | IaC compile | `infra/bicep/main.rg.bicep` | `bicep build infra/bicep/main.rg.bicep` |
| Repo linter | Module headers, secrets scan | `tools/RepoLinter/` | `dotnet run --project tools/RepoLinter/RepoLinter.csproj -- --all` |
| Infra deploy | Bicep deploy (dev/staging/prod) | `scripts/infra/deploy.ps1` | `./scripts/infra/deploy.ps1 -Environment dev -ResourceGroupName <rg>` |
| Infra validate | Bicep build + validate + what-if | `scripts/infra/whatif.ps1` | `./scripts/infra/whatif.ps1 -Environment dev ...` |
| App deploy | API / Admin UI / Worker to ACA | `scripts/deploy/aca-bluegreen.ps1`, `aca-worker-update.ps1` | Used by `app-deploy.yml` |

## Checklist — build & compile readiness

- [ ] **verify-builds.ps1** runs successfully from repo root (all four steps: dotnet, Admin UI, Bicep, RepoLinter).
- [ ] **.NET**: `dotnet build` is warning-free; obsoletes/analyzers addressed (see `build-clean.mdc`).
- [ ] **Admin UI**: `npm run build` completes without errors; type/lint clean.
- [ ] **Bicep**: `bicep build` succeeds; no missing modules or parameters.
- [ ] **RepoLinter**: Passes with `--all` (and in CI with `--diff` for PRs).
- [ ] **Optional**: `-SkipBicep` / `-SkipRepoLinter` documented for environments where those tools aren’t installed.

## Checklist — packages & containers

- [ ] **Dockerfiles** exist and build for: Api, Worker, AdminUi (paths used by `app-deploy.yml`).
- [ ] **Docker build context** is correct (e.g. Admin UI: `-f src/AdminUi/Dockerfile src/AdminUi`).
- [ ] **Dependencies**: No unreachable or private feeds without CI setup; `package.json` / `*.csproj` versions are consistent.
- [ ] **Images**: Tagging strategy is clear (e.g. `latest` for dev; consider semver or commit SHA for prod).

## Checklist — deployment scripts

- [ ] **Idempotent**: Infra and app deploy scripts are safe to re-run (Bicep/ARM, ACA revision updates).
- [ ] **Parameters**: Required params (e.g. resource group, image tag) are documented and validated.
- [ ] **Secrets**: No secrets in scripts; use env vars or Key Vault / GitHub secrets.
- [ ] **Blue/green**: `aca-bluegreen.ps1` used for API and Admin UI; worker uses `aca-worker-update.ps1` (simple update).
- [ ] **Destroy**: `scripts/infra/destroy.ps1` is documented and guarded (e.g. confirm or env check).

## Checklist — CI/CD automation

- [ ] **Build gate**: Every PR (or main) runs the equivalent of “all builds pass” (e.g. dotnet build, npm build, Bicep, RepoLinter) — either via a single job or matrix.
- [ ] **Infra**: `infra-validate.yml` runs on PRs when `infra/bicep/**` or `scripts/infra/**` change; Bicep build + validate + what-if (fail on delete/replace).
- [ ] **App deploy**: `app-deploy.yml` runs on push to main (or dispatch) for `src/**` and `scripts/deploy/**`; builds images, pushes to ACR, runs blue/green (and worker update).
- [ ] **Repo lint**: `repo-lint.yml` runs on PRs; format check + RepoLinter (diff + secrets).
- [ ] **Secrets**: Azure OIDC (and any ACR/ACR_NAME, AZURE_RG_DEV, etc.) are in GitHub env secrets; no secrets in workflow files.
- [ ] **DB migrations**: If applicable, `db-migrate.yml` or equivalent runs in correct order (e.g. after infra, before app).

## Routing (where to look)

- **Unified build test**: `scripts/verify/verify-builds.ps1`
- **Workflows**: `.github/workflows/app-deploy.yml`, `infra-validate.yml`, `infra-deploy.yml`, `repo-lint.yml`, `db-migrate.yml`
- **Infra**: `infra/bicep/README.md`, `scripts/infra/deploy.ps1`, `scripts/infra/whatif.ps1`, `scripts/infra/destroy.ps1`
- **App deploy**: `scripts/deploy/aca-bluegreen.ps1`, `scripts/deploy/aca-worker-update.ps1`
- **Docker**: `src/Api/Dockerfile`, `src/Worker/Dockerfile`, `src/AdminUi/Dockerfile`
- **Conventions**: `docs/ai/repo-map.md`, `.cursor/rules/build-clean.mdc`

## Output format (suggested)

When acting as this subagent, provide:

- **Build status**: Which of the four verify-builds steps pass or fail locally/CI, and why.
- **Package/container**: Any Docker or dependency issues and how to fix them.
- **Scripts**: Whether deploy scripts are idempotent and correctly parameterized; any missing validations.
- **CI/CD gaps**: Workflows missing, triggers wrong, or steps that are manual and should be automated.
- **Blocking vs non-blocking**: What must be fixed before a deploy vs improvements for later.
