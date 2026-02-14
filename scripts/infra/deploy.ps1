<#
module: scripts.infra.deploy
purpose: Idempotently deploy (or update) an environment's Azure infrastructure via Bicep.
exports:
  - Deploy-Infrastructure: main entrypoint function
patterns:
  - repeatable_scripts: safe to re-run; uses ARM/Bicep idempotence
  - idempotent: purges conflicting soft-deleted App Config stores before deploy
notes:
  - Requires Azure CLI (`az`) logged in (or CI OIDC login).
  - Uses `az deployment group create` with a bicepparam file.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('dev','staging','prod')]
  [string] $Environment,

  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter()]
  [string] $Location = 'westus2',

  [Parameter()]
  [string] $PostgresAdminPassword,

  [Parameter()]
  [string] $PostgresAppPassword
)

$ErrorActionPreference = 'Stop'

function Get-AppNameFromParamFile {
  param([string] $ParamFilePath)
  if (-not (Test-Path $ParamFilePath)) { return 'saastpl' }
  $content = Get-Content -Raw -Path $ParamFilePath
  if ($content -match "param\s+appName\s*=\s*['""]([^'""]+)['""]") { return $Matches[1].Trim() }
  return 'saastpl'
}

function Purge-SoftDeletedAppConfigStoresMatchingPrefix {
  param([string] $Prefix)
  try {
    $json = az appconfig list-deleted --output json 2>$null
    if (-not $json) { return }
    $list = $json | ConvertFrom-Json
    if (-not $list) { return }
    if (-not ($list -is [array])) { $list = @($list) }
    foreach ($store in $list) {
      if ($store.name -and $store.name.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) {
        $name = $store.name
        $location = $store.location
        if (-not $location) { continue }
        Write-Host "Purging soft-deleted App Configuration store '$name' so name can be reused..."
        try {
          az appconfig purge --name $name --location $location --yes 2>&1 | Out-Null
          Write-Host "Purged '$name'."
        } catch {
          Write-Host "Purge of '$name' skipped or failed: $_"
        }
      }
    }
  } catch {
    # list-deleted may fail (e.g. no permission or none deleted); continue with deploy
  }
}

function Deploy-Infrastructure {
  Write-Host "Deploying infra for '$Environment' to RG '$ResourceGroupName' in '$Location'..."

  $templateFile = Join-Path $PSScriptRoot '..\..\infra\bicep\main.rg.bicep'
  $paramFile = Join-Path $PSScriptRoot "..\..\infra\bicep\params\$Environment.bicepparam"

  if (-not (Test-Path $templateFile)) { throw "Missing Bicep template: $templateFile" }
  if (-not (Test-Path $paramFile)) { throw "Missing params: $paramFile" }

  # Purge any soft-deleted App Configuration stores that would conflict with our appConfig name (idempotent).
  $appName = Get-AppNameFromParamFile -ParamFilePath $paramFile
  $appConfigPrefix = "appcs-$appName-$Environment-"
  Purge-SoftDeletedAppConfigStoresMatchingPrefix -Prefix $appConfigPrefix

  # Ensure RG exists (create if missing).
  $rgExists = (az group exists --name $ResourceGroupName) | ConvertFrom-Json
  if (-not $rgExists) {
    Write-Host "Resource group does not exist. Creating '$ResourceGroupName'..."
    az group create --name $ResourceGroupName --location $Location | Out-Null
  }

  $deploymentName = "infra-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

  if ([string]::IsNullOrWhiteSpace($PostgresAdminPassword)) {
    $PostgresAdminPassword = $env:POSTGRES_ADMIN_PASSWORD
  }
  if ([string]::IsNullOrWhiteSpace($PostgresAdminPassword)) {
    throw "Missing Postgres admin password. Provide -PostgresAdminPassword or set POSTGRES_ADMIN_PASSWORD."
  }

  if ([string]::IsNullOrWhiteSpace($PostgresAppPassword)) {
    $PostgresAppPassword = $env:POSTGRES_APP_PASSWORD
  }

  $azArgs = @(
    'deployment', 'group', 'create',
    '--name', $deploymentName,
    '--resource-group', $ResourceGroupName,
    '--template-file', $templateFile,
    '--parameters', $paramFile,
    '--parameters', "postgresAdminPassword=$PostgresAdminPassword",
    '--mode', 'Incremental'
  )

  if (-not [string]::IsNullOrWhiteSpace($PostgresAppPassword)) {
    $azArgs += @('--parameters', "postgresAppPassword=$PostgresAppPassword")
  }

  az @azArgs | Out-Null

  Write-Host "Infra deployment complete: $deploymentName"
}

Deploy-Infrastructure

