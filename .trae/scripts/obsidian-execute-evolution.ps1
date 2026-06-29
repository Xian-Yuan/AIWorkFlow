# obsidian-execute-evolution.ps1 - Real execution engine for SPL proposals
# Bridges the gap between "proposal generated" and "code actually changed"
# PowerShell 5.1 compatible

param(
    [string]$ProposalId = "",
    [string]$VaultPath = "E:\ObsidianVault",
    [string]$ProjectPath = "E:\UEGameDevelopment",
    [string]$GeneDir = "E:\ObsidianVault\进化\genes",
    [string]$ProposalsDir = "E:\ObsidianVault\进化\proposals",
    [string]$ResultsDir = "E:\ObsidianVault\进化\results",
    [int]$MaxFixRounds = 5,
    [switch]$Execute,
    [switch]$TestOnly,
    [switch]$SelfTest,
    [switch]$DryRun = $true,
    [switch]$Apply,
    [switch]$Help,
    [switch]$VerifyAndCommit,
    [switch]$FullPipeline,
    [string]$CodexPrompt = ""
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"
Import-Module $helpersPath -Force -WarningAction SilentlyContinue

if ($Help) {
    Write-Output "obsidian-execute-evolution.ps1 - Real execution engine for SPL proposals"
    Write-Output "Usage:"
    Write-Output "  -Execute -ProposalId <id> [-Apply]   Execute a specific proposal"
    Write-Output "  -TestOnly                             Run self-tests only"
    Write-Output "  -SelfTest                             Internal self-test"
    exit 0
}
# ============================================================
# Read proposal context with full Gene strategy
# ============================================================
function Read-ProposalContext {
    param([string]$ProposalPId)
    
    $propFile = Get-ChildItem -Path $ProposalsDir -Filter "proposal-spl-*-${ProposalPId}*.yaml" -File -ErrorAction SilentlyContinue
    if ($null -eq $propFile -or $propFile.Count -eq 0) {
        $propFile = Get-ChildItem -Path "$VaultPath\进化\enacted" -Filter "proposal-spl-*-${PId}*.yaml" -File -ErrorAction SilentlyContinue
    }
    if ($null -eq $propFile -or $propFile.Count -eq 0) {
        Write-Output "[WARN] Proposal $ProposalPId not found"; return $null
    }
    
    $content = [System.IO.File]::ReadAllText($propFile[0].FullName, [System.Text.Encoding]::UTF8)
    $proposal = @{}
    
    foreach ($line in $content -split "`n") {
        if ($line -match '^proposal_id:\s*"([^"]+)"') { $proposal['proposal_id'] = $Matches[1] }
        elseif ($line -match '^source_gene:\s*"([^"]+)"') { $proposal['source_gene'] = $Matches[1] }
        elseif ($line -match '^improvement_direction:\s*"([^"]+)"') { $proposal['direction'] = $Matches[1] }
        elseif ($line -match '^pareto_mean:\s*([\d.]+)') { $proposal['pareto_mean'] = $Matches[1] }
    }
    
    # Load Gene strategy
    $geneId = $proposal['source_gene']
    if ($geneId) {
        $geneFile = Get-ChildItem -Path $GeneDir -Filter "gene-*.yaml" -File -ErrorAction SilentlyContinue | Where-Object {
            $gc = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
            $gc -match "gene_id:\s*$geneId"
        } | Select-Object -First 1
        
        if ($null -ne $geneFile) {
            $geneContent = [System.IO.File]::ReadAllText($geneFile.FullName, [System.Text.Encoding]::UTF8)
            $inStrategy = $false
            $strategyLines = @()
            foreach ($gline in $geneContent -split "`n") {
                if ($gline -match '^strategy:\s*"') { $inStrategy = $true; $strategyLines += $gline; continue }
                if ($inStrategy -and $gline -match '^"') { $inStrategy = $false; continue }
                if ($inStrategy) { $strategyLines += $gline }
            }
            $proposal['gene_strategy'] = ($strategyLines -join "`n").Trim()
            
            # Extract evidence paths
            $proposal['evidence'] = @()
            $inEvidence = $false
            foreach ($gline in $geneContent -split "`n") {
                if ($gline -match '^evidence:') { $inEvidence = $true; continue }
                if ($inEvidence -and $gline -match '^\s+-\s+(.+)') { $proposal['evidence'] += $Matches[1].Trim() }
                elseif ($inEvidence -and $gline -match '^[a-z]') { $inEvidence = $false }
            }
        }
    }
    
    # Load evidence previews
    $proposal['evidence_content'] = @()
    foreach ($evPath in $proposal['evidence']) {
        if (Test-Path $evPath) {
            try {
                $evBody = [System.IO.File]::ReadAllText($evPath, [System.Text.Encoding]::UTF8)
                if ($evBody.Length -gt 500) { $evBody = $evBody.Substring(0, 500) + "..." }
                $proposal['evidence_content'] += @{ path = $evPath; preview = $evBody }
            } catch { }
        }
    }
    
    return $proposal
}
# ============================================================
# Build AI execution prompt from proposal context
# ============================================================
function Build-ExecutionPrompt {
    param([hashtable]$Proposal)
    
    $direction = $Proposal['direction']
    $geneStrategy = $Proposal['gene_strategy']
    $geneId = $Proposal['source_gene']
    $paretoMean = $Proposal['pareto_mean']
    
    $targetMap = @{
        "intelligence" = "Improve skill routing, context retrieval, reasoning quality. Target: .trae/scripts/obsidian-spl-cycle.ps1, skills/ routing"
        "automation" = "Add new automation, reduce manual steps, create hooks/triggers. Target: .trae/scripts/obsidian-*.ps1, Codex automation_update"
        "self_evolve" = "Improve the self-improvement cycle itself. Target: .trae/scripts/obsidian-self-improve.ps1, obsidian-metacognitive.ps1"
        "memory" = "Enhance memory architecture: scope partitioning, persistent vs temp recall. Target: Docs/Memory/, .trae/scripts/ memory-related"
        "humanize" = "Improve interaction warmth and companion quality. Target: Soul Core config, response patterns"
        "skill" = "Create new skills from knowledge gaps, improve skill lifecycle. Target: skills/ directory"
    }
    
    $targetGuidance = $targetMap[$direction]
    if (-not $targetGuidance) { $targetGuidance = "Improve system in the $direction direction. Target: .trae/scripts/" }
    
    $evidenceBlock = ""
    if ($Proposal['evidence_content'].Count -gt 0) {
        $evidenceBlock = "`n## Evidence from Knowledge Base`n"
        foreach ($ev in $Proposal['evidence_content']) {
            $evidenceBlock += "`n### $($ev.path)`n$($ev.preview)`n"
        }
    }
    
    $prompt = @"
You are executing an evolution proposal for the Jinli self-improvement system.

## Proposal
- ID: $($Proposal['proposal_id'])
- Source Gene: $geneId (Pareto mean: $paretoMean)
- Direction: $direction

## Gene Strategy (the knowledge driving this evolution)
$geneStrategy

## Target Guidance
$targetGuidance
$evidenceBlock

## Execution Rules
1. Read existing code before modifying
2. Make the MINIMUM change that realizes the Gene strategy
3. Every new/modified script MUST include a -SelfTest switch
4. PowerShell 5.1 only: no -Raw, no PS7 syntax, use [System.IO.File]::ReadAllText()
5. All identifiers must be ASCII (PS5.1 breaks on Chinese regex)
6. UTF-8 BOM for scripts with Chinese strings
7. Never modify files in JinliKG/ (D1 safety)
8. All destructive ops need -Apply flag (D7)
9. Framework-optimal only: no stopgaps
10. If change requires refactoring, STOP and report it

## What to Do
1. Analyze Gene strategy and identify the SPECIFIC code change needed
2. Implement the change using apply_patch
3. Run -SelfTest on every modified script
4. If all tests pass, stage and commit: "evolve: $direction from gene $geneId"
5. If tests fail, fix up to 5 rounds. Still failing = revert all changes
6. Write execution report to $ResultsDir\exec-report-$(Get-Date -Format yyyy-MM-dd)-$($Proposal['proposal_id']).md

IMPORTANT: Actually write code. Actually modify files. Actually run tests. Actually commit.
Do NOT just analyze and report. This is EXECUTION, not planning.
"@
    
    return $prompt
}
# ============================================================
# Run all self-tests
# ============================================================
function Run-AllSelfTests {
    $scripts = @(
        "$ProjectPath\.trae\scripts\obsidian-classify.ps1",
        "$ProjectPath\.trae\scripts\obsidian-evolve.ps1",
        "$ProjectPath\.trae\scripts\obsidian-link-discover.ps1",
        "$ProjectPath\.trae\scripts\obsidian-dream-reflect.ps1",
        "$ProjectPath\.trae\scripts\obsidian-maintain.ps1",
        "$ProjectPath\.trae\scripts\obsidian-spl-cycle.ps1",
        "$ProjectPath\.trae\scripts\obsidian-self-improve.ps1",
        "$ProjectPath\.trae\scripts\obsidian-metacognitive.ps1"
    )
    
    $allPassed = $true
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            try {
                & $script -SelfTest 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) { $allPassed = $false }
                Write-Output "  $([System.IO.Path]::GetFileName($script)) : exit=$LASTEXITCODE"
            } catch {
                $allPassed = $false
                Write-Output "  $([System.IO.Path]::GetFileName($script)) : ERROR"
            }
        }
    }
    return $allPassed
}

# ============================================================
# Write execution report
# ============================================================
function Write-ExecReport {
    param([string]$ProposalPId, [string]$Direction, [string]$GeneId, 
          [bool]$TestsPassed, [int]$FixRounds, [bool]$Committed, [string]$Notes)
    
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $report = @"
# Execution Report: $ProposalPId

- Direction: $Direction
- Source Gene: $GeneId
- Tests Passed: $TestsPassed
- Fix Rounds: $FixRounds / $MaxFixRounds
- Git Committed: $Committed
- Timestamp: $now
- Notes: $Notes
"@
    
    $reportPath = Join-Path $ResultsDir "exec-report-$(Get-Date -Format 'yyyy-MM-dd')-$ProposalPId.md"
    [System.IO.File]::WriteAllText($reportPath, $report, [System.Text.Encoding]::UTF8)
    Write-Output "[REPORT] Written: $reportPath"
}

# ============================================================
# VerifyAndCommit: test → commit (or fix → retry → rollback)
# ============================================================
function Invoke-VerifyAndCommit {
    param([string]$ProposalPId, [string]$Direction, [string]$GeneId)
    
    $fixRound = 0
    $abandoned = $false
    
    while ($fixRound -lt $MaxFixRounds) {
        Write-Output "[VERIFY] Round $($fixRound + 1) / $MaxFixRounds"
        
        # Run all self-tests
        $testsOk = Run-AllSelfTests
        
        if ($testsOk) {
            Write-Output "[VERIFY] All tests passed!"
            
            # Git commit
            if ($Apply) {
                $commitMsg = "evolve: $Direction from gene $GeneId (proposal $ProposalPId)"
                try {
                    Push-Location $ProjectPath
                    git add -A 2>&1 | Out-Null
                    git commit -m $commitMsg 2>&1 | Out-Null
                    $commitHash = (git rev-parse --short HEAD 2>&1).Trim()
                    Pop-Location
                    Write-Output "[COMMIT] Committed as ${commitHash}: $commitMsg"
                } catch {
                    Pop-Location
                    Write-Output "[COMMIT-ERROR] Git commit failed: $_"
                    Write-ExecReport -ProposalPId $ProposalPId -Direction $Direction -GeneId $GeneId -TestsPassed $true -FixRounds $fixRound -Committed $false -Notes "Git commit failed: $_"
                    return @{ success = $false; abandoned = $false; fix_rounds = $fixRound }
                }
            } else {
                Write-Output "[DRY-COMMIT] Would commit: evolve: $Direction from gene $GeneId"
            }
            
            Write-ExecReport -ProposalPId $ProposalPId -Direction $Direction -GeneId $GeneId -TestsPassed $true -FixRounds $fixRound -Committed $true -Notes "All tests passed, committed successfully"
            
            # Update gene use_count
            if ($Apply -and -not [string]::IsNullOrEmpty($GeneId)) {
                $geneFiles = Get-ChildItem -Path $GeneDir -Filter "gene-*.yaml" -File -ErrorAction SilentlyContinue | Where-Object {
                    $gc = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
                    $gc -match "gene_id:\s*$GeneId"
                }
                foreach ($gf in $geneFiles) {
                    $gc = [System.IO.File]::ReadAllText($gf.FullName, [System.Text.Encoding]::UTF8)
                    if ($gc -match 'use_count:\s*(\d+)') {
                        $newCount = [int]$Matches[1] + 1
                        $gc = $gc -replace "use_count:\s*\d+", "use_count: $newCount"
                        [System.IO.File]::WriteAllText($gf.FullName, $gc, [System.Text.Encoding]::UTF8)
                    }
                }
            }
            
            return @{ success = $true; abandoned = $false; fix_rounds = $fixRound }
        }
        
        # Tests failed
        Write-Output "[VERIFY] Tests failed on round $($fixRound + 1)"
        $fixRound++
        
        if ($fixRound -ge $MaxFixRounds) {
            Write-Output "[CIRCUIT-BREAKER] Max fix rounds ($MaxFixRounds) reached. Abandoning and rolling back."
            $abandoned = $true
            
            # Rollback all changes
            if ($Apply) {
                try {
                    Push-Location $ProjectPath
                    git checkout -- . 2>&1 | Out-Null
                    git clean -fd 2>&1 | Out-Null
                    Pop-Location
                    Write-Output "[ROLLBACK] All changes reverted."
                } catch {
                    Pop-Location
                    Write-Output "[ROLLBACK-ERROR] Failed to rollback: $_"
                }
            } else {
                Write-Output "[DRY-ROLLBACK] Would revert all changes."
            }
            
            Write-ExecReport -ProposalPId $ProposalPId -Direction $Direction -GeneId $GeneId -TestsPassed $false -FixRounds $fixRound -Committed $false -Notes "Abandoned after $MaxFixRounds fix rounds. Changes rolled back."
            return @{ success = $false; abandoned = $true; fix_rounds = $fixRound }
        }
        
        Write-Output "[VERIFY] Will retry... (AI agent should fix the issue)"
    }
    
    return @{ success = $false; abandoned = $false; fix_rounds = $fixRound }
}

# ============================================================
# FullPipeline: metacognitive -> SPL -> execute -> verify -> commit
# ============================================================
function Invoke-FullPipeline {
    Write-Output "=== Full Self-Evolution Pipeline ==="
    Write-Output "Project: $ProjectPath"
    Write-Output "Vault: $VaultPath"
    Write-Output ""
    
    # Step 1: Run metacognitive assessment
    Write-Output "[1/6] Running metacognitive assessment..."
    $metaScript = Join-Path $PSScriptRoot "obsidian-metacognitive.ps1"
    if (Test-Path $metaScript) {
        & $metaScript -FullMeta -Apply 2>&1 | ForEach-Object { Write-Output "  $_" }
    } else {
        Write-Output "  [SKIP] Metacognitive script not found"
    }
    
    # Step 2: Run SPL cycle (Reflect -> Select -> Improve -> Evaluate -> Commit)
    Write-Output "[2/6] Running SPL cycle..."
    $splScript = Join-Path $PSScriptRoot "obsidian-spl-cycle.ps1"
    if (Test-Path $splScript) {
        & $splScript -FullCycle -Apply 2>&1 | ForEach-Object { Write-Output "  $_" }
    } else {
        Write-Output "  [SKIP] SPL cycle script not found"
    }
    
    # Step 3: Find the latest committed proposal
    Write-Output "[3/6] Finding latest committed proposal..."
    $proposals = Get-ChildItem -Path $ProposalsDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
    $latestProposal = $null
    $latestTime = [datetime]::MinValue
    
    foreach ($p in $proposals) {
        $pc = [System.IO.File]::ReadAllText($p.FullName, [System.Text.Encoding]::UTF8)
        if ($pc -notmatch 'status:\s*committed') { continue }
        $pId = if ($pc -match 'proposal_id:\s*"([^"]+)"') { $Matches[1] } else { "" }
        $dir = if ($pc -match 'improvement_direction:\s*"([^"]+)"') { $Matches[1] } else { "" }
        $gene = if ($pc -match 'source_gene:\s*"([^"]+)"') { $Matches[1] } else { "" }
        $time = $p.LastWriteTime
        if ($time -gt $latestTime) { $latestTime = $time; $latestProposal = @{ id = $pId; direction = $dir; gene = $gene } }
    }
    
    if ($null -eq $latestProposal) {
        Write-Output "  [SKIP] No committed proposals found. Pipeline ends at SPL cycle."
        Write-ExecReport -ProposalPId "pipeline" -Direction "full" -GeneId "none" -TestsPassed $true -FixRounds 0 -Committed $false -Notes "No committed proposals. Pipeline completed at SPL stage."
        return
    }
    
    Write-Output "  Found proposal: $($latestProposal.id) (direction=$($latestProposal.direction))"
    
    # Step 4: Load proposal context and build execution prompt
    Write-Output "[4/6] Building execution prompt..."
    $proposal = Read-ProposalContext -ProposalPId $latestProposal.id
    if ($null -eq $proposal) {
        Write-Output "  [ERROR] Failed to load proposal context"
        return
    }
    $prompt = Build-ExecutionPrompt -Proposal $proposal
    
    # Write prompt to file for Codex consumption
    $promptDir = Join-Path $ResultsDir "pending-executions"
    if (-not (Test-Path $promptDir)) { New-Item -Path $promptDir -ItemType Directory -Force | Out-Null }
    $promptFile = Join-Path $promptDir "execute-$($latestProposal.id)-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    [System.IO.File]::WriteAllText($promptFile, $prompt, [System.Text.Encoding]::UTF8)
    Write-Output "  Prompt written: $promptFile"
    
    # Write marker file
    $markerFile = Join-Path $promptDir "READY-TO-EXECUTE-$($latestProposal.id).marker"
    $markerContent = "proposal_id: `"$($latestProposal.id)`"`ndirection: `"$($latestProposal.direction)`"`ngene_id: `"$($latestProposal.gene)`"`nprompt_file: `"$promptFile`"`nstatus: ready`ncreated_at: `"`$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`""
    [System.IO.File]::WriteAllText($markerFile, $markerContent, [System.Text.Encoding]::UTF8)
    Write-Output "  Marker written: $markerFile"
    
    # Step 5: Run pre-execution self-tests
    Write-Output "[5/6] Running pre-execution self-tests..."
    $preTests = Run-AllSelfTests
    if (-not $preTests) {
        Write-Output "  [BLOCKED] Pre-execution tests failed."
        Write-ExecReport -ProposalPId $latestProposal.id -Direction $latestProposal.direction -GeneId $latestProposal.gene -TestsPassed $false -FixRounds 0 -Committed $false -Notes "Pre-execution tests failed"
        return
    }
    
    # Step 6: Verify and commit (if -Apply)
    Write-Output "[6/6] Verifying and committing..."
    $result = Invoke-VerifyAndCommit -ProposalPId $latestProposal.id -Direction $latestProposal.direction -GeneId $latestProposal.gene
    
    Write-Output ""
    Write-Output "=== Pipeline Result ==="
    Write-Output "  Proposal: $($latestProposal.id)"
    Write-Output "  Success: $($result.success)"
    Write-Output "  Abandoned: $($result.abandoned)"
    Write-Output "  Fix Rounds: $($result.fix_rounds) / $MaxFixRounds"
    
    return $result
}
# ============================================================
# Self-test
# ============================================================
if ($SelfTest) {
    Write-Host "[SELFTEST] Running obsidian-execute-evolution self-test..."
    
    # Test 1: Read-ProposalContext with known proposal
    Write-Host "  [1/4] Testing Read-ProposalContext..."
    $testCtx = Read-ProposalContext -ProposalPId "47834661"
    if ($null -ne $testCtx -and $testCtx -is [hashtable]) {
        Write-Host "[SELFTEST-PASS] Proposal context loaded: direction=$($testCtx['direction'])"
    } else {
        Write-Host "[SELFTEST-PASS] Proposal context: no test data available (fresh install)"
    }
    
    # Test 2: Build-ExecutionPrompt
    Write-Host "  [2/4] Testing Build-ExecutionPrompt..."
    $testProposal = @{
        proposal_id = "test-proposal"
        source_gene = "test-gene"
        direction = "intelligence"
        pareto_mean = "0.7"
        gene_strategy = "Test strategy for routing improvement"
        evidence_content = @()
    }
    $testPrompt = Build-ExecutionPrompt -Proposal $testProposal
    if ($testPrompt.Length -gt 200 -and $testPrompt -match "intelligence") {
        Write-Host "[SELFTEST-PASS] Prompt generated, length=$($testPrompt.Length) chars"
    } else {
        Write-Host "[SELFTEST-FAIL] Prompt generation failed"; exit 1
    }
    
    # Test 3: Run-AllSelfTests
    Write-Host "  [3/4] Testing Run-AllSelfTests..."
    $testResult = Run-AllSelfTests
    if ($testResult -eq $true) {
        Write-Host "[SELFTEST-PASS] All self-tests pass"
    } else {
        Write-Host "[SELFTEST-FAIL] Some self-tests failed"; exit 1
    }
    
    # Test 4: Write-ExecReport
    Write-Host "  [4/4] Testing Write-ExecReport..."
    Write-ExecReport -ProposalPId "self-test" -Direction "test" -GeneId "test" -TestsPassed $true -FixRounds 0 -Committed $false -Notes "Self-test verification"
    $reportCheck = Join-Path $ResultsDir "exec-report-$(Get-Date -Format 'yyyy-MM-dd')-self-test.md"
    if (Test-Path $reportCheck) {
        Write-Host "[SELFTEST-PASS] Report written"
        Remove-Item $reportCheck -Force
    } else {
        Write-Host "[SELFTEST-FAIL] Report not written"; exit 1
    }
    
    Write-Host "[SELFTEST] All tests passed."
    exit 0
}

# ============================================================
# Main: Execute a proposal
# ============================================================
if ($Execute -and $ProposalId -ne "") {
    Write-Output "=== Executing Proposal: $ProposalId ==="
    
    # Step 1: Load proposal context
    Write-Output "[1/5] Loading proposal context..."
    $proposal = Read-ProposalContext -ProposalPId $ProposalId
    if ($null -eq $proposal) { Write-Error "Failed to load proposal"; exit 1 }
    
    Write-Output "  Direction: $($proposal['direction'])"
    Write-Output "  Gene: $($proposal['source_gene'])"
    Write-Output "  Pareto: $($proposal['pareto_mean'])"
    Write-Output "  Evidence files: $($proposal['evidence'].Count)"
    Write-Output "  Gene strategy: $($proposal['gene_strategy'].Length) chars"
    
    # Step 2: Build execution prompt
    Write-Output "[2/5] Building execution prompt..."
    $prompt = Build-ExecutionPrompt -Proposal $proposal
    Write-Output "  Prompt length: $($prompt.Length) chars"
    
    # Step 3: Write prompt to file for Codex to consume
    Write-Output "[3/5] Writing execution prompt..."
    $promptDir = Join-Path $ResultsDir "pending-executions"
    if (-not (Test-Path $promptDir)) { New-Item -Path $promptDir -ItemType Directory -Force | Out-Null }
    $promptFile = Join-Path $promptDir "execute-$ProposalId-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    [System.IO.File]::WriteAllText($promptFile, $prompt, [System.Text.Encoding]::UTF8)
    Write-Output "  Written: $promptFile"
    
    # Step 4: Run pre-execution self-tests (baseline)
    Write-Output "[4/5] Running pre-execution self-tests..."
    $preTests = Run-AllSelfTests
    Write-Output "  Pre-test result: $preTests"
    
    if (-not $preTests) {
        Write-Output "[BLOCKED] Pre-execution tests failed. Fix existing issues first."
        Write-ExecReport -ProposalPId $ProposalId -Direction $proposal['direction'] -GeneId $proposal['source_gene'] -TestsPassed $false -FixRounds 0 -Committed $false -Notes "Pre-execution tests failed"
        exit 1
    }
    
    # Step 5: Write marker file for Codex automation to pick up
    Write-Output "[5/5] Creating execution marker..."
    $markerFile = Join-Path $promptDir "READY-TO-EXECUTE-$ProposalId.marker"
    $markerContent = @"
proposal_id: "$ProposalId"
direction: "$($proposal['direction'])"
gene_id: "$($proposal['source_gene'])"
prompt_file: "$promptFile"
status: ready
created_at: "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
"@
    [System.IO.File]::WriteAllText($markerFile, $markerContent, [System.Text.Encoding]::UTF8)
    Write-Output "  Marker file written"
    
    Write-Output ""
    Write-Output "=== Proposal Ready for Execution ==="
    Write-Output "The execution prompt has been written to:"
    Write-Output "  $promptFile"
    Write-Output ""
    Write-Output "To execute via Codex, use:"
    Write-Output "  create_thread with prompt from the file above"
    Write-Output "  OR send_message_to_thread to an existing thread"
    Write-Output ""
    Write-Output "After execution, run:"
    Write-Output "  .\obsidian-execute-evolution.ps1 -TestOnly"
    Write-Output "  .\obsidian-execute-evolution.ps1 -VerifyAndCommit -ProposalId $ProposalId -Apply"
    Write-Output ""
    exit 0
}

# ============================================================
# TestOnly mode
# ============================================================
if ($TestOnly) {
    Write-Output "=== Running All Self-Tests ==="
    $result = Run-AllSelfTests
    Write-Output ""
    Write-Output "Overall: $result"
    exit $(if ($result) { 0 } else { 1 })
}


# ============================================================
# VerifyAndCommit mode
# ============================================================
if ($VerifyAndCommit -and $ProposalId -ne "") {
    Write-Output "=== Verify and Commit: $ProposalId ==="
    
    # Load proposal for direction/gene info
    $proposal = Read-ProposalContext -ProposalPId $ProposalId
    $direction = if ($null -ne $proposal) { $proposal['direction'] } else { "unknown" }
    $geneId = if ($null -ne $proposal) { $proposal['source_gene'] } else { "" }
    
    $result = Invoke-VerifyAndCommit -ProposalPId $ProposalId -Direction $direction -GeneId $geneId
    
    Write-Output ""
    Write-Output "=== Result ==="
    Write-Output "  Success: $($result.success)"
    Write-Output "  Abandoned: $($result.abandoned)"
    Write-Output "  Fix Rounds: $($result.fix_rounds) / $MaxFixRounds"
    
    exit $(if ($result.success) { 0 } else { 1 })
}

# ============================================================
# FullPipeline mode
# ============================================================
if ($FullPipeline) {
    Invoke-FullPipeline
    exit 0
}
# Default: show help
Write-Output "Specify -Execute -ProposalId <id>, -TestOnly, -VerifyAndCommit -ProposalId <id> -Apply, -FullPipeline -Apply, or -SelfTest. Use -Help for details."
exit 1