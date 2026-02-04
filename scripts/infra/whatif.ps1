<#
module: scripts.infra.whatif
purpose: Run Azure what-if for an environment's Bicep deployment and optionally fail on deletes/replacements.
exports:
  - Invoke-InfraWhatIf: main entrypoint function
patterns:
  - safe_change_gates: detect deletes/replacements before applying changes
notes:
  - Intended for CI usage (PR gate) and local review.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('dev','staging','prod')]
  [string] $Environment,

  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter()]
  [switch] $FailOnDeleteOrReplace,

  [Parameter()]
  [string] $PostgresAdminPassword
)

$ErrorActionPreference = 'Stop'

function Invoke-InfraWhatIf {
  Write-Host "Running what-if for '$Environment' against RG '$ResourceGroupName'..."

  $templateFile = Join-Path $PSScriptRoot '..\..\infra\bicep\main.rg.bicep'
  $paramFile = Join-Path $PSScriptRoot "..\..\infra\bicep\params\$Environment.bicepparam"

  if (-not (Test-Path $templateFile)) { throw "Missing Bicep template: $templateFile" }
  if (-not (Test-Path $paramFile)) { throw "Missing params: $paramFile" }

  if ([string]::IsNullOrWhiteSpace($PostgresAdminPassword)) {
    $PostgresAdminPassword = $env:POSTGRES_ADMIN_PASSWORD
  }
  if ([string]::IsNullOrWhiteSpace($PostgresAdminPassword)) {
    throw "Missing Postgres admin password. Provide -PostgresAdminPassword or set POSTGRES_ADMIN_PASSWORD."
  }

  $whatIfJson = az deployment group what-if `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters $paramFile `
    --parameters postgresAdminPassword="$PostgresAdminPassword" `
    --result-format FullResourcePayloads `
    --no-pretty-print `
    --only-show-errors `
    -o json | ConvertFrom-Json

  # Summarize change types.
  $changes = @($whatIfJson.changes)
  $changeTypes = $changes | ForEach-Object { $_.changeType } | Group-Object | Sort-Object Count -Descending
  Write-Host "What-if change summary:"
  $changeTypes | ForEach-Object { Write-Host (" - {0}: {1}" -f $_.Name, $_.Count) }

  if ($FailOnDeleteOrReplace) {
    $destructive = $changes | Where-Object { $_.changeType -in @('Delete','Modify') -and ($_.delta | Where-Object { $_.propertyChangeType -eq 'Delete' -or $_.propertyChangeType -eq 'Modify' }) }
    # NOTE: ARM what-if does not have a universal “Replace” marker; replacements show up as Delete/Create pairs.
    $hasDeletes = ($changes | Where-Object { $_.changeType -eq 'Delete' }).Count -gt 0
    if ($hasDeletes) {
      throw "Destructive changes detected (Delete). Refuse to proceed without explicit approval."
    }
  }
}

Invoke-InfraWhatIf

