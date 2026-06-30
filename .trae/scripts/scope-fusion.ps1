# scope-fusion.ps1 -- Cross-Session Memory Fusion for Jinli (Scope Recall pattern)
#
# Resolves the "cross-window memory recall" problem from Scope Recall (BV19EE16aEn7):
#   When multiple sessions/windows produce overlapping or conflicting knowledge,
#   fusion merges, deduplicates, and reconciles them into a coherent whole.
#
# Capabilities:
#   - Detect: find duplicate and conflicting entries across scopes
#   - Merge: combine duplicate entries (keep latest, preserve access history)
#   - Reconcile: resolve conflicts with configurable strategies (latest, highest-access, manual)
#   - CrossRecall: recall a key across ALL scopes (cross-window visibility)
#   - FusionReport: generate a report of fusion opportunities
#   - AutoFusion: run detect + merge + reconcile in one pass
#
# Depends on: scope-store.ps1 (storage layer)
#
# Usage:
#   .\scope-fusion.ps1 -Init
#   .\scope-fusion.ps1 -Detect
#   .\scope-fusion.ps1 -Merge -Strategy latest -Apply
#   .\scope-fusion.ps1 -Reconcile -Strategy highest-access -Apply
#   .\scope-fusion.ps1 -CrossRecall -Key rts-gas
#   .\scope-fusion.ps1 -FusionReport
#   .\scope-fusion.ps1 -AutoFusion -Strategy latest -Apply
#   .\scope-fusion.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Detect,
    [switch]$Merge,
    [switch]$Reconcile,
    [switch]$CrossRecall,
    [switch]$FusionReport,
    [switch]$AutoFusion,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("latest", "highest-access", "manual")]
    [string]$Strategy = "latest",

    [string]$Key = "",
    [string]$Scope = "",
    [string]$FusionPath = "",
    [string]$DbPath = ""
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scopeStoreScript = Join-Path $PSScriptRoot "scope-store.ps1"

if (-not $DbPath) {
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.sqlite3"
}
if (-not $FusionPath) {
    $FusionPath = Join-Path $repoRoot "Docs\Memory\scope-fusion.json"
}

$persistentScopes = @("user", "project", "ops", "memory")
$localScopes = @("session", "general")

# --- JSON Store Access (mirrors scope-store.ps1) ---

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

# --- Fusion State ---

function Read-FusionState {
    param([string]$FusionFilePath)

    if (-not (Test-Path -LiteralPath $FusionFilePath)) {
        return @{ fusions = @(); meta = @{ created_at = ""; version = 1 } }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($FusionFilePath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $fusionsArray = @()
        if ($parsed.fusions -ne $null) {
            foreach ($f in $parsed.fusions) {
                $ht = @{
                    id = $f.id
                    fusion_type = $f.fusion_type
                    source_keys = $f.source_keys
                    result_key = $f.result_key
                    result_scope = $f.result_scope
                    strategy = $f.strategy
                    created_at = $f.created_at
                    entries_removed = [int]$f.entries_removed
                }
                $fusionsArray += $ht
            }
        }
        $metaHt = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        return @{ fusions = $fusionsArray; meta = $metaHt }
    } catch {
        return @{ fusions = @(); meta = @{ created_at = ""; version = 1 } }
    }
}

function Write-FusionState {
    param(
        [string]$FusionFilePath,
        $Data
    )

    $dir = Split-Path -Parent $FusionFilePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($FusionFilePath, $json, $utf8NoBom)
}

# --- Core Fusion Operations ---

function Initialize-Fusion {
    param([string]$FusionFilePath)

    if (-not (Test-Path -LiteralPath $FusionFilePath)) {
        $state = @{ fusions = @(); meta = @{ created_at = (Get-Date -Format "o"); version = 1 } }
        Write-FusionState -FusionFilePath $FusionFilePath -Data $state
    }
    Write-Host "[INIT] Scope fusion state initialized at: $FusionFilePath"
    return $true
}

function Find-Duplicates {
    param([string]$DatabasePath)

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    # Group by key across all scopes
    $keyGroups = @{}
    foreach ($entry in $entriesList) {
        $k = $entry.key
        if (-not $keyGroups.ContainsKey($k)) {
            $keyGroups[$k] = @()
        }
        $keyGroups[$k] += $entry
    }

    # Find keys that appear in multiple scopes
    $duplicates = @()
    $conflicts = @()

    foreach ($k in $keyGroups.Keys) {
        $group = @($keyGroups[$k])
        if ($group.Count -lt 2) { continue }

        # Check if values differ across scopes = conflict
        $values = @($group | ForEach-Object { $_.value }) | Select-Object -Unique
        if ($values.Count -gt 1) {
            $conflicts += @{
                key = $k
                entries = $group
                distinct_values = $values.Count
                scopes = @($group | ForEach-Object { $_.scope }) | Select-Object -Unique
            }
        } else {
            # Same value in multiple scopes = pure duplicate
            $duplicates += @{
                key = $k
                entries = $group
                value = $group[0].value
                scopes = @($group | ForEach-Object { $_.scope }) | Select-Object -Unique
            }
        }
    }

    return @{ duplicates = $duplicates; conflicts = $conflicts }
}

function Invoke-Merge {
    param(
        [string]$DatabasePath,
        [string]$FusionFilePath,
        [string]$MergeStrategy
    )

    if (-not $Apply) {
        Write-Host "[DRY-RUN] Would merge duplicate entries using strategy: $MergeStrategy"
        return $true
    }

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $result = Find-Duplicates -DatabasePath $DatabasePath
    $duplicates = @($result.duplicates)

    if ($duplicates.Count -eq 0) {
        Write-Host "[MERGE] No duplicates found. Nothing to merge."
        return $true
    }

    $fusionState = Read-FusionState -FusionFilePath $FusionFilePath
    $fusionsList = @()
    if ($fusionState.fusions -ne $null) {
        foreach ($f in $fusionState.fusions) { $fusionsList += $f }
    }

    $totalRemoved = 0

    foreach ($dup in $duplicates) {
        $entries = @($dup.entries)
        if ($entries.Count -lt 2) { continue }

        # Pick winner based on strategy
        $winner = $null
        if ($MergeStrategy -eq "latest") {
            # Sort by updated_at descending, pick first
            $sorted = @($entries | Sort-Object -Property updated_at -Descending)
            $winner = $sorted[0]
        } elseif ($MergeStrategy -eq "highest-access") {
            # Sort by access_count descending, pick first
            $sorted = @($entries | Sort-Object -Property access_count -Descending)
            $winner = $sorted[0]
        } else {
            # manual: pick the one in the most persistent scope, then latest
            $sorted = @($entries | Sort-Object -Property @{ Expression = {
                if ($_.scope -eq "memory") { 4 }
                elseif ($_.scope -eq "ops") { 3 }
                elseif ($_.scope -eq "project") { 2 }
                elseif ($_.scope -eq "user") { 1 }
                else { 0 }
            }; Descending = $true }, updated_at -Descending)
            $winner = $sorted[0]
        }

        # Remove all entries with this key except the winner
        $newEntries = @()
        $removed = 0
        foreach ($e in $entriesList) {
            if ($e.key -eq $dup.key -and $e.id -ne $winner.id) {
                $removed++
            } else {
                $newEntries += $e
            }
        }
        $entriesList = $newEntries

        # Accumulate access counts from removed entries
        $totalAccess = [int]$winner.access_count
        foreach ($e in $entries) {
            if ($e.id -ne $winner.id) {
                $totalAccess += [int]$e.access_count
            }
        }

        # Update winner with accumulated access count
        for ($i = 0; $i -lt $entriesList.Count; $i++) {
            if ($entriesList[$i].id -eq $winner.id) {
                $entriesList[$i].access_count = $totalAccess
                $entriesList[$i].updated_at = (Get-Date -Format "o")
                break
            }
        }

        $totalRemoved += $removed

        # Record fusion
        $fusionRecord = @{
            id = [guid]::NewGuid().ToString("N").Substring(0, 8)
            fusion_type = "merge"
            source_keys = @($entries | ForEach-Object { $_.id })
            result_key = $winner.id
            result_scope = $winner.scope
            strategy = $MergeStrategy
            created_at = (Get-Date -Format "o")
            entries_removed = $removed
        }
        $fusionsList += $fusionRecord

        Write-Host ("[MERGE] key={0}: kept scope={1} id={2}, removed {3} duplicates" -f $dup.key, $winner.scope, $winner.id, $removed)
    }

    # Write back
    $store = @{ entries = $entriesList; meta = $store.meta }
    Write-JsonStore -DatabasePath $DatabasePath -Data $store

    $fusionState = @{ fusions = $fusionsList; meta = $fusionState.meta }
    Write-FusionState -FusionFilePath $FusionFilePath -Data $fusionState

    Write-Host "[MERGE] Total: removed $totalRemoved duplicate entries"
    return $true
}

function Invoke-Reconcile {
    param(
        [string]$DatabasePath,
        [string]$FusionFilePath,
        [string]$ReconcileStrategy
    )

    if (-not $Apply) {
        Write-Host "[DRY-RUN] Would reconcile conflicts using strategy: $ReconcileStrategy"
        return $true
    }

    $result = Find-Duplicates -DatabasePath $DatabasePath
    $conflicts = @($result.conflicts)

    if ($conflicts.Count -eq 0) {
        Write-Host "[RECONCILE] No conflicts found. Nothing to reconcile."
        return $true
    }

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    $fusionState = Read-FusionState -FusionFilePath $FusionFilePath
    $fusionsList = @()
    if ($fusionState.fusions -ne $null) {
        foreach ($f in $fusionState.fusions) { $fusionsList += $f }
    }

    $totalRemoved = 0

    foreach ($conf in $conflicts) {
        $entries = @($conf.entries)
        if ($entries.Count -lt 2) { continue }

        # Pick winner based on strategy
        $winner = $null
        if ($ReconcileStrategy -eq "latest") {
            $sorted = @($entries | Sort-Object -Property updated_at -Descending)
            $winner = $sorted[0]
        } elseif ($ReconcileStrategy -eq "highest-access") {
            $sorted = @($entries | Sort-Object -Property access_count -Descending)
            $winner = $sorted[0]
        } else {
            # manual: most persistent scope wins, then latest
            $sorted = @($entries | Sort-Object -Property @{ Expression = {
                if ($_.scope -eq "memory") { 4 }
                elseif ($_.scope -eq "ops") { 3 }
                elseif ($_.scope -eq "project") { 2 }
                elseif ($_.scope -eq "user") { 1 }
                else { 0 }
            }; Descending = $true }, updated_at -Descending)
            $winner = $sorted[0]
        }

        # Remove all entries with this key except the winner
        $newEntries = @()
        $removed = 0
        foreach ($e in $entriesList) {
            if ($e.key -eq $conf.key -and $e.id -ne $winner.id) {
                $removed++
            } else {
                $newEntries += $e
            }
        }
        $entriesList = $newEntries

        # Accumulate access counts
        $totalAccess = [int]$winner.access_count
        foreach ($e in $entries) {
            if ($e.id -ne $winner.id) {
                $totalAccess += [int]$e.access_count
            }
        }

        # Update winner
        for ($i = 0; $i -lt $entriesList.Count; $i++) {
            if ($entriesList[$i].id -eq $winner.id) {
                $entriesList[$i].access_count = $totalAccess
                $entriesList[$i].updated_at = (Get-Date -Format "o")
                break
            }
        }

        $totalRemoved += $removed

        # Record fusion
        $fusionRecord = @{
            id = [guid]::NewGuid().ToString("N").Substring(0, 8)
            fusion_type = "reconcile"
            source_keys = @($entries | ForEach-Object { $_.id })
            result_key = $winner.id
            result_scope = $winner.scope
            strategy = $ReconcileStrategy
            created_at = (Get-Date -Format "o")
            entries_removed = $removed
        }
        $fusionsList += $fusionRecord

        # Show what was resolved
        $loserValues = @()
        foreach ($e in $entries) {
            if ($e.id -ne $winner.id) {
                $loserValues += ("{0}={1}" -f $e.scope, $e.value)
            }
        }
        Write-Host ("[RECONCILE] key={0}: winner={1} scope={2}, discarded: {3}" -f $conf.key, $winner.value, $winner.scope, ($loserValues -join ", "))
    }

    # Write back
    $store = @{ entries = $entriesList; meta = $store.meta }
    Write-JsonStore -DatabasePath $DatabasePath -Data $store

    $fusionState = @{ fusions = $fusionsList; meta = $fusionState.meta }
    Write-FusionState -FusionFilePath $FusionFilePath -Data $fusionState

    Write-Host "[RECONCILE] Total: resolved $totalRemoved conflicting entries"
    return $true
}

function Invoke-CrossRecall {
    param(
        [string]$DatabasePath,
        [string]$RecallKey
    )

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }

    # Find all entries matching key across ALL scopes
    $results = @()
    foreach ($entry in $entriesList) {
        if ($RecallKey -and $entry.key -ne $RecallKey) { continue }
        $results += $entry
    }

    # Sort: persistent scopes first, then by updated_at descending
    if ($results.Count -gt 0) {
        $results = @($results | Sort-Object -Property @{ Expression = {
            if ($_.scope_type -eq "persistent") { 0 } else { 1 }
        } }, @{ Expression = { $_.updated_at }; Descending = $true })
    }

    return ,$results
}

function Show-FusionReport {
    param([string]$DatabasePath)

    $result = Find-Duplicates -DatabasePath $DatabasePath
    $duplicates = @($result.duplicates)
    $conflicts = @($result.conflicts)

    Write-Host ""
    Write-Host "=== Scope Fusion Report ==="
    Write-Host ""

    $store = Read-JsonStore -DatabasePath $DatabasePath
    $entriesList = @()
    if ($store.entries -ne $null) {
        foreach ($e in $store.entries) { $entriesList += $e }
    }
    Write-Host ("Total entries: {0}" -f $entriesList.Count)
    Write-Host ("Duplicate groups: {0} (same value, different scopes)" -f $duplicates.Count)
    Write-Host ("Conflict groups: {0} (different values, same key)" -f $conflicts.Count)
    Write-Host ""

    if ($duplicates.Count -gt 0) {
        Write-Host "--- Duplicates (safe to merge) ---"
        foreach ($dup in $duplicates) {
            $scopeList = @($dup.entries | ForEach-Object { $_.scope }) -join ","
            Write-Host ("  key={0}  scopes=[{1}]  value=`"{2}`"" -f $dup.key, $scopeList, $dup.value)
        }
        Write-Host ""
    }

    if ($conflicts.Count -gt 0) {
        Write-Host "--- Conflicts (needs reconciliation) ---"
        foreach ($conf in $conflicts) {
            Write-Host ("  key={0}  distinct_values={1}" -f $conf.key, $conf.distinct_values)
            foreach ($e in $conf.entries) {
                Write-Host ("    scope={0}  value=`"{1}`"  access={2}  updated={3}" -f $e.scope, $e.value, $e.access_count, $e.updated_at)
            }
        }
        Write-Host ""
    }

    if ($duplicates.Count -eq 0 -and $conflicts.Count -eq 0) {
        Write-Host "No fusion opportunities found. All entries are unique."
    }

    Write-Host "=== End Report ==="
    return $true
}

function Invoke-AutoFusion {
    param(
        [string]$DatabasePath,
        [string]$FusionFilePath,
        [string]$AutoStrategy
    )

    Write-Host "[AUTOFUSION] Step 1: Detecting duplicates and conflicts..."
    $result = Find-Duplicates -DatabasePath $DatabasePath
    $dupCount = @($result.duplicates).Count
    $confCount = @($result.conflicts).Count
    Write-Host ("[AUTOFUSION] Found {0} duplicate groups, {1} conflict groups" -f $dupCount, $confCount)

    if ($dupCount -gt 0) {
        Write-Host "[AUTOFUSION] Step 2: Merging duplicates..."
        Invoke-Merge -DatabasePath $DatabasePath -FusionFilePath $FusionFilePath -MergeStrategy $AutoStrategy
    } else {
        Write-Host "[AUTOFUSION] Step 2: No duplicates to merge."
    }

    if ($confCount -gt 0) {
        Write-Host "[AUTOFUSION] Step 3: Reconciling conflicts..."
        Invoke-Reconcile -DatabasePath $DatabasePath -FusionFilePath $FusionFilePath -ReconcileStrategy $AutoStrategy
    } else {
        Write-Host "[AUTOFUSION] Step 3: No conflicts to reconcile."
    }

    Write-Host "[AUTOFUSION] Complete."
    return $true
}

# --- SelfTest ---

function Invoke-SelfTest {
    $testDir = Join-Path $env:TEMP "obsidian-scope-fusion-test"
    if (-not (Test-Path -LiteralPath $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    $testDb = Join-Path $testDir "test-store.sqlite3"
    $testFusion = Join-Path $testDir "test-fusion.json"
    $testJson = Get-JsonStorePath -DatabasePath $testDb

    # Cleanup any prior test files
    Remove-Item -LiteralPath $testJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testFusion -Force -ErrorAction SilentlyContinue

    # Init store
    $store = @{ entries = @(); meta = @{ created_at = (Get-Date -Format "o"); version = 1 } }
    Write-JsonStore -DatabasePath $testDb -Data $store
    Initialize-Fusion -FusionFilePath $testFusion | Out-Null

    $script:Apply = $true
    $pass = 0
    $fail = 0

    # Test 1: Init creates fusion state
    try {
        $state = Read-FusionState -FusionFilePath $testFusion
        if ($state.fusions.Count -eq 0 -and $state.meta.version -eq 1) {
            $pass++; Write-Host "[PASS] Init fusion state"
        } else { $fail++; Write-Host "[FAIL] Init fusion state" }
    } catch { $fail++; Write-Host "[FAIL] Init fusion state - exception: $_" }

    # Test 2: Detect finds no duplicates in empty store
    try {
        $result = Find-Duplicates -DatabasePath $testDb
        if (@($result.duplicates).Count -eq 0 -and @($result.conflicts).Count -eq 0) {
            $pass++; Write-Host "[PASS] Detect empty store"
        } else { $fail++; Write-Host "[FAIL] Detect empty store" }
    } catch { $fail++; Write-Host "[FAIL] Detect empty store - exception: $_" }

    # Test 3: Detect finds duplicates (same key+value in multiple scopes)
    try {
        $s = Read-JsonStore -DatabasePath $testDb
        $e1 = @{ id="d1"; scope="project"; key="rts-gas"; value="Use Lyra GAS"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-01T00:00:00"; access_count=3; digest="" }
        $e2 = @{ id="d2"; scope="memory"; key="rts-gas"; value="Use Lyra GAS"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-02T00:00:00"; access_count=1; digest="" }
        $s = @{ entries = @($e1, $e2); meta = $s.meta }
        Write-JsonStore -DatabasePath $testDb -Data $s

        $result = Find-Duplicates -DatabasePath $testDb
        if (@($result.duplicates).Count -eq 1 -and @($result.conflicts).Count -eq 0) {
            $pass++; Write-Host "[PASS] Detect duplicates"
        } else { $fail++; Write-Host "[FAIL] Detect duplicates - dups=$(@($result.duplicates).Count) conf=$(@($result.conflicts).Count)" }
    } catch { $fail++; Write-Host "[FAIL] Detect duplicates - exception: $_" }

    # Test 4: Detect finds conflicts (same key, different values)
    try {
        $s = Read-JsonStore -DatabasePath $testDb
        $e3 = @{ id="c1"; scope="project"; key="rts-ai"; value="Use BT"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-01T00:00:00"; access_count=1; digest="" }
        $e4 = @{ id="c2"; scope="ops"; key="rts-ai"; value="Use StateTree"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-02T00:00:00"; access_count=5; digest="" }
        $s = @{ entries = @($e1, $e2, $e3, $e4); meta = $s.meta }
        Write-JsonStore -DatabasePath $testDb -Data $s

        $result = Find-Duplicates -DatabasePath $testDb
        if (@($result.duplicates).Count -eq 1 -and @($result.conflicts).Count -eq 1) {
            $pass++; Write-Host "[PASS] Detect conflicts"
        } else { $fail++; Write-Host "[FAIL] Detect conflicts - dups=$(@($result.duplicates).Count) conf=$(@($result.conflicts).Count)" }
    } catch { $fail++; Write-Host "[FAIL] Detect conflicts - exception: $_" }

    # Test 5: Merge removes duplicates, keeps winner by latest strategy
    try {
        Invoke-Merge -DatabasePath $testDb -FusionFilePath $testFusion -MergeStrategy "latest"

        $s = Read-JsonStore -DatabasePath $testDb
        $rtsGasEntries = @($s.entries | Where-Object { $_.key -eq "rts-gas" })
        if ($rtsGasEntries.Count -eq 1 -and $rtsGasEntries[0].scope -eq "memory") {
            $pass++; Write-Host "[PASS] Merge latest"
        } else { $fail++; Write-Host "[FAIL] Merge latest - count=$($rtsGasEntries.Count) scope=$($rtsGasEntries[0].scope)" }
    } catch { $fail++; Write-Host "[FAIL] Merge latest - exception: $_" }

    # Test 6: Merge preserves accumulated access count
    try {
        $s = Read-JsonStore -DatabasePath $testDb
        $rtsGasEntry = @($s.entries | Where-Object { $_.key -eq "rts-gas" })[0]
        if ([int]$rtsGasEntry.access_count -eq 4) {
            $pass++; Write-Host "[PASS] Merge access count"
        } else { $fail++; Write-Host "[FAIL] Merge access count - got $($rtsGasEntry.access_count)" }
    } catch { $fail++; Write-Host "[FAIL] Merge access count - exception: $_" }

    # Test 7: Reconcile resolves conflicts by highest-access strategy
    try {
        Invoke-Reconcile -DatabasePath $testDb -FusionFilePath $testFusion -ReconcileStrategy "highest-access"

        $s = Read-JsonStore -DatabasePath $testDb
        $rtsAiEntries = @($s.entries | Where-Object { $_.key -eq "rts-ai" })
        if ($rtsAiEntries.Count -eq 1 -and $rtsAiEntries[0].value -eq "Use StateTree") {
            $pass++; Write-Host "[PASS] Reconcile highest-access"
        } else { $fail++; Write-Host "[FAIL] Reconcile highest-access - count=$($rtsAiEntries.Count) value=$($rtsAiEntries[0].value)" }
    } catch { $fail++; Write-Host "[FAIL] Reconcile highest-access - exception: $_" }

    # Test 8: CrossRecall finds entries across all scopes
    try {
        $s = Read-JsonStore -DatabasePath $testDb
        $e5 = @{ id="x1"; scope="session"; key="rts-gas"; value="Draft note"; scope_type="local"; created_at="2026-01-03T00:00:00"; updated_at="2026-01-03T00:00:00"; access_count=0; digest="" }
        $newEntries = @()
        foreach ($e in $s.entries) { $newEntries += $e }
        $newEntries += $e5
        $s = @{ entries = $newEntries; meta = $s.meta }
        Write-JsonStore -DatabasePath $testDb -Data $s

        $results = Invoke-CrossRecall -DatabasePath $testDb -RecallKey "rts-gas"
        if ($results.Count -eq 2) {
            $pass++; Write-Host "[PASS] CrossRecall"
        } else { $fail++; Write-Host "[FAIL] CrossRecall - count=$($results.Count)" }
    } catch { $fail++; Write-Host "[FAIL] CrossRecall - exception: $_" }

    # Test 9: FusionReport runs without error
    try {
        $r = Show-FusionReport -DatabasePath $testDb
        if ($r) { $pass++; Write-Host "[PASS] FusionReport" } else { $fail++; Write-Host "[FAIL] FusionReport" }
    } catch { $fail++; Write-Host "[FAIL] FusionReport - exception: $_" }

    # Test 10: AutoFusion runs full pipeline
    try {
        # Create another duplicate scenario
        $s = Read-JsonStore -DatabasePath $testDb
        $e6 = @{ id="a1"; scope="user"; key="theme"; value="dark"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-01T00:00:00"; access_count=1; digest="" }
        $e7 = @{ id="a2"; scope="project"; key="theme"; value="dark"; scope_type="persistent"; created_at="2026-01-01T00:00:00"; updated_at="2026-01-02T00:00:00"; access_count=2; digest="" }
        $newEntries = @()
        foreach ($e in $s.entries) { $newEntries += $e }
        $newEntries += $e6
        $newEntries += $e7
        $s = @{ entries = $newEntries; meta = $s.meta }
        Write-JsonStore -DatabasePath $testDb -Data $s

        Invoke-AutoFusion -DatabasePath $testDb -FusionFilePath $testFusion -AutoStrategy "latest"

        $s = Read-JsonStore -DatabasePath $testDb
        $themeEntries = @($s.entries | Where-Object { $_.key -eq "theme" })
        if ($themeEntries.Count -eq 1) {
            $pass++; Write-Host "[PASS] AutoFusion"
        } else { $fail++; Write-Host "[FAIL] AutoFusion - count=$($themeEntries.Count)" }
    } catch { $fail++; Write-Host "[FAIL] AutoFusion - exception: $_" }

    # Cleanup
    Remove-Item -LiteralPath $testJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testFusion -Force -ErrorAction SilentlyContinue

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
    $result = Initialize-Fusion -FusionFilePath $FusionPath
    if (-not $result) { exit 1 }
    exit 0
}

if ($Detect) {
    $result = Find-Duplicates -DatabasePath $DbPath
    $dupCount = @($result.duplicates).Count
    $confCount = @($result.conflicts).Count
    Write-Host "[DETECT] Found $dupCount duplicate groups, $confCount conflict groups"

    if ($dupCount -gt 0) {
        Write-Host ""
        Write-Host "--- Duplicates ---"
        foreach ($dup in @($result.duplicates)) {
            $scopeList = @($dup.entries | ForEach-Object { $_.scope }) -join ","
            Write-Host ("  key={0}  scopes=[{1}]  value=`"{2}`"" -f $dup.key, $scopeList, $dup.value)
        }
    }

    if ($confCount -gt 0) {
        Write-Host ""
        Write-Host "--- Conflicts ---"
        foreach ($conf in @($result.conflicts)) {
            Write-Host ("  key={0}  distinct_values={1}" -f $conf.key, $conf.distinct_values)
            foreach ($e in @($conf.entries)) {
                Write-Host ("    scope={0}  value=`"{1}`"" -f $e.scope, $e.value)
            }
        }
    }
    exit 0
}

if ($Merge) {
    $result = Invoke-Merge -DatabasePath $DbPath -FusionFilePath $FusionPath -MergeStrategy $Strategy
    if (-not $result) { exit 1 }
    exit 0
}

if ($Reconcile) {
    $result = Invoke-Reconcile -DatabasePath $DbPath -FusionFilePath $FusionPath -ReconcileStrategy $Strategy
    if (-not $result) { exit 1 }
    exit 0
}

if ($CrossRecall) {
    if (-not $Key) {
        Write-Host "ERROR: -CrossRecall requires -Key" -ForegroundColor Red
        exit 1
    }
    $results = Invoke-CrossRecall -DatabasePath $DbPath -RecallKey $Key
    if ($results.Count -gt 0) {
        Write-Host "[CROSSRECALL] Found $($results.Count) entries for key=${Key}:"
        foreach ($r in $results) {
            Write-Host ("  [{0}] {1} = {2}  (access={3})" -f $r.scope, $r.key, $r.value, $r.access_count)
        }
    } else {
        Write-Host "[CROSSRECALL] No entries found for key=${Key}"
    }
    exit 0
}

if ($FusionReport) {
    $result = Show-FusionReport -DatabasePath $DbPath
    if (-not $result) { exit 1 }
    exit 0
}

if ($AutoFusion) {
    $result = Invoke-AutoFusion -DatabasePath $DbPath -FusionFilePath $FusionPath -AutoStrategy $Strategy
    if (-not $result) { exit 1 }
    exit 0
}

Write-Host "ERROR: No action specified. Use -Init, -Detect, -Merge, -Reconcile, -CrossRecall, -FusionReport, -AutoFusion, or -SelfTest" -ForegroundColor Red
exit 1
