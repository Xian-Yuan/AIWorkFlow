<#
.SYNOPSIS
    End-to-end integration tests for Hermes workflow integration.
    Tests launcher, sync, gate enforcement, and profile resolution.
#>

$ErrorActionPreference = "Continue"
$repoRoot = "E:\UEGameDevelopment"
$launcher = Join-Path $repoRoot ".trae\scripts\invoke-hermes-agent.ps1"
$syncScript = Join-Path $repoRoot ".trae\scripts\sync-hermes-workflow.ps1"
$compatScript = Join-Path $repoRoot ".trae\scripts\test-hermes-skill-compatibility.ps1"
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Write-Test {
    param([string]$Name, [bool]$Passed, [string]$Detail = "")
    $script:totalTests++
    if ($Passed) {
        $script:passedTests++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor Red }
    }
}

Write-Host "`n=== Hermes Workflow Integration Tests ===`n" -ForegroundColor Cyan

# === 1. Launcher: unknown role rejected ===
Write-Host "--- 1. Launcher role validation ---" -ForegroundColor Yellow
$badRole = & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -Role "hacker" -DryRun 2>&1
$badRoleText = $badRole | Out-String
Write-Test "Unknown role rejected" ($badRoleText -match "BLOCKED" -or $badRoleText -match "not valid" -or $LASTEXITCODE -ne 0)

# === 2. Launcher: missing task rejected for implementer ===
Write-Host "`n--- 2. Missing task for implementer ---" -ForegroundColor Yellow
$noTask = & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -Role implementer -DryRun 2>&1
$noTaskText = $noTask | Out-String
Write-Test "Missing task rejected" ($noTaskText -match "BLOCKED" -or $noTaskText -match "required")

# === 3. Launcher: missing work package rejected ===
Write-Host "`n--- 3. Missing WP for implementer ---" -ForegroundColor Yellow
$noWP = & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -Role implementer -TaskName "_shared/test" -DryRun 2>&1
$noWPText = $noWP | Out-String
Write-Test "Missing WP rejected" ($noWPText -match "BLOCKED" -or $noWPText -match "required")

# === 4. Launcher: planner dry-run resolves ===
Write-Host "`n--- 4. Planner dry-run ---" -ForegroundColor Yellow
$plannerDR = & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -Role planner -DryRun 2>&1
$plannerDRText = $plannerDR | Out-String
$plannerOK = $plannerDRText -match "planner" -and $plannerDRText -match "jinli-planner"
Write-Test "Planner dry-run resolves" $plannerOK "Expected profile jinli-planner in output"

# === 5. Launcher: implementer dry-run with valid task ===
Write-Host "`n--- 5. Implementer dry-run ---" -ForegroundColor Yellow
$implDR = & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -Role implementer -TaskName "_shared/2026-06-19-hermes-workflow-integration" -WorkPackage WP01 -DryRun 2>&1
$implDRText = $implDR | Out-String
$implOK = $implDRText -match "implementer" -and $implDRText -match "jinli-implementer"
Write-Test "Implementer dry-run resolves" $implOK "Expected profile jinli-implementer in output"

# === 6. Sync check detects profile drift ===
Write-Host "`n--- 6. Sync check ---" -ForegroundColor Yellow
$syncCheck = & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -Check 2>&1
$syncCheckText = $syncCheck | Out-String
$syncOK = $LASTEXITCODE -eq 0
Write-Test "Sync check passes" $syncOK "Exit code: $LASTEXITCODE"

# === 7. Compatibility tests pass ===
Write-Host "`n--- 7. Compatibility tests ---" -ForegroundColor Yellow
$compatResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $compatScript 2>&1
$compatText = $compatResult | Out-String
$compatOK = $compatText -match "27 / 27 passed" -or $LASTEXITCODE -eq 0
Write-Test "Compatibility tests pass" $compatOK

# === 8. Runtime files remain under .tools/hermes-worker ===
Write-Host "`n--- 8. Runtime placement ---" -ForegroundColor Yellow
$runtimeDir = Join-Path $repoRoot ".tools\hermes-worker"
$runtimeOK = Test-Path -LiteralPath $runtimeDir
Write-Test "Runtime directory exists" $runtimeOK "Expected: $runtimeDir"

# === 9. Profile sources exist in repository ===
Write-Host "`n--- 9. Repository profile sources ---" -ForegroundColor Yellow
$plannerSrc = Join-Path $repoRoot ".trae\hermes\profiles\jinli-planner\SOUL.md"
$implSrc = Join-Path $repoRoot ".trae\hermes\profiles\jinli-implementer\SOUL.md"
Write-Test "Planner source exists" (Test-Path -LiteralPath $plannerSrc)
Write-Test "Implementer source exists" (Test-Path -LiteralPath $implSrc)

# === 10. MCP server package exists ===
Write-Host "`n--- 10. MCP server package ---" -ForegroundColor Yellow
$mcpInit = Join-Path $repoRoot ".trae\hermes\mcp\jinli_workflow\__init__.py"
$mcpServer = Join-Path $repoRoot ".trae\hermes\mcp\jinli_workflow\server.py"
Write-Test "MCP __init__.py exists" (Test-Path -LiteralPath $mcpInit)
Write-Test "MCP server.py exists" (Test-Path -LiteralPath $mcpServer)

# === 11. Guard plugin exists ===
Write-Host "`n--- 11. Guard plugin ---" -ForegroundColor Yellow
$guardPlugin = Join-Path $repoRoot ".trae\hermes\plugins\jinli-workflow-guard\plugin.yaml"
$guardInit = Join-Path $repoRoot ".trae\hermes\plugins\jinli-workflow-guard\__init__.py"
Write-Test "Guard plugin.yaml exists" (Test-Path -LiteralPath $guardPlugin)
Write-Test "Guard __init__.py exists" (Test-Path -LiteralPath $guardInit)

# === Final Summary ===
Write-Host "`n=== Results: $passedTests / $totalTests passed ===`n" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })

if ($failedTests -gt 0) { exit 1 } else { exit 0 }
