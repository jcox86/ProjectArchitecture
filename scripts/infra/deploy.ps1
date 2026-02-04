<#
module: scripts.infra.deploy
purpose: Idempotently deploy (or update) an environment's Azure infrastructure via Bicep.
exports:
  - Deploy-Infrastructure: main entrypoint function
patterns:
  - repeatable_scripts: safe to re-run; uses ARM/Bicep idempotence
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
  [string] $Location = 'eastus',

  [Parameter()]
  [string] $PostgresAdminPassword
)

$ErrorActionPreference = 'Stop'

function Deploy-Infrastructure {
  Write-Host "Deploying infra for '$Environment' to RG '$ResourceGroupName' in '$Location'..."

  $templateFile = Join-Path $PSScriptRoot '..\..\infra\bicep\main.rg.bicep'
  $paramFile = Join-Path $PSScriptRoot "..\..\infra\bicep\params\$Environment.bicepparam"

  if (-not (Test-Path $templateFile)) { throw "Missing Bicep template: $templateFile" }
  if (-not (Test-Path $paramFile)) { throw "Missing params: $paramFile" }

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

  az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters $paramFile `
    --parameters postgresAdminPassword="$PostgresAdminPassword" `
    --mode Incremental | Out-Null

  Write-Host "Infra deployment complete: $deploymentName"
}

Deploy-Infrastructure

