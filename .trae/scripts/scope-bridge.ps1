# scope-bridge.ps1 -- Scope-Aware Memory Bridge for Jinli
#
# Bridges scope-store.ps1 partitioned memory with memory-retrieve.ps1 failure memories.
# Core idea from Scope Recall (BV19EE16aEn7): scope isolation prevents cross-context
# memory contamination and enables Current Turn Recall for context-aware pre-fetch.
#
# Capabilities:
#   - Contextual recall: auto-detect agent scope and return only relevant memories
#   - Context bridging: link scope-store entries to failure memory index entries
#   - Scope-aware search: search failure memories within scope boundaries
#   - Context snapshot: save/restore working context for session continuity
#   - Contamination guard: detect and warn about scope-crossing memory leaks
#
# Usage:
#   .\scope-bridge.ps1 -Init
#   .\scope-bridge.ps1 -Recall -Scope project -Context rts
#   .\scope-bridge.ps1 -Link -Scope project -Key rts-gas -MemoryId memory-001
#   .\scope-bridge.ps1 -Search -Scope project -Query "GAS"
#   .\scope-bridge.ps1 -Snapshot -Scope session -SessionKey task-rt1
#   .\scope-bridge.ps1 -Restore -Scope session -SessionKey task-rt1
#   .\scope-bridge.ps1 -Guard -Scope project
#   .\scope-bridge.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Recall,
    [switch]$Link,
    [switch]$Unlink,
    [switch]$Search,
    [switch]$Snapshot,
    [switch]$Restore,
    [switch]$Guard,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",

    [string]$Key = "",
    [string]$Context = "",
    [string]$MemoryId = "",
    [string]$Query = "",
    [string]$SessionKey = "",
    [int]$Limit = 20,
    [string]$BridgePath = ""
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scopeStoreScript = Join-Path $PSScriptRoot "scope-store.ps1"
$memoryIndexPath = Join-Path $repoRoot "Docs\Memory\indexes\memory-index.md"

if (-not $BridgePath) {
    $BridgePath = Join-Path $repoRoot "Docs\Memory\scope-bridge.json"
}

$persistentScopes = @("user", "project", "ops", "memory")
$localScopes = @("session", "general")

# --- Bridge Data Structure ---
# The bridge file stores:
#   links: array of { scope_key_id, memory_id, scope, created_at }
#   snapshots: array of { session_key, scope, entries, created_at }
#   guard_warnings: array of { scope, warning_type, detail, created_at }

function Read-BridgeData {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ links = @(); snapshots = @(); guard_warnings = @(); meta = @{ created_at = ""; version = 1 } }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $linksArray = @()
        if ($parsed.links -ne $null) {
            foreach ($l in $parsed.links) {
                $linksArray += @{
                    scope_key_id = $l.scope_key_id
                    memory_id = $l.memory_id
                    scope = $l.scope
                    created_at = $l.created_at
                }
            }
        }
        $snapshotsArray = @()
        if ($parsed.snapshots -ne $null) {
            foreach ($s in $parsed.snapshots) {
                $entriesArray = @()
                if ($s.entries -ne $null) {
                    foreach ($e in $s.entries) {
                        $entriesArray += @{
                            scope = $e.scope
                            key = $e.key
                            value = $e.value
                        }
                    }
                }
                $snapshotsArray += @{
                    session_key = $s.session_key
                    scope = $s.scope
                    entries = $entriesArray
                    created_at = $s.created_at
                }
            }
        }
        $warningsArray = @()
        if ($parsed.guard_warnings -ne $null) {
            foreach ($w in $parsed.guard_warnings) {
                $warningsArray += @{
                    scope = $w.scope
                    warning_type = $w.warning_type
                    detail = $w.detail
                    created_at = $w.created_at
                }
            }
        }
        return @{
            links = $linksArray
            snapshots = $snapshotsArray
            guard_warnings = $warningsArray
            meta = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        }
    } catch {
        return @{ links = @(); snapshots = @(); guard_warnings = @(); meta = @{ created_at = ""; version = 1 } }
    }
}

function Write-BridgeData {
    param(
        [string]$Path,
        $Data
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

# --- Failure Memory Index Parser ---
# Reuses the same parsing logic as memory-retrieve.ps1 but adds scope filtering

function Get-MemoryIndexRows {
    param([string]$IndexPath)

    if (-not (Test-Path $IndexPath)) {
        return @()
    }

    $rows = @()
    foreach ($line in (Get-Content $IndexPath -Encoding UTF8)) {
        if (-not $line.StartsWith("| memory-")) {
            continue
        }
        $trimmed = $line.Trim([char[]]@([char]'|'))
        $parts = @($trimmed -split '\|' | ForEach-Object { $_.Trim() })
        if ($parts.Count -lt 8) {
            continue
        }
        $rows += @{
            Id       = $parts[0]
            Title    = $parts[1]
            Phase    = $parts[2]
            Module   = $parts[3]
            Severity = $parts[4]
            Scope    = $parts[5]
            Tags     = $parts[6]
            File     = $parts[7]
        }
    }
    return $rows
}

# --- Core Operations ---

function Initialize-Bridge {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        $data = @{
            links = @()
            snapshots = @()
            guard_warnings = @()
            meta = @{ created_at = (Get-Date -Format 'o'); version = 1 }
        }
        Write-BridgeData -Path $Path -Data $data
    }
    Write-Host '[INIT] Scope bridge initialized at: ' + $Path
    return $true
}

function Invoke-ContextualRecall {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$ContextFilter,
        [int]$ResultLimit
    )

    # 1. Get scope-store entries for this scope
    $scopeStoreDb = Join-Path $repoRoot 'Docs\Memory\scope-store.sqlite3'
    $storeJsonPath = $scopeStoreDb -replace '\.sqlite3$', '.json'
    $scopeEntries = @()
    if (Test-Path -LiteralPath $storeJsonPath) {
        $raw = [System.IO.File]::ReadAllText($storeJsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                $isVisible = ($e.scope -eq $ScopeName) -or ($persistentScopes -contains $e.scope)
                if ($ScopeName -eq 'session') {
                    $isVisible = $isVisible -or ($e.scope -eq 'general')
                }
                if (-not $isVisible) { continue }
                if ($ContextFilter -and $e.key -notlike ('*' + $ContextFilter + '*')) { continue }
                $scopeEntries += @{ key = $e.key; value = $e.value; scope = $e.scope }
            }
        }
    }

    # 2. Get linked failure memories via bridge
    $bridge = Read-BridgeData -Path $BridgeDataPath
    $linkedMemoryIds = @()
    foreach ($link in $bridge.links) {
        if ($link.scope -eq $ScopeName) {
            $linkedMemoryIds += $link.memory_id
        }
    }

    # 3. Get failure memory rows matching linked IDs or scope-related entries
    $memRows = Get-MemoryIndexRows -IndexPath $memoryIndexPath
    $relevantMemories = @()
    foreach ($row in $memRows) {
        if ($linkedMemoryIds -contains $row.Id) {
            $relevantMemories += $row
            continue
        }
        # Fallback: match by scope field in memory index
        if ($row.Scope -eq 'router' -and $ScopeName -eq 'project') {
            if ($ContextFilter -and ($row.Module -like ('*' + $ContextFilter + '*') -or $row.Tags -like ('*' + $ContextFilter + '*'))) {
                $relevantMemories += $row
            }
        }
        if ($row.Scope -eq 'implement' -and $ScopeName -eq 'ops') {
            if ($ContextFilter -and ($row.Module -like ('*' + $ContextFilter + '*') -or $row.Tags -like ('*' + $ContextFilter + '*'))) {
                $relevantMemories += $row
            }
        }
    }

    # 4. Combine and format results
    $results = @()
    foreach ($entry in $scopeEntries) {
        $results += @{
            type = 'scope-memory'
            scope = $entry.scope
            key = $entry.key
            value = $entry.value
        }
    }
    foreach ($mem in $relevantMemories) {
        $results += @{
            type = 'failure-memory'
            id = $mem.Id
            title = $mem.Title
            phase = $mem.Phase
            module = $mem.Module
            severity = $mem.Severity
            file = $mem.File
        }
    }

    # Sort: scope-memory with matching scope first, then failure-memory
    if ($results.Count -gt 0) {
        $sorted = @($results | Sort-Object -Property @{ Expression = { if ($_.type -eq 'scope-memory' -and $_.scope -eq $ScopeName) { 0 } elseif ($_.type -eq 'scope-memory') { 1 } else { 2 } } } | Select-Object -First $ResultLimit)
        $results = $sorted
    }

    Write-Host ('[RECALL] Scope=' + $ScopeName + ' Context=' + $ContextFilter + ' Found=' + $results.Count)
    foreach ($r in $results) {
        if ($r.type -eq 'scope-memory') {
            Write-Host ('  [scope] ' + $r.scope + '/' + $r.key + ' = ' + $r.value)
        } else {
            Write-Host ('  [memory] ' + $r.id + ': ' + $r.title + ' (' + $r.phase + '/' + $r.module + ')')
        }
    }

    return ,$results
}

function Add-ScopeMemoryLink {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$EntryKey,
        [string]$MemId
    )

    if (-not $Apply) {
        Write-Host ('[DRY-RUN] Would link: scope=' + $ScopeName + ' key=' + $EntryKey + ' -> memory=' + $MemId)
        return $true
    }

    $bridge = Read-BridgeData -Path $BridgeDataPath
    $scopeKeyId = $ScopeName + ':' + $EntryKey

    # Check for duplicate
    foreach ($link in $bridge.links) {
        if ($link.scope_key_id -eq $scopeKeyId -and $link.memory_id -eq $MemId) {
            Write-Host ('[LINK] Already linked: ' + $scopeKeyId + ' -> ' + $MemId)
            return $true
        }
    }

    $bridge.links += @{
        scope_key_id = $scopeKeyId
        memory_id = $MemId
        scope = $ScopeName
        created_at = (Get-Date -Format 'o')
    }

    Write-BridgeData -Path $BridgeDataPath -Data $bridge
    Write-Host ('[LINK] Created: scope=' + $ScopeName + ' key=' + $EntryKey + ' -> memory=' + $MemId)
    return $true
}

function Remove-ScopeMemoryLink {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$EntryKey,
        [string]$MemId
    )

    if (-not $Apply) {
        Write-Host ('[DRY-RUN] Would unlink: scope=' + $ScopeName + ' key=' + $EntryKey + ' -> memory=' + $MemId)
        return $true
    }

    $bridge = Read-BridgeData -Path $BridgeDataPath
    $scopeKeyId = $ScopeName + ':' + $EntryKey

    $filtered = @()
    $removed = 0
    foreach ($link in $bridge.links) {
        if ($link.scope_key_id -eq $scopeKeyId -and $link.memory_id -eq $MemId) {
            $removed++
        } else {
            $filtered += $link
        }
    }

    $bridge.links = $filtered
    Write-BridgeData -Path $BridgeDataPath -Data $bridge
    Write-Host ('[UNLINK] Removed ' + $removed + ' link(s): ' + $scopeKeyId + ' -> ' + $MemId)
    return ($removed -gt 0)
}

function Invoke-ScopeAwareSearch {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$SearchQuery,
        [int]$ResultLimit
    )

    $memRows = Get-MemoryIndexRows -IndexPath $memoryIndexPath

    # Scope-aware filtering: only return memories relevant to this scope
    $scopeFiltered = @()
    foreach ($row in $memRows) {
        $scopeMatch = $false
        if ($ScopeName -eq 'session' -or $ScopeName -eq 'general') {
            $scopeMatch = $true
        } elseif ($ScopeName -eq 'project' -and $row.Scope -eq 'router') {
            $scopeMatch = $true
        } elseif ($ScopeName -eq 'ops' -and $row.Scope -eq 'implement') {
            $scopeMatch = $true
        } elseif ($ScopeName -eq 'memory') {
            $scopeMatch = $true
        } elseif ($ScopeName -eq 'user') {
            $scopeMatch = $true
        }

        if (-not $scopeMatch) { continue }

        if ($SearchQuery) {
            $qMatch = ($row.Module -like ('*' + $SearchQuery + '*')) -or ($row.Tags -like ('*' + $SearchQuery + '*')) -or ($row.Title -like ('*' + $SearchQuery + '*'))
            if (-not $qMatch) { continue }
        }

        $scopeFiltered += $row
    }

    # Also search scope-store entries
    $scopeStoreDb = Join-Path $repoRoot 'Docs\Memory\scope-store.sqlite3'
    $storeJsonPath = $scopeStoreDb -replace '\.sqlite3$', '.json'
    $scopeHits = @()
    if (Test-Path -LiteralPath $storeJsonPath) {
        $raw = [System.IO.File]::ReadAllText($storeJsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                if ($e.scope -ne $ScopeName -and $persistentScopes -notcontains $e.scope) { continue }
                if ($SearchQuery -and $e.key -notlike ('*' + $SearchQuery + '*') -and $e.value -notlike ('*' + $SearchQuery + '*')) { continue }
                $scopeHits += @{ scope = $e.scope; key = $e.key; value = $e.value }
            }
        }
    }

    Write-Host ('[SEARCH] Scope=' + $ScopeName + ' Query=' + $SearchQuery + ' FailureMemories=' + $scopeFiltered.Count + ' ScopeEntries=' + $scopeHits.Count)

    foreach ($row in $scopeFiltered) {
        Write-Host ('  [memory] ' + $row.Id + ': ' + $row.Title)
    }
    foreach ($hit in $scopeHits) {
        Write-Host ('  [scope] ' + $hit.scope + '/' + $hit.key + ' = ' + $hit.value)
    }

    return @{
        failure_memories = $scopeFiltered
        scope_entries = $scopeHits
    }
}

function Save-ContextSnapshot {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$SKey
    )

    if (-not $Apply) {
        Write-Host ('[DRY-RUN] Would snapshot: scope=' + $ScopeName + ' session=' + $SKey)
        return $true
    }

    # Gather current scope-store entries for this scope
    $scopeStoreDb = Join-Path $repoRoot 'Docs\Memory\scope-store.sqlite3'
    $storeJsonPath = $scopeStoreDb -replace '\.sqlite3$', '.json'
    $snapshotEntries = @()
    if (Test-Path -LiteralPath $storeJsonPath) {
        $raw = [System.IO.File]::ReadAllText($storeJsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                if ($e.scope -eq $ScopeName) {
                    $snapshotEntries += @{ scope = $e.scope; key = $e.key; value = $e.value }
                }
            }
        }
    }

    $bridge = Read-BridgeData -Path $BridgeDataPath

    # Remove existing snapshot with same session key
    $filtered = @()
    foreach ($s in $bridge.snapshots) {
        if ($s.session_key -ne $SKey) {
            $filtered += $s
        }
    }
    $bridge.snapshots = $filtered

    $bridge.snapshots += @{
        session_key = $SKey
        scope = $ScopeName
        entries = $snapshotEntries
        created_at = (Get-Date -Format 'o')
    }

    Write-BridgeData -Path $BridgeDataPath -Data $bridge
    Write-Host ('[SNAPSHOT] Saved: scope=' + $ScopeName + ' session=' + $SKey + ' entries=' + $snapshotEntries.Count)
    return $true
}

function Restore-ContextSnapshot {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName,
        [string]$SKey
    )

    $bridge = Read-BridgeData -Path $BridgeDataPath

    $snapshot = $null
    foreach ($s in $bridge.snapshots) {
        if ($s.session_key -eq $SKey) {
            $snapshot = $s
            break
        }
    }

    if ($null -eq $snapshot) {
        Write-Host ('[RESTORE] No snapshot found for session=' + $SKey)
        return @()
    }

    Write-Host ('[RESTORE] Found snapshot for session=' + $SKey + ' scope=' + $snapshot.scope + ' entries=' + $snapshot.entries.Count)

    foreach ($e in $snapshot.entries) {
        Write-Host ('  [' + $e.scope + '] ' + $e.key + ' = ' + $e.value)
    }

    $entries = @()
    if ($snapshot.entries -ne $null) {
        foreach ($e in $snapshot.entries) {
            $entries += @{ scope = $e.scope; key = $e.key; value = $e.value }
        }
    }
    return ,$entries
}

function Invoke-ContaminationGuard {
    param(
        [string]$BridgeDataPath,
        [string]$ScopeName
    )

    $warnings = @()

    # 1. Check for scope-store entries that look misplaced
    $scopeStoreDb = Join-Path $repoRoot 'Docs\Memory\scope-store.sqlite3'
    $storeJsonPath = $scopeStoreDb -replace '\.sqlite3$', '.json'
    if (Test-Path -LiteralPath $storeJsonPath) {
        $raw = [System.IO.File]::ReadAllText($storeJsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                # Detect project-specific keys stored in wrong scopes
                if ($ScopeName -eq 'project') {
                    if ($e.scope -eq 'user' -and ($e.key -like '*rts-*' -or $e.key -like '*gas-*')) {
                        $warnings += @{
                            scope = $e.scope
                            warning_type = 'misplaced-key'
                            detail = 'Project-specific key in user scope, should be in project scope'
                        }
                    }
                }
                # Detect session entries that should have been promoted
                if ($ScopeName -eq 'session' -and $e.scope -eq 'session') {
                    if ([int]$e.access_count -ge 5) {
                        $warnings += @{
                            scope = $e.scope
                            warning_type = 'promotion-candidate'
                            detail = 'Session key accessed multiple times, consider promoting to persistent scope'
                        }
                    }
                }
            }
        }
    }

    # 2. Check bridge links for stale/orphaned references
    $bridge = Read-BridgeData -Path $BridgeDataPath
    $memRows = Get-MemoryIndexRows -IndexPath $memoryIndexPath
    $validIds = @()
    foreach ($row in $memRows) { $validIds += $row.Id }

    foreach ($link in $bridge.links) {
        if ($link.scope -eq $ScopeName -and $validIds -notcontains $link.memory_id) {
            $warnings += @{
                scope = $link.scope
                warning_type = 'orphaned-link'
                detail = 'Link references non-existent failure memory'
            }
        }
    }

    # 3. Report
    Write-Host ('[GUARD] Scope=' + $ScopeName + ' Warnings=' + $warnings.Count)
    foreach ($w in $warnings) {
        Write-Host ('  [' + $w.scope + '] ' + $w.warning_type + ': ' + $w.detail)
    }

    # Record warnings in bridge data if Apply
    if ($Apply -and $warnings.Count -gt 0) {
        foreach ($w in $warnings) {
            $bridge.guard_warnings += @{
                scope = $w.scope
                warning_type = $w.warning_type
                detail = $w.detail
                created_at = (Get-Date -Format 'o')
            }
        }
        Write-BridgeData -Path $BridgeDataPath -Data $bridge
    }

    return ,$warnings
}

# --- SelfTest ---

function Invoke-SelfTest {
    $testBridge = Join-Path $env:TEMP 'scope-bridge-selftest.json'
    $testScopeStore = Join-Path $env:TEMP 'scope-bridge-selftest-scope.json'
    $testMemoryIndex = Join-Path $env:TEMP 'scope-bridge-selftest-index.md'
    Remove-Item -LiteralPath $testBridge -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testScopeStore -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testMemoryIndex -Force -ErrorAction SilentlyContinue

    $pass = 0
    $fail = 0

    # Create a minimal scope-store for testing
    $scopeData = @{
        entries = @(
            @{ id = 'ab01'; scope = 'project'; key = 'rts-gas'; value = 'Use Lyra GAS'; scope_type = 'persistent'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 3; digest = '' }
            @{ id = 'ab02'; scope = 'session'; key = 'temp-draft'; value = 'Draft A'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 0; digest = '' }
            @{ id = 'ab03'; scope = 'user'; key = 'pref-theme'; value = 'dark'; scope_type = 'persistent'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 1; digest = '' }
            @{ id = 'ab04'; scope = 'session'; key = 'rts-config'; value = 'Config X'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 6; digest = '' }
        )
        meta = @{ created_at = '2026-01-01T00:00:00'; version = 1 }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($testScopeStore, ($scopeData | ConvertTo-Json -Depth 10), $utf8NoBom)

    # Create a minimal memory index for testing
    $idxLines = @(
        '| Id | Title | Phase | Module | Severity | Scope | Tags | File |'
        '|----|-------|-------|--------|----------|-------|------|------|'
        '| memory-001 | GAS Setup | plan | rts | high | router | gas,lyra | failures/gas-setup.md |'
        '| memory-002 | UI Layout | implement | web | medium | implement | ui,css | failures/ui-layout.md |'
    )
    $idxContent = $idxLines -join "`r`n"
    [System.IO.File]::WriteAllText($testMemoryIndex, $idxContent, $utf8NoBom)

    # Set up test directory structure for scope-store JSON
    $docsDir = Join-Path $env:TEMP 'Docs\Memory'
    if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }
    $testJson = Join-Path $docsDir 'scope-store.json'
    Copy-Item -LiteralPath $testScopeStore -Destination $testJson -Force

    # Override script-level paths for test isolation
    $origRepoRoot = $repoRoot
    $origMemoryIndexPath = $memoryIndexPath
    $script:repoRoot = $env:TEMP
    $script:memoryIndexPath = $testMemoryIndex

    # Test 1: Init
    try {
        $r = Initialize-Bridge -Path $testBridge
        if ($r) { $pass++; Write-Host '[PASS] Init' } else { $fail++; Write-Host '[FAIL] Init' }
    } catch {
        $fail++; Write-Host ('[FAIL] Init - exception: ' + $_)
    }

    # Test 2: ContextualRecall - project scope sees project + persistent, NOT session
    try {
        $results = Invoke-ContextualRecall -BridgeDataPath $testBridge -ScopeName 'project' -ContextFilter '' -ResultLimit 100
        $hasProject = $false
        $hasUser = $false
        $hasSession = $false
        foreach ($r in $results) {
            if ($r.type -eq 'scope-memory' -and $r.scope -eq 'project') { $hasProject = $true }
            if ($r.type -eq 'scope-memory' -and $r.scope -eq 'user') { $hasUser = $true }
            if ($r.type -eq 'scope-memory' -and $r.scope -eq 'session') { $hasSession = $true }
        }
        if ($hasProject -and $hasUser -and -not $hasSession) {
            $pass++; Write-Host '[PASS] ContextualRecall scope isolation'
        } else {
            $fail++; Write-Host ('[FAIL] ContextualRecall - project=' + $hasProject + ' user=' + $hasUser + ' session=' + $hasSession)
        }
    } catch {
        $fail++; Write-Host ('[FAIL] ContextualRecall - exception: ' + $_)
    }

    # Test 3: ContextualRecall with context filter (key contains 'gas')
    try {
        $results = Invoke-ContextualRecall -BridgeDataPath $testBridge -ScopeName 'project' -ContextFilter 'gas' -ResultLimit 100
        $hasGasKey = $false
        foreach ($r in $results) {
            if ($r.type -eq 'scope-memory' -and $r.key -like '*gas*') { $hasGasKey = $true }
        }
        if ($hasGasKey) {
            $pass++; Write-Host '[PASS] ContextualRecall with filter'
        } else {
            $fail++; Write-Host '[FAIL] ContextualRecall filter - no gas key found'
        }
    } catch {
        $fail++; Write-Host ('[FAIL] ContextualRecall filter - exception: ' + $_)
    }

    # Test 4: Link scope entry to failure memory
    try {
        $script:Apply = $true
        $r = Add-ScopeMemoryLink -BridgeDataPath $testBridge -ScopeName 'project' -EntryKey 'rts-gas' -MemId 'memory-001'
        if ($r) { $pass++; Write-Host '[PASS] Link' } else { $fail++; Write-Host '[FAIL] Link' }
    } catch {
        $fail++; Write-Host ('[FAIL] Link - exception: ' + $_)
    }

    # Test 5: Duplicate link is idempotent
    try {
        $r = Add-ScopeMemoryLink -BridgeDataPath $testBridge -ScopeName 'project' -EntryKey 'rts-gas' -MemId 'memory-001'
        if ($r) { $pass++; Write-Host '[PASS] Link idempotent' } else { $fail++; Write-Host '[FAIL] Link idempotent' }
    } catch {
        $fail++; Write-Host ('[FAIL] Link idempotent - exception: ' + $_)
    }

    # Test 6: Unlink
    try {
        $r = Remove-ScopeMemoryLink -BridgeDataPath $testBridge -ScopeName 'project' -EntryKey 'rts-gas' -MemId 'memory-001'
        if ($r) { $pass++; Write-Host '[PASS] Unlink' } else { $fail++; Write-Host '[FAIL] Unlink' }
    } catch {
        $fail++; Write-Host ('[FAIL] Unlink - exception: ' + $_)
    }

    # Test 7: Scope-aware search
    try {
        $results = Invoke-ScopeAwareSearch -BridgeDataPath $testBridge -ScopeName 'project' -SearchQuery 'gas' -ResultLimit 10
        if ($results.failure_memories.Count -ge 1) {
            $pass++; Write-Host '[PASS] ScopeAwareSearch'
        } else {
            $fail++; Write-Host ('[FAIL] ScopeAwareSearch - count=' + $results.failure_memories.Count)
        }
    } catch {
        $fail++; Write-Host ('[FAIL] ScopeAwareSearch - exception: ' + $_)
    }

    # Test 8: Snapshot save
    try {
        $r = Save-ContextSnapshot -BridgeDataPath $testBridge -ScopeName 'session' -SKey 'test-session'
        if ($r) { $pass++; Write-Host '[PASS] Snapshot save' } else { $fail++; Write-Host '[FAIL] Snapshot save' }
    } catch {
        $fail++; Write-Host ('[FAIL] Snapshot save - exception: ' + $_)
    }

    # Test 9: Snapshot restore
    try {
        $entries = Restore-ContextSnapshot -BridgeDataPath $testBridge -ScopeName 'session' -SKey 'test-session'
        if ($entries.Count -ge 1) {
            $pass++; Write-Host '[PASS] Snapshot restore'
        } else {
            $fail++; Write-Host ('[FAIL] Snapshot restore - count=' + $entries.Count)
        }
    } catch {
        $fail++; Write-Host ('[FAIL] Snapshot restore - exception: ' + $_)
    }

    # Test 10: Contamination guard
    try {
        $warnings = Invoke-ContaminationGuard -BridgeDataPath $testBridge -ScopeName 'session'
        if ($warnings.Count -ge 1) {
            $hasPromotion = $false
            foreach ($w in $warnings) {
                if ($w.warning_type -eq 'promotion-candidate') { $hasPromotion = $true }
            }
            if ($hasPromotion) {
                $pass++; Write-Host '[PASS] ContaminationGuard'
            } else {
                $fail++; Write-Host '[FAIL] ContaminationGuard - no promotion warning'
            }
        } else {
            $fail++; Write-Host '[FAIL] ContaminationGuard - no warnings found'
        }
    } catch {
        $fail++; Write-Host ('[FAIL] ContaminationGuard - exception: ' + $_)
    }

    # Restore script-level paths
    $script:repoRoot = $origRepoRoot
    $script:memoryIndexPath = $origMemoryIndexPath

    # Cleanup
    Remove-Item -LiteralPath $testBridge -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testScopeStore -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testMemoryIndex -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $env:TEMP 'Docs') -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ''
    Write-Host ('=== SelfTest Results: ' + $pass + ' passed, ' + $fail + ' failed ===')
    return ($fail -eq 0)
}

# --- Main Dispatch ---

if ($SelfTest) {
    $result = Invoke-SelfTest
    if (-not $result) { exit 1 }
    exit 0
}

if ($Init) {
    $result = Initialize-Bridge -Path $BridgePath
    if (-not $result) { exit 1 }
    exit 0
}

if ($Recall) {
    if (-not $Scope) {
        Write-Host 'ERROR: -Recall requires -Scope' -ForegroundColor Red
        exit 1
    }
    $results = Invoke-ContextualRecall -BridgeDataPath $BridgePath -ScopeName $Scope -ContextFilter $Context -ResultLimit $Limit
    exit 0
}

if ($Link) {
    if (-not $Scope -or -not $Key -or -not $MemoryId) {
        Write-Host 'ERROR: -Link requires -Scope, -Key, and -MemoryId' -ForegroundColor Red
        exit 1
    }
    $result = Add-ScopeMemoryLink -BridgeDataPath $BridgePath -ScopeName $Scope -EntryKey $Key -MemId $MemoryId
    if (-not $result) { exit 1 }
    exit 0
}

if ($Unlink) {
    if (-not $Scope -or -not $Key -or -not $MemoryId) {
        Write-Host 'ERROR: -Unlink requires -Scope, -Key, and -MemoryId' -ForegroundColor Red
        exit 1
    }
    $result = Remove-ScopeMemoryLink -BridgeDataPath $BridgePath -ScopeName $Scope -EntryKey $Key -MemId $MemoryId
    if (-not $result) { exit 1 }
    exit 0
}

if ($Search) {
    if (-not $Scope) {
        Write-Host 'ERROR: -Search requires -Scope' -ForegroundColor Red
        exit 1
    }
    $results = Invoke-ScopeAwareSearch -BridgeDataPath $BridgePath -ScopeName $Scope -SearchQuery $Query -ResultLimit $Limit
    exit 0
}

if ($Snapshot) {
    if (-not $Scope -or -not $SessionKey) {
        Write-Host 'ERROR: -Snapshot requires -Scope and -SessionKey' -ForegroundColor Red
        exit 1
    }
    $result = Save-ContextSnapshot -BridgeDataPath $BridgePath -ScopeName $Scope -SKey $SessionKey
    if (-not $result) { exit 1 }
    exit 0
}

if ($Restore) {
    if (-not $Scope -or -not $SessionKey) {
        Write-Host 'ERROR: -Restore requires -Scope and -SessionKey' -ForegroundColor Red
        exit 1
    }
    $results = Restore-ContextSnapshot -BridgeDataPath $BridgePath -ScopeName $Scope -SKey $SessionKey
    exit 0
}

if ($Guard) {
    if (-not $Scope) {
        Write-Host 'ERROR: -Guard requires -Scope' -ForegroundColor Red
        exit 1
    }
    $warnings = Invoke-ContaminationGuard -BridgeDataPath $BridgePath -ScopeName $Scope
    exit 0
}

Write-Host 'ERROR: No action specified. Use -Init, -Recall, -Link, -Unlink, -Search, -Snapshot, -Restore, -Guard, or -SelfTest' -ForegroundColor Red
exit 1
