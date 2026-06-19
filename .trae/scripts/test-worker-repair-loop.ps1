param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$TaskGuard = Join-Path $PSScriptRoot "task-guard.ps1"
$TaskState = Join-Path $PSScriptRoot "task-state.ps1"
$TaskHandoff = Join-Path $PSScriptRoot "task-handoff.ps1"
$RepairLoop = Join-Path $PSScriptRoot "worker-repair-loop.ps1"
$Results = @()
$Failed = $false
$Created = @()

function Add-Result {
    param(
        [string]$Scenario,
        [string]$Name,
        [bool]$Passed,
        [string]$Actual
    )
    if ($Passed) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Name - $Actual" -ForegroundColor Red
        $script:Failed = $true
    }
    $script:Results += [pscustomobject]@{
        Scenario = $Scenario
        Name = $Name
        Result = if ($Passed) { "PASS" } else { "FAIL" }
        Actual = $Actual
    }
}

function Remove-Fixture {
    param([string]$Path)
    if ($Path -and (Test-Path -LiteralPath $Path)) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function New-RepairFixture {
    param(
        [string]$Name,
        [ValidateSet("plan","implement","review","verify")]
        [string]$Phase = "plan",
        [bool]$IncludeRepairPolicy = $true,
        [bool]$WeakDs4Package = $false,
        [bool]$CompleteTasks = $false,
        [bool]$CreateWorkerReport = $false,
        [bool]$WorkerClaimsAuthority = $false,
        [ValidateSet("codex","flash-same","flash-fresh")]
        [string]$VerifierMode = "codex"
    )

    $dir = Join-Path $Root ".trae\tasks\_shared\$Name"
    Remove-Fixture $dir
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "work-packages") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "reports") -Force | Out-Null
    $script:Created += $dir

    $verifyResult = if ($Phase -eq "verify") { "pass" } else { "pending" }
    $reviewResult = if ($Phase -in @("verify")) { "pass" } else { "pending" }
    $verificationReport = if ($Phase -eq "verify") { "verification-report.md" } else { "null" }
    $leadVerifier = if ($VerifierMode -in @("flash-same","flash-fresh")) { "ds4-flash-fresh-context" } else { "codex" }
    Set-Content -LiteralPath (Join-Path $dir ".task.yaml") -Value @"
task_name: $Name
workflow: full
phase: $Phase
project_type: other
implement_mode: subagent
isolation: branch
clarification_status: answered
user_confirmed_plan: true
router_skill_loaded: true
review_result: $reviewResult
verify_result: $verifyResult
verification_report: $verificationReport
archived: false
fix_attempts: 0
worker_profile: ds4-flash
lead_verifier: $leadVerifier
repair_loop_status: idle
active_root_cause: null
active_repair_package: null
"@

    $repairPolicy = if ($IncludeRepairPolicy) {
@"

## Worker Repair Policy
- Worker profile: ds4-flash
- Lead/verifier: codex
- Fresh context per repair: yes
- Automatic repair package generation: yes
- Maximum attempts per root cause: 3
- Same-context worker self-verification: forbidden
- Only lead may set Review/Verify pass: yes
"@
    }
    else {
        ""
    }

    Set-Content -LiteralPath (Join-Path $dir "routing.md") -Value @"
# Routing

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes

## Work Package Policy
- External workers: yes
- Task packet root: .trae/tasks/_shared/$Name
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes
$repairPolicy
"@

    Set-Content -LiteralPath (Join-Path $dir "analysis.md") -Value @"
# Analysis

## Architecture Context

### System boundaries
- Fixture only.

### Dependency map
- package -> worker -> verifier.

### Data and state ownership
- Lead owns acceptance.

### Integration points
- task guard and repair loop.

## Mature Solution Evidence

### Project-local evidence
- Existing task packet workflow.

### Official/framework evidence
- Existing Comet task state.

### External mature references
- Evaluator-optimizer workflow.

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Repair loop | Local | Auditable | More state | Selected |
| Reminder | Prompt | Easy | Skippable | Rejected |

### Rejected shortcuts
- No self-verification.

### Selected mature path
- Bounded DS4 worker and independent verifier.

## Acceptance Criteria
- AC01: Repair loop is enforced.

## Automated Verification Plan
- Command: test-worker-repair-loop.ps1
- Expected: all pass.
"@
    Set-Content -LiteralPath (Join-Path $dir "spec.md") -Value "# Spec`n`n### S01`n`n**Status**: [ ]"

    $mark = if ($CompleteTasks -or $Phase -eq "verify") { "x" } else { " " }
    Set-Content -LiteralPath (Join-Path $dir "tasks.md") -Value @"
- [$mark] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [$mark] Run automated verification and record command output in verification-report.md.
- [$mark] Map implementation result to Acceptance Criteria in verification-report.md.
"@
    Set-Content -LiteralPath (Join-Path $dir "doc-impact.md") -Value @"
## Project Document Scope
- Project: _shared
- System: Repair fixture
- Owner: test

## Code Changes
- None

## No Code Changes
Reason: isolated workflow fixture

## Documentation Updates
- Docs/AI/36-DS4-Flash-Worker-Repair-Loop.md

## Docs Tree Updates
- None
"@

    $packagePath = Join-Path $dir "work-packages\WP01-initial.md"
    if ($WeakDs4Package) {
        Set-Content -LiteralPath $packagePath -Value @"
# WP01: Weak package

Owner model: deepseek-v4-flash
Difficulty: simple
Status: unclaimed

## Task Packet
- Root: .trae/tasks/_shared/$Name/
- Parent task: $Name

## Allowed Paths
- src/a.ps1

## Forbidden Paths
- tests/

## Read First
- spec.md

## Goal
- Make the fixture pass.

## Steps
- [ ] Run the command.

## Done Definition
- Command passes.

## Required Verification
- Command: fixture-command
- Expected: pass

## Return Report
- Path: reports/ds4-flash-WP01-result.md
"@
    }
    else {
        Set-Content -LiteralPath $packagePath -Value @"
# WP01: Initial bounded repair

Owner model: deepseek-v4-flash
Difficulty: simple
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile
- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget
- Read only this package and the Read First list.
- Do not inspect unrelated repository files.

## Root Cause Boundary
- Root Cause ID: RC00
- This package handles one bounded initial implementation concern.

## Task Packet
- Root: .trae/tasks/_shared/$Name/
- Parent task: $Name

## Allowed Paths
- src/a.ps1
- src/b.ps1

## Forbidden Paths
- tests/
- .task.yaml
- verification-report.md

## Read First
- spec.md
- analysis.md

## Goal
- Make the bounded fixture behavior pass.

## Steps
- [ ] Change only allowed paths.
- [ ] Run the exact verification command.

## Done Definition
- The exact command passes without weakening tests or acceptance.

## Required Verification
- Command: fixture-command
- Expected: pass

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence.

## Stop Conditions
- Stop when a required change falls outside Allowed Paths.
- Return Status: blocked with the smallest blocker.

## Return Report
- Path: reports/ds4-flash-WP01-result.md
- Required status for merge: done
- Must declare Extra scope taken: no.
"@
    }

    if ($CreateWorkerReport) {
        $reviewClaim = if ($WorkerClaimsAuthority) { "yes" } else { "no" }
        Set-Content -LiteralPath (Join-Path $dir "reports\ds4-flash-WP01-result.md") -Value @"
# Result: DS4 Flash WP01

Task packet: .trae/tasks/_shared/$Name/
Work package: work-packages/WP01-initial.md
Status: done
Worker model: deepseek-v4-flash
Worker context: fresh

## Changed Files
- src/a.ps1 - fixture

## Commands Run
| Command | Result | Notes |
|---|---|---|
| fixture-command | pass | fixture |

## Acceptance Criteria Touched
- AC01: pass - fixture.

## Scope Control
- Extra scope taken: no
- Forbidden paths touched: no
- Architecture decisions changed: no

## Worker Authority
- Review result set by worker: $reviewClaim
- Verify result set by worker: no
- Task state changed by worker: no
- Acceptance criteria changed by worker: no
- Tests weakened by worker: no

## Unresolved Risks
- None
"@
    }

    if ($Phase -eq "verify") {
        $verifierModel = if ($VerifierMode -eq "codex") { "codex" } else { "deepseek-v4-flash" }
        $verifierContext = if ($VerifierMode -eq "flash-same") { "same" } elseif ($VerifierMode -eq "flash-fresh") { "fresh" } else { "independent" }
        Set-Content -LiteralPath (Join-Path $dir "verification-report.md") -Value @"
# Verification Report: $Name

Verification Result: pass
Verifier: fixture verifier
Verifier role: lead
Verifier model: $verifierModel
Worker model: deepseek-v4-flash
Verifier context: $verifierContext

## Review Basis
- Worker reports reviewed: yes
- Independent verification run by reviewer: yes
- Worker success claims accepted without verification: no

## Automated Verification
| Command | Result | Evidence |
|---|---|---|
| fixture-command | pass | independently rerun |

## Acceptance Criteria
| ID | Requirement | Result | Evidence |
|---|---|---|---|
| AC01 | Repair loop | pass | fixture |

## Architecture Compliance
- Selected mature path followed: yes
- Rejected shortcuts reintroduced: no
- Project boundaries respected: yes
- Documentation synchronized: yes

## Test Evidence
- Independent fixture command passed.

## Residual Risk
- None
"@
    }

    return $dir
}

function Invoke-RepairFailure {
    param(
        [string]$TaskName,
        [string]$RootCauseId,
        [string[]]$AllowedPaths
    )
    if (-not (Test-Path -LiteralPath $RepairLoop)) {
        return 127
    }
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $RepairLoop record-failure "_shared/$TaskName" `
        -Stage review `
        -RootCauseId $RootCauseId `
        -Summary "Focused fixture failure" `
        -FailedCommand "fixture-command" `
        -Expected "pass" `
        -Actual "fail" `
        -AllowedPaths ($AllowedPaths -join ";") `
        -ReadFirst "spec.md;analysis.md" *> $null
    return $LASTEXITCODE
}

Push-Location $Root
try {
    $missingPolicy = New-RepairFixture -Name "__repair_missing_policy" -IncludeRepairPolicy $false
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_missing_policy" plan *> $null
    Add-Result "S01" "ds4-missing-repair-policy-blocks" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"

    $weakPackage = New-RepairFixture -Name "__repair_weak_package" -WeakDs4Package $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_weak_package" plan *> $null
    Add-Result "S02" "ds4-weak-package-blocks" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"

    $first = New-RepairFixture -Name "__repair_first" -Phase review
    $exit = Invoke-RepairFailure "__repair_first" "RC01" @("src/a.ps1","src/b.ps1")
    $statePath = Join-Path $first "repair-state.json"
    $evidence = @(Get-ChildItem -LiteralPath (Join-Path $first "verification-history") -Filter "A001-*.md" -File -ErrorAction SilentlyContinue)
    $repairPackages = @(Get-ChildItem -LiteralPath (Join-Path $first "work-packages") -Filter "WP*-fix-rc01-a1.md" -File -ErrorAction SilentlyContinue)
    $tasks = Get-Content -LiteralPath (Join-Path $first "tasks.md") -Raw
    $firstPassed = ($exit -eq 0) -and (Test-Path $statePath) -and ($evidence.Count -eq 1) -and ($repairPackages.Count -eq 1) -and ($tasks -match "R01")
    Add-Result "S03" "first-failure-publishes-repair-artifacts" $firstPassed "exit=$exit evidence=$($evidence.Count) packages=$($repairPackages.Count)"

    $secondExit = Invoke-RepairFailure "__repair_first" "RC01" @("src/a.ps1")
    $secondPackages = @(Get-ChildItem -LiteralPath (Join-Path $first "work-packages") -Filter "WP*-fix-rc01-a2.md" -File -ErrorAction SilentlyContinue)
    Add-Result "S04" "second-failure-allows-narrower-scope" (($secondExit -eq 0) -and ($secondPackages.Count -eq 1)) "exit=$secondExit packages=$($secondPackages.Count)"

    $expanded = New-RepairFixture -Name "__repair_expanded" -Phase review
    $null = Invoke-RepairFailure "__repair_expanded" "RC01" @("src/a.ps1")
    $expandedExit = Invoke-RepairFailure "__repair_expanded" "RC01" @("src/a.ps1","src/new.ps1")
    Add-Result "S05" "repair-scope-expansion-blocks" ($expandedExit -ne 0) "exit=$expandedExit"

    $thirdExit = Invoke-RepairFailure "__repair_first" "RC01" @("src/a.ps1")
    $state = if (Test-Path $statePath) { Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json } else { $null }
    $thirdPackages = @(Get-ChildItem -LiteralPath (Join-Path $first "work-packages") -Filter "WP*-fix-rc01-a3.md" -File -ErrorAction SilentlyContinue)
    $thirdPassed = ($thirdExit -eq 0) -and $state -and ($state.status -eq "architecture_review") -and ($thirdPackages.Count -eq 0)
    Add-Result "S06" "third-failure-trips-circuit-breaker" $thirdPassed "exit=$thirdExit status=$($state.status) packages=$($thirdPackages.Count)"

    $separate = New-RepairFixture -Name "__repair_separate" -Phase review
    $null = Invoke-RepairFailure "__repair_separate" "RC01" @("src/a.ps1")
    $null = Invoke-RepairFailure "__repair_separate" "RC02" @("src/b.ps1")
    $separateStatePath = Join-Path $separate "repair-state.json"
    $separateState = if (Test-Path $separateStatePath) { Get-Content -LiteralPath $separateStatePath -Raw | ConvertFrom-Json } else { $null }
    $rc01 = if ($separateState) { $separateState.attempts_by_root_cause.RC01 } else { 0 }
    $rc02 = if ($separateState) { $separateState.attempts_by_root_cause.RC02 } else { 0 }
    Add-Result "S07" "root-cause-counters-are-independent" (($rc01 -eq 1) -and ($rc02 -eq 1)) "RC01=$rc01 RC02=$rc02"

    $immutable = New-RepairFixture -Name "__repair_immutable" -Phase review
    $null = Invoke-RepairFailure "__repair_immutable" "RC01" @("src/a.ps1")
    $firstEvidence = Get-ChildItem -LiteralPath (Join-Path $immutable "verification-history") -Filter "A001-*.md" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $beforeHash = if ($firstEvidence) { (Get-FileHash -LiteralPath $firstEvidence.FullName).Hash } else { "" }
    $null = Invoke-RepairFailure "__repair_immutable" "RC01" @("src/a.ps1")
    $afterHash = if ($firstEvidence) { (Get-FileHash -LiteralPath $firstEvidence.FullName).Hash } else { "" }
    Add-Result "S08" "failure-evidence-is-immutable" ($beforeHash -and ($beforeHash -eq $afterHash)) "before=$beforeHash after=$afterHash"

    $authority = New-RepairFixture -Name "__repair_authority" -Phase implement -CompleteTasks $true -CreateWorkerReport $true -WorkerClaimsAuthority $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_authority" implement *> $null
    Add-Result "S09" "worker-authority-claim-blocks" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"

    $same = New-RepairFixture -Name "__repair_same_context" -Phase verify -CompleteTasks $true -CreateWorkerReport $true -VerifierMode "flash-same"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_same_context" verify *> $null
    Add-Result "S10" "same-context-flash-verification-blocks" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"

    $fresh = New-RepairFixture -Name "__repair_fresh_context" -Phase verify -CompleteTasks $true -CreateWorkerReport $true -VerifierMode "flash-fresh"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_fresh_context" verify *> $null
    Add-Result "S11" "fresh-context-flash-fallback-passes" ($LASTEXITCODE -eq 0) "exit=$LASTEXITCODE"

    $codex = New-RepairFixture -Name "__repair_codex_verify" -Phase verify -CompleteTasks $true -CreateWorkerReport $true -VerifierMode "codex"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__repair_codex_verify" verify *> $null
    Add-Result "S12" "codex-independent-verification-passes" ($LASTEXITCODE -eq 0) "exit=$LASTEXITCODE"

    $bypass = New-RepairFixture -Name "__repair_transition_bypass" -Phase review
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskState transition "_shared/__repair_transition_bypass" review-fail *> $null
    Add-Result "S13" "legacy-failure-transition-cannot-bypass-repair-loop" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"

    $handoffFixture = New-RepairFixture -Name "__repair_handoff" -Phase review
    $handoffExit = Invoke-RepairFailure "__repair_handoff" "RC09" @("src/a.ps1")
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskHandoff "_shared/__repair_handoff" -Direction plan-to-implement *> $null
    $handoffPath = Join-Path $handoffFixture "handoff-plan-to-implement.txt"
    $handoffContent = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { "" }
    $handoffPassed = ($handoffExit -eq 0) -and ($LASTEXITCODE -eq 0) -and
        ($handoffContent -match "WP\d+-fix-rc09-a1\.md") -and
        ($handoffContent -notmatch "WP01-initial\.md")
    Add-Result "S14" "handoff-exposes-only-active-repair-package" $handoffPassed "repair=$handoffExit handoff=$LASTEXITCODE"

    $resolveFixture = New-RepairFixture -Name "__repair_resolve" -Phase verify -CompleteTasks $true -VerifierMode codex
    $null = Invoke-RepairFailure "__repair_resolve" "RC10" @("src/a.ps1")
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $RepairLoop resolve "_shared/__repair_resolve" -RootCauseId RC10 *> $null
    $resolveExit = $LASTEXITCODE
    $resolvedState = Get-Content -LiteralPath (Join-Path $resolveFixture "repair-state.json") -Raw | ConvertFrom-Json
    $resolvedYaml = Get-Content -LiteralPath (Join-Path $resolveFixture ".task.yaml") -Raw
    $resolvedEvidence = @(Get-ChildItem -LiteralPath (Join-Path $resolveFixture "verification-history") -Filter "A001-*.md" -File)
    $resolvePassed = ($resolveExit -eq 0) -and
        ($resolvedState.status -eq "resolved") -and
        (-not $resolvedState.active_root_cause) -and
        ($resolvedYaml -match "(?m)^repair_loop_status:\s*resolved\s*$") -and
        ($resolvedYaml -match "(?m)^active_root_cause:\s*null\s*$") -and
        ($resolvedEvidence.Count -eq 1)
    Add-Result "S15" "resolution-clears-active-state-and-keeps-history" $resolvePassed "exit=$resolveExit status=$($resolvedState.status) evidence=$($resolvedEvidence.Count)"

    $recurExit = Invoke-RepairFailure "__repair_resolve" "RC10" @("src/a.ps1")
    $recurState = Get-Content -LiteralPath (Join-Path $resolveFixture "repair-state.json") -Raw | ConvertFrom-Json
    $recurPackages = @(Get-ChildItem -LiteralPath (Join-Path $resolveFixture "work-packages") -Filter "WP*-fix-rc10-a1.md" -File)
    $recurPassed = ($recurExit -eq 0) -and
        ($recurState.attempts_by_root_cause.RC10 -eq 1) -and
        ($recurState.total_attempts_by_root_cause.RC10 -eq 2) -and
        ($recurPackages.Count -eq 2)
    Add-Result "S16" "resolved-root-recurrence-starts-new-consecutive-streak" $recurPassed "exit=$recurExit consecutive=$($recurState.attempts_by_root_cause.RC10) total=$($recurState.total_attempts_by_root_cause.RC10)"

    $absoluteScope = New-RepairFixture -Name "__repair_absolute_scope" -Phase review
    $absoluteExit = Invoke-RepairFailure "__repair_absolute_scope" "RC11" @("C:\outside\file.ps1")
    Add-Result "S17" "absolute-worker-scope-is-rejected" ($absoluteExit -ne 0) "exit=$absoluteExit"

    $resolveWithoutEvidence = New-RepairFixture -Name "__repair_resolve_without_evidence" -Phase review
    $null = Invoke-RepairFailure "__repair_resolve_without_evidence" "RC12" @("src/a.ps1")
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $RepairLoop resolve "_shared/__repair_resolve_without_evidence" -RootCauseId RC12 *> $null
    Add-Result "S18" "resolve-without-independent-pass-evidence-blocks" ($LASTEXITCODE -ne 0) "exit=$LASTEXITCODE"
}
finally {
    Pop-Location
    foreach ($dir in $Created) {
        Remove-Fixture $dir
    }
}

if ($Failed) {
    exit 1
}
exit 0
