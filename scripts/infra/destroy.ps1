<#
module: scripts.infra.destroy
purpose: Tear down an environment by deleting the Azure Resource Group and purging soft-deleted App Configuration stores (rebuildable via deploy.ps1).
exports:
  - Remove-Infrastructure: main entrypoint function
patterns:
  - rebuildable_env: treat the RG as disposable in dev/staging; prod requires explicit confirmation
  - idempotent: safe to re-run; purges only deleted App Config stores
notes:
  - This is destructive. Recommended to use manual approvals for staging/prod.
  - Purges soft-deleted App Configuration stores so the same names can be reused on redeploy.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)]
  [ValidateSet('dev','staging','prod')]
  [string] $Environment,

  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter()]
  [switch] $YesIReallyWantToDelete
)

$ErrorActionPreference = 'Stop'

function Get-AppConfigStoresInResourceGroup {
  param([string] $RgName)
  try {
    $json = az appconfig list --resource-group $RgName --output json 2>$null
    if (-not $json) { return @() }
    $list = $json | ConvertFrom-Json
    if ($list -is [array]) { return $list }
    if ($null -ne $list) { return @($list) }
  } catch {
    # RG may not exist or have no appconfig; return empty
  }
  return @()
}

function Purge-SoftDeletedAppConfigStores {
  param([array] $Stores)
  foreach ($store in $Stores) {
    $name = $store.name
    $location = $store.location
    if (-not $name -or -not $location) { continue }
    try {
      Write-Host "Purging soft-deleted App Configuration store '$name' (location: $location)..."
      az appconfig purge --name $name --location $location --yes 2>&1 | Out-Null
      Write-Host "Purged '$name'."
    } catch {
      Write-Host "Purge of '$name' skipped or failed (may already be purged): $_"
    }
  }
}

function Remove-Infrastructure {
  if ($Environment -eq 'prod' -and -not $YesIReallyWantToDelete) {
    throw "Refusing to delete prod without -YesIReallyWantToDelete."
  }

  if (-not $PSCmdlet.ShouldProcess($ResourceGroupName, "Delete resource group and purge App Config")) {
    return
  }

  # 1) List App Configuration stores in the RG (name + location) so we can purge after delete. Idempotent: if RG missing, list returns empty.
  $appConfigStores = @()
  try {
    $appConfigStores = Get-AppConfigStoresInResourceGroup -RgName $ResourceGroupName
  } catch {
    # RG may not exist
  }

  # 2) Delete the resource group. Idempotent: ignore "could not find" if RG already gone.
  Write-Host "Deleting RG '$ResourceGroupName' (env: $Environment)..."
  $deleteResult = az group delete --name $ResourceGroupName --yes 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    if ($deleteResult -match 'could not find|ResourceGroupNotFound|does not exist') {
      Write-Host "Resource group '$ResourceGroupName' not found or already deleted."
    } else {
      Write-Error "Failed to delete resource group: $deleteResult"
    }
  } else {
    Write-Host "Resource group '$ResourceGroupName' deleted."
  }

  # 3) Purge soft-deleted App Configuration stores so the same names can be reused on redeploy. Idempotent: purge only affects deleted stores; already purged is a no-op.
  if ($appConfigStores.Count -gt 0) {
    # Brief wait so deleted stores are visible in list-deleted before purge.
    Start-Sleep -Seconds 3
    Write-Host "Purging $($appConfigStores.Count) soft-deleted App Configuration store(s)..."
    Purge-SoftDeletedAppConfigStores -Stores $appConfigStores
  }
}

Remove-Infrastructure

