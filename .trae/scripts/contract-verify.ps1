# Contract Verify -- Phase-level contract enforcement
# Usage: contract-verify.ps1 <task-name> <action> [-Phase plan|implement|verify] [-Strict]
# Actions: init | verify | report

# Part of: Docs/AI/46-Enforcement-Framework.md

param(
    [Parameter(Mandatory=$true)][string]$TaskName,
    [Parameter(Mandatory=$true)][string]$Action,
    [string]$Phase = "",
    [switch]$Strict,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$VERSION = "1.0.0"

$TASK_ROOTS = @(".trae\tasks", ".opencode\tasks", ".codex\tasks")
$PROJECTS = @("rts","characterdesigntool","_shared")

function Resolve-TaskPath {
    param([string]$Name)
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if (-not $root) { $root = $PWD.Path }
    if ($Name -match "^(.+?)/(.+)$") {
        $project = $matches[1]; $task = $matches[2]
        foreach ($tr in $TASK_ROOTS) {
            $dir = Join-Path $root "$tr\$project\$task"
            if (Test-Path $dir) { return @{ Project=$project; Task=$task; Dir=$dir; Root=$root; TaskRoot=$tr } }
        }
    }
    foreach ($tr in $TASK_ROOTS) {
        foreach ($p in $PROJECTS) {
            $dir = Join-Path $root "$tr\$p\$Name"
            if (Test-Path $dir) { return @{ Project=$p; Task=$Name; Dir=$dir; Root=$root; TaskRoot=$tr } }
        }
        $direct = Join-Path $root "$tr\$Name"
        if (Test-Path $direct) { return @{ Project=""; Task=$Name; Dir=$direct; Root=$root; TaskRoot=$tr } }
    }
    Write-Host "ERROR: Task not found: $Name" -ForegroundColor Red
    exit 1
}

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Get-PhaseContracts {
    param([string]$PPhase, [string]$ProjectType, [string]$TaskDir)
    $contracts = @()
    switch ($PPhase) {
        "plan" {
            $contracts += @{ id="PC01"; description="task-state initialized"; verify_type="file_exists"; verify_path=".task.yaml"; blocking=$true }
            $contracts += @{ id="PC02"; description="Mature Solution Evidence"; verify_type="content_pattern"; verify_path="analysis.md"; verify_pattern="Mature Solution Evidence"; blocking=$true }
            $contracts += @{ id="PC03"; description="Requirement classified"; verify_type="content_pattern"; verify_path="routing.md"; verify_pattern="deep-discovery|fast-track"; blocking=$true }
            $contracts += @{ id="PC04"; description="Quality Gate declared"; verify_type="content_pattern"; verify_path="routing.md"; verify_pattern="Quality Gate"; blocking=$true }
            $contracts += @{ id="PC05"; description="Architecture Context"; verify_type="content_pattern"; verify_path="analysis.md"; verify_pattern="Architecture Context"; blocking=$true }
            $contracts += @{ id="PC06"; description="Acceptance Criteria"; verify_type="content_pattern"; verify_path="analysis.md"; verify_pattern="Acceptance Criteria"; blocking=$true }
            $contracts += @{ id="PC07"; description="User confirmed plan"; verify_type="yaml_field"; verify_path=".task.yaml"; verify_field="user_confirmed_plan"; verify_expected="true"; blocking=$true }
            $contracts += @{ id="PC08"; description="Router skill loaded"; verify_type="yaml_field"; verify_path=".task.yaml"; verify_field="router_skill_loaded"; verify_expected="true"; blocking=$true }
            $contracts += @{ id="PC09"; description="doc-impact.md exists"; verify_type="file_exists"; verify_path="doc-impact.md"; blocking=$true }
            $contracts += @{ id="PC10"; description="Work Package Policy"; verify_type="content_pattern"; verify_path="routing.md"; verify_pattern="Work Package Policy"; blocking=$true }
            $contracts += @{ id="PC11"; description="Automated Verification Plan"; verify_type="content_pattern"; verify_path="analysis.md"; verify_pattern="Automated Verification Plan"; blocking=$true }
        }
        "implement" {
            $contracts += @{ id="IC01"; description="can-edit passed"; verify_type="command"; verify_command="can-edit"; verify_expected_exit=0; blocking=$true }
            $contracts += @{ id="IC02"; description="user_confirmed_plan=true"; verify_type="yaml_field"; verify_path=".task.yaml"; verify_field="user_confirmed_plan"; verify_expected="true"; blocking=$true }
            $contracts += @{ id="IC03"; description="spec.md exists"; verify_type="file_exists"; verify_path="spec.md"; blocking=$true }
        }
        "verify" {
            $contracts += @{ id="VC01"; description="verification-report.md exists"; verify_type="file_exists"; verify_path="verification-report.md"; blocking=$true }
            $contracts += @{ id="VC02"; description="Report has required sections"; verify_type="content_pattern"; verify_path="verification-report.md"; verify_pattern="Automated Verification|Acceptance Criteria|Architecture Compliance|Test Evidence|Residual Risk"; blocking=$true }
            $contracts += @{ id="VC03"; description="verify_result is pass"; verify_type="yaml_field"; verify_path=".task.yaml"; verify_field="verify_result"; verify_expected="pass"; blocking=$true }
        }
    }
    return $contracts
}

function ConvertTo-YamlBlock {
    param([array]$Contracts, [string]$SectionName)
    $lines = @()
    $lines += "${SectionName}:"
    foreach ($c in $Contracts) {
        $lines += "  - id: $($c.id)"
        $desc = $c.description -replace '"', "'"
        $q = [char]0x22
        $lines += "    description: $q$desc$q"
        $lines += "    verify_type: $($c.verify_type)"
        if ($c.ContainsKey("verify_path")) { $lines += "    verify_path: $($c.verify_path)" }
        if ($c.ContainsKey("verify_pattern")) { $lines += "    verify_pattern: $q$($c.verify_pattern)$q" }
        if ($c.ContainsKey("verify_field")) { $lines += "    verify_field: $($c.verify_field)" }
        if ($c.ContainsKey("verify_expected")) { $lines += "    verify_expected: $q$($c.verify_expected)$q" }
        if ($c.ContainsKey("verify_command")) { $lines += "    verify_command: $q$($c.verify_command)$q" }
        if ($c.ContainsKey("verify_expected_exit")) { $lines += "    verify_expected_exit: $($c.verify_expected_exit)" }
        $lines += "    blocking: $($c.blocking.ToString().ToLower())"
    }
    return $lines -join "
"
}

function Invoke-Init {
    param($Resolved)
    $taskDir = $Resolved.Dir
    $contractPath = Join-Path $taskDir "contract.yaml"
    if ((Test-Path $contractPath) -and -not $Apply) {
        Write-Yellow "contract.yaml already exists. Use -Apply to overwrite."
        return
    }
    $yamlPath = Join-Path $taskDir ".task.yaml"
    $projectType = "other"
    if (Test-Path $yamlPath) {
        $yamlContent = Get-Content $yamlPath -Raw
        if ($yamlContent -match 'project_type:\s*(\S+)') { $projectType = $matches[1] }
    }
    $planContracts = Get-PhaseContracts -PPhase "plan" -ProjectType $projectType -TaskDir $taskDir
    $implementContracts = Get-PhaseContracts -PPhase "implement" -ProjectType $projectType -TaskDir $taskDir
    $verifyContracts = Get-PhaseContracts -PPhase "verify" -ProjectType $projectType -TaskDir $taskDir
    $yaml = @()
    $yaml += "# contract.yaml - Auto-generated by contract-verify.ps1 v$VERSION"
    $yaml += "# Regenerate with: contract-verify.ps1 <task> init -Apply"
    $yaml += ""
    $yaml += "task_name: $TaskName"
    $yaml += "project_type: $projectType"
    $yaml += [string]::Format('generated_at: {0}', (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'))
    $yaml += "generator_version: $VERSION"
    $yaml += ""
    $yaml += ConvertTo-YamlBlock -Contracts $planContracts -SectionName "plan_contracts"
    $yaml += ""
    $yaml += ConvertTo-YamlBlock -Contracts $implementContracts -SectionName "implement_contracts"
    $yaml += ""
    $yaml += ConvertTo-YamlBlock -Contracts $verifyContracts -SectionName "verify_contracts"
    Set-Content -Path $contractPath -Value ($yaml -join "
") -Encoding UTF8 -NoNewline
    Write-Green "contract.yaml generated at: $contractPath"
    Write-Host "  Plan: $($planContracts.Count) | Implement: $($implementContracts.Count) | Verify: $($verifyContracts.Count)"
}

function Test-ContractItem {
    param([hashtable]$Contract, [string]$TaskDir, [string]$Root)
    $result = @{ Id=$Contract.id; Description=$Contract.description; Blocking=$Contract.blocking; Status="pending"; Evidence="" }
    $targetPath = Join-Path $TaskDir $Contract.verify_path
    switch ($Contract.verify_type) {
        "file_exists" {
            if (Test-Path $targetPath) {
                $size = (Get-Item $targetPath).Length
                if ($size -gt 0) { $result.Status = "pass"; $result.Evidence = "File exists ($size bytes)" }
                else { $result.Status = "fail"; $result.Evidence = "File exists but empty" }
            } else { $result.Status = "fail"; $result.Evidence = "File not found: $($Contract.verify_path)" }
        }
        "content_pattern" {
            if (-not (Test-Path $targetPath)) { $result.Status = "fail"; $result.Evidence = "File not found: $($Contract.verify_path)"; break }
            $content = Get-Content -LiteralPath $targetPath -Raw -ErrorAction SilentlyContinue
            if ($null -eq $content) { $result.Status = "fail"; $result.Evidence = "Cannot read file"; break }
            if ($content -match $Contract.verify_pattern) { $result.Status = "pass"; $result.Evidence = "Pattern matched" }
            else { $result.Status = "fail"; $result.Evidence = "Pattern not found in $($Contract.verify_path)" }
        }
        "yaml_field" {
            if (-not (Test-Path $targetPath)) { $result.Status = "fail"; $result.Evidence = "File not found"; break }
            $yc = Get-Content -LiteralPath $targetPath -Raw
            $field = $Contract.verify_field; $expected = $Contract.verify_expected
            if ($yc -match "(?m)^${field}:\s*(.+)$") {
                $actual = $matches[1].Trim() -replace '^["'']|["'']$', ''
                if ($actual -eq $expected) { $result.Status = "pass"; $result.Evidence = "$field = $actual" }
                else { $result.Status = "fail"; $result.Evidence = "$field = '$actual' (expected: '$expected')" }
            } else { $result.Status = "fail"; $result.Evidence = "Field '$field' not found" }
        }
        "command" {
            $cmd = $Contract.verify_command -replace '<task>', $TaskName
            if ($cmd -eq "can-edit") {
                $scriptPath = Join-Path $Root ".trae\scripts\task-state.ps1"
                $q = [char]0x22
                $cmd = "& $q$scriptPath$q can-edit $TaskName"
            }
            try {
                $null = & powershell -NoProfile -Command $cmd 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq $Contract.verify_expected_exit) { $result.Status = "pass"; $result.Evidence = "Exit code: $exitCode" }
                else { $result.Status = "fail"; $result.Evidence = "Exit code: $exitCode (expected: $($Contract.verify_expected_exit))" }
            } catch { $result.Status = "fail"; $result.Evidence = "Command error: $($_.Exception.Message)" }
        }
        default { $result.Status = "fail"; $result.Evidence = "Unknown verify_type: $($Contract.verify_type)" }
    }
    return $result
}

function Get-ContractItems {
    param([string]$ContractPath, [string]$CPhase)
    if (-not (Test-Path $ContractPath)) { Write-Red "contract.yaml not found"; return @() }
    $content = Get-Content -LiteralPath $ContractPath -Raw
    $items = @()
    $sections = @()
    if ([string]::IsNullOrEmpty($CPhase)) { $sections = @("plan_contracts","implement_contracts","verify_contracts") }
    else {
        $map = @{ "plan"="plan_contracts"; "implement"="implement_contracts"; "verify"="verify_contracts" }
        if ($map.ContainsKey($CPhase)) { $sections = @($map[$CPhase]) } else { return @() }
    }
    $fileLines = $content -split "
"
    foreach ($section in $sections) {
        $inSection = $false; $currentItem = @{}
        foreach ($line in $fileLines) {
            $trimmed = $line.TrimEnd()
            if ($trimmed -match "^${section}:\s*$") { $inSection = $true; continue }
            if ($inSection -and $trimmed -match "^[a-z_]+:" -and $trimmed -notmatch "^\s") {
                if ($currentItem.Count -gt 0) { $items += [hashtable]$currentItem; $currentItem = @{} }
                $inSection = $false; continue
            }
            if (-not $inSection) { continue }
            if ($trimmed -match "^\s+-\s+id:\s*(.+)") {
                if ($currentItem.Count -gt 0) { $items += [hashtable]$currentItem }
                $currentItem = @{ id=$matches[1].Trim(); blocking=$true }
            }
            elseif ($trimmed -match '^\s+description:\s*"(.+)"') { $currentItem["description"] = $matches[1] }
            elseif ($trimmed -match '^\s+verify_type:\s*(.+)') { $currentItem["verify_type"] = $matches[1].Trim() }
            elseif ($trimmed -match '^\s+verify_path:\s*(.+)') { $currentItem["verify_path"] = $matches[1].Trim() }
            elseif ($trimmed -match '^\s+verify_pattern:\s*"(.+)"') { $currentItem["verify_pattern"] = $matches[1] }
            elseif ($trimmed -match '^\s+verify_field:\s*(.+)') { $currentItem["verify_field"] = $matches[1].Trim() }
            elseif ($trimmed -match '^\s+verify_expected:\s*"(.+)"') { $currentItem["verify_expected"] = $matches[1] }
            elseif ($trimmed -match '^\s+verify_command:\s*"(.+)"') { $currentItem["verify_command"] = $matches[1] }
            elseif ($trimmed -match '^\s+verify_expected_exit:\s*(.+)') { $currentItem["verify_expected_exit"] = [int]$matches[1].Trim() }
            elseif ($trimmed -match '^\s+blocking:\s*(.+)') { $currentItem["blocking"] = ($matches[1].Trim() -eq "true") }
        }
        if ($currentItem.Count -gt 0) { $items += [hashtable]$currentItem }
    }
    return $items
}

function Invoke-Verify {
    param($Resolved)
    $taskDir = $Resolved.Dir
    $contractPath = Join-Path $taskDir "contract.yaml"
    if (-not (Test-Path $contractPath)) { Write-Red "contract.yaml not found. Run init first."; exit 1 }
    $yamlPath = Join-Path $taskDir ".task.yaml"
    $currentPhase = $Phase
    if ([string]::IsNullOrEmpty($currentPhase) -and (Test-Path $yamlPath)) {
        $yc = Get-Content $yamlPath -Raw
        if ($yc -match 'phase:\s*(\S+)') { $currentPhase = $matches[1] }
    }
    Write-Host "=== Contract Verification ===" -ForegroundColor Cyan
    Write-Host "Task: $TaskName"
    Write-Host "Phase: $currentPhase"
    Write-Host ""
    $items = Get-ContractItems -ContractPath $contractPath -CPhase $currentPhase
    if ($items.Count -eq 0) { Write-Yellow "No contract items for phase: $currentPhase"; return }
    $passCount = 0; $failCount = 0; $blockCount = 0
    $failItems = @()
    foreach ($item in $items) {
        $r = Test-ContractItem -Contract $item -TaskDir $taskDir -Root $Resolved.Root
        if ($r.Status -eq "pass") { Write-Green "  [PASS] $($r.Id): $($r.Description)"; $passCount++ }
        else {
            Write-Red "  [FAIL] $($r.Id): $($r.Description)"; Write-Red "         $($r.Evidence)"
            $failCount++; if ($r.Blocking) { $blockCount++ }
            $failItems += $r
        }
    }
    Write-Host ""
    Write-Host "--- Summary ---"
    Write-Host "Total: $($items.Count) | Pass: $passCount | Fail: $failCount | Blocking: $blockCount"
    if ($blockCount -gt 0) {
        Write-Red "BLOCKED: $blockCount blocking contract(s) failed."
        Write-Red "Agent MUST NOT proceed until all blocking contracts pass."
        Write-Host ""
        Write-Host "=== REPAIR GUIDANCE ===" -ForegroundColor Yellow
        foreach ($fi in $failItems) {
            if (-not $fi.Blocking) { continue }
            $repair = Get-RepairGuidance -ContractId $fi.Id -Description $fi.Description -Evidence $fi.Evidence
            Write-Host "  REPAIR $($fi.Id): $repair" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Yellow "Run 'contract-verify scaffold' to generate template files with all required markers."
        Write-Yellow "See Docs/AI/48-Plan-Phase-Checklist.md for the complete checklist."
        if ($Strict) { exit 1 }
    } else {
        Write-Green "All blocking contracts passed."
        if ($failCount -gt 0) { Write-Yellow "$failCount non-blocking contract(s) failed." }
    }
}

function Get-RepairGuidance {
    param([string]$ContractId, [string]$Description, [string]$Evidence)
    switch ($ContractId) {
        "PC01" { return "Run: task-state init <task> full" }
        "PC02" { return "Add 'Mature Solution Evidence' section to analysis.md with all 6 markers: Project-local evidence, Official/framework evidence, Options compared, Rejected shortcuts, Selected mature path" }
        "PC03" { return "Add 'deep-discovery' or 'fast-track' classification to routing.md" }
        "PC04" { return "Add '## Quality Gate' section to routing.md" }
        "PC05" { return "Add '## Architecture Context' section with 'System boundaries' and 'Dependency map' markers to analysis.md" }
        "PC06" { return "Add '## Acceptance Criteria' section to analysis.md with AC1, AC2, etc." }
        "PC07" { return "Run: task-state set <task> user_confirmed_plan true" }
        "PC08" { return "Run: task-state set <task> router_skill_loaded true" }
        "PC09" { return "Create doc-impact.md with - Project/System/Owner scope fields and Code Changes or No Code Changes section" }
        "PC10" { return "Add '## Work Package Policy' with External workers and MVP declaration to routing.md" }
        "PC11" { return "Add '## Automated Verification Plan' section to analysis.md" }
        "IC01" { return "Run: task-state can-edit <task> — if blocked, ensure Plan phase is complete" }
        "IC02" { return "Run: task-state set <task> user_confirmed_plan true" }
        "IC03" { return "Create spec.md with GIVEN/WHEN/THEN specification" }
        "VC01" { return "Create verification-report.md with the 5 required sections: Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk" }
        "VC02" { return "Add all 5 required sections to verification-report.md: Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk" }
        "VC03" { return "Set verify_result to pass in .task.yaml after verification is complete" }
        default { return "Fix: $Description — See Docs/AI/48-Plan-Phase-Checklist.md" }
    }
}
function Invoke-Report {
    param($Resolved)
    $taskDir = $Resolved.Dir
    $contractPath = Join-Path $taskDir "contract.yaml"
    if (-not (Test-Path $contractPath)) { Write-Red "contract.yaml not found."; exit 1 }
    $items = Get-ContractItems -ContractPath $contractPath -CPhase ""
    $results = @()
    foreach ($item in $items) { $results += Test-ContractItem -Contract $item -TaskDir $taskDir -Root $Resolved.Root }
    $reportPath = Join-Path $taskDir "contract-report.md"
    $rLines = @()
    $rLines += "# Contract Verification Report"
    $rLines += ""
    $rLines += [string]::Format('Date: {0}', (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    $rLines += "Task: $TaskName"
    $rLines += ""
    $rLines += "| ID | Description | Status | Blocking | Evidence |"
    $rLines += "|----|------------|--------|----------|----------|"
    foreach ($r in $results) {
        $st = if ($r.Status -eq "pass") { "PASS" } else { "FAIL" }
        $bl = if ($r.Blocking) { "YES" } else { "no" }
        $ev = $r.Evidence -replace '\|', '\|'
        $rLines += "| $($r.Id) | $($r.Description) | $st | $bl | $ev |"
    }
    $pc = ($results | Where-Object { $_.Status -eq 'pass' }).Count
    $fc = ($results | Where-Object { $_.Status -eq 'fail' }).Count
    $bc = ($results | Where-Object { $_.Status -eq 'fail' -and $_.Blocking -eq $true }).Count
    $rLines += ""
    $rLines += "## Summary"
    $rLines += ""
    $rLines += "- Total: $($results.Count)"
    $rLines += "- Pass: $pc"
    $rLines += "- Fail: $fc"
    $rLines += "- Blocking failures: $bc"
    $rLines += ""
    $verdict = if ($bc -eq 0) { 'PASS' } else { 'BLOCKED' }
    $rLines += "Verdict: $verdict"
    Set-Content -Path $reportPath -Value ($rLines -join "
") -Encoding UTF8 -NoNewline
    Write-Green "Report: $reportPath"
}

function Invoke-Status {
    param($Resolved)
    $taskDir = $Resolved.Dir
    $contractPath = Join-Path $taskDir "contract.yaml"
    if (-not (Test-Path $contractPath)) {
        Write-Red "No contract.yaml found. Run 'contract-verify init' first."
        exit 1
    }
    $items = Get-ContractItems -ContractPath $contractPath -CPhase ""
    if ($items.Count -eq 0) {
        Write-Yellow "contract.yaml is empty — no contract items found."
        return
    }
    $yamlPath = Join-Path $taskDir ".task.yaml"
    $currentPhase = ""
    if (Test-Path $yamlPath) {
        $yc = Get-Content $yamlPath -Raw
        if ($yc -match 'phase:\s*(\S+)') { $currentPhase = $matches[1] }
    }
    Write-Host "=== Contract Status ===" -ForegroundColor Cyan
    Write-Host "Task: $TaskName"
    Write-Host "Phase: $currentPhase"
    Write-Host ""
    $phaseMap = @{ "PC"="plan"; "IC"="implement"; "VC"="verify" }
    $phaseGroups = @{}
    foreach ($item in $items) {
        $prefix = if ($item.id -match "^([A-Z]+)") { $matches[1] } else { "OTHER" }
        $pName = if ($phaseMap.ContainsKey($prefix)) { $phaseMap[$prefix] } else { "other" }
        if (-not $phaseGroups.ContainsKey($pName)) { $phaseGroups[$pName] = @() }
        $phaseGroups[$pName] += $item
    }
    $totalPass = 0; $totalFail = 0; $totalBlock = 0; $totalItems = $items.Count
    Write-Host "  Phase       | Total | Pass | Fail | Blocking"
    Write-Host "  -------------|-------|------|------|---------"
    foreach ($pName in @("plan","implement","verify")) {
        if (-not $phaseGroups.ContainsKey($pName)) { continue }
        $group = $phaseGroups[$pName]
        $pPass = 0; $pFail = 0; $pBlock = 0
        foreach ($item in $group) {
            $r = Test-ContractItem -Contract $item -TaskDir $taskDir -Root $Resolved.Root
            if ($r.Status -eq "pass") { $pPass++; $totalPass++ }
            else { $pFail++; $totalFail++; if ($r.Blocking) { $pBlock++; $totalBlock++ } }
        }
        $pNamePad = $pName.PadRight(12)
        Write-Host "  $pNamePad |    $($group.Count) |    $pPass |    $pFail | $pBlock"
    }
    Write-Host "  -------------|-------|------|------|---------"
    $totalPad = "TOTAL".PadRight(12)
    Write-Host "  $totalPad |    $totalItems |    $totalPass |    $totalFail | $totalBlock"
    Write-Host ""
    if ($totalBlock -gt 0) {
        Write-Red "Status: BLOCKED ($totalBlock blocking failure(s))"
        if ($Strict) { exit 1 }
    } elseif ($totalFail -gt 0) {
        Write-Yellow "Status: HAS FAILURES ($totalFail non-blocking)"
    } else {
        Write-Green "Status: ALL PASS"
    }
}
function Invoke-Scaffold {
    param($Resolved)
    $taskDir = $Resolved.Dir
    $yamlPath = Join-Path $taskDir ".task.yaml"
        $profile = "fast"
    if (Test-Path $yamlPath) {
        $yc = Get-Content $yamlPath -Raw
        if ($yc -match 'change_profile:\s*(\S+)') { $profile = $matches[1] }
    }
    # Default to fast-track if not explicitly deep
    if ($profile -ne "deep") { $profile = "fast" }

    $scaffolded = @()

    # --- routing.md ---
    $routingPath = Join-Path $taskDir "routing.md"
    if (-not (Test-Path $routingPath)) {
        $fastSection = ""
        if ($profile -eq "fast") {
            $fastSection = @"

## Fast Track Assessment
- Expected behavior is concrete: yes
- Change is bounded: yes
- Architecture or data ownership change: no
- User journey redesign: no
- Unresolved high-impact implicit requirements: none
- Verification is bounded: yes
- Fast-track reason: (describe why this qualifies as fast-track)
"@
        } elseif ($profile -eq "deep") {
            $fastSection = @"

## Requirement Discovery Gate
- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none
"@
        }

        $routingContent = @"
# Routing Decision

## Task
$TaskName

## Project Type
(UE5 / Web / Other)

## Requirement Classification: fast-track
- (If deep-discovery, replace with: deep-discovery)

## Quality Gate
- (List quality conditions that must be met)

## Work Package Policy
- External workers: no
- MVP/prototype requested by user: no
$fastSection
"@
        Set-Content -Path $routingPath -Value $routingContent -Encoding UTF8
        $scaffolded += "routing.md"
    }

    # --- analysis.md ---
    $analysisPath = Join-Path $taskDir "analysis.md"
    if (-not (Test-Path $analysisPath)) {
        $analysisContent = @"
# Analysis

## Architecture Context
(Describe the system context, what components are involved, and the change scope.)

**System boundaries**: (Describe what is in-scope and out-of-scope. What systems are touched?)

**Dependency map**: (List dependencies: Script/Component A -> B -> C. No new dependencies introduced.)

## Mature Solution Evidence
**Project-local evidence**: (Cite existing code/patterns in this project that support the approach.)

**Official/framework evidence**: (Cite official docs, framework patterns, or well-established practices.)

**Options compared**:
1. Option A: (description) — (pros)
2. Option B: (description) — (pros/cons)
3. Option C: (description) — (cons)

**Rejected shortcuts**: (Explain why you did NOT take the shortcut approaches.)

**Selected mature path**: (State which option you chose and why.)

1. **Project internal**: (Reference to existing implementation.)
2. **Official reference**: (Reference to official documentation.)
3. **Open source reference**: (Reference to open-source, or "No external dependency needed.")
4. **Design doc**: (Reference to Docs/AI/ document.)
5. **Existing implementation**: (What already exists that this builds on.)
6. **Risk assessment**: (Assessment of risk level and reasoning.)

## Acceptance Criteria
- AC1: (Measurable criterion)
- AC2: (Measurable criterion)
- AC3: PowerShell parser reports zero errors
- AC4: Existing functionality unchanged

## Automated Verification Plan
- Step 1: (Verification command or action)
- Step 2: (Verification command or action)
- PowerShell syntax check: zero errors
"@
        Set-Content -Path $analysisPath -Value $analysisContent -Encoding UTF8
        $scaffolded += "analysis.md"
    }

    # --- spec.md ---
    $specPath = Join-Path $taskDir "spec.md"
    if (-not (Test-Path $specPath)) {
        $specContent = @"
# Spec

## GIVEN
- (Precondition 1)
- (Precondition 2)

## WHEN
- (Action or trigger)

## THEN
- (Expected outcome 1)
- (Expected outcome 2)

## Constraints
- (Constraint 1)
- (Constraint 2)
"@
        Set-Content -Path $specPath -Value $specContent -Encoding UTF8
        $scaffolded += "spec.md"
    }

    # --- tasks.md ---
    $tasksPath = Join-Path $taskDir "tasks.md"
    if (-not (Test-Path $tasksPath)) {
        $tasksContent = @"
# Tasks

## Task 1: Implement
- [ ] (Implementation step 1)
- [ ] (Implementation step 2)
- Basis: spec.md

## Task 2: Automated verification
- [ ] Run verification commands
- [ ] Confirm all AC pass
- Basis: analysis.md Automated Verification Plan

## Task 3: Acceptance Criteria mapping
- [ ] AC1: (verify)
- [ ] AC2: (verify)
- Basis: analysis.md Acceptance Criteria

## Task 4: Mature-path verification
- [ ] Verify the selected mature path is followed correctly
- [ ] Verify rejected shortcuts are not taken
- Basis: analysis.md Selected mature path and Rejected shortcuts
"@
        Set-Content -Path $tasksPath -Value $tasksContent -Encoding UTF8
        $scaffolded += "tasks.md"
    }

    # --- doc-impact.md ---
    $docImpactPath = Join-Path $taskDir "doc-impact.md"
    if (-not (Test-Path $docImpactPath)) {
        $docImpactContent = @"
# Doc Impact Assessment

- Project: (project name or "infrastructure")
- System: (system name)
- Owner: (owner/team)

## Code Changes
- (List files under Project/ that will be changed, OR remove this section and use No Code Changes below)

## No Code Changes
Reason: (If no Project/ files are changed, explain why. Remove this section if Code Changes exist.)

## Documentation Updates
- (List documentation updates, or "None required")

## Docs Tree Updates
- (List DOCS_TREE.md updates, or "None")
"@
        Set-Content -Path $docImpactPath -Value $docImpactContent -Encoding UTF8
        $scaffolded += "doc-impact.md"
    }

    # --- execution-prompt.md ---
    $epPath = Join-Path $taskDir "execution-prompt.md"
    if (-not (Test-Path $epPath)) {
        $epContent = @"
# Execution Prompt

## Role
Implement Agent — (describe role)

## Goal
(Describe the concrete goal)

## Task Packet Truth Sources
- spec.md — behavioral specification
- analysis.md — architecture context and mature solution evidence
- routing.md — skill routing and work package policy
- tasks.md — task breakdown

## Confirmed Decisions
- (Decision 1)
- (Decision 2)

## Accepted Architecture
- (Architecture description)
- (Key design choices)

## Allowed Paths
- (List files that may be modified)

## Forbidden Paths
- (List files/paths that must NOT be modified)

## Non-Goals
- (What is explicitly NOT in scope)

## Acceptance Criteria
- AC1: (criterion)
- AC2: (criterion)

## Verification Commands
(Describe the verification steps)

## Stop Conditions
- All AC pass
- PowerShell parser zero errors
- No regressions

## Evidence Rule
Every AC must have script output as evidence. Verbal claims without output are not accepted.
"@
        Set-Content -Path $epPath -Value $epContent -Encoding UTF8
        $scaffolded += "execution-prompt.md"
    }

    Write-Green "Scaffolded $($scaffolded.Count) files:"
    foreach ($f in $scaffolded) { Write-Host "  + $f" -ForegroundColor Green }
    Write-Host ""
    Write-Yellow "IMPORTANT: These are templates with placeholder values in parentheses."
    Write-Yellow "Fill in all (parenthesized) placeholders with concrete content."
    Write-Yellow "Remove sections that do not apply."
    Write-Yellow "Reference: Docs/AI/48-Plan-Phase-Checklist.md"
}

$resolved = Resolve-TaskPath $TaskName
switch ($Action) {
    "init"     { Invoke-Init -Resolved $resolved }
    "verify"   { Invoke-Verify -Resolved $resolved }
    "report"   { Invoke-Report -Resolved $resolved }
    "status"   { Invoke-Status -Resolved $resolved }
    "scaffold" { Invoke-Scaffold -Resolved $resolved }
    default    { Write-Red "Unknown action: $Action. Use: init | verify | report | status | scaffold"; exit 1 }
}

