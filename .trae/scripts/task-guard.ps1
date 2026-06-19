# Task Guard -- Phase exit guard (Comet style)
# Usage: task-guard.ps1 <task-name> <phase> [-Apply]
# Phase: plan | implement | review | verify | archive
# Supports project/task-name format: airpgweb/combat-sandbox-v2

param(
    [Parameter(Mandatory=$true)][string]$TaskName,
    [Parameter(Mandatory=$true)][string]$Phase,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

# --- Project-aware path resolution ---
$TASK_ROOTS = @(".trae\tasks", ".opencode\tasks", ".codex\tasks")
$PROJECTS = @("airpgweb","characterdesigntool","rts","_shared")

function Resolve-TaskPath {
    param([string]$Name)
    $checked = @()

    if ($Name -match "^(.+?)/(.+)$") {
        $project = $matches[1]; $task = $matches[2]
        foreach ($root in $TASK_ROOTS) {
            $dir = Join-Path $root "$project\$task"
            $checked += $dir
            if (Test-Path $dir) {
                return @{ Project=$project; Task=$task; Dir=$dir; Yaml=Join-Path $dir ".task.yaml"; Root=$root }
            }
        }
    }

    foreach ($root in $TASK_ROOTS) {
        $direct = Join-Path $root $Name
        $checked += $direct
        if (Test-Path $direct) {
            return @{ Project=""; Task=$Name; Dir=$direct; Yaml=Join-Path $direct ".task.yaml"; Root=$root }
        }

        foreach ($p in $PROJECTS) {
            $dir = Join-Path $root "$p\$Name"
            $checked += $dir
            if (Test-Path $dir) {
                return @{ Project=$p; Task=$Name; Dir=$dir; Yaml=Join-Path $dir ".task.yaml"; Root=$root }
            }
        }
    }

    Write-Red "ERROR: Task not found: $Name"
    foreach ($path in $checked) { Write-Red "  checked: $path" }
    exit 1
}

$resolved = Resolve-TaskPath $TaskName
$TASK_DIR = $resolved.Dir
$YAML_FILE = $resolved.Yaml

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

$BLOCKED = $false

function Test-Check {
    param([string]$Desc, [scriptblock]$Condition)
    try {
        $result = & $Condition
        if ($result) { Write-Green "  [PASS] $Desc" }
        else { Write-Red "  [FAIL] $Desc"; $script:BLOCKED = $true }
    } catch {
        Write-Red "  [FAIL] $Desc"; Write-Red "    $_"; $script:BLOCKED = $true
    }
}

function Get-YamlField {
    param([string]$Field)
    if (-not (Test-Path $YAML_FILE)) { return $null }
    $line = Select-String -Path $YAML_FILE -Pattern "^${Field}:" | Select-Object -First 1
    if ($null -eq $line) { return $null }
    $value = $line.Line -replace "^${Field}:\s*",""
    $value = $value.Trim() -replace '^["'']|["'']$',''
    if ($value -eq "null") { return $null }
    return $value
}

function Set-YamlField {
    param([string]$Field, [string]$Value)
    $content = Get-Content $YAML_FILE -Raw
    $pattern = "(?m)^${Field}:.*$"
    if ($content -match $pattern) { $content = $content -replace $pattern, "${Field}: ${Value}" }
    else { $content = $content.TrimEnd() + "`r`n${Field}: ${Value}`r`n" }
    Set-Content -Path $YAML_FILE -Value $content -NoNewline
}

function Tasks-All-Done {
    $tf = Join-Path $TASK_DIR "tasks.md"
    if (-not (Test-Path $tf)) { Write-Red "tasks.md missing at $tf"; return $false }
    $c = Get-Content $tf -Raw
    if ($c -notmatch '-\s+\[x\]') { Write-Red "tasks.md has no completed tasks"; return $false }
    if ($c -match '-\s+\[\s\]') { Write-Red "Unfinished tasks remain in tasks.md"; return $false }
    return $true
}

function Tasks-Has-Any {
    $tf = Join-Path $TASK_DIR "tasks.md"
    if (-not (Test-Path $tf)) { return $false }
    return (Get-Content $tf -Raw) -match '-\s+\['
}

function Test-FileNonEmpty {
    param([string]$Path)
    return (Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)
}

function Test-MatureSolutionEvidence {
    $analysisPath = Join-Path $TASK_DIR "analysis.md"
    $routingPath = Join-Path $TASK_DIR "routing.md"
    $tasksPath = Join-Path $TASK_DIR "tasks.md"

    if (-not (Test-FileNonEmpty $analysisPath)) {
        Write-Red "analysis.md missing or empty"
        return $false
    }
    if (-not (Test-FileNonEmpty $routingPath)) {
        Write-Red "routing.md missing or empty"
        return $false
    }
    if (-not (Test-FileNonEmpty $tasksPath)) {
        Write-Red "tasks.md missing or empty"
        return $false
    }

    $analysis = Get-Content -LiteralPath $analysisPath -Raw
    $routing = Get-Content -LiteralPath $routingPath -Raw
    $tasks = Get-Content -LiteralPath $tasksPath -Raw

    $requiredAnalysis = @(
        "Mature Solution Evidence",
        "Project-local evidence",
        "Official/framework evidence",
        "Options compared",
        "Rejected shortcuts",
        "Selected mature path"
    )
    foreach ($marker in $requiredAnalysis) {
        if ($analysis -notmatch [regex]::Escape($marker)) {
            Write-Red "analysis.md missing mature-solution marker: $marker"
            return $false
        }
    }

    if ($routing -notmatch "Quality Gate") {
        Write-Red "routing.md missing Quality Gate"
        return $false
    }

    $declaresNoMvp = $routing -match "MVP/prototype requested by user:\s*no"
    $declaresException = ($routing -match "MVP/prototype requested by user:\s*yes") -and ($routing -match "Quality Exception")
    if (-not ($declaresNoMvp -or $declaresException)) {
        Write-Red "routing.md must declare MVP/prototype requested by user: no, or include a Quality Exception"
        return $false
    }

    if ($tasks -notmatch "mature path" -or $tasks -notmatch "rejected shortcut") {
        Write-Red "tasks.md missing mature-path verification task"
        return $false
    }

    return $true
}

function Test-ArchitectureVerificationAndWorkPackagePolicy {
    $analysisPath = Join-Path $TASK_DIR "analysis.md"
    $routingPath = Join-Path $TASK_DIR "routing.md"
    $tasksPath = Join-Path $TASK_DIR "tasks.md"

    if (-not (Test-FileNonEmpty $analysisPath)) { Write-Red "analysis.md missing or empty"; return $false }
    if (-not (Test-FileNonEmpty $routingPath)) { Write-Red "routing.md missing or empty"; return $false }
    if (-not (Test-FileNonEmpty $tasksPath)) { Write-Red "tasks.md missing or empty"; return $false }

    $analysis = Get-Content -LiteralPath $analysisPath -Raw
    $routing = Get-Content -LiteralPath $routingPath -Raw
    $tasks = Get-Content -LiteralPath $tasksPath -Raw

    $requiredAnalysis = @(
        "Architecture Context",
        "System boundaries",
        "Dependency map",
        "Acceptance Criteria",
        "Automated Verification Plan"
    )
    foreach ($marker in $requiredAnalysis) {
        if ($analysis -notmatch [regex]::Escape($marker)) {
            Write-Red "analysis.md missing architecture/verification marker: $marker"
            return $false
        }
    }

    if ($routing -notmatch "Work Package Policy") {
        Write-Red "routing.md missing Work Package Policy"
        return $false
    }

    if ($routing -notmatch "External workers:\s*(yes|no)") {
        Write-Red "routing.md Work Package Policy must declare External workers: yes|no"
        return $false
    }

    $externalWorkers = ($routing -match "External workers:\s*yes")
    if ($externalWorkers) {
        if (-not (Test-WorkPackageQuality)) {
            return $false
        }
    }

    if ($tasks -notmatch "(?i)automated verification") {
        Write-Red "tasks.md missing automated verification task"
        return $false
    }

    if ($tasks -notmatch "(?i)Acceptance Criteria") {
        Write-Red "tasks.md missing Acceptance Criteria mapping task"
        return $false
    }

    return $true
}

function Test-MarkdownSections {
    param(
        [string]$Content,
        [string[]]$Sections,
        [string]$Label
    )

    foreach ($section in $Sections) {
        if ($Content -notmatch "(?m)^##\s+$([regex]::Escape($section))\s*$") {
            Write-Red "$Label missing section: ## $section"
            return $false
        }
    }
    return $true
}

function Test-NoTemplatePlaceholders {
    param([string]$Content, [string]$Label)
    if ($Content -match "<[^>\r\n]+>") {
        Write-Red "$Label contains template placeholders"
        return $false
    }
    return $true
}

function Get-WorkPackages {
    $workPackageDir = Join-Path $TASK_DIR "work-packages"
    if (-not (Test-Path $workPackageDir)) { return @() }
    return @(Get-ChildItem -LiteralPath $workPackageDir -Filter "*.md" -File -ErrorAction SilentlyContinue)
}

function Test-WorkPackageQuality {
    $workPackages = @(Get-WorkPackages)
    if ($workPackages.Count -eq 0) {
        Write-Red "External workers enabled but no work-packages/*.md files exist"
        return $false
    }

    $requiredSections = @(
        "Task Packet",
        "Allowed Paths",
        "Forbidden Paths",
        "Read First",
        "Goal",
        "Steps",
        "Done Definition",
        "Required Verification",
        "Return Report"
    )

    foreach ($package in $workPackages) {
        $content = Get-Content -LiteralPath $package.FullName -Raw
        $label = "work package $($package.Name)"
        if (-not (Test-NoTemplatePlaceholders $content $label)) { return $false }
        if (-not (Test-MarkdownSections $content $requiredSections $label)) { return $false }
        if ($content -notmatch "(?mi)^\s*Status:\s*(unclaimed|claimed|done|blocked)\s*$") {
            Write-Red "$label missing concrete Status"
            return $false
        }
        if ($content -notmatch '(?mi)^\s*-\s*Path:\s*`?reports/[^`\r\n]+\.md`?\s*$') {
            Write-Red "$label missing concrete Return Report path"
            return $false
        }
    }

    return $true
}

function Test-WorkerReportQuality {
    $routingPath = Join-Path $TASK_DIR "routing.md"
    if (-not (Test-FileNonEmpty $routingPath)) { Write-Red "routing.md missing or empty"; return $false }

    $routing = Get-Content -LiteralPath $routingPath -Raw
    $externalWorkers = ($routing -match "External workers:\s*yes")
    $reportsRequired = ($routing -match "Worker reports required before merge:\s*yes")
    if (-not ($externalWorkers -and $reportsRequired)) { return $true }

    $workPackages = @(Get-WorkPackages)
    if ($workPackages.Count -eq 0) {
        Write-Red "Worker reports required but no work packages exist"
        return $false
    }

    $reportDir = Join-Path $TASK_DIR "reports"
    $reports = @()
    if (Test-Path $reportDir) {
        $reports = @(Get-ChildItem -LiteralPath $reportDir -Filter "*.md" -File -ErrorAction SilentlyContinue)
    }
    if ($reports.Count -lt $workPackages.Count) {
        Write-Red "Worker reports required before merge but reports/*.md count ($($reports.Count)) is less than work-packages/*.md count ($($workPackages.Count))"
        return $false
    }

    $requiredSections = @(
        "Changed Files",
        "Commands Run",
        "Acceptance Criteria Touched",
        "Scope Control",
        "Unresolved Risks"
    )

    foreach ($report in $reports) {
        $content = Get-Content -LiteralPath $report.FullName -Raw
        $label = "worker report $($report.Name)"
        if (-not (Test-NoTemplatePlaceholders $content $label)) { return $false }
        if (-not (Test-MarkdownSections $content $requiredSections $label)) { return $false }
        if ($content -notmatch "(?mi)^\s*Status:\s*done\s*$") {
            Write-Red "$label must declare Status: done before implement can move to review"
            return $false
        }
        if ($content -notmatch "(?mi)^\s*-\s*Extra scope taken:\s*no\s*$") {
            Write-Red "$label must declare Extra scope taken: no"
            return $false
        }
    }

    return $true
}

function Resolve-VerificationReportPath {
    param([string]$Report)
    if (-not $Report -or $Report -eq "null") { return $null }
    if ([System.IO.Path]::IsPathRooted($Report)) { return $Report }
    $fromTask = Join-Path $TASK_DIR $Report
    if (Test-Path $fromTask) { return $fromTask }
    return (Join-Path (Get-Location) $Report)
}

function Test-VerificationReportQuality {
    $reportValue = Get-YamlField "verification_report"
    $reportPath = Resolve-VerificationReportPath $reportValue
    if (-not $reportPath -or -not (Test-Path $reportPath)) {
        Write-Red "verification_report does not point to an existing file"
        return $false
    }

    $report = Get-Content -LiteralPath $reportPath -Raw
    $requiredReport = @(
        "Automated Verification",
        "Acceptance Criteria",
        "Architecture Compliance",
        "Test Evidence",
        "Residual Risk"
    )
    foreach ($marker in $requiredReport) {
        if ($report -notmatch [regex]::Escape($marker)) {
            Write-Red "verification report missing marker: $marker"
            return $false
        }
    }
    return $true
}

function Test-ProjectSpecificChecks {
    $pt = Get-YamlField "project_type"
    Write-Host "  [MECH] Project type: $pt"
    $allPassed = $true
    if ($pt -eq "ue5") {
        $uf = Get-ChildItem -Path "Project" -Filter "*.uproject" -Recurse -Depth 3 -ErrorAction SilentlyContinue
        if ($uf) { Write-Green "  [MECH] .uproject found: $($uf[0].FullName)" }
        else { Write-Yellow "  [MECH] No .uproject detected" }
        $cf = Get-ChildItem -Path "Project" -Include "*.h","*.cpp" -Recurse -Depth 5 -ErrorAction SilentlyContinue | Select-Object -First 50
        $violations = @()
        foreach ($f in $cf) {
            $c = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if ($c -match "Replicated") { $violations += "$($f.Name): contains Replicated" }
            if ($c -match "NetMulticast") { $violations += "$($f.Name): contains NetMulticast" }
        }
        if ($violations.Count -eq 0) { Write-Green "  [MECH] No replication violations" }
        else { Write-Red "  [MECH] Found $($violations.Count) potential replication violations:"; $violations | %{ Write-Red "    $_" }; $allPassed = $false }
    }
    if ($pt -eq "web") {
        $pj = Get-ChildItem -Path "." -Filter "package.json" -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $pj) { Write-Yellow "  [MECH] No package.json found"; return $allPassed }
        Write-Green "  [MECH] package.json found: $($pj.FullName)"
        $pc = Get-Content $pj.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pc -and $pc.scripts) {
            $pn = $pc.scripts.PSObject.Properties.Name
            if ($pn -contains "build") { Write-Green "  [MECH] build script defined" }
            if ($pn -contains "lint") { Write-Green "  [MECH] lint script defined" }
        }
    }
    return $allPassed
}

function Invoke-DocGuard {
    param([string]$StageName)
    $docGuard = Join-Path $PSScriptRoot "doc-guard.ps1"
    if (-not (Test-Path $docGuard)) {
        Write-Red "  [FAIL] doc-guard.ps1 missing"
        $script:BLOCKED = $true
        return
    }

    & $docGuard check-task $TaskName -Stage $StageName
    if ($LASTEXITCODE -ne 0) {
        Write-Red "  [BLOCKED] Documentation governance failed"
        $script:BLOCKED = $true
    }
}

function Guard-Plan {
    Write-Host "=== Guard: plan -> implement ==="
    Test-Check "routing output exists" { Test-FileNonEmpty (Join-Path $TASK_DIR "routing.md") }
    Test-Check "tasks.md exists and non-empty" { Test-FileNonEmpty (Join-Path $TASK_DIR "tasks.md") }
    Test-Check "spec.md exists and non-empty" { Test-FileNonEmpty (Join-Path $TASK_DIR "spec.md") }
    Test-Check "analysis.md exists and non-empty" { Test-FileNonEmpty (Join-Path $TASK_DIR "analysis.md") }
    Test-Check "tasks.md has at least one task" { Tasks-Has-Any }
    Test-Check "mature solution evidence and quality gate present" { Test-MatureSolutionEvidence }
    Test-Check "architecture context, acceptance criteria, automated verification, and work package policy present" { Test-ArchitectureVerificationAndWorkPackagePolicy }
    Test-Check "clarification_status resolved" { (Get-YamlField "clarification_status") -in @("not_needed","answered") }
    Test-Check "user_confirmed_plan is true" { (Get-YamlField "user_confirmed_plan") -eq "true" }
    Test-Check "router_skill_loaded is true" { (Get-YamlField "router_skill_loaded") -eq "true" }
    Invoke-DocGuard "plan"
}

function Guard-Implement {
    Write-Host "=== Guard: implement -> review ==="
    Test-Check "implement phase still has edit auth" {
        ((Get-YamlField "clarification_status") -in @("not_needed","answered")) -and
        ((Get-YamlField "user_confirmed_plan") -eq "true") -and
        ((Get-YamlField "router_skill_loaded") -eq "true")
    }
    Test-Check "all tasks checked" { Tasks-All-Done }
    Test-Check "tasks.md exists" { Test-FileNonEmpty (Join-Path $TASK_DIR "tasks.md") }
    Test-Check "external worker reports are complete and scoped" { Test-WorkerReportQuality }
    $mr = Test-ProjectSpecificChecks
    if (-not $mr) { $script:BLOCKED = $true; Write-Red "  [BLOCKED] Mechanical checks failed" }
    Invoke-DocGuard "implement"
    $fa = Get-YamlField "fix_attempts"
    if ($fa -and [int]$fa -ge 3) {
        Write-Red "  [BLOCKED] Fix-attempt count = $fa (>=3). Forced fresh subagent required."
        $script:BLOCKED = $true
    }
    Write-Host "  [CHECK] Verify reviewer independence"
}

function Guard-Review {
    Write-Host "=== Guard: review -> verify ==="
    Test-Check "review_result is pass" { (Get-YamlField "review_result") -eq "pass" }
    $report = Get-YamlField "verification_report"
    if (-not $report -and (Get-YamlField "review_result") -eq "pass") {
        Write-Yellow "  [WARN] review_result=pass but no verification_report yet"
    }
}

function Guard-Verify {
    Write-Host "=== Guard: verify -> archive ==="
    Test-Check "all tasks checked" { Tasks-All-Done }
    $report = Get-YamlField "verification_report"
    Test-Check "verification_report exists" {
        $resolvedReport = Resolve-VerificationReportPath $report
        $resolvedReport -and (Test-Path $resolvedReport)
    }
    Test-Check "verify_result is pass" { (Get-YamlField "verify_result") -eq "pass" }
    Test-Check "verification report contains required automated acceptance evidence" { Test-VerificationReportQuality }
    $fa = Get-YamlField "fix_attempts"
    if ($fa -and [int]$fa -ge 3) { Write-Yellow "  [WARN] High fix-attempt count ($fa)" }
    Write-Host "  [METRICS] Agent evaluation metrics -> see .trae/tasks/$TaskName/verification-report.md"
}

function Guard-Archive {
    Write-Host "=== Guard: archive completeness ==="
    Test-Check "archived is true" { (Get-YamlField "archived") -eq "true" }
}

if (-not (Test-Path $TASK_DIR)) { Write-Red "FATAL: task directory not found: $TASK_DIR"; exit 1 }
if (-not (Test-Path $YAML_FILE)) { Write-Red "FATAL: .task.yaml not found at $YAML_FILE"; exit 1 }

function Invoke-StateTransition {
    param([string]$Event)
    if ($resolved.Root -eq ".trae\tasks") {
        $ss = Join-Path $PSScriptRoot "task-state.ps1"
        if (-not (Test-Path $ss)) { Write-Red "FATAL: task-state.ps1 not found at $ss"; exit 1 }
        & $ss transition $TaskName $Event
        if (-not $?) { Write-Red "State transition failed"; exit 1 }
        return
    }

    switch ($Event) {
        "plan-complete" { Set-YamlField "phase" "implement" }
        "implement-complete" { Set-YamlField "phase" "review"; Set-YamlField "review_result" "pending" }
        "review-pass" { Set-YamlField "review_result" "pass"; Set-YamlField "phase" "verify"; Set-YamlField "verify_result" "pending"; Set-YamlField "verification_report" "null" }
        "verify-pass" { Set-YamlField "verify_result" "pass"; Set-YamlField "phase" "archived"; Set-YamlField "archived" "true" }
        default { Write-Red "Unknown state transition event: $Event"; exit 1 }
    }
}

switch ($Phase) {
    "plan"      { Guard-Plan; if ($Apply -and -not $BLOCKED) { Invoke-StateTransition "plan-complete" } }
    "implement" { Guard-Implement; if ($Apply -and -not $BLOCKED) { Invoke-StateTransition "implement-complete" } }
    "review"    { Guard-Review; if ($Apply -and -not $BLOCKED) { Invoke-StateTransition "review-pass" } }
    "verify"    { Guard-Verify; if ($Apply -and -not $BLOCKED) { Invoke-StateTransition "verify-pass" } }
    "archive"   { Guard-Archive }
    default     { Write-Red "Unknown phase: $Phase. Use: plan | implement | review | verify | archive"; exit 1 }
}

Write-Host ""
if ($BLOCKED) { Write-Red "BLOCKED - fix failing checks"; exit 1 }
else {
    if ($Apply) { Write-Green "ALL GUARDS PASSED - state auto-transitioned" }
    else { Write-Green "ALL GUARDS PASSED - ready to transition" }
    exit 0
}
