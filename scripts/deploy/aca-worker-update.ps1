<#
module: scripts.deploy.acaWorkerUpdate
purpose: Update Worker container app to a new image (no ingress; simple revision update).
exports:
  - Invoke-AcaWorkerUpdate: main entrypoint
patterns:
  - single_revision: Worker has no public traffic; no blue/green needed
notes:
  - Use aca-bluegreen.ps1 for API and Admin UI; use this for Worker only.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter(Mandatory)]
  [string] $ContainerAppName,

  [Parameter(Mandatory)]
  [string] $Image
)

$ErrorActionPreference = 'Stop'

Write-Host "Updating Worker '$ContainerAppName' to image '$Image'..."
az containerapp update -n $ContainerAppName -g $ResourceGroupName --image $Image
Write-Host "Worker update complete."
