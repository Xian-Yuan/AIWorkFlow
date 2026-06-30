# scope-store.ps1 -- Scoped Memory Store for Jinli (Scope Recall pattern)
#
# Implements memory partitioning inspired by Scope Recall:
#   - Persistent scopes: user, project, ops, memory (cross-session)
#   - Local scopes: session, general (current-session only)
#   - Scope isolation: agents see only current local scope + shared persistent scopes
#   - JSON file-based truth source (SQLite when available)
#   - Current Turn Recall: pre-fetch based on session context
#   - Digest: consolidate persistent facts to prevent bloat
#
# Usage:
#   .\scope-store.ps1 -Init
#   .\scope-store.ps1 -Store -Scope project -Key rts-gas-ref -Value "Use Lyra GAS"
#   .\scope-store.ps1 -Recall -Scope project -Key rts-gas-ref
#   .\scope-store.ps1 -ListScopes
#   .\scope-store.ps1 -Digest -Apply
#   .\scope-store.ps1 -CurrentTurnRecall -SessionKey task-rt1
#   .\scope-store.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Store,
    [switch]$Recall,
    [switch]$Delete,
    [switch]$ListScopes,
    [switch]$Digest,
    [switch]$CurrentTurnRecall,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",

    [string]$Key = "",
    [string]$Value = "",
    [string]$SessionKey = "",
    [int]$Limit = 20,
    [string]$DbPath = ""
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$persistentScopes = @("user", "project", "ops", "memory")
$localScopes = @("session", "general")

if (-not $DbPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.sqlite3"
}

# --- JSON File-based Store ---
# PS5.1 note: ConvertFrom-Json returns PSCustomObject, not Hashtable.
# Empty arrays are falsy in PS, so we use $null checks explicitly.
# Pipeline unrolling: single-element hashtable arrays must be wrapped in @().

function Get-JsonStorePath {
    param([string]$DatabasePath)
    return $DatabasePath -replace '\.sqlite3$', '.json'
}

function Read-JsonStore {
    param([string]$DatabasePath)

    $jsonPath = Get-JsonStorePath -DatabasePath $DatabasePath
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        return @{ entries = @(); meta = @{ created_at = ""; version = 1 } }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        # Convert PSCustomObject entries back to hashtables for mutability
        $entriesArray = @()
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                $ht = @{
                    id = $e.id
                    scope = $e.scope
                    key = $e.key
                    value = $e.value
                    scope_type = $e.scope_type
                    created_at = $e.created_at
                    updated_at = $e.updated_at
                    access_count = [int]$e.access_count
                    digest = $e.digest
                }
                $entriesArray += $ht
            }
        }
        $metaHt = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        return @{ entries = $entriesArray; meta = $metaHt }
    } catch {
        return @{ entries = @(); meta = @{ created_at = ""; version = 1 } }
    }
}

function Write-JsonStore {
    param(
        [string]$DatabasePath,
        $Data
    )

    $jsonPath = Get-JsonStorePath -DatabasePath $DatabasePath
    $dir = Split-Path -Parent $jsonPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($jsonPath, $json, $utf8NoBom)
}

# --- Core Operations ---

function Initialize-Store {
    param([string]$DatabasePath)

    $jsonPath = Get-JsonStorePath -DatabasePath $DatabasePath
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        $store = @{ entries = @(); meta = @{ created_at = (Get-Date -Format "o"); version = 1 } }
        Write-JsonStore -DatabasePath $DatabasePath -Data $store
    }
    Write-Host "[INIT] Scoped memory store initialized at: $jsonPath"
    return $true
}

function Store-MemoryEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [string]$EntryValue
    )

    if (-not $Apply) {
        Write-Host "[DRY-RUN] Would store: scope=$ScopeName key=$EntryKey"
        return $true
    }

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $foundIdx = -1
    for ($i = 0; $i -lt $entriesList.Count; $i++) {
        if ($entriesList[$i].scope -eq $ScopeName -and $entriesList[$i].key -eq $EntryKey) {
            $foundIdx = $i
            break
        }
    }

    $scopeType = if ($persistentScopes -contains $ScopeName) { "persistent" } else { "local" }

    if ($foundIdx -ge 0) {
        $entriesList[$foundIdx].value = $EntryValue
        $entriesList[$foundIdx].updated_at = (Get-Date -Format "o")
        $entriesList[$foundIdx].access_count = [int]$entriesList[$foundIdx].access_count + 1
        Write-Host "[STORE] Updated: scope=$ScopeName key=$EntryKey type=$scopeType"
    } else {
        $newEntry = @{
            id = [guid]::NewGuid().ToString("N").Substring(0, 8)
            scope = $ScopeName
            key = $EntryKey
            value = $EntryValue
            scope_type = $scopeType
            created_at = (Get-Date -Format "o")
            updated_at = (Get-Date -Format "o")
            access_count = 0
            digest = ""
        }
        $entriesList += $newEntry
        Write-Host "[STORE] Created: scope=$ScopeName key=$EntryKey type=$scopeType"
    }

    $store = @{ entries = $entriesList; meta = $store.meta }
    Write-JsonStore -DatabasePath $DatabasePath -Data $store
    return $true
}

function Recall-MemoryEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [int]$EntryLimit
    )

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    # Scope-aware visibility: agent can see current scope + all persistent scopes
    $visibleScopes = @($ScopeName) + $persistentScopes
    if ($ScopeName -eq "session") {
        $visibleScopes += @("general")
    }

    $results = @()
    foreach ($entry in $entriesList) {
        if ($visibleScopes -notcontains $entry.scope) { continue }
        if ($EntryKey -and $entry.key -ne $EntryKey) { continue }
        $results += $entry
    }

    # Sort: exact scope match first, then by updated_at descending
    # CRITICAL: wrap in @() to prevent PS pipeline unrolling single hashtables into properties
    if ($results.Count -gt 0) {
        $results = @($results | Sort-Object -Property @{ Expression = { if ($_.scope -eq $ScopeName) { 0 } else { 1 } } }, @{ Expression = { $_.updated_at }; Descending = $true } | Select-Object -First $EntryLimit)
    }

    return ,$results
}

function Delete-MemoryEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey
    )

    if (-not $Apply) {
        Write-Host "[DRY-RUN] Would delete: scope=$ScopeName key=$EntryKey"
        return $true
    }

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $filtered = @()
    $removed = 0
    foreach ($entry in $entriesList) {
        if ($entry.scope -eq $ScopeName -and $entry.key -eq $EntryKey) {
            $removed++
        } else {
            $filtered += $entry
        }
    }

    $store = @{ entries = $filtered; meta = $store.meta }
    Write-JsonStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[DELETE] Removed $removed entry/entries: scope=$ScopeName key=$EntryKey"
    return ($removed -gt 0)
}

function Get-VisibleScopes {
    param([string]$CurrentScope)

    $visible = @($CurrentScope) + $persistentScopes
    if ($CurrentScope -eq "session") {
        $visible += @("general")
    }
    return ($visible | Select-Object -Unique)
}

function Show-ScopeList {
    param([string]$DatabasePath)

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    Write-Host "=== Scoped Memory Store ==="
    Write-Host ""

    $scopeGroups = @{}
    foreach ($entry in $entriesList) {
        $s = $entry.scope
        if (-not $scopeGroups.ContainsKey($s)) {
            $scopeGroups[$s] = @()
        }
        $scopeGroups[$s] += $entry
    }

    Write-Host "--- Persistent Scopes (cross-session) ---"
    foreach ($s in $persistentScopes) {
        $count = if ($scopeGroups.ContainsKey($s)) { $scopeGroups[$s].Count } else { 0 }
        $type = if ($count -gt 0) { "ACTIVE" } else { "EMPTY" }
        Write-Host ("  {0,-10} {1,3} entries  [{2}]" -f $s, $count, $type)
    }

    Write-Host ""
    Write-Host "--- Local Scopes (current-session only) ---"
    foreach ($s in $localScopes) {
        $count = if ($scopeGroups.ContainsKey($s)) { $scopeGroups[$s].Count } else { 0 }
        $type = if ($count -gt 0) { "ACTIVE" } else { "EMPTY" }
        Write-Host ("  {0,-10} {1,3} entries  [{2}]" -f $s, $count, $type)
    }

    Write-Host ""
    Write-Host "Total entries: $($entriesList.Count)"
    return $true
}

function Invoke-Digest {
    param([string]$DatabasePath)

    if (-not $Apply) {
        Write-Host "[DRY-RUN] Would digest persistent memories"
        return $true
    }

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $changed = $false
    $scopeGroups = @{}
    foreach ($entry in $entriesList) {
        $s = $entry.scope
        if (-not $scopeGroups.ContainsKey($s)) {
            $scopeGroups[$s] = @()
        }
        $scopeGroups[$s] += $entry
    }

    foreach ($scopeName in $persistentScopes) {
        if (-not $scopeGroups.ContainsKey($scopeName)) { continue }
        $scopeEntries = @($scopeGroups[$scopeName])

        if ($scopeEntries.Count -gt 50) {
            $sorted = @($scopeEntries | Sort-Object -Property updated_at)
            $toDigest = @($sorted | Select-Object -First 20)
            $toKeep = @($sorted | Select-Object -Skip 20)

            $digestValues = @()
            foreach ($e in $toDigest) {
                $digestValues += ("[{0}] {1}" -f $e.key, $e.value)
            }

            $digestEntry = @{
                id = [guid]::NewGuid().ToString("N").Substring(0, 8)
                scope = $scopeName
                key = "digest-$(Get-Date -Format 'yyyy-MM-dd')"
                value = ($digestValues -join "; ")
                scope_type = "persistent"
                created_at = (Get-Date -Format "o")
                updated_at = (Get-Date -Format "o")
                access_count = 0
                digest = "auto-consolidated"
            }

            $newEntries = @($toKeep) + @($digestEntry)
            $scopeGroups[$scopeName] = $newEntries
            $changed = $true
            Write-Host "[DIGEST] Consolidated $($toDigest.Count) entries in scope=$scopeName"
        }
    }

    if ($changed) {
        $allEntries = @()
        foreach ($sn in $scopeGroups.Keys) {
            foreach ($e in $scopeGroups[$sn]) {
                $allEntries += $e
            }
        }
        $store = @{ entries = $allEntries; meta = $store.meta }
        Write-JsonStore -DatabasePath $DatabasePath -Data $store
    } else {
        Write-Host "[DIGEST] No consolidation needed"
    }

    return $true
}

function Invoke-CurrentTurnRecall {
    param(
        [string]$DatabasePath,
        [string]$SKey
    )

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $results = @()

    # 1. Session-scoped entries matching the session key
    foreach ($entry in $entriesList) {
        if ($entry.scope -eq "session" -and $entry.key -like "*$SKey*") {
            $results += $entry
        }
    }

    # 2. Persistent entries that match the session key pattern
    foreach ($entry in $entriesList) {
        if ($persistentScopes -contains $entry.scope -and $entry.key -like "*$SKey*") {
            $results += $entry
        }
    }

    # 3. General scope entries
    foreach ($entry in $entriesList) {
        if ($entry.scope -eq "general" -and $entry.key -like "*$SKey*") {
            $results += $entry
        }
    }

    # CRITICAL: wrap in @() to prevent PS pipeline unrolling
    $results = @($results | Select-Object -First $Limit)

    Write-Host "[CURRENT-TURN-RECALL] Session=$SKey Found=$($results.Count) entries"
    foreach ($r in $results) {
        Write-Host ("  [{0}] {1} = {2}" -f $r.scope, $r.key, $r.value)
    }

    return ,$results
}

# --- SelfTest ---

function Invoke-SelfTest {
    $testSqlite = Join-Path $env:TEMP "scope-store-selftest.sqlite3"
    $testJson = Join-Path $env:TEMP "scope-store-selftest.json"
    Remove-Item -LiteralPath $testJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testSqlite -Force -ErrorAction SilentlyContinue

    $pass = 0
    $fail = 0

    # Test 1: Init
    try {
        $r = Initialize-Store -DatabasePath $testSqlite
        if ($r) { $pass++; Write-Host "[PASS] Init" } else { $fail++; Write-Host "[FAIL] Init" }
    } catch {
        $fail++; Write-Host "[FAIL] Init - exception: $_"
    }

    # Test 2: Store persistent entry
    try {
        $script:Apply = $true
        $r = Store-MemoryEntry -DatabasePath $testSqlite -ScopeName "project" -EntryKey "rts-gas" -EntryValue "Use Lyra GAS"
        if ($r) { $pass++; Write-Host "[PASS] Store persistent" } else { $fail++; Write-Host "[FAIL] Store persistent" }
    } catch {
        $fail++; Write-Host "[FAIL] Store persistent - exception: $_"
    }

    # Test 3: Store local entry
    try {
        $r = Store-MemoryEntry -DatabasePath $testSqlite -ScopeName "session" -EntryKey "temp-draft" -EntryValue "Draft content"
        if ($r) { $pass++; Write-Host "[PASS] Store local" } else { $fail++; Write-Host "[FAIL] Store local" }
    } catch {
        $fail++; Write-Host "[FAIL] Store local - exception: $_"
    }

    # Test 4: Recall from persistent scope
    try {
        $results = Recall-MemoryEntry -DatabasePath $testSqlite -ScopeName "project" -EntryKey "rts-gas" -EntryLimit 10
        if ($results.Count -eq 1 -and $results[0].value -eq "Use Lyra GAS") {
            $pass++; Write-Host "[PASS] Recall persistent"
        } else {
            $fail++; Write-Host "[FAIL] Recall persistent - count=$($results.Count)"
        }
    } catch {
        $fail++; Write-Host "[FAIL] Recall persistent - exception: $_"
    }

    # Test 5: Scope isolation - project scope should NOT see general entries
    try {
        Store-MemoryEntry -DatabasePath $testSqlite -ScopeName "general" -EntryKey "other-session" -EntryValue "Other"
        $results = Recall-MemoryEntry -DatabasePath $testSqlite -ScopeName "project" -EntryKey "other-session" -EntryLimit 10
        if ($results.Count -eq 0) {
            $pass++; Write-Host "[PASS] Scope isolation"
        } else {
            $fail++; Write-Host "[FAIL] Scope isolation - found $($results.Count) entries"
        }
    } catch {
        $fail++; Write-Host "[FAIL] Scope isolation - exception: $_"
    }

    # Test 6: Session scope sees persistent + general
    try {
        $results = Recall-MemoryEntry -DatabasePath $testSqlite -ScopeName "session" -EntryKey "" -EntryLimit 100
        $scopes = @()
        if ($results.Count -gt 0) {
            $scopes = @($results | ForEach-Object { $_.scope }) | Select-Object -Unique
        }
        if (($scopes -contains "session") -and ($scopes -contains "project")) {
            $pass++; Write-Host "[PASS] Session sees persistent + own scope"
        } else {
            $fail++; Write-Host "[FAIL] Session visibility - scopes: $($scopes -join ',')"
        }
    } catch {
        $fail++; Write-Host "[FAIL] Session visibility - exception: $_"
    }

    # Test 7: Update existing entry
    try {
        Store-MemoryEntry -DatabasePath $testSqlite -ScopeName "project" -EntryKey "rts-gas" -EntryValue "Use Lyra GAS v2"
        $results = Recall-MemoryEntry -DatabasePath $testSqlite -ScopeName "project" -EntryKey "rts-gas" -EntryLimit 10
        if ($results.Count -eq 1 -and $results[0].value -eq "Use Lyra GAS v2") {
            $pass++; Write-Host "[PASS] Update existing"
        } else {
            $fail++; Write-Host "[FAIL] Update existing - value: $($results[0].value)"
        }
    } catch {
        $fail++; Write-Host "[FAIL] Update existing - exception: $_"
    }

    # Test 8: Delete entry
    try {
        Delete-MemoryEntry -DatabasePath $testSqlite -ScopeName "general" -EntryKey "other-session"
        $results = Recall-MemoryEntry -DatabasePath $testSqlite -ScopeName "general" -EntryKey "other-session" -EntryLimit 10
        if ($results.Count -eq 0) {
            $pass++; Write-Host "[PASS] Delete entry"
        } else {
            $fail++; Write-Host "[FAIL] Delete - found $($results.Count)"
        }
    } catch {
        $fail++; Write-Host "[FAIL] Delete - exception: $_"
    }

    # Test 9: ListScopes
    try {
        $r = Show-ScopeList -DatabasePath $testSqlite
        if ($r) { $pass++; Write-Host "[PASS] ListScopes" } else { $fail++; Write-Host "[FAIL] ListScopes" }
    } catch {
        $fail++; Write-Host "[FAIL] ListScopes - exception: $_"
    }

    # Test 10: CurrentTurnRecall
    try {
        Store-MemoryEntry -DatabasePath $testSqlite -ScopeName "session" -EntryKey "task-rt1-config" -EntryValue "Config A"
        $results = Invoke-CurrentTurnRecall -DatabasePath $testSqlite -SKey "rt1"
        if ($results.Count -ge 1) {
            $pass++; Write-Host "[PASS] CurrentTurnRecall"
        } else {
            $fail++; Write-Host "[FAIL] CurrentTurnRecall - found $($results.Count)"
        }
    } catch {
        $fail++; Write-Host "[FAIL] CurrentTurnRecall - exception: $_"
    }

    # Cleanup
    Remove-Item -LiteralPath $testJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testSqlite -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "=== SelfTest Results: $pass passed, $fail failed ==="
    return ($fail -eq 0)
}

# --- Main Dispatch ---

if ($SelfTest) {
    $result = Invoke-SelfTest
    if (-not $result) { exit 1 }
    exit 0
}

if ($Init) {
    $result = Initialize-Store -DatabasePath $DbPath
    if (-not $result) { exit 1 }
    exit 0
}

if ($Store) {
    if (-not $Scope -or -not $Key) {
        Write-Host "ERROR: -Store requires -Scope and -Key" -ForegroundColor Red
        exit 1
    }
    $result = Store-MemoryEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -EntryValue $Value
    if (-not $result) { exit 1 }
    exit 0
}

if ($Recall) {
    if (-not $Scope) {
        Write-Host "ERROR: -Recall requires -Scope" -ForegroundColor Red
        exit 1
    }
    $results = Recall-MemoryEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -EntryLimit $Limit
    if ($results.Count -gt 0) {
        Write-Host "[RECALL] Found $($results.Count) entries:"
        foreach ($r in $results) {
            Write-Host ("  [{0}] {1} = {2}" -f $r.scope, $r.key, $r.value)
        }
    } else {
        Write-Host "[RECALL] No entries found for scope=$Scope key=$Key"
    }
    exit 0
}

if ($Delete) {
    if (-not $Scope -or -not $Key) {
        Write-Host "ERROR: -Delete requires -Scope and -Key" -ForegroundColor Red
        exit 1
    }
    $result = Delete-MemoryEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key
    if (-not $result) { exit 1 }
    exit 0
}

if ($ListScopes) {
    $result = Show-ScopeList -DatabasePath $DbPath
    if (-not $result) { exit 1 }
    exit 0
}

if ($Digest) {
    $result = Invoke-Digest -DatabasePath $DbPath
    if (-not $result) { exit 1 }
    exit 0
}

if ($CurrentTurnRecall) {
    if (-not $SessionKey) {
        Write-Host "ERROR: -CurrentTurnRecall requires -SessionKey" -ForegroundColor Red
        exit 1
    }
    $results = Invoke-CurrentTurnRecall -DatabasePath $DbPath -SKey $SessionKey
    exit 0
}

Write-Host "ERROR: No action specified. Use -Init, -Store, -Recall, -Delete, -ListScopes, -Digest, -CurrentTurnRecall, or -SelfTest" -ForegroundColor Red
exit 1
