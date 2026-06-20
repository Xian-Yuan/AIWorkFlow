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

function Test-IsDs4Task {
    return (Get-YamlField "worker_profile") -eq "ds4-flash"
}

function Test-IsAuthorityTask {
    return (Get-YamlField "authority_profile") -eq "issuer-worker-v1"
}

function Test-AuthorityPolicy {
    if (-not (Test-IsAuthorityTask)) { return $true }
    $routingPath = Join-Path $TASK_DIR "routing.md"
    if (-not (Test-FileNonEmpty $routingPath)) { return $false }
    $routing = Get-Content -LiteralPath $routingPath -Raw
    foreach ($pattern in @(
        "(?mi)^##\s+Authority Policy\s*$",
        "(?mi)^\s*-\s*Authority profile:\s*issuer-worker-v1\s*$",
        "(?mi)^\s*-\s*Packet mutation authority:\s*issuer only\s*$",
        "(?mi)^\s*-\s*Review authority:\s*original issuer only\s*$",
        "(?mi)^\s*-\s*Verify authority:\s*original issuer only\s*$",
        "(?mi)^\s*-\s*Archive authority:\s*original issuer only\s*$",
        "(?mi)^\s*-\s*Verify auto-archive:\s*forbidden\s*$"
    )) {
        if ($routing -notmatch $pattern) {
            Write-Red "routing.md authority policy missing: $pattern"
            return $false
        }
    }
    return $true
}

function Test-AuthorityPacketReady {
    if (-not (Test-IsAuthorityTask)) { return $true }
    try {
        Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking
        $authorityTask = Resolve-AuthorityTask $TaskName $resolved.Root
        $null = Test-AuthorityPacketSeal $authorityTask
        return $true
    }
    catch {
        Write-Red "Authority packet verification failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-AuthorityWorkerSubmissions {
    $routing = Get-Content -LiteralPath (Join-Path $TASK_DIR "routing.md") -Raw
    if ($routing -notmatch "(?mi)^\s*-\s*External workers:\s*yes\s*$") { return $true }
    try {
        Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking
        $authorityTask = Resolve-AuthorityTask $TaskName $resolved.Root
        $packet = Test-AuthorityPacketSeal $authorityTask
        $capabilityDir = Join-Path $TASK_DIR "capabilities"
        $capabilities = if (Test-Path -LiteralPath $capabilityDir) {
            @(Get-ChildItem -LiteralPath $capabilityDir -Filter "*.capability.json" -File)
        }
        else { @() }
        foreach ($package in @(Get-WorkPackages)) {
            $relativePackage = "work-packages/$($package.Name)"
            $current = @()
            foreach ($candidate in $capabilities) {
                try {
                    $artifact = Test-AuthorityCapability $authorityTask $candidate.FullName
                    if ($artifact.packet_digest -eq $packet.packet_digest -and $artifact.work_package_path -eq $relativePackage) {
                        $current += [pscustomobject]@{ File=$candidate; Artifact=$artifact }
                    }
                }
                catch {}
            }
            $selected = $current | Sort-Object { $_.Artifact.attempt_id } | Select-Object -Last 1
            if (-not $selected) { throw "No current signed capability for $relativePackage" }
            $resultPath = Join-Path $TASK_DIR ($selected.Artifact.result_path -replace "/", "\")
            if (-not (Test-Path -LiteralPath $resultPath)) { throw "Worker result missing for $relativePackage" }
            $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($result.status -ne "implementation_done") { throw "Worker result is not implementation_done for $relativePackage" }
        }
        return $true
    }
    catch {
        Write-Red "Authority worker submission verification failed: $($_.Exception.Message)"
        return $false
    }
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

    if (Test-IsDs4Task) {
        if (-not (Test-Ds4RepairPolicy)) { return $false }
        if (-not (Test-Ds4WorkPackageQuality)) { return $false }
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

function Test-Ds4RepairPolicy {
    $routingPath = Join-Path $TASK_DIR "routing.md"
    if (-not (Test-FileNonEmpty $routingPath)) { return $false }
    $routing = Get-Content -LiteralPath $routingPath -Raw
    if ($routing -notmatch "(?m)^##\s+Worker Repair Policy\s*$") {
        Write-Red "routing.md missing Worker Repair Policy for ds4-flash"
        return $false
    }
    $required = @(
        "Worker profile:\s*ds4-flash",
        "Lead/verifier:\s*(codex|ds4-flash-fresh-context)",
        "Fresh context per repair:\s*yes",
        "Automatic repair package generation:\s*yes",
        "Maximum attempts per root cause:\s*3",
        "Only lead may set Review/Verify pass:\s*yes",
        "Worker reports required before merge:\s*yes"
    )
    foreach ($pattern in $required) {
        if ($routing -notmatch $pattern) {
            Write-Red "routing.md DS4 repair policy missing: $pattern"
            return $false
        }
    }
    $leadVerifier = Get-YamlField "lead_verifier"
    if ($leadVerifier -notin @("codex","ds4-flash-fresh-context")) {
        Write-Red ".task.yaml lead_verifier must be codex or ds4-flash-fresh-context for ds4-flash"
        return $false
    }
    return $true
}

function Test-Ds4WorkPackageQuality {
    $workPackages = @(Get-WorkPackages)
    if ($workPackages.Count -eq 0) {
        Write-Red "ds4-flash task requires at least one work package"
        return $false
    }
    $requiredSections = @(
        "Worker Profile",
        "Context Budget",
        "Root Cause Boundary",
        "Do Not Game The Gate",
        "Stop Conditions"
    )
    foreach ($package in $workPackages) {
        $content = Get-Content -LiteralPath $package.FullName -Raw
        $label = "DS4 work package $($package.Name)"
        if (-not (Test-MarkdownSections $content $requiredSections $label)) { return $false }
        if ($content -notmatch "(?mi)^\s*Target model:\s*deepseek-v4-flash\s*$") {
            Write-Red "$label must target deepseek-v4-flash"
            return $false
        }
        if ($content -notmatch "(?mi)^\s*Fresh context required:\s*yes\s*$") {
            Write-Red "$label must require a fresh context"
            return $false
        }
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

function Test-MarkdownSectionBody {
    param(
        [string]$Content,
        [string]$Section,
        [string]$Label
    )
    $escaped = [regex]::Escape($Section)
    $match = [regex]::Match($Content, "(?ms)^##\s+$escaped\s*$\s*(?<body>.*?)(?=^##\s+|\z)")
    if (-not $match.Success -or [string]::IsNullOrWhiteSpace($match.Groups["body"].Value)) {
        Write-Red "$Label has empty section: ## $Section"
        return $false
    }
    return $true
}

function Test-RequirementUnderstandingGate {
    $version = Get-YamlField "requirements_gate_version"
    if (-not $version) {
        return $true
    }
    if ($version -ne "1") {
        Write-Red "Unsupported requirements_gate_version: $version"
        return $false
    }

    $profile = Get-YamlField "change_profile"
    if ($profile -notin @("deep","fast")) {
        Write-Red "change_profile must be deep or fast for requirement-gate version 1"
        return $false
    }

    $routingPath = Join-Path $TASK_DIR "routing.md"
    if (-not (Test-FileNonEmpty $routingPath)) {
        Write-Red "routing.md missing for requirement-understanding gate"
        return $false
    }
    $routing = Get-Content -LiteralPath $routingPath -Raw

    $promptPath = Resolve-TaskArtifactPath (Get-YamlField "execution_prompt")
    if (-not $promptPath -or -not (Test-FileNonEmpty $promptPath)) {
        Write-Red "execution_prompt must point to a non-empty file"
        return $false
    }
    $prompt = Get-Content -LiteralPath $promptPath -Raw
    if (-not (Test-NoTemplatePlaceholders $prompt "execution prompt")) { return $false }
    $promptSections = @(
        "Role",
        "Goal",
        "Task Packet Truth Sources",
        "Confirmed Decisions",
        "Accepted Architecture",
        "Allowed Paths",
        "Forbidden Paths",
        "Non-Goals",
        "Acceptance Criteria",
        "Verification Commands",
        "Stop Conditions",
        "Evidence Rule"
    )
    if (-not (Test-MarkdownSections $prompt $promptSections "execution prompt")) { return $false }
    foreach ($section in $promptSections) {
        if (-not (Test-MarkdownSectionBody $prompt $section "execution prompt")) { return $false }
    }

    $status = Get-YamlField "requirements_status"
    if ($profile -eq "deep") {
        if ($status -ne "confirmed") {
            Write-Red "deep task requires requirements_status: confirmed"
            return $false
        }
        if ((Get-YamlField "clarification_status") -ne "answered") {
            Write-Red "deep task cannot use clarification_status: not_needed"
            return $false
        }
        if ($routing -notmatch "(?mi)^##\s+Requirement Discovery Gate\s*$" -or
            $routing -notmatch "(?mi)^\s*-\s*Plain-language summary confirmed:\s*yes\s*$" -or
            $routing -notmatch "(?mi)^\s*-\s*Unresolved high-impact questions:\s*none\s*$") {
            Write-Red "routing.md deep discovery evidence is incomplete"
            return $false
        }

        $requirementsPath = Resolve-TaskArtifactPath (Get-YamlField "requirements_doc")
        if (-not $requirementsPath -or -not (Test-FileNonEmpty $requirementsPath)) {
            Write-Red "deep task requirements_doc must point to a non-empty file"
            return $false
        }
        $requirements = Get-Content -LiteralPath $requirementsPath -Raw
        if (-not (Test-NoTemplatePlaceholders $requirements "requirements document")) { return $false }
        $requirementsSections = @(
            "Desired Outcome",
            "Intended User and Context",
            "End-to-End Experience",
            "Confirmed Decisions",
            "Implicit Requirements",
            "Boundaries and Non-Goals",
            "Success Experience",
            "Open Questions",
            "Teach-Back Summary",
            "User Confirmation Evidence"
        )
        if (-not (Test-MarkdownSections $requirements $requirementsSections "requirements document")) { return $false }
        foreach ($section in $requirementsSections) {
            if (-not (Test-MarkdownSectionBody $requirements $section "requirements document")) { return $false }
        }
        $openQuestions = [regex]::Match($requirements, "(?ms)^##\s+Open Questions\s*$\s*(?<body>.*?)(?=^##\s+|\z)")
        if (-not $openQuestions.Success -or $openQuestions.Groups["body"].Value.Trim() -notmatch "^(None|None\.)$") {
            Write-Red "deep task must resolve Open Questions before implementation"
            return $false
        }
    }
    else {
        if ($status -ne "not_required") {
            Write-Red "fast task requires requirements_status: not_required"
            return $false
        }
        $fastReason = Get-YamlField "fast_track_reason"
        if ([string]::IsNullOrWhiteSpace($fastReason) -or $fastReason -match "<[^>\r\n]+>") {
            Write-Red "fast task requires a concrete fast_track_reason"
            return $false
        }
        $fastPatterns = @(
            "(?mi)^##\s+Fast Track Assessment\s*$",
            "(?mi)^\s*-\s*Expected behavior is concrete:\s*yes\s*$",
            "(?mi)^\s*-\s*Change is bounded:\s*yes\s*$",
            "(?mi)^\s*-\s*Architecture or data ownership change:\s*no\s*$",
            "(?mi)^\s*-\s*User journey redesign:\s*no\s*$",
            "(?mi)^\s*-\s*Unresolved high-impact implicit requirements:\s*none\s*$",
            "(?mi)^\s*-\s*Verification is bounded:\s*yes\s*$",
            "(?mi)^\s*-\s*Fast-track reason:\s*\S.+$"
        )
        foreach ($pattern in $fastPatterns) {
            if ($routing -notmatch $pattern) {
                Write-Red "routing.md fast-track assessment is incomplete: $pattern"
                return $false
            }
        }
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
    if (Test-IsAuthorityTask) { return Test-AuthorityWorkerSubmissions }

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
        if (Test-IsDs4Task) {
            if (-not (Test-MarkdownSections $content @("Worker Authority") $label)) { return $false }
            $authorityRules = @(
                "Review result set by worker:\s*no",
                "Verify result set by worker:\s*no",
                "Task state changed by worker:\s*no",
                "Acceptance criteria changed by worker:\s*no",
                "Tests weakened by worker:\s*no"
            )
            foreach ($rule in $authorityRules) {
                if ($content -notmatch "(?mi)^\s*-\s*$rule\s*$") {
                    Write-Red "$label violates worker authority rule: $rule"
                    return $false
                }
            }
        }
    }

    return $true
}

function Test-Ds4RepairState {
    if (-not (Test-IsDs4Task)) { return $true }
    $status = Get-YamlField "repair_loop_status"
    if ($status -eq "architecture_review") {
        Write-Red "DS4 repair loop is in architecture_review; automatic implementation cannot advance"
        return $false
    }
    if ($status -notin @("idle","repair_required","resolved")) {
        Write-Red "Invalid DS4 repair_loop_status: $status"
        return $false
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

function Test-Ds4VerifierIndependence {
    if (-not (Test-IsDs4Task)) { return $true }
    $reportValue = Get-YamlField "verification_report"
    $reportPath = Resolve-VerificationReportPath $reportValue
    if (-not $reportPath -or -not (Test-Path -LiteralPath $reportPath)) {
        Write-Red "DS4 task requires an existing verification report before Review/Verify pass"
        return $false
    }
    $report = Get-Content -LiteralPath $reportPath -Raw
    foreach ($pattern in @(
        "(?mi)^Verifier role:\s*lead\s*$",
        "(?mi)^Worker model:\s*deepseek-v4-flash\s*$",
        "(?mi)^\s*-\s*Independent verification run by reviewer:\s*yes\s*$",
        "(?mi)^\s*-\s*Worker success claims accepted without verification:\s*no\s*$"
    )) {
        if ($report -notmatch $pattern) {
            Write-Red "DS4 verification report missing independence evidence: $pattern"
            return $false
        }
    }

    $modelMatch = [regex]::Match($report, "(?mi)^Verifier model:\s*(?<value>.+?)\s*$")
    $contextMatch = [regex]::Match($report, "(?mi)^Verifier context:\s*(?<value>.+?)\s*$")
    if (-not $modelMatch.Success -or -not $contextMatch.Success) {
        Write-Red "DS4 verification report must declare Verifier model and Verifier context"
        return $false
    }
    $model = $modelMatch.Groups["value"].Value.Trim()
    $context = $contextMatch.Groups["value"].Value.Trim()
    $leadVerifier = Get-YamlField "lead_verifier"
    if ($leadVerifier -eq "codex" -and $model -ne "codex") {
        Write-Red "Configured lead_verifier=codex requires Verifier model: codex"
        return $false
    }
    if ($leadVerifier -eq "ds4-flash-fresh-context" -and $model -ne "deepseek-v4-flash") {
        Write-Red "Configured Flash fallback requires Verifier model: deepseek-v4-flash"
        return $false
    }
    if ($model -eq "codex") {
        if ($context -notin @("independent","fresh")) {
            Write-Red "Codex verifier context must be independent or fresh"
            return $false
        }
        return $true
    }
    if ($model -eq "deepseek-v4-flash") {
        if ($context -ne "fresh") {
            Write-Red "Flash-only verification must run in a fresh context"
            return $false
        }
        return $true
    }
    Write-Red "Unsupported DS4 verifier model: $model"
    return $false
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
    Test-Check "issuer-worker authority policy is complete" { Test-AuthorityPolicy }
    Test-Check "requirement understanding and execution prompt are complete" { Test-RequirementUnderstandingGate }
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
    Test-Check "requirement understanding remains valid" { Test-RequirementUnderstandingGate }
    Test-Check "all tasks checked" { Tasks-All-Done }
    Test-Check "tasks.md exists" { Test-FileNonEmpty (Join-Path $TASK_DIR "tasks.md") }
    Test-Check "authority packet seal is current" { Test-AuthorityPacketReady }
    Test-Check "external worker reports are complete and scoped" { Test-WorkerReportQuality }
    Test-Check "DS4 repair state allows review" { Test-Ds4RepairState }
    $mr = Test-ProjectSpecificChecks
    if (-not $mr) { $script:BLOCKED = $true; Write-Red "  [BLOCKED] Mechanical checks failed" }
    Invoke-DocGuard "implement"
    $fa = Get-YamlField "fix_attempts"
    if (-not (Test-IsDs4Task) -and $fa -and [int]$fa -ge 3) {
        Write-Red "  [BLOCKED] Fix-attempt count = $fa (>=3). Forced fresh subagent required."
        $script:BLOCKED = $true
    }
    Write-Host "  [CHECK] Verify reviewer independence"
}

function Guard-Review {
    Write-Host "=== Guard: review -> verify ==="
    Test-Check "review_result is pass" { (Get-YamlField "review_result") -eq "pass" }
    if (Test-IsAuthorityTask) {
        $approval = Get-YamlField "verification_report"
        Test-Check "issuer-signed review approval is current" {
            if (-not $approval) { return $false }
            $reviewScript = Join-Path $PSScriptRoot "issuer-review.ps1"
            & $reviewScript verify $TaskName -Approval $approval *> $null
            return ($LASTEXITCODE -eq 0)
        }
        return
    }
    Test-Check "DS4 verifier is independent" { Test-Ds4VerifierIndependence }
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
    if (Test-IsAuthorityTask) {
        Test-Check "issuer-signed review approval is current" {
            $reviewScript = Join-Path $PSScriptRoot "issuer-review.ps1"
            & $reviewScript verify $TaskName -Approval $report *> $null
            return ($LASTEXITCODE -eq 0)
        }
    }
    else {
        Test-Check "verification report contains required automated acceptance evidence" { Test-VerificationReportQuality }
        Test-Check "DS4 verifier is independent" { Test-Ds4VerifierIndependence }
    }
    $fa = Get-YamlField "fix_attempts"
    if ($fa -and [int]$fa -ge 3) { Write-Yellow "  [WARN] High fix-attempt count ($fa)" }
    Write-Host "  [METRICS] Agent evaluation metrics -> see .trae/tasks/$TaskName/verification-report.md"
}

function Guard-Archive {
    Write-Host "=== Guard: archive completeness ==="
    Test-Check "archived is true" { (Get-YamlField "archived") -eq "true" }
    if (Test-IsAuthorityTask) {
        Test-Check "issuer-signed archive certificate is current" {
            $certificate = Get-YamlField "archive_certificate"
            if (-not $certificate) { return $false }
            $archiveScript = Join-Path $PSScriptRoot "issuer-archive.ps1"
            & $archiveScript verify $TaskName -ArchiveCertificate $certificate *> $null
            return ($LASTEXITCODE -eq 0)
        }
    }
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
        "review-pass" {
            Set-YamlField "review_result" "pass"
            Set-YamlField "phase" "verify"
            Set-YamlField "verify_result" "pending"
            if (-not (Test-IsDs4Task)) {
                Set-YamlField "verification_report" "null"
            }
        }
        "verify-pass" { Set-YamlField "verify_result" "pass"; Set-YamlField "phase" "archived"; Set-YamlField "archived" "true" }
        default { Write-Red "Unknown state transition event: $Event"; exit 1 }
    }
}

switch ($Phase) {
    "plan"      { Guard-Plan; if ($Apply -and -not $BLOCKED) { Invoke-StateTransition "plan-complete" } }
    "implement" {
        Guard-Implement
        if ($Apply -and -not $BLOCKED -and -not (Test-IsAuthorityTask)) { Invoke-StateTransition "implement-complete" }
    }
    "review"    { Guard-Review }
    "verify"    { Guard-Verify }
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
