<#
module: scripts.deploy.acaBlueGreen
purpose: Deploy a new ACA revision and shift traffic using labels (blue/green) for near-zero downtime.
exports:
  - Invoke-AcaBlueGreenDeploy: main entrypoint
patterns:
  - multiple_revisions: requires container app revisions mode 'Multiple'
  - label_weight_traffic: uses revision labels + `az containerapp ingress traffic set --label-weight`
notes:
  - This is a template script: wire smoke tests and telemetry gates to your app's health endpoints and SLOs.
  - Docs:
    - Traffic splitting: https://learn.microsoft.com/en-us/azure/container-apps/traffic-splitting
    - CLI traffic commands: https://learn.microsoft.com/en-us/cli/azure/containerapp/ingress/traffic?view=azure-cli-latest
    - Revision labels: https://learn.microsoft.com/en-us/cli/azure/containerapp/revision/label?view=azure-cli-latest
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter(Mandatory)]
  [string] $ContainerAppName,

  [Parameter(Mandatory)]
  [string] $Image,

  [Parameter()]
  [string] $StableLabel = 'blue',

  [Parameter()]
  [string] $NewLabel = 'green',

  [Parameter()]
  [int[]] $TrafficSteps = @(1, 10, 50, 100)
)

$ErrorActionPreference = 'Stop'

function Ensure-LabelExistsOnLatest {
  param([string]$Label)

  $traffic = az containerapp ingress traffic show -n $ContainerAppName -g $ResourceGroupName -o json | ConvertFrom-Json
  $labels = @($traffic.traffic | Where-Object { $_.label -ne $null } | Select-Object -ExpandProperty label)

  if ($labels -contains $Label) {
    return
  }

  Write-Host "Label '$Label' not found; assigning it to latest revision..."
  az containerapp revision label add -n $ContainerAppName -g $ResourceGroupName --label $Label --revision latest --yes | Out-Null
}

function Set-TrafficByLabels {
  param([int]$StableWeight, [int]$NewWeight)

  az containerapp ingress traffic set -n $ContainerAppName -g $ResourceGroupName `
    --label-weight "$StableLabel=$StableWeight" "$NewLabel=$NewWeight" | Out-Null
}

Write-Host "Ensuring stable label '$StableLabel' exists..."
Ensure-LabelExistsOnLatest -Label $StableLabel

Write-Host "Deploying new revision with image '$Image'..."
az containerapp update -n $ContainerAppName -g $ResourceGroupName --image $Image | Out-Null

Write-Host "Assigning new label '$NewLabel' to latest revision..."
az containerapp revision label add -n $ContainerAppName -g $ResourceGroupName --label $NewLabel --revision latest --yes | Out-Null

Write-Host "Pinning traffic: $StableLabel=100, $NewLabel=0"
Set-TrafficByLabels -StableWeight 100 -NewWeight 0

foreach ($step in $TrafficSteps) {
  if ($step -le 0) { continue }
  if ($step -ge 100) {
    Write-Host "Shifting traffic to $NewLabel=100"
    Set-TrafficByLabels -StableWeight 0 -NewWeight 100
    break
  }

  Write-Host "Canary shift: $NewLabel=$step, $StableLabel=$([Math]::Max(0, 100 - $step))"
  Set-TrafficByLabels -StableWeight ([Math]::Max(0, 100 - $step)) -NewWeight $step

  # TODO: add smoke tests + metrics gate here (p95 latency, error rate, etc.) before proceeding.
  Start-Sleep -Seconds 10
}

Write-Host "Blue/green deploy complete."

