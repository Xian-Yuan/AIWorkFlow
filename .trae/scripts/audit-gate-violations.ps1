param(
    [ValidateSet("check", "report")]
    [string]$Mode = "check"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskRoot = Join-Path $root ".trae\tasks"

$violations = @()
$warnings = @()

# Scan all task directories
$taskDirs = Get-ChildItem -LiteralPath $taskRoot -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName ".task.yaml") }

foreach ($dir in $taskDirs) {
    $yamlPath = Join-Path $dir.FullName ".task.yaml"
    $content = Get-Content $yamlPath -Raw

    $phase = if ($content -match 'phase:\s*(\S+)') { $matches[1] } else { "unknown" }
    $confirmed = ($content -match 'user_confirmed_plan:\s*true')
    $router = ($content -match 'router_skill_loaded:\s*true')
    $clarified = if ($content -match 'clarification_status:\s*(\S+)') { $matches[1] } else { "unknown" }
    $archived = ($content -match 'archived:\s*true')
    $taskName = $dir.FullName.Replace($taskRoot, "").TrimStart("\").Replace("\", "/")

    if ($archived) { continue }
    if ($taskName -match "^_shared/regression-") { continue }  # Skip regression test fixtures

    # Violation 1: implement phase but no plan confirmation
    if ($phase -eq "implement" -and -not $confirmed) {
        $violations += "V1: $taskName — phase=implement but user_confirmed_plan=false (Plan gate bypassed)"
    }

    # Violation 2: implement phase but router not loaded
    if ($phase -eq "implement" -and -not $router) {
        $violations += "V2: $taskName — phase=implement but router_skill_loaded=false (routing bypassed)"
    }

    # Violation 3: implement phase but clarification not resolved
    if ($phase -eq "implement" -and $clarified -eq "none") {
        $violations += "V3: $taskName — phase=implement but clarification_status=none (unresolved ambiguities)"
    }

    # Violation 4: verify phase but no verification report
    if ($phase -eq "verify") {
        $hasReport = $content -match 'verification_report:\s*\S+'
        $reportFile = Join-Path $dir.FullName "verification-report.md"
        $reportExists = Test-Path $reportFile
        if (-not $hasReport -and -not $reportExists) {
            $violations += "V4: $taskName — phase=verify but no verification_report reference and no verification-report.md file"
        }
    }

    # Warning: plan phase with unclear state
    if ($phase -eq "plan" -and $confirmed -and -not $router) {
        $warnings += "W1: $taskName — plan confirmed but router_skill not loaded (may be pre-router task)"
    }
}

Write-Host "=== Gate Violation Audit ==="
Write-Host "Total active tasks scanned: $(($taskDirs | Where-Object { Test-Path (Join-Path $_.FullName '.task.yaml') }).Count)"
Write-Host "Violations: $($violations.Count)"
Write-Host "Warnings: $($warnings.Count)"
Write-Host ""

if ($violations.Count -gt 0) {
    foreach ($v in $violations) {
        Write-Host "[VIOLATION] $v" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    foreach ($w in $warnings) {
        Write-Host "[WARNING] $w" -ForegroundColor Yellow
    }
}

if ($violations.Count -eq 0) {
    Write-Host "No gate violations detected." -ForegroundColor Green
}

if ($Mode -eq "report") {
    $reportPath = Join-Path $root ".trae\tasks\_shared\gate-violation-report.md"
    $lines = @(
        "# Gate Violation Report",
        "",
        "Date: $(Get-Date -Format 'yyyy-MM-dd')",
        "",
        "## Violations ($($violations.Count))",
        ""
    )
    foreach ($v in $violations) {
        $lines += "- $v"
    }
    $lines += @(
        "",
        "## Warnings ($($warnings.Count))",
        ""
    )
    foreach ($w in $warnings) {
        $lines += "- $w"
    }
    Set-Content -Path $reportPath -Value ($lines -join "`n")
    Write-Host "Report saved to: $reportPath"
}

exit $violations.Count
