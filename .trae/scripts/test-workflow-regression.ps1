param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskGuard = Join-Path $PSScriptRoot "task-guard.ps1"
$DocGuardTest = Join-Path $PSScriptRoot "test-doc-guard.ps1"
$DocsTreeScript = Join-Path $PSScriptRoot "update-docs-tree.ps1"
$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$Results = @()
$Failed = $false

function Add-Result {
    param(
        [string]$Scenario,
        [string]$Name,
        [string]$Expected,
        [string]$Actual,
        [bool]$Passed,
        [string]$Notes = ""
    )
    if ($Passed) { Write-Host "[PASS] $Name" -ForegroundColor Green }
    else { Write-Host "[FAIL] $Name" -ForegroundColor Red; $script:Failed = $true }
    $script:Results += [pscustomobject]@{
        Scenario = $Scenario
        Expected = $Expected
        Actual = $Actual
        Result = if ($Passed) { "PASS" } else { "FAIL" }
        Notes = $Notes
    }
}

function Remove-TestDir {
    param([string]$Path)
    if ($Path -and (Test-Path $Path)) { Remove-Item -LiteralPath $Path -Recurse -Force }
}

function New-TaskPacket {
    param(
        [string]$RootName = ".trae\tasks",
        [string]$Scope = "_shared",
        [string]$Name,
        [bool]$ExternalWorkers = $false,
        [bool]$CreateWorkPackage = $false,
        [bool]$InvalidWorkPackage = $false,
        [bool]$CompleteTasks = $false,
        [bool]$CreateWorkerReport = $false,
        [bool]$BadWorkerReport = $false,
        [bool]$WeakAnalysis = $false,
        [bool]$MissingWorkPackagePolicy = $false,
        [bool]$VerifyMode = $false,
        [bool]$WeakReport = $false,
        [ValidateSet("","deep","fast")][string]$RequirementProfile = "",
        [bool]$MissingRequirementsDocument = $false,
        [bool]$MissingExecutionPrompt = $false,
        [bool]$MissingFastTrackReason = $false,
        [bool]$OutsideArtifactPaths = $false
    )

    $dir = if ($Scope) {
        Join-Path $Root "$RootName\$Scope\$Name"
    } else {
        Join-Path $Root "$RootName\$Name"
    }
    Remove-TestDir $dir
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $phase = if ($VerifyMode) { "verify" } else { "plan" }
    $verifyResult = if ($VerifyMode) { "pass" } else { "pending" }
    $reportValue = if ($VerifyMode) { "verification-report.md" } else { "null" }
    $clarificationStatus = if ($RequirementProfile -eq "deep") { "answered" } else { "not_needed" }
    $requirementsYaml = if ($RequirementProfile) {
        $requirementsStatus = if ($RequirementProfile -eq "deep") { "confirmed" } else { "not_required" }
        $requirementsDoc = if ($MissingRequirementsDocument) { "missing-requirements.md" } elseif ($OutsideArtifactPaths) { "../__outside-requirements.md" } else { "requirements.md" }
        $executionPrompt = if ($MissingExecutionPrompt) { "missing-execution-prompt.md" } elseif ($OutsideArtifactPaths) { "../__outside-execution-prompt.md" } else { "execution-prompt.md" }
        $fastReason = if ($RequirementProfile -eq "fast" -and -not $MissingFastTrackReason) { "Bounded exact fix with no architecture, data ownership, or user-journey impact." } else { "null" }
@"
requirements_gate_version: 1
change_profile: $RequirementProfile
requirements_status: $requirementsStatus
requirements_doc: $requirementsDoc
execution_prompt: $executionPrompt
fast_track_reason: $fastReason
"@
    } else { "" }
    Set-Content -LiteralPath (Join-Path $dir ".task.yaml") -Value @"
phase: $phase
project_type: other
clarification_status: $clarificationStatus
user_confirmed_plan: true
router_skill_loaded: true
$requirementsYaml
review_result: pass
verify_result: $verifyResult
verification_report: $reportValue
archived: false
fix_attempts: 0
"@

    $externalText = if ($ExternalWorkers) { "yes" } else { "no" }
    $workPackagePolicy = if ($MissingWorkPackagePolicy) { "" } else {
@"

## Work Package Policy
- External workers: $externalText
- Task packet root: $RootName/$Scope/$Name
- Work packages required: $externalText
- Claim files required: $externalText
- Worker reports required before merge: $externalText
"@
    }

    $requirementRouting = if ($RequirementProfile -eq "deep") {
@"

## Requirement Discovery Gate
- Change profile: deep
- Requirements status: confirmed
- Requirements document: requirements.md
- Execution prompt: execution-prompt.md
- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none
"@
    }
    elseif ($RequirementProfile -eq "fast") {
        $reason = if ($MissingFastTrackReason) { "" } else { "Bounded exact fix with no architecture, data ownership, or user-journey impact." }
@"

## Fast Track Assessment
- Change profile: fast
- Expected behavior is concrete: yes
- Change is bounded: yes
- Architecture or data ownership change: no
- User journey redesign: no
- Unresolved high-impact implicit requirements: none
- Verification is bounded: yes
- Fast-track reason: $reason
- Execution prompt: execution-prompt.md
"@
    }
    else { "" }

    Set-Content -LiteralPath (Join-Path $dir "routing.md") -Value @"
# Routing

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
$requirementRouting
$workPackagePolicy
"@

    $analysis = if ($WeakAnalysis) {
        "# Analysis`n`n## Mature Solution Evidence`n"
    } else {
@"
# Analysis

## Architecture Context

### System boundaries
- Shared workflow regression only.

### Dependency map
- task packet -> task-guard -> doc-guard.

### Data and state ownership
- Task state lives in .task.yaml.

### Integration points
- Docs/AI and .trae/scripts.

## Mature Solution Evidence

### Project-local evidence
- Existing workflow docs define phase gates.

### Official/framework evidence
- Shared PowerShell guards are the framework for this repository.

### External mature references
- Anthropic agent workflow patterns already recorded in Docs/AI/29.

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Mechanical gate | Docs/AI | Enforceable | Requires task files | Selected |
| Reminder only | Conversation | Easy | Forgotten under context drift | Rejected |

### Rejected shortcuts
- Do not allow placeholder analysis.

### Selected mature path
- Enforce quality, architecture, and verification evidence in task-guard.

## Acceptance Criteria
- AC01: Plan gate blocks missing architecture evidence.
- AC02: Verify gate blocks weak evidence reports.

## Automated Verification Plan
- Command: powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
- Expected: PASS for all regression scenarios.
"@
    }
    Set-Content -LiteralPath (Join-Path $dir "analysis.md") -Value $analysis
    Set-Content -LiteralPath (Join-Path $dir "spec.md") -Value "# Spec`n`n## Progress Summary`n"

    $taskCheck = if ($VerifyMode -or $CompleteTasks) { "x" } else { " " }
    Set-Content -LiteralPath (Join-Path $dir "tasks.md") -Value @"
- [$taskCheck] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [$taskCheck] Run automated verification and record command output in verification-report.md.
- [$taskCheck] Map implementation result to Acceptance Criteria in verification-report.md.
"@

    Set-Content -LiteralPath (Join-Path $dir "doc-impact.md") -Value @"
## Project Document Scope
- Project: _shared
- System: Workflow regression
- Owner: test

## Code Changes
- None

## No Code Changes
Reason: workflow regression fixture

## Documentation Updates
- Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md

## Docs Tree Updates
- None
"@

    if ($RequirementProfile -and -not $MissingRequirementsDocument) {
        Set-Content -LiteralPath (Join-Path $dir "requirements.md") -Value @"
# Requirement Understanding

## Desired Outcome
- Prevent premature implementation.

## Intended User and Context
- A non-technical decision maker working with a planning agent.

## End-to-End Experience
- Clarify, teach back, confirm, then generate execution artifacts.

## Confirmed Decisions
- The selected change profile is $RequirementProfile.

## Implicit Requirements
- The planner owns technical translation.

## Boundaries and Non-Goals
- Do not infer unresolved high-impact choices.

## Success Experience
- The user recognizes the described outcome as their intent.

## Open Questions
None.

## Teach-Back Summary
- The agent understands the goal and may proceed to technical planning.

## User Confirmation Evidence
- Confirmed in the planning conversation.
"@
    }

    if ($RequirementProfile -and -not $MissingExecutionPrompt) {
        Set-Content -LiteralPath (Join-Path $dir "execution-prompt.md") -Value @"
# Task Execution Prompt

## Role
- Execute the approved task packet without changing its intent.

## Goal
- Implement the confirmed requirement.

## Task Packet Truth Sources
- requirements.md
- analysis.md
- spec.md
- tasks.md

## Confirmed Decisions
- Respect the selected $RequirementProfile profile.

## Accepted Architecture
- Follow analysis.md.

## Allowed Paths
- .trae/tasks/_shared/$Name/

## Forbidden Paths
- Project/

## Non-Goals
- Do not change acceptance criteria.

## Acceptance Criteria
- AC01: Gate behavior is correct.

## Verification Commands
- regression -> pass

## Stop Conditions
- Stop if the task packet is incomplete.

## Evidence Rule
- Do not claim success without current-session evidence.
"@
    }

    if ($OutsideArtifactPaths) {
        Copy-Item -LiteralPath (Join-Path $dir "requirements.md") -Destination (Join-Path (Split-Path -Parent $dir) "__outside-requirements.md") -Force
        Copy-Item -LiteralPath (Join-Path $dir "execution-prompt.md") -Destination (Join-Path (Split-Path -Parent $dir) "__outside-execution-prompt.md") -Force
    }

    if ($ExternalWorkers -and $CreateWorkPackage) {
        $wpDir = Join-Path $dir "work-packages"
        New-Item -ItemType Directory -Path $wpDir -Force | Out-Null
        if ($InvalidWorkPackage) {
            Set-Content -LiteralPath (Join-Path $wpDir "WP01-regression.md") -Value "# WP01: <placeholder>"
        }
        else {
            Set-Content -LiteralPath (Join-Path $wpDir "WP01-regression.md") -Value @"
# WP01: Regression fixture

Owner model: unclaimed
Difficulty: simple
Status: unclaimed

## Task Packet
- Root: .trae/tasks/_shared/$Name/
- Parent task: $Name

## Allowed Paths
- .trae/tasks/_shared/$Name/reports/

## Forbidden Paths
- Project/

## Read First
- routing.md
- analysis.md
- spec.md
- tasks.md

## Goal
- Verify that worker package gates reject incomplete evidence.

## Steps
- [ ] Inspect the task packet.
- [ ] Produce the required worker report.

## Done Definition
- A worker report exists with command evidence and no extra scope.

## Required Verification
- Command: powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
- Expected: pass

## Return Report
- Path: reports/regression-WP01-result.md
- Must include changed files, commands run, results, acceptance criteria touched, unresolved risks, and no extra scope.
"@
        }
    }

    if ($ExternalWorkers -and $CreateWorkerReport) {
        $reportDir = Join-Path $dir "reports"
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        $extraScope = if ($BadWorkerReport) { "yes" } else { "no" }
        $risk = if ($BadWorkerReport) { "Worker changed forbidden paths." } else { "None" }
        Set-Content -LiteralPath (Join-Path $reportDir "regression-WP01-result.md") -Value @"
# Result: regression WP01

Task packet: .trae/tasks/_shared/$Name/
Work package: work-packages/WP01-regression.md
Status: done

## Changed Files
- .trae/tasks/_shared/$Name/reports/regression-WP01-result.md - evidence fixture

## Commands Run
| Command | Result | Notes |
|---|---|---|
| regression | pass | fixture |

## Acceptance Criteria Touched
- AC01: pass - worker evidence returned.

## Scope Control
- Extra scope taken: $extraScope

## Unresolved Risks
- $risk
"@
    }

    if ($VerifyMode) {
        $report = if ($WeakReport) {
            "# Verification Report`n`nLooks good."
        } else {
@"
# Verification Report: $Name

Verification Result: pass

## Automated Verification
| Command | Result | Evidence |
|---|---|---|
| regression | pass | fixture |

## Acceptance Criteria
| ID | Requirement | Result | Evidence |
|---|---|---|---|
| AC01 | Gate checks | pass | fixture |

## Architecture Compliance
- Selected mature path followed: yes
- Rejected shortcuts reintroduced: no

## Test Evidence
- Regression fixture executed.

## Residual Risk
- None
"@
        }
        Set-Content -LiteralPath (Join-Path $dir "verification-report.md") -Value $report
    }

    return $dir
}

Push-Location $Root
try {
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $DocGuardTest *> $null
    Add-Result "S01" "documentation-governance-regression" "doc guard enforced" $(if ($LASTEXITCODE -eq 0) { "enforced" } else { "failed" }) ($LASTEXITCODE -eq 0)

    $readme = Get-Content -LiteralPath (Join-Path $Root "Docs\AI\README.md") -Raw
    $cache = Get-Content -LiteralPath (Join-Path $Root "Docs\AI\.cache-manifest.md") -Raw
    $docsIndexed = ($readme -match "33-Multi-Agent-Task-Packet-Workflow") -and ($cache -match "33-Multi-Agent-Task-Packet-Workflow")
    Add-Result "S02" "docs-ai-index-current" "33 indexed" $(if ($docsIndexed) { "indexed" } else { "missing" }) $docsIndexed

    $codexSkill = Test-Path (Join-Path $Root "skills\codex-project-router\SKILL.md")
    Add-Result "S03" "codex-adapter-skill-exists" "skill exists" $(if ($codexSkill) { "exists" } else { "missing" }) $codexSkill

    $valid = New-TaskPacket -Name "__workflow_valid"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_valid" plan *> $null
    Add-Result "S04" "valid-task-packet-plan-pass" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $valid

    $stateInitDir = Join-Path $Root ".trae\tasks\_shared\__requirements_state_init"
    Remove-TestDir $stateInitDir
    New-Item -ItemType Directory -Path $stateInitDir -Force | Out-Null
    $TaskState = Join-Path $PSScriptRoot "task-state.ps1"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskState init "_shared/__requirements_state_init" full *> $null
    $stateYaml = Get-Content -LiteralPath (Join-Path $stateInitDir ".task.yaml") -Raw
    $stateFieldsPresent =
        ($stateYaml -match "(?m)^requirements_gate_version:\s*1\s*$") -and
        ($stateYaml -match "(?m)^change_profile:\s*unclassified\s*$") -and
        ($stateYaml -match "(?m)^requirements_status:\s*pending\s*$") -and
        ($stateYaml -match "(?m)^requirements_doc:\s*null\s*$") -and
        ($stateYaml -match "(?m)^execution_prompt:\s*null\s*$") -and
        ($stateYaml -match "(?m)^fast_track_reason:\s*null\s*$")
    Add-Result "RQ01" "new-task-initializes-requirement-gate-metadata" "all fields present" $(if ($stateFieldsPresent) { "present" } else { "missing" }) $stateFieldsPresent
    Remove-TestDir $stateInitDir

    $deepMissingRequirements = New-TaskPacket -Name "__requirements_deep_missing_doc" -RequirementProfile deep -MissingRequirementsDocument $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_deep_missing_doc" plan *> $null
    Add-Result "RQ02" "deep-task-missing-requirements-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $deepMissingRequirements

    $deepMissingPrompt = New-TaskPacket -Name "__requirements_deep_missing_prompt" -RequirementProfile deep -MissingExecutionPrompt $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_deep_missing_prompt" plan *> $null
    Add-Result "RQ03" "deep-task-missing-execution-prompt-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $deepMissingPrompt

    $deepValid = New-TaskPacket -Name "__requirements_deep_valid" -RequirementProfile deep
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_deep_valid" plan *> $null
    Add-Result "RQ04" "complete-deep-requirement-packet-passes" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $deepValid

    $fastMissingReason = New-TaskPacket -Name "__requirements_fast_missing_reason" -RequirementProfile fast -MissingFastTrackReason $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_fast_missing_reason" plan *> $null
    Add-Result "RQ05" "fast-task-missing-reason-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $fastMissingReason

    $fastValid = New-TaskPacket -Name "__requirements_fast_valid" -RequirementProfile fast
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_fast_valid" plan *> $null
    Add-Result "RQ06" "complete-fast-requirement-packet-passes" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $fastValid

    $outsideArtifacts = New-TaskPacket -Name "__requirements_outside_artifacts" -RequirementProfile deep -OutsideArtifactPaths $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__requirements_outside_artifacts" plan *> $null
    Add-Result "RQ07" "requirement-artifacts-outside-task-packet-block" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $outsideArtifacts
    Remove-Item -LiteralPath (Join-Path $Root ".trae\tasks\_shared\__outside-requirements.md") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Root ".trae\tasks\_shared\__outside-execution-prompt.md") -Force -ErrorAction SilentlyContinue

    $smartRequirements = Get-Content -LiteralPath (Join-Path $Root "skills\smart-requirements\SKILL.md") -Raw
    $jinliPlannerPath = Get-ChildItem -LiteralPath (Join-Path $Root "skills") -Directory |
        ForEach-Object {
            $candidate = Join-Path $_.FullName "SKILL.md"
            if (Test-Path -LiteralPath $candidate) {
                $candidateContent = Get-Content -LiteralPath $candidate -Raw
                if ($candidateContent -match "Plan Agent" -and $candidateContent -match "soul_auto" -and $candidateContent -match "Mature Solution Evidence") {
                    $candidate
                }
            }
        } |
        Select-Object -First 1
    $jinliPlanner = if ($jinliPlannerPath) { Get-Content -LiteralPath $jinliPlannerPath -Raw } else { "" }
    $skillContractPresent =
        ($smartRequirements -match "one-question-per-turn") -and
        ($smartRequirements -match "no-fixed-round-limit") -and
        ($smartRequirements -match "execution-prompt\.md") -and
        ($jinliPlanner -match "deep-discovery") -and
        ($jinliPlanner -match "fast-track") -and
        ($jinliPlanner -match "teach-back")
    Add-Result "RQ08" "planner-skills-contain-conversational-contract" "contract present" $(if ($skillContractPresent) { "present" } else { "missing" }) $skillContractPresent

    $weak = New-TaskPacket -Name "__workflow_missing_arch" -WeakAnalysis $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_missing_arch" plan *> $null
    Add-Result "S05" "missing-architecture-context-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $weak

    $missingPolicy = New-TaskPacket -Name "__workflow_missing_policy" -MissingWorkPackagePolicy $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_missing_policy" plan *> $null
    Add-Result "S06" "missing-work-package-policy-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $missingPolicy

    $missingWp = New-TaskPacket -Name "__workflow_external_no_wp" -ExternalWorkers $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_no_wp" plan *> $null
    Add-Result "S07" "external-workers-without-work-package-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $missingWp

    $withWp = New-TaskPacket -Name "__workflow_external_with_wp" -ExternalWorkers $true -CreateWorkPackage $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_with_wp" plan *> $null
    Add-Result "S08" "external-workers-with-work-package-pass" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $withWp

    $badWp = New-TaskPacket -Name "__workflow_external_bad_wp" -ExternalWorkers $true -CreateWorkPackage $true -InvalidWorkPackage $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_bad_wp" plan *> $null
    Add-Result "S09" "external-workers-placeholder-work-package-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $badWp

    $missingWorkerReport = New-TaskPacket -Name "__workflow_external_missing_report" -ExternalWorkers $true -CreateWorkPackage $true -CompleteTasks $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_missing_report" implement *> $null
    Add-Result "S10" "external-workers-missing-report-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $missingWorkerReport

    $badWorkerReport = New-TaskPacket -Name "__workflow_external_bad_report" -ExternalWorkers $true -CreateWorkPackage $true -CompleteTasks $true -CreateWorkerReport $true -BadWorkerReport $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_bad_report" implement *> $null
    Add-Result "S11" "external-workers-extra-scope-report-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $badWorkerReport

    $validWorkerReport = New-TaskPacket -Name "__workflow_external_valid_report" -ExternalWorkers $true -CreateWorkPackage $true -CompleteTasks $true -CreateWorkerReport $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_external_valid_report" implement *> $null
    Add-Result "S12" "external-workers-valid-report-pass" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $validWorkerReport

    $opencode = New-TaskPacket -RootName ".opencode\tasks" -Scope "" -Name "__opencode_workflow_valid"
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "__opencode_workflow_valid" plan *> $null
    Add-Result "S13" "opencode-root-task-plan-pass" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $opencode

    $verify = New-TaskPacket -Name "__workflow_verify_valid" -VerifyMode $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_verify_valid" verify *> $null
    Add-Result "S14" "valid-verification-report-pass" "allowed" $(if ($LASTEXITCODE -eq 0) { "allowed" } else { "blocked" }) ($LASTEXITCODE -eq 0)
    Remove-TestDir $verify

    $weakVerify = New-TaskPacket -Name "__workflow_verify_weak" -VerifyMode $true -WeakReport $true
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TaskGuard "_shared/__workflow_verify_weak" verify *> $null
    Add-Result "S15" "weak-verification-report-blocks" "blocked" $(if ($LASTEXITCODE -ne 0) { "blocked" } else { "allowed" }) ($LASTEXITCODE -ne 0)
    Remove-TestDir $weakVerify

    if (Test-Path $DocsTreeScript) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $DocsTreeScript -Mode check *> $null
        Add-Result "S16" "docs-tree-check" "present" $(if ($LASTEXITCODE -eq 0) { "present" } else { "missing" }) ($LASTEXITCODE -eq 0)
    }

    # --- Codex Capability Consistency Regression (added T5) ---
    $CapabilityBaseline = Join-Path $PSScriptRoot "test-codex-capability-baseline.ps1"
    $SkillDiscovery = Join-Path $PSScriptRoot "test-codex-skill-discovery.ps1"
    $CCSwitchSync = Join-Path $PSScriptRoot "test-ccswitch-codex-config-sync.ps1"

    if (Test-Path $CapabilityBaseline) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $CapabilityBaseline *> $null
        Add-Result "S17" "capability-baseline-schema-pass" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }

    if (Test-Path $SkillDiscovery) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $SkillDiscovery *> $null
        Add-Result "S18" "skill-discovery-all-pass" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }

    if (Test-Path $CCSwitchSync) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $CCSwitchSync -Mode Test *> $null
        Add-Result "S19" "ccswitch-config-sync-pass" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }

    # Validate-codex-capabilities inspect
    $ValidateCapabilities = Join-Path $PSScriptRoot "validate-codex-capabilities.ps1"
    if (Test-Path $ValidateCapabilities) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $ValidateCapabilities -Mode Inspect *> $null
        Add-Result "S20" "validate-codex-capabilities-inspect" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }

    $WorkerRepairLoopRegression = Join-Path $PSScriptRoot "test-worker-repair-loop.ps1"
    if (Test-Path $WorkerRepairLoopRegression) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $WorkerRepairLoopRegression *> $null
        Add-Result "S21" "ds4-worker-repair-loop-pass" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }

    $AuthoritySeparationRegression = Join-Path $PSScriptRoot "test-authority-separation.ps1"
    if (Test-Path $AuthoritySeparationRegression) {
        & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $AuthoritySeparationRegression *> $null
        Add-Result "S22" "issuer-worker-authority-separation-pass" "pass" $(if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }) ($LASTEXITCODE -eq 0)
    }
}
finally {
    Pop-Location
}

$ResultDir = Join-Path $Root ".trae\tasks\_shared\regression-results"
New-Item -ItemType Directory -Path $ResultDir -Force | Out-Null
$ResultPath = Join-Path $ResultDir "workflow-regression.md"
$lines = @(
    "# Workflow Regression Results",
    "",
    "| Scenario | Expected | Actual | Result | Notes |",
    "|---|---|---|---|---|"
)
foreach ($row in $Results) {
    $lines += "| $($row.Scenario) | $($row.Expected) | $($row.Actual) | $($row.Result) | $($row.Notes) |"
}
Set-Content -LiteralPath $ResultPath -Value $lines

if ($Failed) { exit 1 }
exit 0
