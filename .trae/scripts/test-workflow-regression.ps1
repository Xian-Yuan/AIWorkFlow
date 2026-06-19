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
        [bool]$WeakReport = $false
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
    Set-Content -LiteralPath (Join-Path $dir ".task.yaml") -Value @"
phase: $phase
project_type: other
clarification_status: not_needed
user_confirmed_plan: true
router_skill_loaded: true
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

    Set-Content -LiteralPath (Join-Path $dir "routing.md") -Value @"
# Routing

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
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
