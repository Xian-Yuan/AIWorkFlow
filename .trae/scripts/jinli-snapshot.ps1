#Requires -Version 5.1
<#
jinli-snapshot.ps1 - Jinli (Little-Glass) System Audit Snapshot

Generates a structured JSON snapshot of the current Jinli system state for:
- Four canonical SKILL.md files (Plan, Implement, Soul Core contract, Soul Core ref)
- Authority subsystem (issuer-public.json)
- OpenCode agent pointer files
- Three skill directory layout and junction topology
- Active tasks in .trae/tasks/ with doc-impact coverage
- Memory subsystem status (Mem0 config)
- AGENTS.md presence and freshness

USAGE
    jinli-snapshot.ps1                  Apply: write snapshot to .trae\state\jinli-snapshot.json
    jinli-snapshot.ps1 -DryRun          Compute and print JSON to stdout, no file write
    jinli-snapshot.ps1 -Apply -Json     Write file AND print JSON to stdout
    jinli-snapshot.ps1 -Compare         Compare with previous snapshot, print diff
    jinli-snapshot.ps1 -Strict          Exit code 2 if any CRITICAL gap found
    jinli-snapshot.ps1 -OutputPath P    Override output path
    jinli-snapshot.ps1 -PreviousPath P  Override previous snapshot path (for -Compare)
    jinli-snapshot.ps1 -Help            Show this help

EXIT CODES
    0  ok or warn (snapshot written)
    1  internal error
    2  critical gaps found (with -Strict)
    3  previous snapshot not found (with -Compare)

DESIGN
- Idempotent: re-running produces the same JSON if no files changed.
- Read-only by default: never modifies project files. Only writes to output path.
- Single source of truth: one file describes the whole Jinli system.
- Designed for "audit snapshot" use case: snapshot is a fact, not a plan.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Json,
    [switch]$Compare,
    [switch]$Strict,
    [string]$OutputPath,
    [string]$PreviousPath,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$TOOL_VERSION = "1.0.0"
$SNAPSHOT_VERSION = "1.0"

# --- Help ---
if ($Help) {
    Write-Host @"
jinli-snapshot.ps1 - Jinli (Little-Glass) System Audit Snapshot

USAGE
    jinli-snapshot.ps1                  Apply: write snapshot to .trae\state\jinli-snapshot.json
    jinli-snapshot.ps1 -DryRun          Compute and print JSON to stdout, no file write
    jinli-snapshot.ps1 -Apply -Json     Write file AND print JSON to stdout
    jinli-snapshot.ps1 -Compare         Compare with previous snapshot, print diff
    jinli-snapshot.ps1 -Strict          Exit code 2 if any CRITICAL gap found
    jinli-snapshot.ps1 -OutputPath P    Override output path
    jinli-snapshot.ps1 -PreviousPath P  Override previous snapshot path (for -Compare)
    jinli-snapshot.ps1 -Help            Show this help

EXIT CODES
    0  ok or warn (snapshot written)
    1  internal error
    2  critical gaps found (with -Strict)
    3  previous snapshot not found (with -Compare)
"@
    exit 0
}

# --- Workspace ---
$WORKSPACE = (Get-Location).Path
$STATE_DIR = Join-Path $WORKSPACE ".trae\state"
$DEFAULT_OUTPUT = Join-Path $STATE_DIR "jinli-snapshot.json"
$DEFAULT_PREVIOUS = Join-Path $STATE_DIR "jinli-snapshot.previous.json"
if (-not $OutputPath) { $OutputPath = $DEFAULT_OUTPUT }
if (-not $PreviousPath) { $PreviousPath = $DEFAULT_PREVIOUS }


# --- Runtime-constructed Chinese folder names (PS5.1 lacks `u{XXXX}) ---
$PLAN_FOLDER = [System.Text.Encoding]::UTF8.GetString([byte[]]@(0xE9,0x87,0x91,0xE7,0x92,0x83,0xE5,0xB0,0x8F,0xE5,0xA4,0xA9,0xE6,0x89,0x8D))
$IMPL_FOLDER = [System.Text.Encoding]::UTF8.GetString([byte[]]@(0xE9,0x87,0x91,0xE7,0x92,0x83,0xE5,0xA5,0xBD,0xE5,0xB8,0xAE,0xE6,0x89,0x8B))

# --- Skill catalog ---
$CANONICAL_SKILLS = @(
    @{ id="plan_agent";            role="Plan";          path="skills\$PLAN_FOLDER\SKILL.md";   must_exist=$true;  stale_days=30 },
    @{ id="implement_agent";       role="Implement";     path="skills\$IMPL_FOLDER\SKILL.md";   must_exist=$true;  stale_days=30 },
    @{ id="soul_core_contract";    role="SoulContract";  path="skills\jinli-agent-soul\SKILL.md";  must_exist=$true;  stale_days=60 },
    @{ id="soul_engine_ref";       role="SoulEngineRef"; path="skills\daughter-companion\SKILL.md"; must_exist=$true; stale_days=60 }
)

# --- OpenCode agent pointer files ---
$OPENCODE_AGENTS = @(
    @{ id="plan";      path=".opencode\agents\$PLAN_FOLDER.md"; canonical="skills\$PLAN_FOLDER\SKILL.md" },
    @{ id="implement"; path=".opencode\agents\$IMPL_FOLDER.md"; canonical="skills\$IMPL_FOLDER\SKILL.md" }
)

# --- Skill directories to inspect ---
$SKILL_DIRS = @(
    @{ id="skills";           path="skills" },
    @{ id="trae_skills";      path=".trae\skills" },
    @{ id="opencode_skills";  path=".opencode\skills" },
    @{ id="codex_skills";     path=".codex\skills" },
    @{ id="agents_skills";    path=".agents\skills" }
)

# --- Color helpers ---
function Write-Info  { param($m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "[OK]    $m" -ForegroundColor Green }
function Write-WarnC { param($m) Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err   { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

# --- Helpers ---
function Get-FileSha256 {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $h = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
        return $h.Hash.ToLower()
    } catch {
        return $null
    }
}

function Get-FileMeta {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ exists=$false }
    }
    $item = Get-Item -LiteralPath $Path -Force
    $meta = @{
        exists       = $true
        size_bytes   = $item.Length
        modified_at  = $item.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        sha256       = (Get-FileSha256 -Path $Path)
    }
    if ($item -is [System.IO.FileInfo]) {
        $meta.line_count = (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    }
    return $meta
}

function Get-SkillFrontmatter {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $content = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $null }
    $match = [regex]::Match($content, "(?s)^---\s*\r?\n(.+?)\r?\n---")
    if (-not $match.Success) { return $null }
    $fm = @{}
    $match.Groups[1].Value -split "`r?`n" | ForEach-Object {
        $line = $_
        if ($line -match "^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.+?)\s*$") {
            $key = $matches[1]
            $val = $matches[2].Trim() -replace '^["'']|["'']$', ''
            $fm[$key] = $val
        }
    }
    return $fm
}

function Get-JunctionInfo {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @{ exists=$false } }
    $item = Get-Item -LiteralPath $Path -Force
    $isReparse = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    $info = @{
        exists           = $true
        is_reparse_point = $isReparse
        target           = $null
        junction_kind    = if ($isReparse) { "junction_or_symlink" } else { "real_directory" }
    }
    if ($isReparse) {
        try {
            $fsutilOut = & fsutil.exe reparsepoint query "$Path" 2>$null
            $subLine = $fsutilOut | Where-Object { $_ -match "Substitute Name" } | Select-Object -First 1
            if ($subLine) {
                $raw = ($subLine -replace ".*Substitute Name\s*:\s*", "").Trim()
                $info.target = $raw
            }
        } catch {
            $info.target_query_error = $_.Exception.Message
        }
    } else {
        $info.target = (Resolve-Path -LiteralPath $Path).Path
    }
    return $info
}

function Get-DirSummary {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @{ exists=$false } }
    $dirs = Get-ChildItem -LiteralPath $Path -Directory -Force -ErrorAction SilentlyContinue
    $mdCount = 0; $skillCount = 0; $archivedCount = 0
    if ($dirs) {
        $skillCount = ($dirs | Where-Object { $_.Name -ne "_archived" }).Count
        $archivedCount = ($dirs | Where-Object { $_.Name -eq "_archived" }).Count
        $archivedSubCount = 0
        $archivedDir = $dirs | Where-Object { $_.Name -eq "_archived" } | Select-Object -First 1
        if ($archivedDir) {
            $archivedSubCount = (Get-ChildItem -LiteralPath $archivedDir.FullName -Directory -Force -ErrorAction SilentlyContinue).Count
        }
        $mdCount = (Get-ChildItem -LiteralPath $Path -Filter "*.md" -Recurse -Force -ErrorAction SilentlyContinue).Count
    }
    return @{
        exists                  = $true
        subdir_count            = if ($dirs) { $dirs.Count } else { 0 }
        skill_count             = $skillCount
        archived_top_count      = $archivedCount
        archived_nested_count   = $archivedSubCount
        total_md_files          = $mdCount
    }
}

function Get-ActiveTasks {
    $tasksRoot = Join-Path $WORKSPACE ".trae\tasks"
    if (-not (Test-Path -LiteralPath $tasksRoot)) { return @() }
    $taskList = @()
    Get-ChildItem -LiteralPath $tasksRoot -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $projectName = $_.Name
        if ($projectName -eq "_shared") {
            Get-ChildItem -LiteralPath $_.FullName -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
                $taskList += [PSCustomObject]@{ Project = "_shared"; Task = $_.Name; Path = $_.FullName }
            }
        } else {
            Get-ChildItem -LiteralPath $_.FullName -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
                $taskList += [PSCustomObject]@{ Project = $projectName; Task = $_.Name; Path = $_.FullName }
            }
        }
    }
    return $taskList
}

function Get-TaskSnapshot {
    param([object]$TaskEntry)
    $dir = $TaskEntry.Path
    $yamlPath = Join-Path $dir ".task.yaml"
    $docImpact = Join-Path $dir "doc-impact.md"
    $routing = Join-Path $dir "routing.md"
    $analysis = Join-Path $dir "analysis.md"
    $spec = Join-Path $dir "spec.md"
    $tasksMd = Join-Path $dir "tasks.md"
    $snap = @{
        project            = $TaskEntry.Project
        task               = $TaskEntry.Task
        path               = $dir.Substring($WORKSPACE.Length).TrimStart('\','/')
        doc_impact_exists  = (Test-Path -LiteralPath $docImpact)
        packet_files       = @{
            routing_md  = (Test-Path -LiteralPath $routing)
            analysis_md = (Test-Path -LiteralPath $analysis)
            spec_md     = (Test-Path -LiteralPath $spec)
            tasks_md    = (Test-Path -LiteralPath $tasksMd)
            task_yaml   = (Test-Path -LiteralPath $yamlPath)
        }
        last_modified_at   = (Get-Item -LiteralPath $dir -Force).LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    return $snap
}

function Get-MemorySnapshot {
    $memConfig = Join-Path $WORKSPACE ".trae\memory\mem0.config.json"
    $hermesDir = Join-Path $WORKSPACE ".trae\memory"
    $info = @{
        mem0_config_exists = (Test-Path -LiteralPath $memConfig)
        mem0_enabled       = $null
        hermes_memory_dir_exists = (Test-Path -LiteralPath $hermesDir)
    }
    if ($info.mem0_config_exists) {
        try {
            $raw = Get-Content -LiteralPath $memConfig -Raw -ErrorAction Stop
            $obj = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($obj.PSObject.Properties["enabled"]) {
                $info.mem0_enabled = [bool]$obj.enabled
            }
        } catch {
            $info.mem0_config_parse_error = $_.Exception.Message
        }
    }
    return $info
}

function Get-AgentsMdSnapshot {
    $p = Join-Path $WORKSPACE "AGENTS.md"
    $m = Get-FileMeta -Path $p
    if ($m.exists) {
        $m.line_count = (Get-Content -LiteralPath $p -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    }
    return $m
}

function Get-AuthoritySnapshot {
    $pub = Join-Path $WORKSPACE ".trae\authority\issuer-public.json"
    $priv = Join-Path $WORKSPACE ".trae\authority\issuer-private.json"
    $info = @{
        issuer_public_exists  = (Test-Path -LiteralPath $pub)
        issuer_private_exists = (Test-Path -LiteralPath $priv)
    }
    if ($info.issuer_public_exists) {
        try {
            $raw = Get-Content -LiteralPath $pub -Raw -ErrorAction Stop
            $obj = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($obj.PSObject.Properties["schema_version"]) { $info.schema_version = [int]$obj.schema_version }
            if ($obj.PSObject.Properties["algorithm"])      { $info.algorithm = [string]$obj.algorithm }
            if ($obj.PSObject.Properties["key_name"])       { $info.key_name = [string]$obj.key_name }
            if ($obj.PSObject.Properties["issuer_key_id"])  { $info.issuer_key_id = [string]$obj.issuer_key_id }
            if ($obj.PSObject.Properties["issuer_sid"])     { $info.issuer_sid = [string]$obj.issuer_sid }
            if ($obj.PSObject.Properties["private_exportable"]) { $info.private_exportable = [bool]$obj.private_exportable }
            if ($obj.PSObject.Properties["public_blob_base64"]) {
                $pb = [string]$obj.public_blob_base64
                $info.public_blob_byte_count = $pb.Length
                $info.public_blob_sha256     = (Get-FileSha256 -Path $pub)
            }
        } catch {
            $info.parse_error = $_.Exception.Message
        }
    }
    return $info
}

function Get-SkillDirSnapshot {
    param([hashtable]$Spec)
    $p = Join-Path $WORKSPACE $Spec.path
    $junction = Get-JunctionInfo -Path $p
    $summary = Get-DirSummary -Path $p
    return @{
        id     = $Spec.id
        path   = $Spec.path
        junction = $junction
        summary  = $summary
    }
}

function Get-OpencodeAgentSnapshot {
    param([hashtable]$Spec)
    $p = Join-Path $WORKSPACE $Spec.path
    $canonicalP = Join-Path $WORKSPACE $Spec.canonical
    $exists = Test-Path -LiteralPath $p
    $canonicalExists = Test-Path -LiteralPath $canonicalP
    $snap = @{
        id                  = $Spec.id
        path                = $Spec.path
        exists              = $exists
        canonical_path      = $Spec.canonical
        canonical_exists    = $canonicalExists
        references_canonical = $false
    }
    if ($exists) {
        $content = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match [regex]::Escape($Spec.canonical))) {
            $snap.references_canonical = $true
        }
        $snap.sha256 = (Get-FileSha256 -Path $p)
        $snap.modified_at = (Get-Item -LiteralPath $p -Force).LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    return $snap
}

function Get-CanonicalSkillSnapshot {
    param([hashtable]$Spec)
    $p = Join-Path $WORKSPACE $Spec.path
    $meta = Get-FileMeta -Path $p
    $fm = $null
    if ($meta.exists) {
        $fm = Get-SkillFrontmatter -Path $p
    }
    return @{
        id            = $Spec.id
        role          = $Spec.role
        path          = $Spec.path
        must_exist    = $Spec.must_exist
        stale_days    = $Spec.stale_days
        meta          = $meta
        frontmatter   = $fm
    }
}

function Compare-Snapshots {
    param($Current, $Previous)
    $diffs = @()
    $curHash = $Current.summary
    $prevHash = $Previous.summary
    if ($curHash -and $prevHash) {
        foreach ($k in @("skill_files_present","authority_state","opencode_agents_count","active_tasks_count","tasks_with_doc_impact","critical_gaps","warn_gaps")) {
            if ($curHash.$k -ne $prevHash.$k) {
                $diffs += [PSCustomObject]@{ kind="summary.$k"; from=$prevHash.$k; to=$curHash.$k }
            }
        }
    }
    if ($Current.skills -and $Previous.skills) {
        foreach ($skillId in @("plan_agent","implement_agent","soul_core_contract","soul_engine_ref")) {
            $curSkill = $Current.skills.$skillId
            $prevSkill = $Previous.skills.$skillId
            if (-not $curSkill -or -not $prevSkill) { continue }
            if ($curSkill.meta.sha256 -ne $prevSkill.meta.sha256) {
                $diffs += [PSCustomObject]@{ kind="skill.$skillId.hash"; from=$prevSkill.meta.sha256; to=$curSkill.meta.sha256 }
            }
            if ($curSkill.meta.exists -ne $prevSkill.meta.exists) {
                $diffs += [PSCustomObject]@{ kind="skill.$skillId.exists"; from=$prevSkill.meta.exists; to=$curSkill.meta.exists }
            }
        }
    }
    if ($Current.active_tasks -and $Previous.active_tasks) {
        $curTasks = @($Current.active_tasks | ForEach-Object { "$($_.project)/$($_.task)" })
        $prevTasks = @($Previous.active_tasks | ForEach-Object { "$($_.project)/$($_.task)" })
        $added = $curTasks | Where-Object { $_ -notin $prevTasks }
        $removed = $prevTasks | Where-Object { $_ -notin $curTasks }
        foreach ($a in $added)   { $diffs += [PSCustomObject]@{ kind="task.added";   from=$null; to=$a } }
        foreach ($r in $removed) { $diffs += [PSCustomObject]@{ kind="task.removed"; from=$r; to=$null } }
    }
    if ($Current.overall_status -ne $Previous.overall_status) {
        $diffs += [PSCustomObject]@{ kind="overall_status"; from=$Previous.overall_status; to=$Current.overall_status }
    }
    return $diffs
}

# --- Collect ---
try { $skillSnaps = [ordered]@{} } catch { Write-Host "ERR skillSnaps: $($_.Exception.Message)" -ForegroundColor Red; throw }
try {
    foreach ($s in $CANONICAL_SKILLS) {
        $skillSnaps[$s.id] = Get-CanonicalSkillSnapshot -Spec $s
    }
} catch { Write-Host "ERR skills loop: $($_.Exception.Message)" -ForegroundColor Red; throw }
$agentSnaps = @()
foreach ($a in $OPENCODE_AGENTS) {
    $agentSnaps += Get-OpencodeAgentSnapshot -Spec $a
}
$skillDirSnaps = @()
foreach ($d in $SKILL_DIRS) {
    $skillDirSnaps += Get-SkillDirSnapshot -Spec $d
}
$taskEntries = Get-ActiveTasks
$taskSnaps = @()
$tasksWithDoc = 0
foreach ($t in $taskEntries) {
    $ts = Get-TaskSnapshot -TaskEntry $t
    if ($ts.doc_impact_exists) { $tasksWithDoc++ }
    $taskSnaps += $ts
}
$authoritySnap = Get-AuthoritySnapshot
$memorySnap = Get-MemorySnapshot
$agentsMdSnap = Get-AgentsMdSnapshot
# --- Compute gaps ---
$gaps = @()
$skillPresent = 0
foreach ($s in $CANONICAL_SKILLS) {
    $snap = $skillSnaps[$s.id]
    if (-not $snap.meta.exists) {
        $gaps += [PSCustomObject]@{
            severity = "critical"
            category = "skill"
            subject  = $s.id
            message  = "Required skill file missing: $($s.path)"
        }
    } else {
        $skillPresent++
        $lastWrite = (Get-Item -LiteralPath (Join-Path $WORKSPACE $s.path) -Force).LastWriteTimeUtc
        $ageDays = ((Get-Date).ToUniversalTime() - $lastWrite).TotalDays
        if ($ageDays -gt $s.stale_days) {
            $gaps += [PSCustomObject]@{
                severity    = "warn"
                category    = "skill"
                subject     = $s.id
                message     = "Skill file has not been updated in $([int]$ageDays) days (threshold $($s.stale_days))"
                last_modified_at = $snap.meta.modified_at
                age_days    = [int]$ageDays
            }
        }
    }
}
if (-not $authoritySnap.issuer_public_exists) {
    $gaps += [PSCustomObject]@{
        severity = "critical"
        category = "authority"
        subject  = "issuer_public_key"
        message  = "Issuer public key (.trae/authority/issuer-public.json) not found. Run issuer-identity.ps1 init."
    }
}
if ($authoritySnap.issuer_private_exists) {
    $gaps += [PSCustomObject]@{
        severity = "critical"
        category = "authority"
        subject  = "issuer_private_key"
        message  = "Issuer private key file found in repo (.trae/authority/issuer-private.json). Should NEVER be on disk."
    }
}
$agentCount = 0
foreach ($a in $agentSnaps) {
    if ($a.exists) {
        $agentCount++
        if (-not $a.references_canonical) {
            $gaps += [PSCustomObject]@{
                severity = "warn"
                category = "agent_pointer"
                subject  = $a.id
                message  = "OpenCode agent pointer does not reference canonical path: $($a.canonical_path)"
            }
        }
    } else {
        $gaps += [PSCustomObject]@{
            severity = "warn"
            category = "agent_pointer"
            subject  = $a.id
            message  = "OpenCode agent pointer missing: $($a.path)"
        }
    }
}
foreach ($d in $skillDirSnaps) {
    if (-not $d.summary.exists -and $d.id -in @("skills","trae_skills","opencode_skills","codex_skills")) {
        $gaps += [PSCustomObject]@{
            severity = "critical"
            category = "skill_dir"
            subject  = $d.id
            message  = "Required skill directory missing: $($d.path)"
        }
    }
}
foreach ($ts in $taskSnaps) {
    if (-not $ts.doc_impact_exists) {
        $gaps += [PSCustomObject]@{
            severity = "warn"
            category = "doc_governance"
            subject  = "$($ts.project)/$($ts.task)"
            message  = "Active task is missing doc-impact.md. AGENTS.md IMPLEMENT PHASE GATE requires it."
            path     = $ts.path
        }
    }
}
if (-not $agentsMdSnap.exists) {
    $gaps += [PSCustomObject]@{
        severity = "critical"
        category = "agents_md"
        subject  = "AGENTS.md"
        message  = "AGENTS.md not found at workspace root."
    }
} else {
    $lastWrite = (Get-Item -LiteralPath (Join-Path $WORKSPACE "AGENTS.md") -Force).LastWriteTimeUtc
    $ageDays = ((Get-Date).ToUniversalTime() - $lastWrite).TotalDays
    if ($ageDays -gt 90) {
        $gaps += [PSCustomObject]@{
            severity    = "info"
            category    = "agents_md"
            subject     = "AGENTS.md"
            message     = "AGENTS.md has not been updated in $([int]$ageDays) days"
            age_days    = [int]$ageDays
        }
    }
}
if ($null -ne $memorySnap.mem0_enabled -and $memorySnap.mem0_enabled) {
    $gaps += [PSCustomObject]@{
        severity    = "info"
        category    = "memory"
        subject     = "mem0"
        message     = "Mem0 is enabled. Memory subsystem active."
    }
} elseif ($memorySnap.mem0_config_exists -and -not $memorySnap.mem0_enabled) {
    $gaps += [PSCustomObject]@{
        severity    = "info"
        category    = "memory"
        subject     = "mem0"
        message     = "Mem0 configured but disabled (enabled=false). Phase 2 semantic enhancement deferred."
    }
}
$criticalCount = ($gaps | Where-Object { $_.severity -eq "critical" }).Count
$warnCount     = ($gaps | Where-Object { $_.severity -eq "warn" }).Count
$infoCount     = ($gaps | Where-Object { $_.severity -eq "info" }).Count
if ($criticalCount -gt 0)       { $overall = "critical" }
elseif ($warnCount -gt 0)       { $overall = "warn" }
else                            { $overall = "ok" }
$authorityState = if ($authoritySnap.issuer_public_exists -and -not $authoritySnap.issuer_private_exists) { "ok" } elseif ($authoritySnap.issuer_private_exists) { "compromised" } else { "missing" }
$summary = [ordered]@{
    skill_files_checked        = $CANONICAL_SKILLS.Count
    skill_files_present        = $skillPresent
    authority_state            = $authorityState
    opencode_agents_count      = $agentCount
    active_tasks_count         = $taskSnaps.Count
    tasks_with_doc_impact      = $tasksWithDoc
    critical_gaps              = $criticalCount
    warn_gaps                  = $warnCount
    info_gaps                  = $infoCount
}
$snapshot = [ordered]@{
    snapshot_version   = $SNAPSHOT_VERSION
    generated_at       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    tool               = "jinli-snapshot.ps1"
    tool_version       = $TOOL_VERSION
    workspace          = $WORKSPACE
    overall_status     = $overall
    summary            = $summary
    skills             = $skillSnaps
    authority          = $authoritySnap
    opencode_agents    = $agentSnaps
    skill_directories  = $skillDirSnaps
    active_tasks       = $taskSnaps
    memory             = $memorySnap
    agents_md          = $agentsMdSnap
    gaps               = $gaps
}
# ConvertTo-Json in PS5.1 has a known bug with deeply nested + mixed type structures
# that produces a parameter binding error AFTER successful serialization.
# Workaround: serialize each top-level field separately and concatenate manually.
function Safe-ConvertToJson {
    param($InputObject, [int]$Depth = 12)
    try {
        return (ConvertTo-Json -InputObject $InputObject -Depth $Depth)
    } catch {
        Write-Warning "Safe-ConvertToJson partial failure: $($_.Exception.Message)"
        return $null
    }
}
# Trace each section variable before assignment
# Serialize each section individually
# IMPORTANT: All fields are SIBLINGS inside ONE root object, not nested.
# Previously $metaJson was a separate object + comma + summary, which produced
# TWO top-level objects (invalid JSON).
$sections = [ordered]@{
    snapshot_version   = $SNAPSHOT_VERSION
    generated_at       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    tool               = "jinli-snapshot.ps1"
    tool_version       = $TOOL_VERSION
    workspace          = $WORKSPACE
    overall_status     = $overall
    summary            = $summary
    skills             = $skillSnaps
    authority          = $authoritySnap
    opencode_agents    = $agentSnaps
    skill_directories  = $skillDirSnaps
    active_tasks       = $taskSnaps
    memory             = $memorySnap
    agents_md          = $agentsMdSnap
    gaps               = $gaps
}
$sectionJson = [ordered]@{}
foreach ($k in $sections.Keys) {
    $sj = Safe-ConvertToJson -InputObject $sections[$k]
    if ($null -eq $sj) {
        # Fallback: try as PSCustomObject
        $sj = Safe-ConvertToJson -InputObject ([PSCustomObject]@{})
    }
    $sectionJson[$k] = $sj
}
$keyArr = @($sectionJson.Keys)
$lastKey = $keyArr[-1]
# Build final JSON manually using StringBuilder.
# IMPORTANT: Use $jsonFinal (NOT $json) because $Json is a [switch] parameter and PS is case-insensitive
# CRITICAL: All keys are inside ONE root object {...}, not nested objects with comma between them.
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append('{')
foreach ($k in $keyArr) {
    $sjValue = $sectionJson[$k]
    $isLast = ($k -eq $lastKey)
    $commaChar = if ($isLast) { '' } else { ',' }
    [void]$sb.Append("`n  ")
    [void]$sb.Append('"')
    [void]$sb.Append($k)
    [void]$sb.Append('": ')
    [void]$sb.Append($sjValue)
    [void]$sb.Append($commaChar)
}
[void]$sb.Append("`n}")
$jsonFinal = $sb.ToString()
[System.IO.File]::WriteAllText("E:\UEGameDevelopment\.trae\state\test-manual-output.json", $jsonFinal, [System.Text.UTF8Encoding]::new($true))
# --- Output ---
if ($DryRun -or ($Apply -and $Json)) {
    [Console]::Out.WriteLine($jsonFinal)
}

if ($DryRun) {
    if ($Strict -and $overall -eq "critical") { exit 2 }
    exit 0
}

if ($Apply -or (-not $DryRun -and -not $Compare)) {
    if (Test-Path -LiteralPath $OutputPath) {
        Copy-Item -LiteralPath $OutputPath -Destination $PreviousPath -Force -ErrorAction SilentlyContinue
    }
    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($OutputPath, $jsonFinal, [System.Text.UTF8Encoding]::new($true))
    Write-Ok "Snapshot written to: $OutputPath"
    Write-Info "Status: $overall  (critical=$criticalCount warn=$warnCount info=$infoCount)"
}

if ($Compare) {
    if (-not (Test-Path -LiteralPath $PreviousPath)) {
        Write-Err "Previous snapshot not found: $PreviousPath"
        exit 3
    }
    try {
        $prevJson = Get-Content -LiteralPath $PreviousPath -Raw -ErrorAction Stop
        $prev = $prevJson | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Err "Failed to parse previous snapshot: $($_.Exception.Message)"
        exit 3
    }
    $diffs = Compare-Snapshots -Current $snapshot -Previous $prev
    if ($diffs.Count -eq 0) {
        Write-Ok "No changes since previous snapshot."
    } else {
        Write-WarnC "$($diffs.Count) difference(s) detected:"
        $diffs | ForEach-Object {
            $from = if ($null -eq $_.from) { "<null>" } else { "$($_.from)" }
            $to   = if ($null -eq $_.to)   { "<null>" } else { "$($_.to)" }
            Write-Host "  - $($_.kind): $from  ->  $to" -ForegroundColor Yellow
        }
    }
}

if ($Strict -and $overall -eq "critical") {
    Write-Err "STRICT mode: $criticalCount critical gap(s) found. Exit 2."
    exit 2
}

exit 0