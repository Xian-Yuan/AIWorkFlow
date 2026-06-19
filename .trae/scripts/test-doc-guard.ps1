param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$DocGuard = Join-Path $PSScriptRoot "doc-guard.ps1"
$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$Failed = $false
$RunId = "__doc_guard_$PID"

function Add-Result {
    param([string]$Name, [bool]$Passed)
    if ($Passed) { Write-Host "[PASS] $Name" -ForegroundColor Green }
    else { Write-Host "[FAIL] $Name" -ForegroundColor Red; $script:Failed = $true }
}

function New-TestTask {
    param([string]$Name, [string]$DocImpact)
    $dir = Join-Path $Root ".trae\tasks\_shared\$Name"
    if (Test-Path $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir ".task.yaml") -Value @"
phase: plan
project_type: other
clarification_status: not_needed
user_confirmed_plan: true
router_skill_loaded: true
"@
    if ($DocImpact) {
        Set-Content -LiteralPath (Join-Path $dir "doc-impact.md") -Value $DocImpact
    }
    return $dir
}

Push-Location $Root
try {
    $validImpact = @"
## Project Document Scope
- Project: _shared
- System: Workflow regression
- Owner: test

## Code Changes
- None

## No Code Changes
Reason: doc guard regression fixture

## Documentation Updates
- Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md

## Docs Tree Updates
- None
"@

    $validName = "$RunId`_valid"
    $validDir = New-TestTask $validName $validImpact
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $DocGuard check-task "_shared/$validName" -Stage plan *> $null
    Add-Result "doc-impact with no-code reason passes" ($LASTEXITCODE -eq 0)
    if (Test-Path $validDir) { Remove-Item -LiteralPath $validDir -Recurse -Force }

    $missingName = "$RunId`_missing"
    $missingDir = New-TestTask $missingName ""
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $DocGuard check-task "_shared/$missingName" -Stage plan *> $null
    Add-Result "missing doc-impact blocks" ($LASTEXITCODE -ne 0)
    if (Test-Path $missingDir) { Remove-Item -LiteralPath $missingDir -Recurse -Force }
}
finally {
    Pop-Location
}

if ($Failed) { exit 1 }
exit 0
