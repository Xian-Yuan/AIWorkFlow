param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"
$script:Passed = 0
$script:Failed = 0

function Test-Fact {
    param(
        [string]$Name,
        [scriptblock]$Check
    )
    try {
        if (& $Check) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:Passed++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $script:Failed++
        }
    } catch {
        Write-Host "  [FAIL] $Name - $($_.Exception.Message)" -ForegroundColor Red
        $script:Failed++
    }
}

$taskRoot = Join-Path $Root ".trae\tasks\_shared\2026-06-19-hermes-workflow-integration"
$yaml = Get-Content -LiteralPath (Join-Path $taskRoot ".task.yaml") -Raw -Encoding UTF8
$spec = Get-Content -LiteralPath (Join-Path $taskRoot "spec.md") -Raw -Encoding UTF8
$report = Get-Content -LiteralPath (Join-Path $taskRoot "verification-report.md") -Raw -Encoding UTF8
$ops = Get-Content -LiteralPath (Join-Path $Root "Docs\AI\39-Hermes-Workflow-Integration.md") -Raw -Encoding UTF8
$opencode = Get-Content -LiteralPath (Join-Path $Root "opencode.json") -Raw -Encoding UTF8
$taskDocs = (Get-ChildItem -LiteralPath $taskRoot -Recurse -File |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"

Write-Host "=== Hermes Archive Consistency ==="

Test-Fact "Task phase is archive" { $yaml -match '(?m)^phase:\s*archive\s*$' }
Test-Fact "Review result is pass" { $yaml -match '(?m)^review_result:\s*pass\s*$' }
Test-Fact "Verify result is pass" { $yaml -match '(?m)^verify_result:\s*pass\s*$' }
Test-Fact "Task is archived" { $yaml -match '(?m)^archived:\s*true\s*$' }
Test-Fact "Scenario count is 7" { $yaml -match '(?m)^spec_scenario_count:\s*7\s*$' }
Test-Fact "Scenario completion is 7" { $yaml -match '(?m)^spec_scenarios_done:\s*7\s*$' }

Test-Fact "Living Spec reports Archive" { $spec -match '\*\*Current Phase\*\*:\s*Archive' }
Test-Fact "Living Spec reports 13/13 verified" { $spec -match '\*\*Progress\*\*:\s*13/13 acceptance criteria verified' }
Test-Fact "All seven scenarios are verified" {
    ([regex]::Matches($spec, '\*\*Status\*\*:\s*\[x\]\s*verified')).Count -eq 7
}
Test-Fact "T7 is complete" { $spec -match '\|\s*T7\s*\|[^\r\n]*\|\s*\[x\]\s*Done\s*\|' }
Test-Fact "Living Spec has no pending Review/Verify state" {
    $spec -notmatch 'pending independent review|Review gate \| .*Pending|Verify gate \| .*Pending'
}

Test-Fact "Verification report has final archive addendum" {
    $report -match '## 2026-06-20 Final Archive Addendum'
}
Test-Fact "Verification report records 66/66" { $report -match '\b66/66\b' }
Test-Fact "Verification report records stdio 5/5" { $report -match 'stdio[^\r\n]*5/5' }
Test-Fact "Obsolete stdio residual risk removed" {
    $report -notmatch 'MCP stdio integration.*not as a running stdio subprocess'
}
Test-Fact "Final addendum does not claim pending state" {
    $final = ($report -split '## 2026-06-20 Final Archive Addendum', 2)[-1]
    $final -notmatch 'review_result:\s*pending|verify_result:\s*pending|不可归档'
}

Test-Fact "Operations doc reports Archived" { $ops -match '\*\*Status\*\*:\s*Active \(Archived\)' }
Test-Fact "Operations doc records 23/23 Python tests" { $ops -match 'pytest \.trae/hermes/tests -q`.*23/23' }
Test-Fact "Operations doc records 66/66 total" { $ops -match '\b66/66\b' }
Test-Fact "Old provider key is absent from config and task evidence" {
    $configHasInlineKey = $opencode -match '"apiKey"\s*:\s*"[^"]{8,}"'
    $evidenceHasUnredactedKey = $taskDocs -match '"apiKey"\s*:\s*"(?!<REDACTED|\$\{)[^"]{8,}"'
    -not $configHasInlineKey -and -not $evidenceHasUnredactedKey
}

Write-Host "`n=== Results: $($script:Passed) passed, $($script:Failed) failed ==="
if ($script:Failed -gt 0) { exit 1 }
exit 0
