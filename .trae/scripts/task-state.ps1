# Task State -- task state machine utilities (Comet style)
# Usage:
#   task-state.ps1 init <task-name> <workflow>
#   task-state.ps1 get <task-name> <field>
#   task-state.ps1 set <task-name> <field> <value>
#   task-state.ps1 memory-gate <task-name> --input-json-path <path> [--decision-path <path>]
#     [T6 patch] Runs the Memory Gate via memory-guard.ps1.
#     Returns 0 on PASS/SKIP, 1 on FAIL, 2 on internal error.
#     Auto-invoked before implement-complete and verify-pass transitions
#     when env var JINLI_MEMORY_GATE_INPUT is set.
#   task-state.ps1 transition <task-name> <event>
#   task-state.ps1 check <task-name> <phase>
#   task-state.ps1 can-edit <task-name>
#   Supports project/task-name format: airpgweb/combat-sandbox-v2

param(
    [Parameter(Mandatory=$true)][string]$Command,
    [Parameter(Mandatory=$true)][string]$TaskName,
    [string]$Arg1,
    [string]$Arg2
)

$ErrorActionPreference = "Stop"

# --- Project-aware path resolution ---
$TASKS_ROOT = ".trae\tasks"
$PROJECTS = @("airpgweb", "characterdesigntool", "rts", "_shared")

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

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Validate-TaskName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { Write-Red "ERROR: Task name cannot be empty"; exit 1 }
    if ($Name -match "\.\.") { Write-Red "ERROR: Task name cannot contain '..'"; exit 1 }
    if ($Name -notmatch '^[a-zA-Z0-9_/-]+$') { Write-Red "ERROR: Invalid task name: '$Name'. Valid: a-z, A-Z, 0-9, -, _, /"; exit 1 }
}

function Validate-Enum {
    param([string]$Value, [string[]]$ValidValues)
    if ($Value -notin $ValidValues) { Write-Red "ERROR: Invalid value '$Value'. Valid: $($ValidValues -join ', ')"; exit 1 }
}

function Get-YamlField {
    param([string]$Field, [string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $line = Select-String -Path $FilePath -Pattern "^${Field}:" | Select-Object -First 1
    if ($null -eq $line) { return $null }
    $value = $line.Line -replace "^${Field}:\s*", ""
    $value = $value.Trim() -replace '^["'']|["'']$', ''
    if ($value -eq "null") { return $null }
    return $value
}

function Set-YamlField {
    param([string]$FilePath, [string]$Field, [string]$Value)
    $content = Get-Content $FilePath -Raw
    $pattern = "(?m)^${Field}:.*$"
    if ($content -match $pattern) { $content = $content -replace $pattern, "${Field}: ${Value}" }
    else { $content = $content.TrimEnd() + "`r`n${Field}: ${Value}`r`n" }
    Set-Content -Path $FilePath -Value $content -NoNewline
}

function New-YamlFile {
    param([string]$FilePath, [string]$Workflow)
    $dir = Split-Path -Parent $FilePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $FilePath) { Write-Red "ERROR: .task.yaml already exists at $FilePath"; exit 1 }
    $baseRef = try { git rev-parse HEAD 2>$null } catch { "null" }
    if (-not $baseRef) { $baseRef = "null" }
    $today = Get-Date -Format "yyyy-MM-dd"
    $buildMode = "null"; $isolation = "null"
    if ($Workflow -eq "hotfix") { $buildMode = "direct"; $isolation = "branch" }
    @"
workflow: $Workflow
phase: plan
project_type: null
implement_mode: $buildMode
isolation: $isolation
clarification_status: pending
user_confirmed_plan: false
router_skill_loaded: false
requirements_gate_version: 1
change_profile: unclassified
requirements_status: pending
requirements_doc: null
execution_prompt: null
fast_track_reason: null
review_result: pending
verify_result: pending
verification_report: null
archived: false
design_doc: null
base_ref: $baseRef
created_at: $today
verified_at: null
fix_attempts: 0
worker_profile: none
lead_verifier: null
repair_loop_status: idle
active_root_cause: null
active_repair_package: null
authority_profile: none
authority_status: legacy
issuer_key_id: null
issuer_sid: null
packet_version: 0
packet_digest: null
legacy_trust: legacy_untrusted
archive_certificate: null
spec_exists: false
spec_scenario_count: 0
spec_scenarios_done: 0
"@ | Set-Content -Path $FilePath -NoNewline
    Write-Green "Initialized: $FilePath (workflow=$Workflow)"
}

function Require-FileExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Red "ERROR: Required file missing: $Path"; exit 1 }
}

function Resolve-TaskArtifactPath {
    param([string]$Value)
    if (-not $Value) { return $null }
    $taskRoot = [System.IO.Path]::GetFullPath($TASK_DIR).TrimEnd("\","/")
    $candidate = if ([System.IO.Path]::IsPathRooted($Value)) {
        [System.IO.Path]::GetFullPath($Value)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $TASK_DIR ($Value -replace "/", "\")))
    }
    $taskPrefix = $taskRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($taskPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    return $candidate
}

function Test-RequirementGateReady {
    param([string]$FilePath, [bool]$WriteEvidence)
    $version = Get-YamlField "requirements_gate_version" $FilePath
    if (-not $version) {
        if ($WriteEvidence) { Write-Host "  [PASS] legacy requirement gate compatibility" -ForegroundColor Green }
        return $true
    }
    if ($version -ne "1") {
        if ($WriteEvidence) { Write-Host "  [FAIL] unsupported requirements_gate_version=$version" -ForegroundColor Red }
        return $false
    }

    $profile = Get-YamlField "change_profile" $FilePath
    $status = Get-YamlField "requirements_status" $FilePath
    $requirementsPath = Resolve-TaskArtifactPath (Get-YamlField "requirements_doc" $FilePath)
    $promptPath = Resolve-TaskArtifactPath (Get-YamlField "execution_prompt" $FilePath)
    $clarification = Get-YamlField "clarification_status" $FilePath
    $fastReason = Get-YamlField "fast_track_reason" $FilePath
    $ready = $true

    if ($profile -notin @("deep","fast")) {
        if ($WriteEvidence) { Write-Host "  [FAIL] change_profile=$profile (expected: deep|fast)" -ForegroundColor Red }
        $ready = $false
    }
    elseif ($WriteEvidence) { Write-Host "  [PASS] change_profile=$profile" -ForegroundColor Green }

    if (-not $promptPath -or -not (Test-Path -LiteralPath $promptPath)) {
        if ($WriteEvidence) { Write-Host "  [FAIL] execution_prompt missing" -ForegroundColor Red }
        $ready = $false
    }
    elseif ($WriteEvidence) { Write-Host "  [PASS] execution_prompt exists" -ForegroundColor Green }

    if ($profile -eq "deep") {
        if ($status -ne "confirmed") {
            if ($WriteEvidence) { Write-Host "  [FAIL] deep task requirements_status=$status (expected: confirmed)" -ForegroundColor Red }
            $ready = $false
        }
        elseif ($WriteEvidence) { Write-Host "  [PASS] requirements_status=confirmed" -ForegroundColor Green }
        if ($clarification -ne "answered") {
            if ($WriteEvidence) { Write-Host "  [FAIL] deep task requires clarification_status=answered" -ForegroundColor Red }
            $ready = $false
        }
        if (-not $requirementsPath -or -not (Test-Path -LiteralPath $requirementsPath)) {
            if ($WriteEvidence) { Write-Host "  [FAIL] deep task requirements_doc missing" -ForegroundColor Red }
            $ready = $false
        }
        elseif ($WriteEvidence) { Write-Host "  [PASS] requirements_doc exists" -ForegroundColor Green }
    }
    elseif ($profile -eq "fast") {
        if ($status -ne "not_required") {
            if ($WriteEvidence) { Write-Host "  [FAIL] fast task requirements_status=$status (expected: not_required)" -ForegroundColor Red }
            $ready = $false
        }
        elseif ($WriteEvidence) { Write-Host "  [PASS] requirements_status=not_required" -ForegroundColor Green }
        if ([string]::IsNullOrWhiteSpace($fastReason)) {
            if ($WriteEvidence) { Write-Host "  [FAIL] fast_track_reason missing" -ForegroundColor Red }
            $ready = $false
        }
        elseif ($WriteEvidence) { Write-Host "  [PASS] fast_track_reason recorded" -ForegroundColor Green }
    }

    return $ready
}

function Test-PlanReady {
    param([string]$FilePath)
    $cs = Get-YamlField "clarification_status" $FilePath
    $ucp = Get-YamlField "user_confirmed_plan" $FilePath
    $rsl = Get-YamlField "router_skill_loaded" $FilePath
    if ($cs -notin @("not_needed","answered")) { Write-Red "ERROR: clarification_status must be not_needed/answered, got '$cs'"; exit 1 }
    if ($ucp -ne "true") { Write-Red "ERROR: user_confirmed_plan must be true"; exit 1 }
    if ($rsl -ne "true") { Write-Red "ERROR: router_skill_loaded must be true"; exit 1 }
    if (-not (Test-RequirementGateReady $FilePath $false)) { Write-Red "ERROR: requirement-understanding gate is not ready"; exit 1 }
}

# T6 patch: Memory Gate helper (spec sec.G.2 + sec.H.1)
# Runs memory-guard.ps1 and returns $true if gate passes (PASS or SKIP),
# $false if it FAILs or errors. Decision report is saved to $DecisionPath.
function Invoke-MemoryGate {
    param(
        [string]$TASK_DIR_LOCAL,
        [string]$InputJsonPath,
        [string]$DecisionPath = ""
    )

    if (-not (Test-Path -LiteralPath $InputJsonPath)) {
        Write-Red "  [MEMORY-GATE] input json not found: $InputJsonPath"
        return $false
    }

    # $PSScriptRoot is the directory containing the running script; works for both
    # dot-sourced and &-invoked cases. Fall back to $MyInvocation.MyCommand.Path
    # for compat, then to script dir inferred from TASK_DIR_LOCAL.
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if (-not $scriptRoot) {
        # Last resort: try TASK_DIR_LOCAL parent
        $scriptRoot = Split-Path -Parent $TASK_DIR_LOCAL
    }
    $guardScript = Join-Path $scriptRoot "memory-guard.ps1"
    if (-not (Test-Path -LiteralPath $guardScript)) {
        Write-Red "  [MEMORY-GATE] memory-guard.ps1 not found at $guardScript"
        return $false
    }

    Write-Yellow "  Running Memory Gate (input=$InputJsonPath)..."
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        # Use a hashtable splat (not array splat) to dodge PowerShell 5.1
        # [CmdletBinding()] array-splat binding bug (where the 1st named value
        # gets re-bound positionally to the 2nd positional param).
        $splat = @{
            TaskName     = "memory-gate"
            InputJsonPath = $InputJsonPath
            Workdir      = (Get-Location).Path
        }
        if ($DecisionPath) { $splat.DecisionPath = $DecisionPath }
        & $guardScript @splat 2>&1 | Out-Null
        $exit = $LASTEXITCODE
    } catch {
        Write-Red "  [MEMORY-GATE] invocation failed: $_"
        $exit = 2
    } finally {
        $ErrorActionPreference = $prevEAP
    }

    if ($exit -eq 0) { Write-Green "  [MEMORY-GATE] PASS/SKIP"; return $true }
    if ($exit -eq 1) { Write-Red "  [MEMORY-GATE] FAIL (exit 1)"; return $false }
    Write-Red "  [MEMORY-GATE] INTERNAL ERROR (exit $exit)"; return $false
}

function Test-ImplementChecks {
    param([string]$FilePath, [bool]$RequirePhaseMatch)
    $localBlocked = $false
    if ($RequirePhaseMatch) {
        $ap = Get-YamlField "phase" $FilePath
        if ($ap -eq "implement") { Write-Host "  [PASS] phase=implement" -ForegroundColor Green }
        else { Write-Host "  [FAIL] phase=$ap (expected: implement)" -ForegroundColor Red; $localBlocked = $true }
    }
    $cs = Get-YamlField "clarification_status" $FilePath
    if ($cs -in @("not_needed","answered")) { Write-Host "  [PASS] clarification_status=$cs" -ForegroundColor Green }
    else { Write-Host "  [FAIL] clarification_status=$cs" -ForegroundColor Red; $localBlocked = $true }
    $ucp = Get-YamlField "user_confirmed_plan" $FilePath
    if ($ucp -eq "true") { Write-Host "  [PASS] user_confirmed_plan=true" -ForegroundColor Green }
    else { Write-Host "  [FAIL] user_confirmed_plan=$ucp" -ForegroundColor Red; $localBlocked = $true }
    $rsl = Get-YamlField "router_skill_loaded" $FilePath
    if ($rsl -eq "true") { Write-Host "  [PASS] router_skill_loaded=true" -ForegroundColor Green }
    else { Write-Host "  [FAIL] router_skill_loaded=$rsl" -ForegroundColor Red; $localBlocked = $true }
    if (-not (Test-RequirementGateReady $FilePath $true)) { $localBlocked = $true }
    $authorityProfile = Get-YamlField "authority_profile" $FilePath
    $issuerSid = Get-YamlField "issuer_sid" $FilePath
    if ($authorityProfile -eq "issuer-worker-v1" -and $issuerSid) {
        $currentSid = if ($env:JINLI_AUTH_TEST_MODE -eq "1" -and $env:JINLI_AUTH_TEST_SID) {
            $env:JINLI_AUTH_TEST_SID
        }
        else {
            [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        }
        if ($currentSid -eq $issuerSid) {
            Write-Host "  [PASS] authority issuer SID matches" -ForegroundColor Green
        }
        else {
            Write-Host "  [FAIL] authority task edits require issuer SID" -ForegroundColor Red
            $localBlocked = $true
        }
    }
    $tasksFile = Join-Path $TASK_DIR "tasks.md"
    if (Test-Path $tasksFile) { Write-Host "  [PASS] tasks.md exists" -ForegroundColor Green }
    else { Write-Host "  [FAIL] tasks.md missing" -ForegroundColor Red; $localBlocked = $true }
    $specFile = Join-Path $TASK_DIR "spec.md"
    if (Test-Path $specFile) {
        Write-Host "  [PASS] spec.md exists" -ForegroundColor Green
        $sc = Get-Content -LiteralPath $specFile -Raw
        if ($sc -match '###\s+S\d+') { Write-Host "  [PASS] spec.md has scenarios" -ForegroundColor Green }
        else { Write-Host "  [WARN] spec.md has no scenarios" -ForegroundColor Yellow }
    } else { Write-Host "  [WARN] spec.md missing" -ForegroundColor Yellow }
    return (-not $localBlocked)
}

Validate-TaskName $TaskName

switch ($Command) {
    "init" {
        Validate-Enum $Arg1 @("full","hotfix")
        New-YamlFile $YAML_FILE $Arg1
    }
    "get" {
        Require-FileExists $YAML_FILE
        $val = Get-YamlField $Arg1 $YAML_FILE
        Write-Output $val
    }
    "set" {
        Require-FileExists $YAML_FILE
        $field = $Arg1; $value = $Arg2
        $validFields = @("workflow","implement_mode","isolation","clarification_status","user_confirmed_plan","router_skill_loaded","requirements_gate_version","change_profile","requirements_status","requirements_doc","execution_prompt","fast_track_reason","design_doc","created_at","verified_at","base_ref","project_type","fix_attempts","worker_profile","lead_verifier","repair_loop_status","active_root_cause","active_repair_package","spec_exists","spec_scenario_count","spec_scenarios_done")
        if ($field -notin $validFields) { Write-Red "ERROR: Unknown field '$field'. Valid: $($validFields -join ', ')"; exit 1 }
        $enumMap = @{
            "workflow"=@("full","hotfix")
            "implement_mode"=@("direct","subagent")
            "isolation"=@("branch","worktree")
            "clarification_status"=@("pending","not_needed","asked","answered")
            "user_confirmed_plan"=@("true","false")
            "router_skill_loaded"=@("true","false")
            "requirements_gate_version"=@("1")
            "change_profile"=@("unclassified","deep","fast")
            "requirements_status"=@("pending","confirmed","not_required")
            "project_type"=@("ue5","web","other")
            "worker_profile"=@("none","ds4-flash")
            "repair_loop_status"=@("idle","repair_required","architecture_review","resolved")
        }
        if ($enumMap.ContainsKey($field)) { Validate-Enum $value $enumMap[$field] }
        Set-YamlField $YAML_FILE $field $value
        Write-Green "[SET] ${field}=${value}"
    }
    "transition" {
        Require-FileExists $YAML_FILE
        $event = $Arg1
        Validate-Enum $event @("plan-complete","implement-complete","review-pass","review-fail","verify-pass","verify-fail","archived")
        function Require-Phase { param([string]$Expected); $actual = Get-YamlField "phase" $YAML_FILE; if ($actual -ne $Expected) { Write-Red "ERROR: expected phase '$Expected', got '$actual'"; exit 1 } }
        function Require-ReviewEvidence {
            $report = Get-YamlField "verification_report" $YAML_FILE
            $reportPath = if ($report -and [System.IO.Path]::IsPathRooted($report)) { $report } else { Join-Path $TASK_DIR $report }
            if (-not $report -or -not (Test-Path -LiteralPath $reportPath)) {
                Write-Red "ERROR: verification_report must point to existing file"
                exit 1
            }
        }
        $workerProfile = Get-YamlField "worker_profile" $YAML_FILE
        $authorityProfile = Get-YamlField "authority_profile" $YAML_FILE
        if ($authorityProfile -eq "issuer-worker-v1" -and $event -ne "plan-complete") {
            Write-Red "ERROR: Authority-managed tasks cannot use generic transitions. Use issuer packet, review, and archive commands."
            exit 1
        }
        if ($event -in @("review-pass","verify-pass","archived")) {
            Write-Red "ERROR: Review, Verify, and Archive acceptance require issuer-signed commands"
            exit 1
        }
        if ($workerProfile -eq "ds4-flash" -and $event -in @("review-fail","verify-fail")) {
            Write-Red "ERROR: DS4 failures must use worker-repair-loop.ps1 record-failure so evidence and repair packages cannot be skipped"
            exit 1
        }
        switch ($event) {
            "plan-complete" { Require-Phase "plan"; Test-PlanReady $YAML_FILE; Set-YamlField $YAML_FILE "phase" "implement" }
            "implement-complete" {
                Require-Phase "implement"
                # T6 patch: run Memory Gate before transitioning (opt-in via env var)
        if ($env:JINLI_MEMORY_GATE_INPUT -and -not $env:JINLI_MEMORY_GATE_SKIP) {
            $decisionPath = Join-Path $TASK_DIR "memory-decision.json"
            $inputPath = $env:JINLI_MEMORY_GATE_INPUT
            if (-not [System.IO.Path]::IsPathRooted($inputPath)) {
                $inputPath = Join-Path (Get-Location) $inputPath
            }
            $ok = Invoke-MemoryGate -TASK_DIR_LOCAL $TASK_DIR -InputJsonPath $inputPath -DecisionPath $decisionPath
            if (-not $ok) {
                Write-Red "  BLOCKED: Memory Gate FAILED -- transition implement-complete aborted"
                Write-Red "  Fix: set JINLI_MEMORY_GATE_SKIP=1 to bypass, or call Lead.approve() to write memory first"
                exit 1
            }
        }
                Set-YamlField $YAML_FILE "phase" "review"
                Set-YamlField $YAML_FILE "review_result" "pending"
                $specFile = Join-Path $TASK_DIR "spec.md"
                if (Test-Path $specFile) {
                    $sc = Get-Content -LiteralPath $specFile -Raw
                    $tm = [regex]::Matches($sc, '###\s+S\d+'); $dm = [regex]::Matches($sc, '\*\*Status\*\*:\s*\[x\]')
                    if ($tm.Count -gt 0) { Set-YamlField $YAML_FILE "spec_scenario_count" $tm.Count; Set-YamlField $YAML_FILE "spec_scenarios_done" $dm.Count; Write-Yellow "  Spec: $($dm.Count)/$($tm.Count) scenarios complete" }
                }
            }
            "review-pass" {
                Require-Phase "review"
                Set-YamlField $YAML_FILE "review_result" "pass"
                Set-YamlField $YAML_FILE "phase" "verify"
                Set-YamlField $YAML_FILE "verify_result" "pending"
                if ($workerProfile -ne "ds4-flash") {
                    Set-YamlField $YAML_FILE "verification_report" "null"
                }
            }
            "review-fail" { Require-Phase "review"; Set-YamlField $YAML_FILE "review_result" "fail"; Set-YamlField $YAML_FILE "phase" "implement" }
            "verify-pass" {
                Require-Phase "verify"; Require-ReviewEvidence
                # T6 patch: run Memory Gate before transitioning to archive (opt-in via env var)
                if ($env:JINLI_MEMORY_GATE_INPUT -and -not $env:JINLI_MEMORY_GATE_SKIP) {
                    $decisionPath = Join-Path $TASK_DIR "memory-decision.json"
                    $inputPath = $env:JINLI_MEMORY_GATE_INPUT
                    if (-not [System.IO.Path]::IsPathRooted($inputPath)) {
                        $inputPath = Join-Path (Get-Location) $inputPath
                    }
                    $ok = Invoke-MemoryGate -TASK_DIR_LOCAL $TASK_DIR -InputJsonPath $inputPath -DecisionPath $decisionPath
                    if (-not $ok) {
                        Write-Red "  BLOCKED: Memory Gate FAILED -- transition verify-pass aborted"
                        Write-Red "  Fix: set JINLI_MEMORY_GATE_SKIP=1 to bypass, or call Lead.approve() to write memory first"
                        exit 1
                    }
                }
                Set-YamlField $YAML_FILE "verify_result" "pass"
                Set-YamlField $YAML_FILE "phase" "archive"
                Set-YamlField $YAML_FILE "verified_at" (Get-Date -Format "yyyy-MM-dd")
            }
            "verify-fail" { Require-Phase "verify"; Set-YamlField $YAML_FILE "verify_result" "fail"; Set-YamlField $YAML_FILE "phase" "implement" }
            "archived" {
                Require-Phase "archive"
                # T6 patch: also gate the final archive step (opt-in)
                if ($env:JINLI_MEMORY_GATE_INPUT -and -not $env:JINLI_MEMORY_GATE_SKIP) {
                    $decisionPath = Join-Path $TASK_DIR "memory-decision.json"
                    $inputPath = $env:JINLI_MEMORY_GATE_INPUT
                    if (-not [System.IO.Path]::IsPathRooted($inputPath)) {
                        $inputPath = Join-Path (Get-Location) $inputPath
                    }
                    $ok = Invoke-MemoryGate -TASK_DIR_LOCAL $TASK_DIR -InputJsonPath $inputPath -DecisionPath $decisionPath
                    if (-not $ok) {
                        Write-Red "  BLOCKED: Memory Gate FAILED -- transition archived aborted"
                        exit 1
                    }
                }
                Set-YamlField $YAML_FILE "archived" "true"
            }
        }
        Write-Green "[TRANSITION] $event"
    }
    "memory-gate" {
        # T6 patch: standalone memory-gate subcommand (sec.G.2)
        # Usage: task-state.ps1 memory-gate <task> --input-json-path <path> [--decision-path <path>]
        # Or via env var: set JINLI_MEMORY_GATE_INPUT=<path> then call transition (auto-invoked).
        Require-FileExists $YAML_FILE
        $inputPath = $Arg1
        $decisionPath = $Arg2
        if (-not $inputPath) { Write-Red "ERROR: memory-gate requires --input-json-path <path>"; exit 1 }
        # Resolve to absolute paths so memory-guard.ps1 doesn't depend on CWD
        if (-not [System.IO.Path]::IsPathRooted($inputPath)) {
            $inputPath = Join-Path (Get-Location) $inputPath
        }
        if ($decisionPath -and -not [System.IO.Path]::IsPathRooted($decisionPath)) {
            $decisionPath = Join-Path (Get-Location) $decisionPath
        }
        $ok = Invoke-MemoryGate -TASK_DIR_LOCAL $TASK_DIR -InputJsonPath $inputPath -DecisionPath $decisionPath
        if ($ok) { exit 0 } else { exit 1 }
    }
    "check" {
        Require-FileExists $YAML_FILE
        $phase = $Arg1
        Validate-Enum $phase @("plan","implement","review","verify","archive")
        Write-Host "=== Entry Check: task-$phase ==="
        $blocked = $false
        function check-pass { Write-Host "  [PASS] $($args[0])" -ForegroundColor Green }
        function check-fail { Write-Host "  [FAIL] $($args[0])" -ForegroundColor Red; $script:blocked = $true }
        $ap = Get-YamlField "phase" $YAML_FILE
        if ($ap -eq $phase) { check-pass "phase=$phase" } else { check-fail "phase=$ap (expected: $phase)" }
        if ($phase -eq "implement") { if (-not (Test-ImplementChecks $YAML_FILE $false)) { $script:blocked = $true } }
        if ($phase -eq "review") { $tf = Join-Path $TASK_DIR "tasks.md"; if (Test-Path $tf) { check-pass "tasks.md exists" } else { check-fail "tasks.md missing" } }
        if ($phase -eq "verify") { $vr = Get-YamlField "verify_result" $YAML_FILE; if ($vr -eq "pending" -or -not $vr) { check-pass "verify_result=pending" } else { check-fail "verify_result=$vr (expected: pending)" } }
        if ($phase -eq "archive") { $vr = Get-YamlField "verify_result" $YAML_FILE; if ($vr -eq "pass") { check-pass "verify_result=pass" } else { check-fail "verify_result=$vr (expected: pass)" }; $ar = Get-YamlField "archived" $YAML_FILE; if ($ar -ne "true") { check-pass "archived=$ar (not yet)" } else { check-fail "archived=true (already)" } }
        Write-Host ""
        if ($blocked) { Write-Red "BLOCKED - fix failing checks"; exit 1 } else { Write-Green "ALL CHECKS PASSED"; exit 0 }
    }
    "can-edit" {
        Require-FileExists $YAML_FILE
        Write-Host "=== Edit Gate Check ==="
        if (Test-ImplementChecks $YAML_FILE $true) { Write-Green "EDIT AUTHORIZED"; exit 0 }
        Write-Red "BLOCKED - editing not authorized"; exit 1
    }
    default { Write-Red "ERROR: Unknown command '$Command'. Use: init, get, set, transition, check, can-edit"; exit 1 }
}
