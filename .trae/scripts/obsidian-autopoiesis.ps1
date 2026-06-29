# obsidian-autopoiesis.ps1 - Master orchestrator for self-evolution pipeline
# Chains: dream -> metacognitive -> SPL -> execute -> verify -> commit
# PowerShell 5.1 compatible
# Safety: -Apply required for any real changes; dry-run by default

param(
    [string]$VaultPath = "E:\ObsidianVault",
    [string]$ProjectPath = "E:\UEGameDevelopment",
    [switch]$FullCycle,
    [switch]$DreamReflect,
    [switch]$Execute,
    [string]$ProposalId = "",
    [switch]$VerifyOnly,
    [switch]$SelfTest,
    [switch]$DryRun = $true,
    [switch]$Apply,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$scriptDir = "$PSScriptRoot"

if ($Help) {
    Write-Output "obsidian-autopoiesis.ps1 - Master self-evolution orchestrator"
    Write-Output ""
    Write-Output "Usage:"
    Write-Output "  -FullCycle -Apply       Run full pipeline: dream -> metacognitive -> SPL -> execute -> verify -> commit"
    Write-Output "  -DreamReflect -Apply    Run dream reflection + metacognitive only"
    Write-Output "  -Execute -ProposalId <id> -Apply  Execute a specific proposal"
    Write-Output "  -VerifyOnly -ProposalId <id> -Apply  Verify and commit an already-executed proposal"
    Write-Output "  -SelfTest               Internal self-test"
    Write-Output ""
    Write-Output "Safety: -Apply required for real changes. Default is dry-run."
    exit 0
}

# ============================================================
# Full self-evolution cycle
# ============================================================
function Invoke-FullEvolutionCycle {
    Write-Output "============================================"
    Write-Output "  Jinli Self-Evolution Cycle"
    Write-Output "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "  Mode: $(if ($Apply) { 'LIVE' } else { 'DRY-RUN' })"
    Write-Output "============================================"
    Write-Output ""
    
    $results = @{}
    
    # Phase 1: Dream Reflection
    Write-Output "--- Phase 1: Dream Reflection ---"
    $dreamScript = Join-Path $scriptDir "obsidian-dream-reflect.ps1"
    if (Test-Path $dreamScript) {
        try {
            & $dreamScript -FullScan 2>&1 | Out-Null
            $results['dream'] = $LASTEXITCODE
            Write-Output "  Result: exit=$LASTEXITCODE"
        } catch {
            $results['dream'] = 1
            Write-Output "  Result: ERROR"
        }
    } else {
        Write-Output "  [SKIP] Dream reflection script not found"
        $results['dream'] = -1
    }
    Write-Output ""
    
    # Phase 2: Metacognitive Assessment
    Write-Output "--- Phase 2: Metacognitive Assessment ---"
    $metaScript = Join-Path $scriptDir "obsidian-metacognitive.ps1"
    if (Test-Path $metaScript) {
        try {
            if ($Apply) { & $metaScript -FullMeta -Apply 2>&1 | Out-Null }
            else { & $metaScript -FullMeta 2>&1 | Out-Null }
            $results['meta'] = $LASTEXITCODE
            Write-Output "  Result: exit=$LASTEXITCODE"
        } catch {
            $results['meta'] = 1
            Write-Output "  Result: ERROR"
        }
    } else {
        Write-Output "  [SKIP] Metacognitive script not found"
        $results['meta'] = -1
    }
    Write-Output ""
    
    # Phase 3: SPL Cycle (Reflect -> Select -> Improve -> Evaluate -> Commit)
    Write-Output "--- Phase 3: SPL Evolution Cycle ---"
    $splScript = Join-Path $scriptDir "obsidian-spl-cycle.ps1"
    if (Test-Path $splScript) {
        try {
            if ($Apply) { & $splScript -FullCycle -Apply 2>&1 | Out-Null }
            else { & $splScript -FullCycle 2>&1 | Out-Null }
            $results['spl'] = $LASTEXITCODE
            Write-Output "  Result: exit=$LASTEXITCODE"
        } catch {
            $results['spl'] = 1
            Write-Output "  Result: ERROR"
        }
    } else {
        Write-Output "  [SKIP] SPL cycle script not found"
        $results['spl'] = -1
    }
    Write-Output ""
    
    # Phase 4: Execute latest committed proposal
    Write-Output "--- Phase 4: Execute Proposal ---"
    $execScript = Join-Path $scriptDir "obsidian-execute-evolution.ps1"
    $proposalsDir = Join-Path $VaultPath "进化\proposals"
    
    # Find the latest committed proposal
    $latestProposalId = ""
    $latestTime = [datetime]::MinValue
    $proposals = Get-ChildItem -Path $proposalsDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
    
    foreach ($p in $proposals) {
        $pc = [System.IO.File]::ReadAllText($p.FullName, [System.Text.Encoding]::UTF8)
        if ($pc -notmatch 'status:\s*committed') { continue }
        $proposalPId = if ($pc -match 'proposal_id:\s*"([^"]+)"') { $Matches[1] } else { "" }
        if ($proposalPId -eq "") { continue }
        if ($p.LastWriteTime -gt $latestTime) { $latestTime = $p.LastWriteTime; $latestProposalId = $proposalPId }
    }
    
    if ($latestProposalId -ne "" -and (Test-Path $execScript)) {
        Write-Output "  Found committed proposal: $latestProposalId"
        
        try {
            & $execScript -Execute -ProposalId $latestProposalId 2>&1 | Out-Null
            $results['execute'] = $LASTEXITCODE
            
            # Verify and commit if apply
            if ($Apply -and $LASTEXITCODE -eq 0) {
                & $execScript -VerifyAndCommit -ProposalId $latestProposalId -Apply 2>&1 | Out-Null
                $results['verify'] = $LASTEXITCODE
            } else {
                $results['verify'] = -1
            }
        } catch {
            $results['execute'] = 1
            $results['verify'] = -1
        }
    } else {
        if ($latestProposalId -eq "") {
            Write-Output "  [SKIP] No committed proposals found"
        }
        $results['execute'] = -1
        $results['verify'] = -1
    }
    Write-Output ""
    
    # Phase 5: Vault Maintenance
    Write-Output "--- Phase 5: Vault Maintenance ---"
    $maintainScript = Join-Path $scriptDir "obsidian-maintain.ps1"
    if (Test-Path $maintainScript) {
        try {
            if ($Apply) { & $maintainScript -Apply 2>&1 | Out-Null }
            else { & $maintainScript 2>&1 | Out-Null }
            $results['maintain'] = $LASTEXITCODE
            Write-Output "  Result: exit=$LASTEXITCODE"
        } catch {
            $results['maintain'] = 1
            Write-Output "  Result: ERROR"
        }
    } else {
        $results['maintain'] = -1
    }
    Write-Output ""
    
    # Summary
    Write-Output "============================================"
    Write-Output "  Evolution Cycle Summary"
    Write-Output "============================================"
    $phases = @('dream', 'meta', 'spl', 'execute', 'verify', 'maintain')
    foreach ($phase in $phases) {
        $code = if ($results.ContainsKey($phase)) { $results[$phase] } else { "?" }
        $status = if ($code -eq 0) { "PASS" } elseif ($code -eq -1) { "SKIP" } else { "FAIL" }
        Write-Output "  $phase : $status (exit=$code)"
    }
    Write-Output ""
    
    # Write cycle report
    $cycleReportDir = Join-Path $VaultPath "进化\results"
    if (-not (Test-Path $cycleReportDir)) { New-Item -Path $cycleReportDir -ItemType Directory -Force | Out-Null }
    $reportPath = Join-Path $cycleReportDir "cycle-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').md"
    $reportLines = @(
        "# Self-Evolution Cycle Report",
        "",
        "- Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')",
        "- Mode: $(if ($Apply) { 'LIVE' } else { 'DRY-RUN' })",
        ""
    )
    foreach ($phase in $phases) {
        $code = if ($results.ContainsKey($phase)) { $results[$phase] } else { "?" }
        $status = if ($code -eq 0) { "PASS" } elseif ($code -eq -1) { "SKIP" } else { "FAIL" }
        $reportLines += "- $phase : $status (exit=$code)"
    }
    [System.IO.File]::WriteAllText($reportPath, ($reportLines -join "`n"), [System.Text.Encoding]::UTF8)
    Write-Output "  Report: $reportPath"
    
    return $results
}

# ============================================================
# Self-test
# ============================================================
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-autopoiesis self-test..."
    
    $required = @(
        "obsidian-classify.ps1",
        "obsidian-dream-reflect.ps1",
        "obsidian-evolve.ps1",
        "obsidian-link-discover.ps1",
        "obsidian-maintain.ps1",
        "obsidian-spl-cycle.ps1",
        "obsidian-self-improve.ps1",
        "obsidian-metacognitive.ps1",
        "obsidian-execute-evolution.ps1"
    )
    
    $allFound = $true
    foreach ($r in $required) {
        $path = Join-Path $scriptDir $r
        if (Test-Path $path) { Write-Output "  [OK] $r" }
        else { Write-Output "  [MISSING] $r"; $allFound = $false }
    }
    if (-not $allFound) { Write-Output "[SELFTEST-FAIL] Some scripts missing"; exit 1 }
    
    Write-Output ""
    Write-Output "  Running individual self-tests..."
    $allPassed = $true
    foreach ($r in $required) {
        $path = Join-Path $scriptDir $r
        try {
            & $path -SelfTest 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Output "  [FAIL] $r self-test failed (exit=$LASTEXITCODE)"
                $allPassed = $false
            } else {
                Write-Output "  [PASS] $r self-test"
            }
        } catch {
            Write-Output "  [ERROR] $r : $_"
            $allPassed = $false
        }
    }
    
    if (-not $allPassed) { Write-Output "[SELFTEST-FAIL] Some self-tests failed"; exit 1 }
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# ============================================================
# Run
# ============================================================
if ($FullCycle) {
    Invoke-FullEvolutionCycle
    exit 0
}
elseif ($DreamReflect) {
    $dreamScript = Join-Path $scriptDir "obsidian-dream-reflect.ps1"
    $metaScript = Join-Path $scriptDir "obsidian-metacognitive.ps1"
    
    Write-Output "--- Dream Reflection ---"
    & $dreamScript -FullScan
    Write-Output ""
    Write-Output "--- Metacognitive Assessment ---"
    if ($Apply) { & $metaScript -FullMeta -Apply }
    else { & $metaScript -FullMeta }
    exit 0
}
elseif ($Execute -and $ProposalId -ne "") {
    $execScript = Join-Path $scriptDir "obsidian-execute-evolution.ps1"
    & $execScript -Execute -ProposalId $ProposalId
    if ($Apply) {
        & $execScript -VerifyAndCommit -ProposalId $ProposalId -Apply
    }
    exit 0
}
elseif ($VerifyOnly -and $ProposalId -ne "") {
    $execScript = Join-Path $scriptDir "obsidian-execute-evolution.ps1"
    & $execScript -VerifyAndCommit -ProposalId $ProposalId -Apply
    exit 0
}
else {
    Write-Output "Specify -FullCycle, -DreamReflect, -Execute -ProposalId <id>, -VerifyOnly -ProposalId <id>, or -SelfTest. Use -Help for details."
    exit 1
}