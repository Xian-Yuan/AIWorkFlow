# DS4 Flash Worker Repair Loop
# Usage:
#   worker-repair-loop.ps1 init <task>
#   worker-repair-loop.ps1 record-failure <task> -Stage review -RootCauseId RC01 ...
#   worker-repair-loop.ps1 resolve <task> -RootCauseId RC01
#   worker-repair-loop.ps1 status <task>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("init","record-failure","resolve","status")]
    [string]$Command,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,

    [ValidateSet("review","verify")]
    [string]$Stage,

    [string]$RootCauseId,
    [string]$Summary,
    [string]$FailedCommand,
    [string]$Expected,
    [string]$Actual,
    [string[]]$AllowedPaths,
    [string[]]$ReadFirst,
    [string]$Verifier = "Codex",
    [string]$KeyName
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskRoots = @(".trae\tasks", ".opencode\tasks", ".codex\tasks")

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Fail {
    param([string]$Message)
    Write-Red "ERROR: $Message"
    exit 1
}

function Test-PathWithinRoot {
    param([string]$Path, [string]$Root)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd("\","/") + [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-TaskPath {
    param([string]$Name)
    $relative = $Name -replace "/", "\"
    foreach ($rootName in $TaskRoots) {
        $root = Join-Path $WorkspaceRoot $rootName
        if ($Name -match "^(.+?)/(.+)$") {
            $candidate = Join-Path $root $relative
            if ((Test-PathWithinRoot $candidate $root) -and (Test-Path -LiteralPath $candidate)) {
                return @{
                    Dir = [System.IO.Path]::GetFullPath($candidate)
                    Yaml = Join-Path ([System.IO.Path]::GetFullPath($candidate)) ".task.yaml"
                    Root = $rootName
                }
            }
        }
        else {
            $direct = Join-Path $root $Name
            if ((Test-PathWithinRoot $direct $root) -and (Test-Path -LiteralPath $direct)) {
                $fullDirect = [System.IO.Path]::GetFullPath($direct)
                return @{ Dir=$fullDirect; Yaml=(Join-Path $fullDirect ".task.yaml"); Root=$rootName }
            }
            foreach ($scope in @("_shared","airpgweb","characterdesigntool","rts","ai-drama")) {
                $candidate = Join-Path $root "$scope\$Name"
                if ((Test-PathWithinRoot $candidate $root) -and (Test-Path -LiteralPath $candidate)) {
                    $fullCandidate = [System.IO.Path]::GetFullPath($candidate)
                    return @{ Dir=$fullCandidate; Yaml=(Join-Path $fullCandidate ".task.yaml"); Root=$rootName }
                }
            }
        }
    }
    Fail "Task not found: $Name"
}

function Get-YamlField {
    param([string]$Path, [string]$Field)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $match = Select-String -LiteralPath $Path -Pattern "^$([regex]::Escape($Field)):" | Select-Object -First 1
    if (-not $match) { return $null }
    $value = $match.Line -replace "^$([regex]::Escape($Field)):\s*", ""
    $value = $value.Trim() -replace '^["'']|["'']$', ''
    if ($value -eq "null") { return $null }
    return $value
}

function Set-YamlFieldInContent {
    param([string]$Content, [string]$Field, [string]$Value)
    $pattern = "(?m)^$([regex]::Escape($Field)):.*$"
    if ($Content -match $pattern) {
        return ($Content -replace $pattern, "${Field}: ${Value}")
    }
    return $Content.TrimEnd() + "`r`n${Field}: ${Value}`r`n"
}

function Assert-ConcreteText {
    param([string]$Name, [string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { Fail "$Name is required" }
    if ($Value -match "<[^>]+>|\bTBD\b|\bTODO\b") { Fail "$Name contains a placeholder" }
}

function Assert-PathList {
    param([string]$Name, [string[]]$Values)
    if (-not $Values -or $Values.Count -eq 0) { Fail "$Name requires at least one path" }
    foreach ($value in $Values) {
        Assert-ConcreteText $Name $value
        if ($value -match "(^|[\\/])\.\.([\\/]|$)") { Fail "$Name cannot contain '..': $value" }
        if ([System.IO.Path]::IsPathRooted($value) -or $value -match "^[\\/]") {
            Fail "$Name must contain repository-relative paths only: $value"
        }
        if ($value -match "[*?\[\]]") { Fail "$Name must contain exact paths, not wildcards: $value" }
    }
}

function New-DefaultState {
    return [pscustomobject]@{
        schema_version = 1
        status = "idle"
        worker_profile = "ds4-flash"
        max_attempts_per_root_cause = 3
        active_root_cause = $null
        attempts_by_root_cause = [pscustomobject]@{}
        total_attempts_by_root_cause = [pscustomobject]@{}
        latest_attempt = 0
        active_package = $null
        latest_evidence = $null
    }
}

function Read-State {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return New-DefaultState }
    $state = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($state.schema_version -ne 1) { Fail "Unsupported repair-state schema: $($state.schema_version)" }
    if (-not $state.PSObject.Properties["attempts_by_root_cause"]) {
        $state | Add-Member -NotePropertyName attempts_by_root_cause -NotePropertyValue ([pscustomobject]@{})
    }
    if (-not $state.PSObject.Properties["total_attempts_by_root_cause"]) {
        $state | Add-Member -NotePropertyName total_attempts_by_root_cause -NotePropertyValue ([pscustomobject]@{})
    }
    return $state
}

function Get-ObjectInt {
    param([object]$Object, [string]$Name)
    if (-not $Object) { return 0 }
    $property = $Object.PSObject.Properties[$Name]
    if (-not $property) { return 0 }
    return [int]$property.Value
}

function Set-ObjectValue {
    param([object]$Object, [string]$Name, [object]$Value)
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { $property.Value = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Normalize-PathItem {
    param([string]$Value)
    return ($Value.Trim() -replace "^``|``$", "" -replace "\\", "/")
}

function Get-MarkdownSectionItems {
    param([string]$Content, [string]$Section)
    $match = [regex]::Match(
        $Content,
        "(?ms)^##\s+$([regex]::Escape($Section))\s*\r?\n(?<body>.*?)(?=^##\s+|\z)"
    )
    if (-not $match.Success) { return @() }
    $items = @()
    foreach ($line in ($match.Groups["body"].Value -split "\r?\n")) {
        if ($line -match "^\s*-\s+(?<item>.+?)\s*$") {
            $item = Normalize-PathItem $matches["item"]
            if ($item) { $items += $item }
        }
    }
    return $items
}

function Get-NextNumber {
    param([string]$Directory, [string]$Pattern, [string]$Regex)
    $max = 0
    if (Test-Path -LiteralPath $Directory) {
        foreach ($file in Get-ChildItem -LiteralPath $Directory -Filter $Pattern -File -ErrorAction SilentlyContinue) {
            if ($file.Name -match $Regex) {
                $number = [int]$matches[1]
                if ($number -gt $max) { $max = $number }
            }
        }
    }
    return ($max + 1)
}

function Get-MaxEvidenceNumber {
    param([string]$Directory)
    $max = 0
    if (Test-Path -LiteralPath $Directory) {
        foreach ($file in Get-ChildItem -LiteralPath $Directory -Filter "A*.md" -File -ErrorAction SilentlyContinue) {
            if ($file.Name -match "^A(\d+)") {
                $number = [int]$matches[1]
                if ($number -gt $max) { $max = $number }
            }
        }
    }
    return $max
}

function Get-NextRepairTaskNumber {
    param([string]$TasksContent)
    $max = 0
    foreach ($match in [regex]::Matches($TasksContent, "(?m)^\s*-\s+\[[ xX]\]\s+R(\d+):")) {
        $number = [int]$match.Groups[1].Value
        if ($number -gt $max) { $max = $number }
    }
    return ($max + 1)
}

function Get-PreviousRepairPackage {
    param([string]$WorkPackageDir, [string]$RootId)
    $slug = $RootId.ToLowerInvariant()
    return Get-ChildItem -LiteralPath $WorkPackageDir -Filter "WP*-fix-${slug}-a*.md" -File -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -Last 1
}

function Assert-ScopeDoesNotExpand {
    param([System.IO.FileInfo]$PreviousPackage, [string[]]$NewPaths)
    if (-not $PreviousPackage) { return }
    $previousContent = Get-Content -LiteralPath $PreviousPackage.FullName -Raw
    $previousPaths = @(Get-MarkdownSectionItems $previousContent "Allowed Paths")
    if ($previousPaths.Count -eq 0) { Fail "Previous repair package has no Allowed Paths: $($PreviousPackage.Name)" }
    foreach ($path in $NewPaths) {
        $normalized = Normalize-PathItem $path
        if ($normalized -notin $previousPaths) {
            Fail "Repair scope expansion is forbidden. Added path: $normalized"
        }
    }
}

function Write-AtomicText {
    param([string]$Path, [string]$Content)
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $temp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
    Set-Content -LiteralPath $temp -Value $Content -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Initialize-RepairState {
    param([hashtable]$Task)
    foreach ($name in @("verification-history","work-packages","reports")) {
        $path = Join-Path $Task.Dir $name
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    $statePath = Join-Path $Task.Dir "repair-state.json"
    if (-not (Test-Path -LiteralPath $statePath)) {
        $state = New-DefaultState
        Write-AtomicText $statePath ($state | ConvertTo-Json -Depth 8)
    }
    return $statePath
}

function New-EvidenceContent {
    param(
        [string]$EvidenceId,
        [string]$StageName,
        [string]$RootId,
        [int]$RootAttempt,
        [string]$VerifierName,
        [string]$FailureSummary,
        [string]$CommandText,
        [string]$ExpectedText,
        [string]$ActualText,
        [string[]]$Paths,
        [string[]]$ReadFiles,
        [string]$PackagePath,
        [bool]$CircuitOpen
    )
    $pathLines = ($Paths | ForEach-Object { "- $_" }) -join "`r`n"
    $readLines = ($ReadFiles | ForEach-Object { "- $_" }) -join "`r`n"
    $packageValue = if ($PackagePath) { $PackagePath } else { "none" }
    $circuit = if ($CircuitOpen) { "triggered" } else { "not-triggered" }
    return @"
# Repair Failure Evidence: $EvidenceId

Evidence ID: $EvidenceId
Stage: $StageName
Root Cause ID: $RootId
Root Cause Attempt: $RootAttempt
Verifier: $VerifierName
Worker profile: ds4-flash

## Failure

- Summary: $FailureSummary
- Command: $CommandText
- Expected: $ExpectedText
- Actual: $ActualText

## Repair Boundary

### Allowed Paths
$pathLines

### Read First
$readLines

## Outcome

- Task phase: implement
- Repair package: $packageValue
- Circuit breaker: $circuit
"@
}

function New-RepairPackageContent {
    param(
        [int]$PackageNumber,
        [string]$TaskRootText,
        [string]$ParentTask,
        [string]$RootId,
        [int]$RootAttempt,
        [string]$EvidencePath,
        [string]$FailureSummary,
        [string]$CommandText,
        [string]$ExpectedText,
        [string]$ActualText,
        [string[]]$Paths,
        [string[]]$ReadFiles,
        [string]$PreviousPackage
    )
    $wp = "WP{0:D2}" -f $PackageNumber
    $pathLines = ($Paths | ForEach-Object { "- $_" }) -join "`r`n"
    $readLines = ($ReadFiles | ForEach-Object { "- $_" }) -join "`r`n"
    $previous = if ($PreviousPackage) { $PreviousPackage } else { "none; first repair for this root cause" }
    return @"
# ${wp}: Fix $RootId attempt $RootAttempt

Owner model: deepseek-v4-flash
Difficulty: focused
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
- Do not re-read the complete task packet or repository.
- Import architecture decisions; do not reinterpret them.

## Root Cause Boundary
- Root Cause ID: $RootId
- Attempt: $RootAttempt
- Failure evidence: $EvidencePath
- Summary: $FailureSummary
- Previous repair package: $previous
- Scope rule: this package handles only $RootId and may not expand allowed paths.

## Task Packet
- Root: $TaskRootText/
- Parent task: $ParentTask

## Allowed Paths
$pathLines

## Forbidden Paths
- tests or fixtures unless explicitly listed in Allowed Paths
- acceptance criteria and specification files
- .task.yaml
- repair-state.json
- verification-report.md
- verification-history/

## Read First
$readLines
- $EvidencePath

## Goal
- Fix the bounded root cause described above without changing architecture or acceptance.

## Steps
- [ ] Reproduce: $CommandText
- [ ] Confirm actual failure: $ActualText
- [ ] Modify only Allowed Paths.
- [ ] Re-run the exact command until it produces: $ExpectedText
- [ ] Write the required worker report.

## Done Definition
- $CommandText returns the expected result.
- No forbidden path, test weakening, acceptance change, or extra scope occurred.

## Required Verification
- Command: $CommandText
- Expected: $ExpectedText

## Do Not Game The Gate
- Do not modify tests to hide the failure.
- Do not weaken acceptance criteria or expected output.
- Do not change task state, Review result, Verify result, or verification evidence.
- Do not introduce a workaround outside the selected architecture.

## Stop Conditions
- Stop if the fix requires a path outside Allowed Paths.
- Stop if the evidence identifies a different root cause.
- Return Status: blocked with the smallest concrete blocker.

## Return Report
- Path: reports/ds4-flash-${wp}-result.md
- Required status for merge: done
- Must include changed files, raw command result, acceptance criteria touched, authority declarations, residual risk, and Extra scope taken: no.
"@
}

$task = Resolve-TaskPath $TaskName
if (-not (Test-Path -LiteralPath $task.Yaml)) { Fail ".task.yaml missing: $($task.Yaml)" }
$authorityProfile = Get-YamlField $task.Yaml "authority_profile"
if ($authorityProfile -eq "issuer-worker-v1" -and $Command -in @("record-failure","resolve")) {
    if (-not $KeyName) { Fail "KeyName is required for issuer-owned repair actions" }
    Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking
    try { $null = Assert-AuthorityIssuer $task $KeyName }
    catch { Fail $_.Exception.Message }
}
$statePath = Initialize-RepairState $task

switch ($Command) {
    "init" {
        $yaml = Get-Content -LiteralPath $task.Yaml -Raw
        $yaml = Set-YamlFieldInContent $yaml "worker_profile" "ds4-flash"
        $yaml = Set-YamlFieldInContent $yaml "lead_verifier" "codex"
        $yaml = Set-YamlFieldInContent $yaml "repair_loop_status" "idle"
        $yaml = Set-YamlFieldInContent $yaml "active_root_cause" "null"
        $yaml = Set-YamlFieldInContent $yaml "active_repair_package" "null"
        Write-AtomicText $task.Yaml $yaml
        Write-Green "Repair loop initialized: $statePath"
        exit 0
    }
    "status" {
        Get-Content -LiteralPath $statePath -Raw
        exit 0
    }
    "resolve" {
        Assert-ConcreteText "RootCauseId" $RootCauseId
        if ($RootCauseId -notmatch "^RC\d{2,}$") { Fail "RootCauseId must match RC01 or higher" }
        $state = Read-State $statePath
        if ($state.active_root_cause -and $state.active_root_cause -ne $RootCauseId) {
            Fail "Active root cause is $($state.active_root_cause), not $RootCauseId"
        }
        $reportValue = Get-YamlField $task.Yaml "verification_report"
        if (-not $reportValue) { Fail "Independent verification report is required before resolve" }
        $reportPath = if ([System.IO.Path]::IsPathRooted($reportValue)) {
            $reportValue
        }
        else {
            Join-Path $task.Dir $reportValue
        }
        if (-not (Test-Path -LiteralPath $reportPath)) { Fail "Verification report not found: $reportValue" }
        $report = Get-Content -LiteralPath $reportPath -Raw
        foreach ($pattern in @(
            "(?mi)^Verification Result:\s*pass\s*$",
            "(?mi)^Verifier role:\s*lead\s*$",
            "(?mi)^\s*-\s*Independent verification run by reviewer:\s*yes\s*$",
            "(?mi)^\s*-\s*Worker success claims accepted without verification:\s*no\s*$"
        )) {
            if ($report -notmatch $pattern) { Fail "Verification report is not independent pass evidence: $pattern" }
        }
        $verifierModel = [regex]::Match($report, "(?mi)^Verifier model:\s*(?<value>.+?)\s*$")
        $verifierContext = [regex]::Match($report, "(?mi)^Verifier context:\s*(?<value>.+?)\s*$")
        if (-not $verifierModel.Success -or -not $verifierContext.Success) {
            Fail "Verification report must declare Verifier model and Verifier context"
        }
        $model = $verifierModel.Groups["value"].Value.Trim()
        $context = $verifierContext.Groups["value"].Value.Trim()
        if (($model -eq "codex" -and $context -notin @("independent","fresh")) -or
            ($model -eq "deepseek-v4-flash" -and $context -ne "fresh") -or
            ($model -notin @("codex","deepseek-v4-flash"))) {
            Fail "Verification report does not satisfy the DS4 verifier independence contract"
        }
        $state.status = "resolved"
        $state.active_root_cause = $null
        $state.active_package = $null
        Set-ObjectValue $state.attempts_by_root_cause $RootCauseId 0
        Write-AtomicText $statePath ($state | ConvertTo-Json -Depth 8)
        $yaml = Get-Content -LiteralPath $task.Yaml -Raw
        $yaml = Set-YamlFieldInContent $yaml "repair_loop_status" "resolved"
        $yaml = Set-YamlFieldInContent $yaml "active_root_cause" "null"
        $yaml = Set-YamlFieldInContent $yaml "active_repair_package" "null"
        Write-AtomicText $task.Yaml $yaml
        Write-Green "Resolved repair root cause: $RootCauseId"
        exit 0
    }
    "record-failure" {
        $AllowedPaths = @($AllowedPaths | ForEach-Object { $_ -split ";" } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $ReadFirst = @($ReadFirst | ForEach-Object { $_ -split ";" } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Assert-ConcreteText "Stage" $Stage
        Assert-ConcreteText "RootCauseId" $RootCauseId
        Assert-ConcreteText "Summary" $Summary
        Assert-ConcreteText "FailedCommand" $FailedCommand
        Assert-ConcreteText "Expected" $Expected
        Assert-ConcreteText "Actual" $Actual
        Assert-PathList "AllowedPaths" $AllowedPaths
        Assert-PathList "ReadFirst" $ReadFirst
        if ($RootCauseId -notmatch "^RC\d{2,}$") { Fail "RootCauseId must match RC01 or higher" }

        $state = Read-State $statePath
        $rootAttempt = (Get-ObjectInt $state.attempts_by_root_cause $RootCauseId) + 1
        $rootTotalAttempt = (Get-ObjectInt $state.total_attempts_by_root_cause $RootCauseId) + 1
        $evidenceDirectory = Join-Path $task.Dir "verification-history"
        $globalAttempt = [Math]::Max([int]$state.latest_attempt, (Get-MaxEvidenceNumber $evidenceDirectory)) + 1
        $workPackageDir = Join-Path $task.Dir "work-packages"
        $previousPackage = Get-PreviousRepairPackage $workPackageDir $RootCauseId
        Assert-ScopeDoesNotExpand $previousPackage $AllowedPaths

        $evidenceId = "A{0:D3}" -f $globalAttempt
        $evidenceName = "$evidenceId-$Stage-$($RootCauseId.ToLowerInvariant()).md"
        $evidenceRelative = "verification-history/$evidenceName"
        $evidencePath = Join-Path $task.Dir ($evidenceRelative -replace "/", "\")
        if (Test-Path -LiteralPath $evidencePath) { Fail "Evidence already exists: $evidenceRelative" }

        $circuitOpen = $rootAttempt -ge [int]$state.max_attempts_per_root_cause
        $packageRelative = $null
        $packagePath = $null
        $packageContent = $null
        if (-not $circuitOpen) {
            $packageNumber = Get-NextNumber $workPackageDir "WP*.md" "^WP(\d+)"
            $packageName = "WP{0:D2}-fix-{1}-a{2}.md" -f $packageNumber, $RootCauseId.ToLowerInvariant(), $rootAttempt
            $packageRelative = "work-packages/$packageName"
            $packagePath = Join-Path $task.Dir ($packageRelative -replace "/", "\")
            $taskRootText = (($task.Root -replace "\\","/").TrimEnd("/") + "/" + ($TaskName -replace "\\","/"))
            $packageContent = New-RepairPackageContent `
                -PackageNumber $packageNumber `
                -TaskRootText $taskRootText `
                -ParentTask ($TaskName -replace "^.+/","") `
                -RootId $RootCauseId `
                -RootAttempt $rootAttempt `
                -EvidencePath $evidenceRelative `
                -FailureSummary $Summary `
                -CommandText $FailedCommand `
                -ExpectedText $Expected `
                -ActualText $Actual `
                -Paths $AllowedPaths `
                -ReadFiles $ReadFirst `
                -PreviousPackage $(if ($previousPackage) { "work-packages/$($previousPackage.Name)" } else { $null })
        }

        $tasksPath = Join-Path $task.Dir "tasks.md"
        if (-not (Test-Path -LiteralPath $tasksPath)) { Fail "tasks.md missing" }
        $tasksContent = Get-Content -LiteralPath $tasksPath -Raw
        $repairTaskNumber = Get-NextRepairTaskNumber $tasksContent
        $repairTaskId = "R{0:D2}" -f $repairTaskNumber
        $repairDescription = if ($circuitOpen) {
            "Architecture review required for $RootCauseId after attempt $rootAttempt; automatic redistribution stopped."
        }
        else {
            "Repair $RootCauseId attempt $rootAttempt using $packageRelative."
        }
        $newTasksContent = $tasksContent.TrimEnd() + "`r`n- [ ] ${repairTaskId}: $repairDescription`r`n"

        $evidenceContent = New-EvidenceContent `
            -EvidenceId $evidenceId `
            -StageName $Stage `
            -RootId $RootCauseId `
            -RootAttempt $rootAttempt `
            -VerifierName $Verifier `
            -FailureSummary $Summary `
            -CommandText $FailedCommand `
            -ExpectedText $Expected `
            -ActualText $Actual `
            -Paths $AllowedPaths `
            -ReadFiles $ReadFirst `
            -PackagePath $packageRelative `
            -CircuitOpen $circuitOpen

        Set-ObjectValue $state.attempts_by_root_cause $RootCauseId $rootAttempt
        Set-ObjectValue $state.total_attempts_by_root_cause $RootCauseId $rootTotalAttempt
        $state.latest_attempt = $globalAttempt
        $state.active_root_cause = $RootCauseId
        $state.latest_evidence = $evidenceRelative
        if ($circuitOpen) {
            $state.status = "architecture_review"
            $state.active_package = $null
        }
        else {
            $state.status = "repair_required"
            $state.active_package = $packageRelative
        }

        $yaml = Get-Content -LiteralPath $task.Yaml -Raw
        $globalFixAttempts = [int](Get-YamlField $task.Yaml "fix_attempts")
        $yaml = Set-YamlFieldInContent $yaml "phase" "implement"
        $yaml = Set-YamlFieldInContent $yaml "fix_attempts" ($globalFixAttempts + 1)
        $yaml = Set-YamlFieldInContent $yaml "repair_loop_status" $state.status
        $yaml = Set-YamlFieldInContent $yaml "active_root_cause" $RootCauseId
        $yaml = Set-YamlFieldInContent $yaml "active_repair_package" $(if ($packageRelative) { $packageRelative } else { "null" })
        if ($Stage -eq "review") {
            $yaml = Set-YamlFieldInContent $yaml "review_result" "fail"
        }
        else {
            $yaml = Set-YamlFieldInContent $yaml "verify_result" "fail"
        }

        $verificationPath = Join-Path $task.Dir "verification-report.md"
        $verificationContent = if (Test-Path -LiteralPath $verificationPath) {
            Get-Content -LiteralPath $verificationPath -Raw
        }
        else {
            "# Verification Report`r`n"
        }
        if ($verificationContent -notmatch "(?m)^## Repair Loop Failures\s*$") {
            $verificationContent = $verificationContent.TrimEnd() + "`r`n`r`n## Repair Loop Failures`r`n"
        }
        $verificationContent = $verificationContent.TrimEnd() +
            "`r`n- ${evidenceId}: [$Stage/$RootCauseId attempt $rootAttempt]($evidenceRelative) - $Summary`r`n"

        Write-AtomicText $evidencePath $evidenceContent
        if ($packagePath) { Write-AtomicText $packagePath $packageContent }
        Write-AtomicText $tasksPath $newTasksContent
        Write-AtomicText $verificationPath $verificationContent
        Write-AtomicText $statePath ($state | ConvertTo-Json -Depth 8)
        Write-AtomicText $task.Yaml $yaml

        if ($authorityProfile -eq "issuer-worker-v1") {
            & (Join-Path $PSScriptRoot "task-packet-seal.ps1") seal $TaskName -KeyName $KeyName
            if ($LASTEXITCODE -ne 0) { Fail "Failed to reseal authority task after repair publication" }
        }

        if ($circuitOpen) {
            Write-Yellow "Circuit breaker opened for $RootCauseId after attempt $rootAttempt. Architecture review required."
        }
        else {
            Write-Green "Published repair package: $packageRelative"
        }
        Write-Green "Recorded immutable evidence: $evidenceRelative"
        exit 0
    }
}
