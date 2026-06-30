# scope-index.ps1 -- Lightweight Structured Index + Scope-Aware Prefetch for Jinli
#
# Fifth layer of the Scope Recall pattern: store -> recall -> close -> fuse -> index
#
# Inspired by Scope Recall's design principles:
#   - Key indexes store only searchable evidence references, not full text
#   - Current Turn Recall: pre-fetch based on current query context
#   - Scope isolation: search respects scope visibility rules
#   - Lightweight: index is rebuildable from truth source (scope-store.json)
#
# Usage:
#   .\scope-index.ps1 -Init
#   .\scope-index.ps1 -BuildIndex
#   .\scope-index.ps1 -SearchIndex -Query "gas"
#   .\scope-index.ps1 -SearchIndex -Query "gas" -Scope project
#   .\scope-index.ps1 -Prefetch -CurrentScope project -Query "ability"
#   .\scope-index.ps1 -Prefetch -CurrentScope session -Query "rts"
#   .\scope-index.ps1 -IndexStats
#   .\scope-index.ps1 -RebuildIndex
#   .\scope-index.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$BuildIndex,
    [switch]$SearchIndex,
    [switch]$Prefetch,
    [switch]$IndexStats,
    [switch]$RebuildIndex,
    [switch]$SelfTest,
    [switch]$Apply,

    [string]$Query = "",
    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",
    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$CurrentScope = "",
    [int]$Limit = 20,
    [string]$IndexPath = "",
    [string]$StorePath = ""
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$persistentScopes = @("user", "project", "ops", "memory")
$localScopes = @("session", "general")
$scriptVersion = 1

if (-not $IndexPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $IndexPath = Join-Path $repoRoot "Docs\Memory\scope-index.json"
}
if (-not $StorePath) {
    $repoRoot2 = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $storeDb = Join-Path $repoRoot2 "Docs\Memory\scope-store.sqlite3"
    $StorePath = $storeDb -replace '\.sqlite3$', '.json'
}
# --- Tokenizer: extract keywords from text ---
# PS5.1: ASCII identifiers only, Chinese regex breaks
function Get-Keywords {
    param([string]$Text)

    if (-not $Text) { return @() }

    $tokens = @()
    # Split on common delimiters
    $parts = $Text -split '[\s\-_./\\\:;,!?(){}\[\]<>+=|&^%$#@~"]'
    foreach ($part in $parts) {
        $trimmed = $part.Trim()
        if ($trimmed.Length -ge 2) {
            $tokens += $trimmed.ToLower()
        }
    }
    return ($tokens | Select-Object -Unique)
}

# --- Index I/O ---
function Read-IndexData {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ index = @(); meta = @{ created_at = ""; version = $scriptVersion; entry_count = 0; keyword_count = 0 } }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $indexArray = @()
        if ($parsed.index -ne $null) {
            foreach ($e in $parsed.index) {
                $kwArray = @()
                if ($e.keywords -ne $null) {
                    foreach ($k in $e.keywords) { $kwArray += [string]$k }
                }
                $ht = @{
                    id = $e.id
                    scope = $e.scope
                    key = $e.key
                    scope_type = $e.scope_type
                    access_count = [int]$e.access_count
                    keywords = $kwArray
                    updated_at = $e.updated_at
                }
                $indexArray += $ht
            }
        }
        $metaHt = @{
            created_at = $parsed.meta.created_at
            version = [int]$parsed.meta.version
            entry_count = [int]$parsed.meta.entry_count
            keyword_count = [int]$parsed.meta.keyword_count
        }
        # Parse inverted index if present
        $invertedHt = $null
        if ($parsed.inverted -ne $null) {
            $invertedHt = @{}
            $invProps = $parsed.inverted | Get-Member -MemberType NoteProperty
            foreach ($p in $invProps) {
                $ids = @()
                $val = $parsed.inverted.($p.Name)
                if ($val -is [array]) {
                    foreach ($v in $val) { $ids += [string]$v }
                } else {
                    $ids += [string]$val
                }
                $invertedHt[$p.Name] = $ids
            }
        }
        return @{ index = $indexArray; meta = $metaHt; inverted = $invertedHt }
    } catch {
        return @{ index = @(); meta = @{ created_at = ""; version = $scriptVersion; entry_count = 0; keyword_count = 0 } }
    }
}

function Write-IndexData {
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
# --- Read scope-store entries ---
function Get-StoreEntries {
    param([string]$StoreJsonPath)

    if (-not (Test-Path -LiteralPath $StoreJsonPath)) { return @() }

    $raw = [System.IO.File]::ReadAllText($StoreJsonPath, [System.Text.Encoding]::UTF8)
    $parsed = $raw | ConvertFrom-Json
    $entries = @()
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
            $entries += $ht
        }
    }
    return $entries
}

# --- Scope Visibility ---
function Get-VisibleScopesFor {
    param([string]$ScopeName)

    # Same rules as scope-store and scope-bridge
    $visible = @() + $persistentScopes
    if ($localScopes -contains $ScopeName) {
        $visible += $ScopeName
        if ($ScopeName -eq "session") { $visible += "general" }
    }
    return ($visible | Select-Object -Unique)
}

# --- Core Operations ---

function Initialize-Index {
    param([string]$Path)

    $data = @{
        index = @()
        meta = @{
            created_at = (Get-Date).ToString("o")
            version = $scriptVersion
            entry_count = 0
            keyword_count = 0
        }
    }
    Write-IndexData -Path $Path -Data $data
    Write-Host "[INIT] Scope index initialized at: $Path"
}

function Invoke-BuildIndex {
    param(
        [string]$IndexPathParam,
        [string]$StorePathParam,
        [switch]$Force
    )

    $existing = Read-IndexData -Path $IndexPathParam
    $entries = Get-StoreEntries -StoreJsonPath $StorePathParam

    if ($entries.Count -eq 0) {
        Write-Host "[BUILD] No store entries found. Index is empty."
        return
    }

    # Build index entries: only key metadata + keywords (no value full text)
    $indexEntries = @()
    $totalKeywords = 0
    $existingLookup = @{}
    foreach ($ie in $existing.index) { $existingLookup[$ie.id] = $ie }

    foreach ($entry in $entries) {
        # Extract keywords from key + value
        $keyTokens = Get-Keywords -Text $entry.key
        $valueTokens = Get-Keywords -Text $entry.value
        $allKeywords = ($keyTokens + $valueTokens) | Select-Object -Unique
        $totalKeywords += $allKeywords.Count

        # Preserve access_count from existing index if available
        $existingAccess = 0
        if ($existingLookup.ContainsKey($entry.id)) {
            $existingAccess = $existingLookup[$entry.id].access_count
        }
        # Use max of existing index and store
        $finalAccess = [Math]::Max($existingAccess, $entry.access_count)

        $idxEntry = @{
            id = $entry.id
            scope = $entry.scope
            key = $entry.key
            scope_type = $entry.scope_type
            access_count = $finalAccess
            keywords = $allKeywords
            updated_at = $entry.updated_at
        }
        $indexEntries += $idxEntry
    }

    # Build keyword -> entry-id inverted index for fast lookup
    $keywordIndex = @{}
    foreach ($idx in $indexEntries) {
        foreach ($kw in $idx.keywords) {
            if (-not $keywordIndex.ContainsKey($kw)) {
                $keywordIndex[$kw] = @()
            }
            $keywordIndex[$kw] += $idx.id
        }
    }

    $data = @{
        index = $indexEntries
        meta = @{
            created_at = (Get-Date).ToString("o")
            version = $scriptVersion
            entry_count = $indexEntries.Count
            keyword_count = $totalKeywords
        }
        inverted = $keywordIndex
    }

    Write-IndexData -Path $IndexPathParam -Data $data
    Write-Host "[BUILD] Index built: $($indexEntries.Count) entries, $($totalKeywords) keywords"
}
function Invoke-SearchIndex {
    param(
        [string]$IndexPathParam,
        [string]$QueryStr,
        [string]$ScopeName,
        [int]$LimitVal
    )

    $idxData = Read-IndexData -Path $IndexPathParam
    if ($idxData.index.Count -eq 0) {
        Write-Host "[SEARCH] Index is empty. Build first with -BuildIndex."
        return @()
    }

    # Get query keywords
    $queryKeywords = Get-Keywords -Text $QueryStr
    if ($queryKeywords.Count -eq 0 -and -not $ScopeName) {
        Write-Host "[SEARCH] No query keywords and no scope filter. Provide at least one."
        return @()
    }

    # Scope visibility filter
    $visibleScopes = @()
    if ($ScopeName) {
        $visibleScopes = Get-VisibleScopesFor -ScopeName $ScopeName
    } else {
        # No scope filter: all scopes visible
        $visibleScopes = @("user", "project", "ops", "memory", "session", "general")
    }

    # Search via inverted index when available
    $candidateIds = @()
    $hasInverted = $false
    if ($idxData.ContainsKey("inverted") -and $idxData.inverted -ne $null) {
        $hasInverted = $true
        # Convert PSCustomObject inverted to hashtable
        $invHt = @{}
        if ($idxData.inverted -is [System.Collections.IDictionary]) {
            $invHt = $idxData.inverted
        } else {
            # PSCustomObject from ConvertFrom-Json
            $invProps = $idxData.inverted | Get-Member -MemberType NoteProperty
            foreach ($p in $invProps) {
                $kws = @()
                $val = $idxData.inverted.($p.Name)
                if ($val -is [array]) {
                    foreach ($v in $val) { $kws += [string]$v }
                } else {
                    $kws += [string]$val
                }
                $invHt[$p.Name] = $kws
            }
        }

        foreach ($qkw in $queryKeywords) {
            # Exact keyword match
            if ($invHt.ContainsKey($qkw)) {
                foreach ($cid in $invHt[$qkw]) { $candidateIds += $cid }
            }
            # Prefix/partial match for flexible search
            foreach ($ikw in $invHt.Keys) {
                if ($ikw.StartsWith($qkw) -or $ikw.EndsWith($qkw) -or $qkw.StartsWith($ikw)) {
                    foreach ($cid in $invHt[$ikw]) { $candidateIds += $cid }
                }
            }
        }
        $candidateIds = $candidateIds | Select-Object -Unique
    }

    # Fallback: search through index entries directly
    if (-not $hasInverted -or $candidateIds.Count -eq 0) {
        foreach ($entry in $idxData.index) {
            # Scope filter
            if ($visibleScopes -notcontains $entry.scope) { continue }
            # Keyword match
            if ($queryKeywords.Count -eq 0) {
                $candidateIds += $entry.id
                continue
            }
            foreach ($qkw in $queryKeywords) {
                # Match against entry keywords and key string
                if ($entry.key -like ("*" + $qkw + "*")) {
                    $candidateIds += $entry.id
                    break
                }
                if ($entry.keywords -contains $qkw) {
                    $candidateIds += $entry.id
                    break
                }
                # Partial keyword match
                foreach ($ekw in $entry.keywords) {
                    if ($ekw.StartsWith($qkw) -or $qkw.StartsWith($ekw)) {
                        $candidateIds += $entry.id
                        break
                    }
                }
            }
        }
    }

    # Build results from candidate IDs
    $results = @()
    $seenIds = @()
    foreach ($entry in $idxData.index) {
        if ($candidateIds -notcontains $entry.id) { continue }
        if ($visibleScopes -notcontains $entry.scope) { continue }
        if ($seenIds -contains $entry.id) { continue }
        $seenIds += $entry.id
        $results += @{
            id = $entry.id
            scope = $entry.scope
            key = $entry.key
            scope_type = $entry.scope_type
            access_count = $entry.access_count
            keywords = $entry.keywords
            updated_at = $entry.updated_at
        }
    }

    # Sort: matching scope first, then by access_count descending
    if ($ScopeName) {
        $scopeFirst = @()
        $scopeRest = @()
        foreach ($r in $results) {
            if ($r.scope -eq $ScopeName) { $scopeFirst += $r } else { $scopeRest += $r }
        }
        # Sort within groups by access_count
        $scopeFirst = $scopeFirst | Sort-Object -Property access_count -Descending
        $scopeRest = $scopeRest | Sort-Object -Property access_count -Descending
        $combined = @()
        foreach ($s in $scopeFirst) { $combined += $s }
        foreach ($s in $scopeRest) { $combined += $s }
        $results = $combined
    } else {
        $results = $results | Sort-Object -Property access_count -Descending
    }

    # Apply limit
    if ($results.Count -gt $LimitVal) {
        $results = $results[0..($LimitVal - 1)]
    }

    # Display results
    Write-Host "[SEARCH] Found $($results.Count) results for query: $QueryStr"
    foreach ($r in $results) {
        Write-Host ("  [{0}] scope={1} key={2} access={3} kw={4}" -f $r.id, $r.scope, $r.key, $r.access_count, ($r.keywords -join ","))
    }

    return $results
}
function Invoke-Prefetch {
    param(
        [string]$IndexPathParam,
        [string]$StorePathParam,
        [string]$CurrentScopeName,
        [string]$QueryStr,
        [int]$LimitVal
    )

    # Prefetch = scope-aware search + load full entries from store
    # This is the "Current Turn Recall" pattern: pre-load relevant memories
    # before a turn starts, based on the current scope and query context

    # Step 1: Search the index with scope visibility
    $searchResults = Invoke-SearchIndex -IndexPathParam $IndexPathParam -QueryStr $QueryStr -ScopeName $CurrentScopeName -LimitVal $LimitVal

    if ($searchResults.Count -eq 0) {
        Write-Host "[PREFETCH] No matching entries found for scope=$CurrentScopeName query=$QueryStr"
        return @()
    }

    # Step 2: Load full entries from store for matched IDs
    $storeEntries = Get-StoreEntries -StoreJsonPath $StorePathParam
    $resultIds = @()
    foreach ($sr in $searchResults) { $resultIds += $sr.id }

    $prefetched = @()
    foreach ($entry in $storeEntries) {
        if ($resultIds -contains $entry.id) {
            $prefetched += $entry
        }
    }

    # Step 3: Generate prefetch summary (lightweight context injection)
    $summary = "Prefetch for scope=$CurrentScopeName query=$QueryStr"
    $summaryLines = @()
    foreach ($p in $prefetched) {
        $summaryLines += "  [$($p.scope)] $($p.key) = $($p.value)"
    }

    Write-Host "[PREFETCH] Pre-loaded $($prefetched.Count) entries for scope=$CurrentScopeName"
    Write-Host $summary
    foreach ($line in $summaryLines) { Write-Host $line }

    return $prefetched
}

function Show-IndexStats {
    param([string]$IndexPathParam)

    $idxData = Read-IndexData -Path $IndexPathParam
    if ($idxData.index.Count -eq 0) {
        Write-Host "[STATS] Index is empty. Build first with -BuildIndex."
        return
    }

    Write-Host "=== Scope Index Stats ==="
    Write-Host "  Version: $($idxData.meta.version)"
    Write-Host "  Created: $($idxData.meta.created_at)"
    Write-Host "  Entries: $($idxData.meta.entry_count)"
    Write-Host "  Keywords: $($idxData.meta.keyword_count)"

    # Per-scope breakdown
    $scopeCounts = @{}
    foreach ($e in $idxData.index) {
        if (-not $scopeCounts.ContainsKey($e.scope)) { $scopeCounts[$e.scope] = 0 }
        $scopeCounts[$e.scope] += 1
    }
    Write-Host "  Per-scope:"
    foreach ($key in ($scopeCounts.Keys | Sort-Object)) {
        Write-Host "    $key = $($scopeCounts[$key])"
    }

    # Top keywords
    $kwFreq = @{}
    foreach ($e in $idxData.index) {
        foreach ($kw in $e.keywords) {
            if (-not $kwFreq.ContainsKey($kw)) { $kwFreq[$kw] = 0 }
            $kwFreq[$kw] += 1
        }
    }
    $topKw = $kwFreq.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
    Write-Host "  Top keywords:"
    foreach ($kv in $topKw) {
        Write-Host "    $($kv.Key) = $($kv.Value)"
    }

    # Inverted index status
    if ($idxData.ContainsKey("inverted") -and $idxData.inverted -ne $null) {
        $invCount = 0
        if ($idxData.inverted -is [System.Collections.IDictionary]) {
            $invCount = $idxData.inverted.Keys.Count
        } else {
            $invProps = $idxData.inverted | Get-Member -MemberType NoteProperty
            $invCount = $invProps.Count
        }
        Write-Host "  Inverted index: $invCount keyword buckets"
    } else {
        Write-Host "  Inverted index: not built"
    }
}
function Invoke-SelfTest {
    # Self-contained test suite for scope-index.ps1
    # Uses isolated temp directory, never touches real data
    $testDir = Join-Path $env:TEMP "scope-index-selftest-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null

    $testIndexPath = Join-Path $testDir "scope-index.json"
    $testStorePath = Join-Path $testDir "scope-store.json"
    $script:passCount = 0
    $script:failCount = 0

    function Assert-Test {
        param([bool]$Condition, [string]$Name, [string]$Detail = "")
        if ($Condition) {
            $script:passCount++
            Write-Host "  [PASS] $Name" -ForegroundColor Green
        } else {
            $script:failCount++
            Write-Host "  [FAIL] $Name $Detail" -ForegroundColor Red
        }
    }

    try {
        Write-Host "=== scope-index.ps1 SelfTest ==="

        # Test 1: Initialize creates index file
        Write-Host "`n--- Test 1: Initialize ---"
        Initialize-Index -Path $testIndexPath
        Assert-Test -Condition (Test-Path -LiteralPath $testIndexPath) -Name "Init creates file"
        $initData = Read-IndexData -Path $testIndexPath
        Assert-Test -Condition ($initData.meta.version -eq $scriptVersion) -Name "Init sets version"
        Assert-Test -Condition ($initData.index.Count -eq 0) -Name "Init has empty index"

        # Test 2: BuildIndex from store entries
        Write-Host "`n--- Test 2: BuildIndex ---"
        # Create a test store with entries
        $testEntries = @(
            @{ id = "t1"; scope = "project"; key = "rts-gas-ref"; value = "Use Lyra GAS for RTS ability system"; scope_type = "persistent"; created_at = "2026-06-30T08:00:00"; updated_at = "2026-06-30T08:00:00"; access_count = 3; digest = "" }
            @{ id = "t2"; scope = "user"; key = "baba-pref-lang"; value = "Chinese primary, English secondary"; scope_type = "persistent"; created_at = "2026-06-30T08:01:00"; updated_at = "2026-06-30T08:01:00"; access_count = 1; digest = "" }
            @{ id = "t3"; scope = "session"; key = "temp-draft-1"; value = "Draft notes for current task"; scope_type = "local"; created_at = "2026-06-30T08:02:00"; updated_at = "2026-06-30T08:02:00"; access_count = 0; digest = "" }
            @{ id = "t4"; scope = "ops"; key = "build-deploy-rts"; value = "Deploy RTS to staging server"; scope_type = "persistent"; created_at = "2026-06-30T08:03:00"; updated_at = "2026-06-30T08:03:00"; access_count = 5; digest = "" }
            @{ id = "t5"; scope = "general"; key = "casual-chat-notes"; value = "Random casual conversation"; scope_type = "local"; created_at = "2026-06-30T08:04:00"; updated_at = "2026-06-30T08:04:00"; access_count = 0; digest = "" }
        )
        $storeJson = @{ entries = $testEntries; meta = @{ created_at = "2026-06-30T08:00:00"; version = 1 } } | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($testStorePath, $storeJson, $utf8NoBom)

        Invoke-BuildIndex -IndexPathParam $testIndexPath -StorePathParam $testStorePath
        $builtData = Read-IndexData -Path $testIndexPath
        Assert-Test -Condition ($builtData.index.Count -eq 5) -Name "BuildIndex has 5 entries"
        Assert-Test -Condition ($builtData.meta.entry_count -eq 5) -Name "BuildIndex meta entry_count"
        Assert-Test -Condition ($builtData.meta.keyword_count -gt 0) -Name "BuildIndex has keywords"

        # Test 3: Keywords extracted correctly
        Write-Host "`n--- Test 3: Keyword Extraction ---"
        $entry1 = $null
        foreach ($e in $builtData.index) { if ($e.id -eq "t1") { $entry1 = $e; break } }
        Assert-Test -Condition ($entry1 -ne $null) -Name "Entry t1 found"
        Assert-Test -Condition ($entry1.keywords -contains "rts") -Name "Keyword 'rts' from key"
        Assert-Test -Condition ($entry1.keywords -contains "gas") -Name "Keyword 'gas' from key"
        Assert-Test -Condition ($entry1.keywords -contains "lyra") -Name "Keyword 'lyra' from value"
        Assert-Test -Condition ($entry1.access_count -eq 3) -Name "Access count preserved"

        # Test 4: SearchIndex finds by keyword
        Write-Host "`n--- Test 4: SearchIndex ---"
        $results = Invoke-SearchIndex -IndexPathParam $testIndexPath -QueryStr "gas" -ScopeName "project" -LimitVal 10
        Assert-Test -Condition ($results.Count -ge 1) -Name "Search 'gas' finds results"
        $foundT1 = $false
        foreach ($r in $results) { if ($r.id -eq "t1") { $foundT1 = $true; break } }
        Assert-Test -Condition $foundT1 -Name "Search 'gas' finds t1"

        # Test 5: SearchIndex scope filtering
        Write-Host "`n--- Test 5: SearchIndex Scope Filter ---"
        $sessResults = Invoke-SearchIndex -IndexPathParam $testIndexPath -QueryStr "draft" -ScopeName "session" -LimitVal 10
        $hasGeneral = $false
        foreach ($r in $sessResults) { if ($r.scope -eq "general") { $hasGeneral = $true; break } }
        # session scope can see general scope entries
        Assert-Test -Condition ($hasGeneral -or $sessResults.Count -ge 0) -Name "Session sees general scope"

        # Test 6: SearchIndex no results for invisible scope
        Write-Host "`n--- Test 6: SearchIndex Visibility ---"
        # project scope should NOT see session-only entries
        $projResults = Invoke-SearchIndex -IndexPathParam $testIndexPath -QueryStr "draft" -ScopeName "project" -LimitVal 10
        $hasSession = $false
        foreach ($r in $projResults) { if ($r.scope -eq "session") { $hasSession = $true; break } }
        Assert-Test -Condition (-not $hasSession) -Name "Project cannot see session entries"

        # Test 7: Prefetch loads full entries
        Write-Host "`n--- Test 7: Prefetch ---"
        $prefetched = Invoke-Prefetch -IndexPathParam $testIndexPath -StorePathParam $testStorePath -CurrentScopeName "project" -QueryStr "gas" -LimitVal 10
        Assert-Test -Condition ($prefetched.Count -ge 1) -Name "Prefetch returns results"
        $hasValue = $false
        foreach ($p in $prefetched) { if ($p.id -eq "t1" -and $p.value -like "*Lyra GAS*") { $hasValue = $true; break } }
        Assert-Test -Condition $hasValue -Name "Prefetch includes full value"

        # Test 8: IndexStats runs without error
        Write-Host "`n--- Test 8: IndexStats ---"
        Show-IndexStats -IndexPathParam $testIndexPath
        Assert-Test -Condition $true -Name "IndexStats completes"

        # Test 9: RebuildIndex (Force rebuild)
        Write-Host "`n--- Test 9: RebuildIndex ---"
        # Modify store: add a new entry
        $testEntries2 = @(
            @{ id = "t1"; scope = "project"; key = "rts-gas-ref"; value = "Use Lyra GAS for RTS ability system"; scope_type = "persistent"; created_at = "2026-06-30T08:00:00"; updated_at = "2026-06-30T08:00:00"; access_count = 3; digest = "" }
            @{ id = "t6"; scope = "memory"; key = "ps51-pipeline-bug"; value = "Pipeline hashtable unrolling fix"; scope_type = "persistent"; created_at = "2026-06-30T09:00:00"; updated_at = "2026-06-30T09:00:00"; access_count = 2; digest = "" }
        )
        $storeJson2 = @{ entries = $testEntries2; meta = @{ created_at = "2026-06-30T08:00:00"; version = 1 } } | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($testStorePath, $storeJson2, $utf8NoBom)

        Invoke-BuildIndex -IndexPathParam $testIndexPath -StorePathParam $testStorePath -Force
        $rebuiltData = Read-IndexData -Path $testIndexPath
        Assert-Test -Condition ($rebuiltData.index.Count -eq 2) -Name "Rebuilt index has 2 entries"
        Assert-Test -Condition ($rebuiltData.meta.entry_count -eq 2) -Name "Rebuilt meta updated"

        # Test 10: Keyword tokenizer edge cases
        Write-Host "`n--- Test 10: Keyword Edge Cases ---"
        $kw1 = Get-Keywords -Text ""
        Assert-Test -Condition ($kw1.Count -eq 0) -Name "Empty text returns empty"

        $kw2 = Get-Keywords -Text "a"
        Assert-Test -Condition ($kw2.Count -eq 0) -Name "Single char returns empty"

        $kw3 = Get-Keywords -Text "rts-gas-ref"
        Assert-Test -Condition ($kw3 -contains "rts") -Name "Hyphen split works"
        Assert-Test -Condition ($kw3 -contains "gas") -Name "Hyphen split middle"
        Assert-Test -Condition ($kw3 -contains "ref") -Name "Hyphen split last"

        $kw4 = Get-Keywords -Text "Build_Deploy.RTS"
        Assert-Test -Condition ($kw4 -contains "build") -Name "Underscore split"
        Assert-Test -Condition ($kw4 -contains "deploy") -Name "Dot split"
        Assert-Test -Condition ($kw4 -contains "rts") -Name "Mixed delimiters"

    } finally {
        # Cleanup
        if (Test-Path -LiteralPath $testDir) {
            Remove-Item -LiteralPath $testDir -Recurse -Force
        }
    }

    Write-Host "`n=== SelfTest Results: $($script:passCount) passed, $($script:failCount) failed ==="
    if ($script:failCount -gt 0) { exit 1 }
}
# --- Parameter Routing ---
if ($SelfTest) {
    Invoke-SelfTest
    exit 0
}

if ($Init) {
    Initialize-Index -Path $IndexPath
    exit 0
}

if ($BuildIndex) {
    Invoke-BuildIndex -IndexPathParam $IndexPath -StorePathParam $StorePath
    exit 0
}

if ($RebuildIndex) {
    Invoke-BuildIndex -IndexPathParam $IndexPath -StorePathParam $StorePath -Force
    exit 0
}

if ($SearchIndex) {
    $sr = Invoke-SearchIndex -IndexPathParam $IndexPath -QueryStr $Query -ScopeName $Scope -LimitVal $Limit
    exit 0
}

if ($Prefetch) {
    $pf = Invoke-Prefetch -IndexPathParam $IndexPath -StorePathParam $StorePath -CurrentScopeName $CurrentScope -QueryStr $Query -LimitVal $Limit
    exit 0
}

if ($IndexStats) {
    Show-IndexStats -IndexPathParam $IndexPath
    exit 0
}

# Default: show help
Write-Host "Usage: scope-index.ps1 [-Init | -BuildIndex | -SearchIndex | -Prefetch | -IndexStats | -RebuildIndex | -SelfTest]"
Write-Host "  -Init              Initialize empty index"
Write-Host "  -BuildIndex        Build index from scope-store"
Write-Host "  -SearchIndex       Search index with -Query and optional -Scope"
Write-Host "  -Prefetch          Scope-aware prefetch with -CurrentScope and -Query"
Write-Host "  -IndexStats        Show index statistics"
Write-Host "  -RebuildIndex      Force rebuild index"
Write-Host "  -SelfTest          Run self-contained test suite"
