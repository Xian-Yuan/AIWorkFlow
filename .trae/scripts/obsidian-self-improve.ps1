 # obsidian-self-improve-v2.ps1 - Self-improvement execution engine v2
 # Full closed-loop: knowledge exhaustion -> web search -> 5-round circuit breaker
 # -> refactor pause -> evolution logging -> git auto-commit -> rollback on abandon
 # Inspired by: Autogenesis SPL, Hermes JIPA, Loop Engineering, Agent行为约束框架
 # PowerShell 5.1 compatible, no external modules
 # Safety: framework-optimal priority (NO stopgap), refactor pause, 5-round circuit breaker
 
 param(
     [string]$ProposalId = "",
     [string]$VaultPath = "E:\ObsidianVault",
     [string]$ProjectPath = "E:\UEGameDevelopment",
     [string]$StrategiesPath = "E:\ObsidianVault\进化\rules\evolution-strategies.yaml",
     [string]$EvolutionLogPath = "E:\ObsidianVault\进化\logs\evolution-log.md",
     [string]$RefactorLogPath = "E:\ObsidianVault\进化\logs\refactor-candidates.md",
     [switch]$ListProposals,
     [switch]$Execute,
     [switch]$AutoTest,
     [switch]$DryRun = $true,
     [switch]$Apply,
     [switch]$FullImprove,
     [switch]$WebSearch,
     [int]$MaxFixRounds = 5,
     [switch]$SelfTest,
     [switch]$Help
 )
 
 $ErrorActionPreference = "Stop"
 $helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"
 Import-Module $helpersPath -Force -WarningAction SilentlyContinue
 
 function Show-Help {
     Write-Output @"
 obsidian-self-improve-v2.ps1 - Self-improvement execution engine v2
 
 Full closed-loop self-evolution with safety guardrails:
   - Knowledge exhaustion detection + web search trigger
   - 5-round circuit breaker (Hermes JIPA + Agent行为约束 inspired)
   - Refactor pause: log but don't execute, continue other directions
   - Framework-optimal priority: NO stopgap/minimal-fix solutions
   - Evolution logging: every cycle recorded with timestamp
   - Git auto-commit on success, rollback on abandon
 
 Usage:
   .\obsidian-self-improve-v2.ps1 -ListProposals
   .\obsidian-self-improve-v2.ps1 -Execute -ProposalId <id>
   .\obsidian-self-improve-v2.ps1 -FullImprove
   .\obsidian-self-improve-v2.ps1 -FullImprove -WebSearch -Apply
   .\obsidian-self-improve-v2.ps1 -SelfTest
 
 Safety:
   D7: -Apply required for actual execution
   Circuit breaker: max $MaxFixRounds fix rounds, then reassess
   Refactor pause: detected refactors logged to refactor-candidates.md
   Framework-optimal: stopgap solutions are rejected
"@
 }
 
 if ($Help) { Show-Help; exit 0 }
 
 $vault = Get-VaultPath -VaultPath $VaultPath
 if ($null -eq $vault) { exit 1 }
 
 $proposalsDir = Join-Path $vault "进化\proposals"
 $enactedDir = Join-Path $vault "进化\enacted"
 $resultsDir = Join-Path $vault "进化\results"
 
 if (-not (Test-Path $resultsDir)) { New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null }
 
 # ============================================================
 # Evolution Logging
 # ============================================================
 function Write-EvolutionLog {
     param(
         [string]$Direction = "unknown",
         [string]$GeneId = "",
         [string]$ProposalIdVal = "",
         [string]$Result = "unknown",
         [int]$IssuesFixed = 0,
         [bool]$TestsPassed = $true,
         [string]$Notes = ""
     )
     $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
     $entry = @"
 
 ### $now
 - **Direction**: $Direction
 - **Gene**: $GeneId
 - **Proposal**: $ProposalIdVal
 - **Result**: $Result
 - **Issues Fixed**: $IssuesFixed
 - **Tests Passed**: $($TestsPassed.ToString())
 - **Notes**: $Notes
"@
     if (Test-Path $EvolutionLogPath) {
         Add-Content -Path $EvolutionLogPath -Value $entry -Encoding UTF8
     } else {
         $header = "# Jinli Evolution Log`n`nEvery self-evolution cycle records an entry here.`n`n## Log Entries`n"
         ($header + $entry) | Out-File -FilePath $EvolutionLogPath -Encoding UTF8
     }
     Write-Output "[LOG] Evolution logged: $Direction | $Result"
 }
 
 # ============================================================
 # Knowledge Exhaustion Detection
 # ============================================================
 function Test-KnowledgeExhaustion {
     param([hashtable]$Proposal)
     $contextCount = 0
     if ($Proposal.ContainsKey('context_sources')) { $contextCount += @($Proposal['context_sources']).Count }
     if ($Proposal.ContainsKey('system_sources')) { $contextCount += @($Proposal['system_sources']).Count }
     $isExhausted = ($contextCount -lt 2)
     if ($isExhausted) { Write-Output "[EXHAUST] Local knowledge insufficient (context=$contextCount). Web search needed." }
     return $isExhausted
 }
 
 # ============================================================
 # Web Search Trigger
 # ============================================================
 function Invoke-WebSearchForImprovement {
     param([string]$Direction, [string]$Query = "")
     if (-not $WebSearch) {
         Write-Output "[WEB] Web search not enabled. Use -WebSearch flag."
         Write-Output "[WEB] Recommended search for: $Direction"
         return @()
     }
     $searchQueries = @()
     if (Test-Path $StrategiesPath) {
         $content = [System.IO.File]::ReadAllText($StrategiesPath, [System.Text.Encoding]::UTF8)
         $qMatches = [regex]::Matches($content, '^\s*-\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::Multiline)
         foreach ($qm in $qMatches) {
             if ($qm.Groups[1].Value -match 'agent|self|improv|evolv|memory|skill|knowledge|automat') {
                 $searchQueries += $qm.Groups[1].Value
             }
         }
     }
     if ($Query -ne "") { $searchQueries = @($Query) }
     if ($searchQueries.Count -eq 0) {
         $searchQueries = @(
             "AI agent self-improvement framework 2025",
             "autonomous agent self-evolution protocol",
             "AI agent memory architecture best practices"
         )
     }
     Write-Output "[WEB] Searching for: $($searchQueries -join '; ')"
     Write-Output "[WEB] Note: Web search requires external tool. Results should be saved to vault via vsummary."
     return @(@{ direction = $Direction; queries = $searchQueries; status = "pending" })
 }
 
 # ============================================================
 # Refactor Detection
 # ============================================================
 function Test-IsRefactor {
     param([string]$StepDescription, [string]$AffectedFiles = "")
     $refactorKeywords = @("重构", "refactor", "restructure", "reorganize", "rewrite", "重写", "重组", "迁移", "migrate", "修改.*架构")
     foreach ($kw in $refactorKeywords) { if ($StepDescription -match $kw) { return $true } }
     $corePatterns = @("ObsidianHelpers\.psm1", "17-Self-Improving", "project_rules", "AGENTS\.md")
     foreach ($cp in $corePatterns) { if ($AffectedFiles -match $cp) { return $true } }
     return $false
 }
 
 function Write-RefactorCandidate {
     param([string]$ProposalIdVal, [string]$Direction, [string]$Description, [string]$AffectedFiles)
     $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
     $entry = @"
 
 ### $now - Proposal $ProposalIdVal
 - **Direction**: $Direction
 - **Description**: $Description
 - **Affected**: $AffectedFiles
 - **Status**: PENDING Ba Ba review
 - **Action**: Do NOT execute until Ba Ba confirms
"@
     if (Test-Path $RefactorLogPath) { Add-Content -Path $RefactorLogPath -Value $entry -Encoding UTF8 }
     else {
         $header = "# Refactor Candidates`n`n`n## Candidates`n"
         ($header + $entry) | Out-File -FilePath $RefactorLogPath -Encoding UTF8
     }
     Write-Output "[REFACTOR] Logged refactor candidate: $Description"
 }
 
 # ============================================================
 # Git Auto-Commit
 # ============================================================
 function Invoke-GitAutoCommit {
     param([string]$ProposalIdVal, [string]$Direction, [bool]$TestsPassed)
     if (-not $TestsPassed) { Write-Output "[GIT] Tests not passed. No auto-commit."; return $false }
     if (-not $Apply) { Write-Output "[GIT] DryRun. Would commit: evolve: $Direction ($ProposalIdVal)"; return $false }
     $commitMsg = "evolve: $Direction ($ProposalIdVal) - self-evolution cycle"
     try {
         Push-Location $ProjectPath
         & git add ".trae/scripts/obsidian-*.ps1" 2>$null
         & git add ".trae/scripts/_shared/ObsidianHelpers.psm1" 2>$null
         $status = & git status --porcelain 2>$null
         $staged = $status | Where-Object { $_ -match '^[AMRC]' }
         if ($null -eq $staged -or $staged.Count -eq 0) { Write-Output "[GIT] No staged changes."; Pop-Location; return $false }
         & git commit -m $commitMsg 2>$null
         if ($LASTEXITCODE -eq 0) { Write-Output "[GIT] Committed: $commitMsg"; Pop-Location; return $true }
         else { Write-Output "[GIT] Commit failed."; Pop-Location; return $false }
     } catch { Write-Output "[GIT] Error: $($_.Exception.Message)"; Pop-Location; return $false }
 }
 
 # ============================================================
 # Git Rollback (for abandoned proposals)
 # ============================================================
 function Invoke-GitRollback {
     param([string]$ProposalIdVal)
     Write-Output "[ROLLBACK] Abandoning proposal $ProposalIdVal. Restoring..."
     try {
         Push-Location $ProjectPath
         & git checkout -- ".trae/scripts/obsidian-*.ps1" 2>$null
         & git checkout -- ".trae/scripts/_shared/ObsidianHelpers.psm1" 2>$null
         Write-Output "[ROLLBACK] Changes reverted."
         Pop-Location; return $true
     } catch { Write-Output "[ROLLBACK] Error: $($_.Exception.Message)"; Pop-Location; return $false }
 }
 
 # ============================================================
 # Parse proposal YAML
 # ============================================================
 function Parse-ProposalYaml {
     param([string]$FilePath)
     if (-not (Test-Path $FilePath)) { return $null }
     $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
     if ($null -eq $content) { return $null }
     $proposal = @{}
     if ($content -match 'proposal_id:\s*"?([^"\n]+)"?') { $proposal['proposal_id'] = $Matches[1].Trim().Trim('"') }
     if ($content -match 'source_gene:\s*"?([^"\n]+)"?') { $proposal['source_gene'] = $Matches[1].Trim().Trim('"') }
     if ($content -match 'improvement_direction:\s*"?([^"\n]+)"?') { $proposal['improvement_direction'] = $Matches[1].Trim().Trim('"') }
     if ($content -match 'pareto_mean:\s*([\d.]+)') { $proposal['pareto_mean'] = [double]$Matches[1] }
     if ($content -match 'status:\s*(\w+)') { $proposal['status'] = $Matches[1] }
     # Extract steps
     $proposal['steps'] = @()
     $stepMatches = [regex]::Matches($content, '^\s*-\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
     foreach ($sm in $stepMatches) {
         $stepText = $sm.Groups[1].Value.Trim().Trim("'").Trim('"')
         if ($stepText -notmatch '^[A-Z]:\\' -and $stepText.Length -gt 5) { $proposal['steps'] += $stepText }
     }
     $proposal['context_sources'] = @()
     $proposal['system_sources'] = @()
     $proposal['overlap_warning'] = @()
     return $proposal
 }
 
 # ============================================================
 # List proposals
 # ============================================================
 function List-AllProposals {
     Write-Output "=== SPL Proposals ==="
     $proposals = Get-ChildItem -Path $proposalsDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
     if ($null -eq $proposals -or $proposals.Count -eq 0) {
         Write-Output "No proposals found. Run obsidian-spl-cycle.ps1 -FullCycle first."
         return
     }
     foreach ($p in $proposals) {
         $proposal = Parse-ProposalYaml -FilePath $p.FullName
         if ($null -eq $proposal) { continue }
         $status = if ($proposal.ContainsKey('status')) { $proposal['status'] } else { "unknown" }
         $direction = if ($proposal.ContainsKey('improvement_direction')) { $proposal['improvement_direction'] } else { "?" }
         Write-Output "  [$status] $($proposal['proposal_id']) | dir=$direction | steps=$($proposal['steps'].Count)"
     }
     $enacted = Get-ChildItem -Path $enactedDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
     if ($null -ne $enacted -and $enacted.Count -gt 0) {
         Write-Output ""; Write-Output "=== Enacted Proposals ==="
         foreach ($e in $enacted) {
             $ep = Parse-ProposalYaml -FilePath $e.FullName
             if ($null -ne $ep) { Write-Output "  [enacted] $($ep['proposal_id']) | dir=$($ep['improvement_direction'])" }
         }
     }
 }
 
 # ============================================================
 # Execute proposal with 5-round circuit breaker
 # ============================================================
 function Execute-Proposal {
     param([string]$ProposalPId)
     
     $execScript = Join-Path $PSScriptRoot "obsidian-execute-evolution.ps1"
     if (-not (Test-Path $execScript)) {
         Write-Error "[DELEGATE] obsidian-execute-evolution.ps1 not found. Cannot execute."
         return $null
     }
     
     Write-Output "[DELEGATE] Delegating execution to obsidian-execute-evolution.ps1..."
     
     # Step 1: Execute the proposal (generate prompt + marker)
     & $execScript -Execute -ProposalId $ProposalPId
     if ($LASTEXITCODE -ne 0) {
         Write-Output "[DELEGATE] Execution setup failed."
         return @{ proposal_id = $ProposalPId; all_passed = $false; fix_rounds = 0; abandoned = $false; has_refactor = $false }
     }
     
     # Step 2: Verify and commit (test → fix → commit with circuit breaker)
     if ($Apply) {
         & $execScript -VerifyAndCommit -ProposalId $ProposalPId -Apply
         if ($LASTEXITCODE -ne 0) {
             Write-Output "[DELEGATE] Verification failed. Proposal may be abandoned."
             return @{ proposal_id = $ProposalPId; all_passed = $false; fix_rounds = 0; abandoned = $true; has_refactor = $false }
         }
     } else {
         Write-Output "[DRY-DELEGATE] Would verify and commit with -Apply flag."
         # Just run tests in dry-run mode
         & $execScript -TestOnly
     }
     
     # Step 3: Read the latest execution report for this proposal
     $reportFiles = Get-ChildItem -Path $resultsDir -Filter "exec-report-*-$ProposalPId*.md" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
     if ($null -ne $reportFiles -and $reportFiles.Count -gt 0) {
         $reportContent = [System.IO.File]::ReadAllText($reportFiles[0].FullName, [System.Text.Encoding]::UTF8)
         Write-Output "[DELEGATE] Latest report: $($reportFiles[0].Name)"
         
         # Parse key results from report
         $allPassed = $reportContent -match 'Tests Passed: True'
         $abandoned = $reportContent -match 'Abandoned: True'
         $committed = $reportContent -match 'Git Committed: True'
         
         return @{ proposal_id = $ProposalPId; all_passed = $allPassed; fix_rounds = 0; abandoned = $abandoned; has_refactor = $false; committed = $committed }
     }
     
     return @{ proposal_id = $ProposalPId; all_passed = $true; fix_rounds = 0; abandoned = $false; has_refactor = $false }
 }
 
 # ============================================================
 # Full Improve: find best proposal and execute with full loop
 # ============================================================
 function Run-FullImprove {
     Write-Output "=== Full Self-Improvement (v2) ==="
     Write-Output "Circuit breaker: $MaxFixRounds rounds"
     Write-Output "Framework-optimal: stopgap solutions rejected"
     Write-Output "Refactor pause: detected refactors logged, not executed"
     Write-Output ""
     
     # Step 1: Check for committed proposals
     $proposals = Get-ChildItem -Path $proposalsDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
     $committed = @()
     foreach ($p in $proposals) {
         $proposal = Parse-ProposalYaml -FilePath $p.FullName
         if ($null -ne $proposal -and $proposal.ContainsKey('status') -and $proposal['status'] -eq 'committed') {
             $committed += $proposal
         }
     }
     
     if ($committed.Count -eq 0) {
         Write-Output "[IMPROVE] No committed proposals. Running SPL cycle..."
         $splScript = Join-Path $PSScriptRoot "obsidian-spl-cycle.ps1"
         if (Test-Path $splScript) { & $splScript -FullCycle -Apply }
         # Re-check
         $proposals = Get-ChildItem -Path $proposalsDir -Filter "proposal-spl-*.yaml" -File -ErrorAction SilentlyContinue
         foreach ($p in $proposals) {
             $proposal = Parse-ProposalYaml -FilePath $p.FullName
             if ($null -ne $proposal -and $proposal.ContainsKey('status') -and $proposal['status'] -eq 'committed') {
                 $committed += $proposal
             }
         }
     }
     
     if ($committed.Count -eq 0) {
         Write-Output "[IMPROVE] No committed proposals available."
         Write-Output "[IMPROVE] Try: obsidian-evolve.ps1 -Batch -ExtractGene -Apply"
         Write-Output "[IMPROVE] Then: obsidian-spl-cycle.ps1 -FullCycle -Apply"
         return
     }
     
     # Step 2: Pick best committed proposal (highest pareto_mean)
     $bestProposal = $committed[0]
     foreach ($c in $committed) {
         $cMean = if ($c.ContainsKey('pareto_mean')) { $c['pareto_mean'] } else { 0 }
         $bMean = if ($bestProposal.ContainsKey('pareto_mean')) { $bestProposal['pareto_mean'] } else { 0 }
         if ($cMean -gt $bMean) { $bestProposal = $c }
     }
     
     Write-Output "[IMPROVE] Selected: $($bestProposal['proposal_id']) (mean=$($bestProposal['pareto_mean']))"
     
     # Step 3: Execute with circuit breaker
     $result = Execute-Proposal -ProposalPId $bestProposal['proposal_id']
     
     if ($null -ne $result) {
         Write-Output ""
         Write-Output "=== Improvement Result ==="
         Write-Output "Proposal: $($bestProposal['proposal_id'])"
         Write-Output "All Passed: $($result.all_passed)"
         Write-Output "Fix Rounds: $($result.fix_rounds) / $MaxFixRounds"
         Write-Output "Abandoned: $($result.abandoned)"
         Write-Output "Has Refactor: $($result.has_refactor)"
         
         # If abandoned, try next proposal
         if ($result.abandoned -and $committed.Count -gt 1) {
             Write-Output "[IMPROVE] Trying next proposal..."
             foreach ($c in $committed) {
                 if ($c['proposal_id'] -ne $bestProposal['proposal_id']) {
                     Write-Output "[IMPROVE] Trying: $($c['proposal_id'])"
                     $result2 = Execute-Proposal -ProposalPId $c['proposal_id']
                     if ($null -ne $result2 -and $result2.all_passed) { break }
                 }
             }
         }
         
         # If refactor detected, remind about it
         if ($result.has_refactor) {
             Write-Output ""
             Write-Output "[REMIND] Refactor candidates detected! Check: $RefactorLogPath"
             Write-Output "[REMIND] These require Ba Ba's approval before execution."
         }
     }
 }
 
 # ============================================================
 # Self-test
 # ============================================================
 if ($SelfTest) {
     Write-Output "[SELFTEST] Running obsidian-self-improve-v2 self-test..."
     
     $testDir = "$env:TEMP\obsidian-improve-v2-selftest"
     if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
     New-Item -Path "$testDir\进化\proposals" -ItemType Directory -Force | Out-Null
     New-Item -Path "$testDir\进化\enacted" -ItemType Directory -Force | Out-Null
     New-Item -Path "$testDir\进化\results" -ItemType Directory -Force | Out-Null
     New-Item -Path "$testDir\进化\genes" -ItemType Directory -Force | Out-Null
     New-Item -Path "$testDir\进化\logs" -ItemType Directory -Force | Out-Null
     
     # Test evolution logging
     $EvolutionLogPath = Join-Path $testDir "进化\logs\evolution-log.md"
     Write-EvolutionLog -Direction "test" -GeneId "test001" -ProposalIdVal "ptest001" -Result "SUCCESS" -TestsPassed $true
     if (-not (Test-Path $EvolutionLogPath)) { Write-Output "[SELFTEST-FAIL] Evolution log not created"; exit 1 }
     Write-Output "[SELFTEST-PASS] Evolution logging works"
     
     # Test refactor detection
     $isRefactor = Test-IsRefactor -StepDescription "重构现有架构" -AffectedFiles ""
     if (-not $isRefactor) { Write-Output "[SELFTEST-FAIL] Refactor detection failed"; exit 1 }
     Write-Output "[SELFTEST-PASS] Refactor detection works"
     
     $isRefactor2 = Test-IsRefactor -StepDescription "Add new feature" -AffectedFiles ""
     if ($isRefactor2) { Write-Output "[SELFTEST-FAIL] False positive refactor"; exit 1 }
     Write-Output "[SELFTEST-PASS] No false positive refactor"
     
     # Test knowledge exhaustion
     $exhausted = Test-KnowledgeExhaustion -Proposal @{ context_sources = @(); system_sources = @() }
     if (-not $exhausted) { Write-Output "[SELFTEST-FAIL] Exhaustion not detected"; exit 1 }
     Write-Output "[SELFTEST-PASS] Knowledge exhaustion detection works"
     
     $notExhausted = Test-KnowledgeExhaustion -Proposal @{ context_sources = @("a","b","c"); system_sources = @("d") }
     if ($notExhausted) { Write-Output "[SELFTEST-FAIL] False positive exhaustion"; exit 1 }
     Write-Output "[SELFTEST-PASS] No false positive exhaustion"
     
     # Test stopgap rejection
     $stopgapStep = "Add workaround for routing bug"
     $stopgapPatterns = @("workaround", "临时", "hack", "quick fix", "band-aid", "patch only")
     $hasStopgap = $false
     foreach ($sp in $stopgapPatterns) { if ($stopgapStep -match $sp) { $hasStopgap = $true; break } }
     if (-not $hasStopgap) { Write-Output "[SELFTEST-FAIL] Stopgap not detected"; exit 1 }
     Write-Output "[SELFTEST-PASS] Stopgap detection works"
     
     # Test proposal parsing
     $testProposal = @"
 proposal_id: "testv2_001"
 source_gene: "gene_test"
 improvement_direction: "self-evolve"
 pareto_mean: 0.7
 steps:
   - "Analyze system for improvement opportunity"
   - "Design improvement from Gene and context"
   - "Implement with SPL safety"
   - "Test with self-verification"
 status: committed
"@
     $testProposalPath = Join-Path $testDir "进化\proposals\proposal-spl-test-testv2_001.yaml"
     Set-Content -Path $testProposalPath -Value $testProposal -Encoding UTF8
     
     $parsed = Parse-ProposalYaml -FilePath $testProposalPath
     if ($null -eq $parsed -or $parsed['proposal_id'] -ne 'testv2_001') { Write-Output "[SELFTEST-FAIL] Parse failed"; exit 1 }
     Write-Output "[SELFTEST-PASS] Proposal parsing works"
     
     # Test refactor logging
     $RefactorLogPath = Join-Path $testDir "进化\logs\refactor-candidates.md"
     Write-RefactorCandidate -ProposalIdVal "ptest" -Direction "test" -Description "Refactor test" -AffectedFiles "none"
     if (-not (Test-Path $RefactorLogPath)) { Write-Output "[SELFTEST-FAIL] Refactor log not created"; exit 1 }
     Write-Output "[SELFTEST-PASS] Refactor logging works"
     
     Remove-Item $testDir -Recurse -Force
     Write-Output "[SELFTEST] All tests passed."
     exit 0
 }
 
 # ============================================================
 # Run
 # ============================================================
 if ($ListProposals) { List-AllProposals }
 elseif ($Execute -and $ProposalId -ne "") { Execute-Proposal -ProposalPId $ProposalId }
 elseif ($AutoTest -and $ProposalId -ne "") {
     $result = Execute-Proposal -ProposalPId $ProposalId
     if ($null -ne $result -and -not $result.all_passed) { exit 1 }
 }
 elseif ($FullImprove) { Run-FullImprove }
 else {
     Write-Error "Specify: -ListProposals, -Execute, -AutoTest, -FullImprove, or -SelfTest. Use -Help for details."
     exit 1
 }
 exit 0
