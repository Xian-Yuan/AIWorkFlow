<#
.SYNOPSIS
    Role-aware Hermes agent launcher. Resolves profile, verifies gates,
    sets environment, and starts Hermes from the repository root.
.DESCRIPTION
    This script is the safe, bounded entry point for running Hermes agents
    within the jinli workflow. It:
    - Validates role, task, and work package parameters
    - Runs Plan gate for implementer/verifier roles
    - Runs Can-Edit check for implementer roles
    - Calls sync-hermes-workflow.ps1 to ensure profiles are current
    - Sets JINLI_ROLE, JINLI_TASK_NAME, JINLI_WORK_PACKAGE, UEGAMEDEV_ROOT
    - Starts Hermes with the correct profile from the repository root
.PARAMETER Role
    Required. One of: planner, implementer, verifier.
.PARAMETER TaskName
    Required for implementer and verifier. Optional for planner.
    The task packet name (e.g. _shared/2026-06-19-hermes-workflow-integration).
.PARAMETER WorkPackage
    Required for implementer. The work package ID (e.g. WP01).
.PARAMETER DryRun
    If set, prints the resolved configuration without starting Hermes.
.PARAMETER NoSync
    If set, skips profile synchronization before launch.
.EXAMPLE
    .\invoke-hermes-agent.ps1 -Role planner -DryRun
.EXAMPLE
    .\invoke-hermes-agent.ps1 -Role implementer -TaskName _shared/2026-06-19-hermes-workflow-integration -WorkPackage WP01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("planner", "implementer", "verifier")]
    [string]$Role,

    [string]$TaskName = "",

    [string]$WorkPackage = "",

    [switch]$DryRun,

    [switch]$NoSync
)

$ErrorActionPreference = "Stop"
$repoRoot = "E:\UEGameDevelopment"
$hermesRoot = Join-Path $repoRoot ".tools\hermes-worker"
$hermesExe = Join-Path $hermesRoot "hermes-agent\venv\Scripts\hermes.exe"
$syncScript = Join-Path $repoRoot ".trae\scripts\sync-hermes-workflow.ps1"
$taskStateScript = Join-Path $repoRoot ".trae\scripts\task-state.ps1"
$taskGuardScript = Join-Path $repoRoot ".trae\scripts\task-guard.ps1"

# === 1. Validate role ===
$profileName = switch ($Role) {
    "planner"    { "jinli-planner" }
    "implementer" { "jinli-implementer" }
    "verifier"   { "jinli-planner" }  # verifier uses planner profile in verifier mode
}

# === 2. Validate task name (required for implementer/verifier) ===
if ($Role -in @("implementer", "verifier") -and [string]::IsNullOrWhiteSpace($TaskName)) {
    Write-Host "[BLOCKED] Task name is required for role: $Role" -ForegroundColor Red
    Write-Host "  Usage: invoke-hermes-agent.ps1 -Role $Role -TaskName <task-name>" -ForegroundColor Yellow
    exit 1
}

# === 3. Validate work package (required for implementer) ===
if ($Role -eq "implementer" -and [string]::IsNullOrWhiteSpace($WorkPackage)) {
    Write-Host "[BLOCKED] Work package is required for role: implementer" -ForegroundColor Red
    Write-Host "  Usage: invoke-hermes-agent.ps1 -Role implementer -TaskName <task> -WorkPackage <WPxx>" -ForegroundColor Yellow
    exit 1
}

# Validate WP format
if ($WorkPackage -and $WorkPackage -notmatch '^WP\d+$') {
    Write-Host "[BLOCKED] Invalid work package ID: $WorkPackage (expected format: WP01, WP02, etc.)" -ForegroundColor Red
    exit 1
}

# Validate task name format (no traversal)
if ($TaskName -and $TaskName -match '\.\.') {
    Write-Host "[BLOCKED] Task name contains traversal: $TaskName" -ForegroundColor Red
    exit 1
}

# === 4. Check Plan gate for implementer ===
if ($Role -in @("implementer", "verifier") -and $TaskName) {
    Write-Host "=== Checking Plan gate for: $TaskName ===" -ForegroundColor Cyan
    $planResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $taskGuardScript $TaskName plan 2>&1
    $planOutput = $planResult | Out-String
    if ($planOutput -notmatch "ALL GUARDS PASSED" -and $planOutput -notmatch "PASSED") {
        Write-Host "[BLOCKED] Plan gate has not passed for: $TaskName" -ForegroundColor Red
        Write-Host "  Run task-guard.ps1 first to resolve plan requirements." -ForegroundColor Yellow
        if (-not $DryRun) { exit 1 }
    } else {
        Write-Host "[PASS] Plan gate passed" -ForegroundColor Green
    }
}

# === 5. Check Can-Edit for implementer ===
if ($Role -eq "implementer" -and $TaskName) {
    Write-Host "=== Checking Can-Edit for: $TaskName ===" -ForegroundColor Cyan
    $editResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $taskStateScript can-edit $TaskName 2>&1
    $editOutput = $editResult | Out-String
    if ($editOutput -notmatch "AUTHORIZED" -and $editOutput -notmatch "\[PASS\]") {
        Write-Host "[BLOCKED] Can-Edit check failed for: $TaskName" -ForegroundColor Red
        Write-Host "  Phase may not be 'implement', or gate requirements are not met." -ForegroundColor Yellow
        if (-not $DryRun) { exit 1 }
    } else {
        Write-Host "[PASS] Can-Edit authorized" -ForegroundColor Green
    }
}

# === 6. Synchronize profiles ===
if (-not $NoSync) {
    Write-Host "=== Synchronizing profiles ===" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $syncScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -Check 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Sync check detected drift. Applying..." -ForegroundColor Yellow
            & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -Apply 2>&1
        }
    } else {
        Write-Host "[WARN] Sync script not found, skipping: $syncScript" -ForegroundColor Yellow
    }
}

# === 7. Resolve paths ===
$taskRoot = ""
$claimPath = ""
$reportPath = ""
$mcpConfig = Join-Path $repoRoot ".trae\hermes\profiles\$profileName\mcp.json"
$pluginSource = Join-Path $repoRoot ".trae\hermes\plugins\jinli-workflow-guard"

if ($TaskName) {
    $taskRoot = Join-Path $repoRoot ".trae\tasks\$TaskName"
    if (-not (Test-Path -LiteralPath $taskRoot)) {
        Write-Host "[BLOCKED] Task packet not found: $taskRoot" -ForegroundColor Red
        if (-not $DryRun) { exit 1 }
    }
}

if ($WorkPackage) {
    $claimPath = Join-Path $taskRoot "claims\hermes-mcp-$WorkPackage.md"
    $reportPath = Join-Path $taskRoot "reports\hermes-mcp-$WorkPackage-result.md"
}

# === 8. Build environment ===
$envVars = @{
    "JINLI_ROLE" = $Role
    "UEGAMEDEV_ROOT" = $repoRoot
}
if ($TaskName) { $envVars["JINLI_TASK_NAME"] = $TaskName }
if ($WorkPackage) { $envVars["JINLI_WORK_PACKAGE"] = $WorkPackage }

# === 9. Dry-run output ===
if ($DryRun) {
    Write-Host "`n=== Dry Run Resolution ===" -ForegroundColor Cyan
    Write-Host "  Role:           $Role"
    Write-Host "  Profile:        $profileName"
    Write-Host "  Task:           $(if ($TaskName) { $TaskName } else { '(not required)' })"
    Write-Host "  Work Package:   $(if ($WorkPackage) { $WorkPackage } else { '(not required)' })"
    Write-Host "  Repo Root:      $repoRoot"
    Write-Host "  Hermes Exe:     $(if (Test-Path $hermesExe) { $hermesExe } else { 'NOT FOUND' })"
    Write-Host "  MCP Config:     $(if (Test-Path $mcpConfig) { $mcpConfig } else { 'NOT FOUND' })"
    Write-Host "  Plugin Source:  $(if (Test-Path $pluginSource) { $pluginSource } else { 'NOT FOUND' })"
    Write-Host "  Task Root:      $(if ($taskRoot -and (Test-Path $taskRoot)) { $taskRoot } else { 'N/A' })"
    Write-Host "  Claim Path:     $(if ($claimPath) { $claimPath } else { 'N/A' })"
    Write-Host "  Report Path:    $(if ($reportPath) { $reportPath } else { 'N/A' })"
    Write-Host "`n  Environment Variables:"
    foreach ($key in $envVars.Keys) {
        Write-Host "    $key=$($envVars[$key])"
    }
    Write-Host "`n=== Dry Run Complete ===" -ForegroundColor Green
    exit 0
}

# === 10. Execute Hermes ===
if (-not (Test-Path -LiteralPath $hermesExe)) {
    Write-Host "[BLOCKED] Hermes executable not found: $hermesExe" -ForegroundColor Red
    Write-Host "  Ensure Hermes is installed under .tools/hermes-worker/" -ForegroundColor Yellow
    exit 1
}

# Set environment variables
foreach ($key in $envVars.Keys) {
    Set-Item -Path "env:$key" -Value $envVars[$key]
}

Write-Host "`n=== Starting Hermes ===" -ForegroundColor Cyan
Write-Host "  Role: $Role | Profile: $profileName | Task: $TaskName | WP: $WorkPackage" -ForegroundColor White

# Start Hermes with the correct profile from the repo root
$hermesArgs = @("-p", $profileName)
if ($TaskName) {
    # Hermes doesn't natively understand task names, but the profile
    # and env vars provide the workflow context
}

try {
    & $hermesExe @hermesArgs
} catch {
    Write-Host "[ERROR] Hermes execution failed: $_" -ForegroundColor Red
    exit 1
}
