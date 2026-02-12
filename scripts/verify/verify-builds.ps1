<#
module: scripts.verify.verifyBuilds
purpose: Run all four repo builds, verify success, and report exceptions or issues.
exports:
  - Invoke-AllBuilds: main entrypoint; returns $true if all passed
patterns:
  - repeatable_scripts: safe to re-run; captures exit codes and output
notes:
  - Builds: (1) .NET solution, (2) Admin UI npm build, (3) Bicep compile, (4) RepoLinter.
  - Bicep CLI required for Bicep step; optional -SkipBicep to skip if bicep not installed.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [switch] $SkipBicep,

  [Parameter()]
  [switch] $SkipRepoLinter,

  [Parameter()]
  [string] $RepoRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = if ($PSScriptRoot) {
    (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  } else {
    (Get-Location).Path
  }
}

$RepoRoot = (Resolve-Path $RepoRoot).Path

function Invoke-BuildStep {
  param(
    [string] $Name,
    [scriptblock] $Run
  )
  $record = @{
    Name   = $Name
    Passed = $false
    Code   = $null
    Output = ''
    Error  = ''
  }
  try {
    $record.Output = (& $Run 2>&1 | Out-String).Trim()
    $record.Code = $LASTEXITCODE
    if ($null -eq $record.Code) { $record.Code = 0 }
    $record.Passed = ($record.Code -eq 0)
  } catch {
    $record.Passed = $false
    $record.Code = -1
    $record.Error = $_.Exception.Message
    $record.Output = $_.ScriptStackTrace
  }
  return $record
}

$results = @()

# 1. .NET build
Write-Host "Build 1/4: .NET solution..." -ForegroundColor Cyan
$results += Invoke-BuildStep -Name 'dotnet build' -Run {
  Set-Location $RepoRoot
  dotnet build (Join-Path $RepoRoot 'ProjectArchitecture.slnx') --verbosity minimal --nologo
}

# 2. Admin UI build
Write-Host "Build 2/4: Admin UI (npm)..." -ForegroundColor Cyan
$adminUiPath = Join-Path $RepoRoot 'src\AdminUi'
if (-not (Test-Path (Join-Path $adminUiPath 'package.json'))) {
  $results += @{ Name = 'Admin UI (npm)'; Passed = $false; Code = -1; Output = ''; Error = 'package.json not found' }
} else {
  $results += Invoke-BuildStep -Name 'Admin UI (npm)' -Run {
    Set-Location $adminUiPath
    npm run build
  }
}

# 3. Bicep build
if (-not $SkipBicep) {
  Write-Host "Build 3/4: Bicep compile..." -ForegroundColor Cyan
  $bicepFile = Join-Path $RepoRoot 'infra\bicep\main.rg.bicep'
  if (-not (Test-Path $bicepFile)) {
    $results += @{ Name = 'Bicep compile'; Passed = $false; Code = -1; Output = ''; Error = 'main.rg.bicep not found' }
  } else {
    $bicep = Get-Command bicep -ErrorAction SilentlyContinue
    if (-not $bicep) {
      $results += @{ Name = 'Bicep compile'; Passed = $false; Code = -1; Output = ''; Error = 'Bicep CLI (bicep) not found. Install it or use -SkipBicep.' }
    } else {
      $results += Invoke-BuildStep -Name 'Bicep compile' -Run {
        Set-Location $RepoRoot
        bicep build (Join-Path $RepoRoot 'infra\bicep\main.rg.bicep')
      }
    }
  }
} else {
  Write-Host "Build 3/4: Bicep compile (skipped -SkipBicep)" -ForegroundColor Gray
}

# 4. RepoLinter
if (-not $SkipRepoLinter) {
  Write-Host "Build 4/4: RepoLinter..." -ForegroundColor Cyan
  $repoLinterProj = Join-Path $RepoRoot 'tools\RepoLinter\RepoLinter.csproj'
  if (-not (Test-Path $repoLinterProj)) {
    $results += @{ Name = 'RepoLinter'; Passed = $false; Code = -1; Output = ''; Error = 'RepoLinter.csproj not found' }
  } else {
    $results += Invoke-BuildStep -Name 'RepoLinter' -Run {
      Set-Location $RepoRoot
      dotnet run --project (Join-Path $RepoRoot 'tools\RepoLinter\RepoLinter.csproj') -- --all
    }
  }
} else {
  Write-Host "Build 4/4: RepoLinter (skipped -SkipRepoLinter)" -ForegroundColor Gray
}

# Summary
$total = [int] $results.Count
$passed = [int] ($results | Where-Object { $_.Passed }).Count
$failed = $total - $passed

Write-Host ""
Write-Host "========== Build verification summary ==========" -ForegroundColor White
foreach ($r in $results) {
  $status = if ($r.Passed) { 'PASS' } else { 'FAIL' }
  $color = if ($r.Passed) { 'Green' } else { 'Red' }
  $code = if ($null -ne $r.Code -and $r.Code -ne 0) { " (exit $($r.Code))" } else { '' }
  Write-Host "  $status  $($r.Name)$code" -ForegroundColor $color
  if (-not $r.Passed -and ($r.Error -or $r.Output)) {
    $err = if ($r.Error) { $r.Error } else { $r.Output }
    $lines = ($err -split "`n") | Select-Object -First 15
    foreach ($line in $lines) {
      Write-Host "         $line" -ForegroundColor DarkGray
    }
    if (($err -split "`n").Count -gt 15) {
      Write-Host "         ... (truncated)" -ForegroundColor DarkGray
    }
  }
}
Write-Host "=================================================" -ForegroundColor White
Write-Host "  Passed: $passed / $total | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host ""

if ($failed -gt 0) {
  exit 1
}
exit 0
