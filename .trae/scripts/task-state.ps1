# Task State -- task state machine utilities (Comet style)
# Usage:
#   task-state.ps1 init <task-name> <workflow>
#   task-state.ps1 get <task-name> <field>
#   task-state.ps1 set <task-name> <field> <value>
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
review_result: pending
verify_result: pending
verification_report: null
archived: false
design_doc: null
base_ref: $baseRef
created_at: $today
verified_at: null
fix_attempts: 0
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

function Test-PlanReady {
    param([string]$FilePath)
    $cs = Get-YamlField "clarification_status" $FilePath
    $ucp = Get-YamlField "user_confirmed_plan" $FilePath
    $rsl = Get-YamlField "router_skill_loaded" $FilePath
    if ($cs -notin @("not_needed","answered")) { Write-Red "ERROR: clarification_status must be not_needed/answered, got '$cs'"; exit 1 }
    if ($ucp -ne "true") { Write-Red "ERROR: user_confirmed_plan must be true"; exit 1 }
    if ($rsl -ne "true") { Write-Red "ERROR: router_skill_loaded must be true"; exit 1 }
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
        $validFields = @("phase","workflow","implement_mode","isolation","clarification_status","user_confirmed_plan","router_skill_loaded","review_result","verify_result","verification_report","archived","design_doc","created_at","verified_at","base_ref","project_type","fix_attempts","spec_exists","spec_scenario_count","spec_scenarios_done")
        if ($field -notin $validFields) { Write-Red "ERROR: Unknown field '$field'. Valid: $($validFields -join ', ')"; exit 1 }
        $enumMap = @{
            "phase"=@("plan","implement","review","verify","archive")
            "workflow"=@("full","hotfix")
            "implement_mode"=@("direct","subagent")
            "isolation"=@("branch","worktree")
            "clarification_status"=@("pending","not_needed","asked","answered")
            "user_confirmed_plan"=@("true","false")
            "router_skill_loaded"=@("true","false")
            "review_result"=@("pending","pass","fail")
            "verify_result"=@("pending","pass","fail")
            "archived"=@("true","false")
            "project_type"=@("ue5","web","other")
        }
        if ($enumMap.ContainsKey($field)) { Validate-Enum $value $enumMap[$field] }
        if ($field -eq "phase") { Write-Yellow "WARNING: Setting 'phase' directly bypasses state machine. Use 'transition' instead." }
        Set-YamlField $YAML_FILE $field $value
        Write-Green "[SET] ${field}=${value}"
    }
    "transition" {
        Require-FileExists $YAML_FILE
        $event = $Arg1
        Validate-Enum $event @("plan-complete","implement-complete","review-pass","review-fail","verify-pass","verify-fail","archived")
        function Require-Phase { param([string]$Expected); $actual = Get-YamlField "phase" $YAML_FILE; if ($actual -ne $Expected) { Write-Red "ERROR: expected phase '$Expected', got '$actual'"; exit 1 } }
        function Require-ReviewEvidence { $report = Get-YamlField "verification_report" $YAML_FILE; if (-not $report -or -not (Test-Path $report)) { Write-Red "ERROR: verification_report must point to existing file"; exit 1 } }
        switch ($event) {
            "plan-complete" { Require-Phase "plan"; Test-PlanReady $YAML_FILE; Set-YamlField $YAML_FILE "phase" "implement" }
            "implement-complete" {
                Require-Phase "implement"
                Set-YamlField $YAML_FILE "phase" "review"
                Set-YamlField $YAML_FILE "review_result" "pending"
                $specFile = Join-Path $TASK_DIR "spec.md"
                if (Test-Path $specFile) {
                    $sc = Get-Content -LiteralPath $specFile -Raw
                    $tm = [regex]::Matches($sc, '###\s+S\d+'); $dm = [regex]::Matches($sc, '\*\*Status\*\*:\s*\[x\]')
                    if ($tm.Count -gt 0) { Set-YamlField $YAML_FILE "spec_scenario_count" $tm.Count; Set-YamlField $YAML_FILE "spec_scenarios_done" $dm.Count; Write-Yellow "  Spec: $($dm.Count)/$($tm.Count) scenarios complete" }
                }
            }
            "review-pass" { Require-Phase "review"; Set-YamlField $YAML_FILE "review_result" "pass"; Set-YamlField $YAML_FILE "phase" "verify"; Set-YamlField $YAML_FILE "verify_result" "pending"; Set-YamlField $YAML_FILE "verification_report" "null" }
            "review-fail" { Require-Phase "review"; Set-YamlField $YAML_FILE "review_result" "fail"; Set-YamlField $YAML_FILE "phase" "implement" }
            "verify-pass" { Require-Phase "verify"; Require-ReviewEvidence; Set-YamlField $YAML_FILE "verify_result" "pass"; Set-YamlField $YAML_FILE "phase" "archive"; Set-YamlField $YAML_FILE "verified_at" (Get-Date -Format "yyyy-MM-dd") }
            "verify-fail" { Require-Phase "verify"; Set-YamlField $YAML_FILE "verify_result" "fail"; Set-YamlField $YAML_FILE "phase" "implement" }
            "archived" { Require-Phase "archive"; Set-YamlField $YAML_FILE "archived" "true" }
        }
        Write-Green "[TRANSITION] $event"
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