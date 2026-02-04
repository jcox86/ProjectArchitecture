<#
module: scripts.infra.destroy
purpose: Tear down an environment by deleting the Azure Resource Group (rebuildable via `deploy.ps1`).
exports:
  - Remove-Infrastructure: main entrypoint function
patterns:
  - rebuildable_env: treat the RG as disposable in dev/staging; prod requires explicit confirmation
notes:
  - This is destructive. Recommended to use manual approvals for staging/prod.
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

function Remove-Infrastructure {
  if ($Environment -eq 'prod' -and -not $YesIReallyWantToDelete) {
    throw "Refusing to delete prod without -YesIReallyWantToDelete."
  }

  if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Delete resource group")) {
    Write-Host "Deleting RG '$ResourceGroupName' (env: $Environment)..."
    az group delete --name $ResourceGroupName --yes --no-wait | Out-Null
    Write-Host "Delete initiated."
  }
}

Remove-Infrastructure

