# Task Handoff Generator
# Usage:
#   task-handoff.ps1 <task-name>
#   task-handoff.ps1 <task-name> -Direction plan-to-implement
#   Supports project/task-name format: airpgweb/combat-sandbox-v2

param(
    [Parameter(Mandatory=$true)][string]$TaskName,
    [ValidateSet("auto","plan-to-implement","implement-to-review","review-to-verify")]
    [string]$Direction = "auto"
)

$ErrorActionPreference = "Stop"

# --- Project-aware path resolution ---
$TASKS_ROOT = ".trae\tasks"
$PROJECTS = @("airpgweb","characterdesigntool","rts","_shared")

function Resolve-TaskPath {
    param([string]$Name)
    if ($Name -match "^(.+?)/(.+)$") {
        $project = $matches[1]; $task = $matches[2]
        $dir = Join-Path $TASKS_ROOT "$project\$task"
        if (Test-Path $dir) { return @{ Project=$project; Task=$task; Dir=$dir; Yaml=Join-Path $dir ".task.yaml" } }
        Write-Red "ERROR: Task not found: $Name ($dir)"; exit 1
    }
    foreach ($p in $PROJECTS) {
        $dir = Join-Path $TASKS_ROOT "$p\$Name"
        if (Test-Path $dir) { return @{ Project=$p; Task=$Name; Dir=$dir; Yaml=Join-Path $dir ".task.yaml" } }
    }
    Write-Red "ERROR: Task not found: $Name"; exit 1
}

$resolved = Resolve-TaskPath $TaskName
$TASK_DIR = $resolved.Dir
$YAML_FILE = $resolved.Yaml

function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Red { Write-Host $args[0] -ForegroundColor Red }

function Get-YamlField {
    param([string]$Field, [string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $line = Select-String -Path $FilePath -Pattern "^${Field}:" | Select-Object -First 1
    if ($null -eq $line) { return $null }
    $value = $line.Line -replace "^${Field}:\s*",""
    $value = $value.Trim() -replace '^["'']|["'']$',''
    if ($value -eq "null") { return $null }
    return $value
}

if (-not (Test-Path $YAML_FILE)) {
    Write-Red "ERROR: .task.yaml not found at $YAML_FILE"
    Write-Red "HINT: Run 'task-state.ps1 init $TaskName full' first"
    exit 1
}

$phase = Get-YamlField "phase" $YAML_FILE
$projectType = Get-YamlField "project_type" $YAML_FILE
$workflow = Get-YamlField "workflow" $YAML_FILE
$workerProfile = Get-YamlField "worker_profile" $YAML_FILE
$activeRepairPackage = Get-YamlField "active_repair_package" $YAML_FILE
$authorityProfile = Get-YamlField "authority_profile" $YAML_FILE

if ($Direction -eq "auto") {
    switch ($phase) {
        "plan"      { $Direction = "plan-to-implement" }
        "implement" { $Direction = "implement-to-review" }
        "review"    { $Direction = "review-to-verify" }
        default     { Write-Red "ERROR: Cannot auto-detect direction. Phase: $phase"; exit 1 }
    }
}

function Get-ChangedFiles {
    $added = @(); $modified = @()
    try {
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($gitRoot) {
            $status = git diff --name-status HEAD 2>$null
            if ($status) {
                foreach ($line in $status -split "`n") {
                    if ($line -match '^A\s+(.+)$') { $added += $matches[1] }
                    elseif ($line -match '^M\s+(.+)$') { $modified += $matches[1] }
                }
            }
            $untracked = git ls-files --others --exclude-standard 2>$null
            if ($untracked) { foreach ($f in $untracked -split "`n") { if ($f) { $added += $f } } }
        }
    } catch {}
    return @{ added=$added; modified=$modified }
}

$handoff = ""
$modelHint = ""
$nextPhase = ""

switch ($Direction) {
    "plan-to-implement" {
        $nextPhase = "implement"; $modelHint = "Flash"
        $routingMd = Join-Path $TASK_DIR "routing.md"
        $tasksMd = Join-Path $TASK_DIR "tasks.md"
        $specMd = Join-Path $TASK_DIR "spec.md"
        $routingExists = Test-Path $routingMd
        $tasksExists = Test-Path $tasksMd
        $specExists = Test-Path $specMd
        $specSummary = ""
        if ($specExists) {
            $sc = Get-Content -LiteralPath $specMd -Raw
            $tm = [regex]::Matches($sc,'###\s+S\d+')
            $im = [regex]::Matches($sc,'\*\*Status\*\*:\s*\[/\]')
            $dm = [regex]::Matches($sc,'\*\*Status\*\*:\s*\[x\]')
            $pc = $tm.Count - $im.Count - $dm.Count
            $specSummary = @"

## Spec progress
- Total Scenarios: $($tm.Count)
- Done: $($dm.Count) | In Progress: $($im.Count) | Not Started: $pc
- New Agent reads spec.md -> Quick Status table to understand state
"@
        }
        if ($workerProfile -eq "ds4-flash") {
            $modelHint = "DS4 Flash (fresh context)"
            if ($authorityProfile -eq "issuer-worker-v1") {
                $capabilityDir = Join-Path $TASK_DIR "capabilities"
                $capabilities = if (Test-Path -LiteralPath $capabilityDir) {
                    @(Get-ChildItem -LiteralPath $capabilityDir -Filter "*.capability.json" -File | Sort-Object Name)
                }
                else { @() }
                $capabilityList = if ($capabilities.Count -gt 0) {
                    ($capabilities | ForEach-Object { "- " + (Resolve-Path -LiteralPath $_.FullName -Relative) }) -join "`n"
                }
                else {
                    "- No signed capability exists. Issuer must run worker-capability.ps1 issue."
                }
                $handoff = @"
# Handover: Issuer -> DS4 Flash Worker

## Task Identity
- Task: $TaskName
- Worker profile: ds4-flash
- Authority profile: issuer-worker-v1

## Signed Capabilities
$capabilityList

## Worker Contract
1. Use only the assigned signed capability.
2. Read the work package named by the capability.
3. Modify only capability Allowed Paths.
4. Do not modify `.task.yaml`, task docs, work packages, evidence, approvals, or archive state.
5. Append progress with `worker-submit.ps1 progress`.
6. Submit one final result with `worker-submit.ps1 result`.
7. Report only `working`, `partial`, `blocked`, or `implementation_done`.
8. Review, Verify, repair publication, and Archive belong to the original Issuer.
"@
            }
            else {
            $workPackageDir = Join-Path $TASK_DIR "work-packages"
            $packageFiles = @()
            if ($activeRepairPackage) {
                $candidate = Join-Path $TASK_DIR $activeRepairPackage
                if (Test-Path -LiteralPath $candidate) {
                    $packageFiles = @($candidate)
                }
            }
            if ($packageFiles.Count -eq 0 -and (Test-Path -LiteralPath $workPackageDir)) {
                $packageFiles = @(Get-ChildItem -LiteralPath $workPackageDir -Filter "*.md" -File |
                    Where-Object {
                        $content = Get-Content -LiteralPath $_.FullName -Raw
                        $content -match "(?mi)^Status:\s*(unclaimed|claimed)\s*$"
                    } |
                    Sort-Object Name |
                    Select-Object -ExpandProperty FullName)
            }
            $packageList = if ($packageFiles.Count -gt 0) {
                ($packageFiles | ForEach-Object { "- " + (Resolve-Path -LiteralPath $_ -Relative) }) -join "`n"
            }
            else {
                "- No ready DS4 work package found. Lead must publish one before implementation."
            }
            $handoff = @"
# Handover: Lead -> DS4 Flash Worker

## Task Identity
- Task: $TaskName
- Project type: $projectType
- Worker profile: ds4-flash
- State file: $YAML_FILE

## Assigned Work Packages
$packageList

## Worker Contract
1. Start a fresh context for one work package.
2. Read only the assigned package and its Read First files.
3. Modify only Allowed Paths and honor Forbidden Paths.
4. Work on the package Root Cause ID only; do not redesign the architecture.
5. Run the exact Required Verification command.
6. Write the exact Return Report, including raw command results and Worker Authority.
7. Do not edit tests, acceptance criteria, task state, verification evidence, or Review/Verify results.
8. If blocked, stop and report the smallest reproducible blocker.

## Completion Boundary
- DS4 Flash may report implementation results only.
- Codex lead independently performs Review and Verify.
- A failed lead verification is repackaged through worker-repair-loop.ps1; the worker does not reopen the full plan.
"@
            }
        }
        else {
            $handoff = @"
# Handover: Plan -> Implement

## Task Identity
- Task: $TaskName
- Project type: $projectType
- State file: $YAML_FILE

## Current Phase
- Current: implement (switch to **Flash model**)
- Previous: plan (done, user confirmed)

## Key Context
- routing.md: $routingMd $(if ($routingExists){"OK"}else{"MISSING"})
- tasks.md: $tasksMd $(if ($tasksExists){"OK"}else{"MISSING"})
- spec.md: $specMd $(if ($specExists){"OK"}else{"MISSING"})

## Execution Instructions (paste into new Flash session)
1. Read routing.md for architecture decisions
2. Execute tasks.md items in order
3. Check off each task immediately upon completion
4. Verify compilation before marking done
5. When all done, run: task-handoff.ps1 $TaskName
$specSummary
"@
        }
    }
    "implement-to-review" {
        $nextPhase = "review"; $modelHint = "Pro"
        $files = Get-ChangedFiles
        $addedList = if ($files.added.Count -gt 0) { ($files.added | %{"  - $_"}) -join "`n" } else { "  (none)" }
        $modifiedList = if ($files.modified.Count -gt 0) { ($files.modified | %{"  - $_"}) -join "`n" } else { "  (none)" }
        $specMd = Join-Path $TASK_DIR "spec.md"
        $specSummary = ""
        if (Test-Path $specMd) {
            $sc = Get-Content -LiteralPath $specMd -Raw
            $tm = [regex]::Matches($sc,'###\s+S\d+'); $dm = [regex]::Matches($sc,'\*\*Status\*\*:\s*\[x\]')
            $specSummary = "Spec progress: $($dm.Count)/$($tm.Count) scenarios done"
        }
        if ($authorityProfile -eq "issuer-worker-v1") {
            $modelHint = "Original Issuer (fresh review context)"
            $handoff = @"
# Handover: Worker Submission -> Issuer Review

## Task Identity
- Task: $TaskName
- Authority profile: issuer-worker-v1

## Issuer Contract
1. Start a fresh review context under the original Issuer Windows SID.
2. Verify packet and capability signatures.
3. Independently rerun required tests and build the evidence manifest.
4. Run `issuer-review.ps1 approve` or `issuer-review.ps1 reject`.
5. On reject, publish the repair package only through the Issuer command.
6. Do not archive during Review or Verify.
7. Archive later with `issuer-archive.ps1 archive`.
"@
        }
        elseif ($workerProfile -eq "ds4-flash") {
            $modelHint = "Codex lead/verifier"
            $handoff = @"
# Handover: DS4 Flash Worker -> Codex Review+Verify

## Task Identity
- Task: $TaskName
- Project type: $projectType
- Worker profile: ds4-flash

## Change Summary
### New Files
$addedList

### Modified Files
$modifiedList

### $specSummary

## Independent Acceptance Contract
1. Review every worker report but do not accept its success claims as evidence.
2. Independently rerun the required commands and acceptance criteria.
3. Record verifier role, verifier model, worker model, and verifier context in verification-report.md.
4. On failure, run worker-repair-loop.ps1 record-failure with one Root Cause ID and narrower Allowed Paths.
5. Do not set Review/Verify pass until the relevant task guard passes.
"@
        }
        else {
            $handoff = @"
# Handover: Implement -> Review+Verify

## Task Identity
- Task: $TaskName
- Project type: $projectType

## Current Phase
- Current: review+verify (switch to **Pro model**)
- Previous: implement (done)

## Change Summary
### New Files
$addedList

### Modified Files
$modifiedList

### $specSummary

## Pro Session Instructions (paste into new Pro session)
1. **Code Review** - check cross-file deps, edge cases, code style
2. **Compile Verify** - run build
3. **Fix Issues** - fix compile errors or review findings directly
4. **Output Report** - summary of passed, fixed, known risks
"@
        }
    }
    "review-to-verify" {
        $nextPhase = "verify"
        if ($workerProfile -eq "ds4-flash") {
            $modelHint = "Codex lead/verifier"
            $handoff = @"
# Handover: Codex Review -> Independent Verify

## Task Identity
- Task: $TaskName
- Project type: $projectType
- Worker profile: ds4-flash

## Instructions
1. Continue as the Codex lead that is independent of the DS4 worker context.
2. Rerun automated verification and map evidence to every acceptance criterion.
3. Confirm worker claims were not accepted without verification.
4. Run task-guard.ps1 $TaskName verify before declaring completion.
"@
        }
        else {
            $modelHint = "Pro (same model, no switch)"
            $handoff = @"
# Handover: Review -> Verify

## Task Identity
- Task: $TaskName
- Project type: $projectType

## Current Phase
- Current: verify (Pro model, continue in same session)
- Previous: review (done)

## Instructions
1. Compile verification
2. Runtime smoke test (if applicable)
3. Asset wiring completeness check (UE5)
4. Output verification report
"@
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HANDOFF: $Direction" -ForegroundColor Cyan
Write-Host "  Switch model: $modelHint" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host $handoff
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  How to use:" -ForegroundColor Green
Write-Host "  1. Copy handoff content above" -ForegroundColor White
Write-Host "  2. /clear or open new session" -ForegroundColor White
Write-Host "  3. Switch model to: $modelHint" -ForegroundColor White
Write-Host "  4. Paste handoff as first message" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

$handoffFile = Join-Path $TASK_DIR "handoff-$($Direction -replace '->','-').txt"
$handoff | Set-Content -Path $handoffFile -NoNewline
Write-Host ""
Write-Green "Saved to: $handoffFile"
