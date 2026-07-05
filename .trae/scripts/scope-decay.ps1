# scope-decay.ps1 -- Scope-Aware Memory Decay and Garbage Collection
#
# Eighth layer of the Scope Recall pattern: memory lifecycle management.
# Addresses the "temporary context pollution" problem identified in gene e7f6845e:
#   - Persistent scopes accumulate entries indefinitely with no aging mechanism
#   - Stale entries with low access counts pollute recall results
#   - No TTL-based expiration exists for any scope type
#
# Implements:
#   - TTL policies per scope type (session=1h, general=4h, project=30d, ops=7d, user=90d, memory=365d)
#   - Access-based decay scoring: low-access + old = high decay priority
#   - Scope-aware GC: expire stale entries, compress low-value ones, protect high-value
#   - DecayReport: show which entries are at risk, which are protected
#   - Protect/Unprotect: manual override to preserve important entries
#   - AutoDecay: one-pass TTL check + decay scoring + GC pipeline
#
# Usage:
#   .\scope-decay.ps1 -Init
#   .\scope-decay.ps1 -DecayReport -Scope project
#   .\scope-decay.ps1 -Expire -Scope session -Apply
#   .\scope-decay.ps1 -Compress -Scope project -Apply
#   .\scope-decay.ps1 -Protect -Scope project -Key rts-gas-ref -Apply
#   .\scope-decay.ps1 -Unprotect -Scope project -Key rts-gas-ref -Apply
#   .\scope-decay.ps1 -AutoDecay -Apply
#   .\scope-decay.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$DecayReport,
    [switch]$Expire,
    [switch]$Compress,
    [switch]$Protect,
    [switch]$Unprotect,
    [switch]$AutoDecay,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",

    [string]$Key = "",
    [int]$OlderThanDays = 0,
    [double]$DecayThreshold = 0.7,
    [string]$DbPath = ""
)

$ErrorActionPreference = "Stop"

# --- TTL Policy (hours) ---
# Local scopes expire fast; persistent scopes have generous TTLs.
$ttlPolicy = @{
    session = 1
    general = 4
    ops     = 168    # 7 days
    project = 720    # 30 days
    user    = 2160   # 90 days
    memory  = 8760   # 365 days
}

# --- Constants ---
$script:decayVersion = 1

if (-not $DbPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.sqlite3"
}

# --- JSON helpers (PS5.1 safe) ---
function Get-DecayStorePath {
    param([string]$DatabasePath)
    return $DatabasePath -replace '\.sqlite3$', '-decay.json'
}

function Read-DecayStore {
    param([string]$DatabasePath)
    $jsonPath = Get-DecayStorePath -DatabasePath $DatabasePath
    if (-not (Test-Path -LiteralPath $jsonPath)) { return $null }
    try {
        $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $protected = @{}
        if ($parsed.protected -ne $null) {
            foreach ($prop in $parsed.protected.PSObject.Properties) {
                $protected[$prop.Name] = $prop.Value
            }
        }
        return @{
            protected  = $protected
            meta       = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
            last_decay = $parsed.last_decay
        }
    } catch { return $null }
}

function Write-DecayStore {
    param([string]$DatabasePath, $Data)
    $jsonPath = Get-DecayStorePath -DatabasePath $DatabasePath
    $dir = Split-Path -Parent $jsonPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Data.meta.version = $script:decayVersion
    $json = $Data | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($jsonPath, $json, (New-Object System.Text.UTF8Encoding $true))
}

# --- Scope Store Reader (reuse scope-store format) ---
function Get-JsonStorePath {
    param([string]$DatabasePath)
    return $DatabasePath -replace '\.sqlite3$', '.json'
}

function Read-ScopeStore {
    param([string]$DatabasePath)
    $jsonPath = Get-JsonStorePath -DatabasePath $DatabasePath
    if (-not (Test-Path -LiteralPath $jsonPath)) { return $null }
    try {
        $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $entriesArray = @()
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                $ht = @{
                    id           = $e.id
                    scope        = $e.scope
                    key          = $e.key
                    value        = $e.value
                    type         = $e.type
                    created_at   = $e.created_at
                    updated_at   = $e.updated_at
                    access_count = [int]$e.access_count
                    digest       = $e.digest
                }
                $entriesArray += $ht
            }
        }
        return @{ entries = $entriesArray; meta = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version } }
    } catch { return $null }
}

function Write-ScopeStore {
    param([string]$DatabasePath, $Data)
    $jsonPath = Get-JsonStorePath -DatabasePath $DatabasePath
    $dir = Split-Path -Parent $jsonPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = $Data | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($jsonPath, $json, (New-Object System.Text.UTF8Encoding $true))
}

# --- Core Functions ---

function Initialize-Decay {
    param([string]$DatabasePath)
    $data = @{
        protected  = @{}
        meta       = @{ created_at = (Get-Date -Format "o"); version = 1 }
        last_decay = ""
    }
    Write-DecayStore -DatabasePath $DatabasePath -Data $data
    Write-Host "[INIT] Scope decay state initialized at: $(Get-DecayStorePath -DatabasePath $DatabasePath)"
    return $true
}

function Get-DecayScore {
    param(
        [hashtable]$Entry,
        [double]$Threshold = 0.7
    )
    # Decay score: 0 = fresh/valuable, 1 = completely stale
    # Factors: age relative to TTL, access count (inverse)
    $ttlHours = $ttlPolicy[$Entry.scope]
    if (-not $ttlHours) { $ttlHours = 720 }

    $updatedAt = $Entry.updated_at
    if (-not $updatedAt) { $updatedAt = $Entry.created_at }
    if (-not $updatedAt) { return 0.0 }

    try { $updated = [datetime]$updatedAt } catch { return 0.0 }
    $now = Get-Date
    $ageHours = ($now - $updated).TotalHours
    if ($ageHours -lt 0) { $ageHours = 0 }

    # Age factor: 0 at creation, 1 at TTL, >1 past TTL
    $ageFactor = $ageHours / $ttlHours

    # Access factor: high access = low decay
    $accessFactor = 1.0 / (1.0 + [double]$Entry.access_count)

    # Combined: age drives decay, access resists it
    $score = ($ageFactor * 0.7) + ($accessFactor * 0.3)
    if ($score -gt 1.0) { $score = 1.0 }
    if ($score -lt 0.0) { $score = 0.0 }
    return [math]::Round($score, 4)
}

function Get-IsExpired {
    param([hashtable]$Entry)
    $ttlHours = $ttlPolicy[$Entry.scope]
    if (-not $ttlHours) { return $false }
    $updatedAt = $Entry.updated_at
    if (-not $updatedAt) { $updatedAt = $Entry.created_at }
    if (-not $updatedAt) { return $false }
    try { $updated = [datetime]$updatedAt } catch { return $false }
    $now = Get-Date
    $ageHours = ($now - $updated).TotalHours
    return ($ageHours -gt $ttlHours)
}

function Invoke-DecayReport {
    param(
        [string]$DatabasePath,
        [string]$ScopeName = ""
    )
    $store = Read-ScopeStore -DatabasePath $DatabasePath
    if (-not $store) { Write-Host "[ERROR] Scope store not found"; return $false }

    $decayState = Read-DecayStore -DatabasePath $DatabasePath
    $protectedKeys = @{}
    if ($decayState -and $decayState.protected) {
        foreach ($k in $decayState.protected.Keys) { $protectedKeys[$k] = $true }
    }

    $entries = @($store.entries)
    if ($ScopeName) {
        $entries = @($entries | Where-Object { $_.scope -eq $ScopeName })
    }

    Write-Host "=== Scope Decay Report ==="
    Write-Host ""

    $expiredCount = 0
    $atRiskCount  = 0
    $healthyCount = 0
    $protectedCount = 0

    foreach ($e in $entries) {
        $pk = ("{0}/{1}" -f $e.scope, $e.key)
        $isProtected = $protectedKeys.ContainsKey($pk)
        $isExpired = Get-IsExpired -Entry $e
        $decayScore = Get-DecayScore -Entry $e

        $status = "HEALTHY"
        if ($isProtected) { $status = "PROTECTED"; $protectedCount++ }
        elseif ($isExpired) { $status = "EXPIRED"; $expiredCount++ }
        elseif ($decayScore -ge 0.7) { $status = "AT-RISK"; $atRiskCount++ }
        else { $healthyCount++ }

        $ttlH = $ttlPolicy[$e.scope]
        if (-not $ttlH) { $ttlH = 720 }
        Write-Host ("  [{0}] scope={1} key={2} decay={3} access={4} ttl={5}h" -f $status, $e.scope, $e.key, $decayScore, $e.access_count, $ttlH)
    }

    Write-Host ""
    Write-Host ("  Total: {0} entries" -f $entries.Count)
    Write-Host ("  Healthy: {0} | At-risk: {1} | Expired: {2} | Protected: {3}" -f $healthyCount, $atRiskCount, $expiredCount, $protectedCount)
    Write-Host "=== End Decay Report ==="
    return $true
}

function Invoke-Expire {
    param(
        [string]$DatabasePath,
        [string]$ScopeName = "",
        [int]$OlderDays = 0,
        [bool]$ShouldApply = $false
    )
    $store = Read-ScopeStore -DatabasePath $DatabasePath
    if (-not $store) { Write-Host "[ERROR] Scope store not found"; return $false }

    $decayState = Read-DecayStore -DatabasePath $DatabasePath
    $protectedKeys = @{}
    if ($decayState -and $decayState.protected) {
        foreach ($k in $decayState.protected.Keys) { $protectedKeys[$k] = $true }
    }

    $entries = @($store.entries)
    if ($ScopeName) {
        $entries = @($entries | Where-Object { $_.scope -eq $ScopeName })
    }

    $toRemove = @()
    foreach ($e in $entries) {
        $pk = ("{0}/{1}" -f $e.scope, $e.key)
        if ($protectedKeys.ContainsKey($pk)) { continue }
        $isExpired = Get-IsExpired -Entry $e
        if ($OlderDays -gt 0) {
            $updatedAt = $e.updated_at
            if (-not $updatedAt) { $updatedAt = $e.created_at }
            if (-not $updatedAt) { continue }
            try { $updated = [datetime]$updatedAt } catch { continue }
            $ageDays = ((Get-Date) - $updated).TotalDays
            if ($ageDays -lt $OlderDays) { continue }
        }
        if ($isExpired -or ($OlderDays -gt 0)) { $toRemove += $e }
    }

    if ($toRemove.Count -eq 0) { Write-Host "[EXPIRE] No expired entries found"; return $true }

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would expire $($toRemove.Count) entries:"
        foreach ($e in $toRemove) {
            Write-Host ("  [{0}] {1}/{2}" -f $e.scope, $e.key, $e.value)
        }
        return $true
    }

    $remaining = @($store.entries)
    foreach ($r in $toRemove) {
        $remaining = @($remaining | Where-Object { $_.id -ne $r.id })
    }
    $store.entries = $remaining
    Write-ScopeStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[EXPIRE] Removed $($toRemove.Count) expired entries"
    return $true
}

function Invoke-Compress {
    param(
        [string]$DatabasePath,
        [string]$ScopeName = "",
        [double]$Threshold = 0.7,
        [bool]$ShouldApply = $false
    )
    $store = Read-ScopeStore -DatabasePath $DatabasePath
    if (-not $store) { Write-Host "[ERROR] Scope store not found"; return $false }

    $decayState = Read-DecayStore -DatabasePath $DatabasePath
    $protectedKeys = @{}
    if ($decayState -and $decayState.protected) {
        foreach ($k in $decayState.protected.Keys) { $protectedKeys[$k] = $true }
    }

    $entries = @($store.entries)
    if ($ScopeName) {
        $entries = @($entries | Where-Object { $_.scope -eq $ScopeName })
    }

    # Find high-decay-score entries (not expired, not protected)
    $toCompress = @()
    foreach ($e in $entries) {
        $pk = ("{0}/{1}" -f $e.scope, $e.key)
        if ($protectedKeys.ContainsKey($pk)) { continue }
        $isExpired = Get-IsExpired -Entry $e
        if ($isExpired) { continue }
        $score = Get-DecayScore -Entry $e -Threshold $Threshold
        if ($score -ge $Threshold) { $toCompress += $e }
    }

    if ($toCompress.Count -eq 0) { Write-Host "[COMPRESS] No compressible entries found"; return $true }

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would compress $($toCompress.Count) high-decay entries:"
        foreach ($e in $toCompress) {
            $score = Get-DecayScore -Entry $e -Threshold $Threshold
            Write-Host ("  [{0}] {1}/{2} decay={3}" -f $e.scope, $e.key, $e.value, $score)
        }
        return $true
    }

    # Compress: summarize values into a digest entry, remove originals
    $compressValues = @()
    foreach ($e in $toCompress) {
        $compressValues += ("[{0}/{1}] {2}" -f $e.scope, $e.key, $e.value)
    }

    $compressScope = if ($ScopeName) { $ScopeName } else { "memory" }
    $digestEntry = @{
        id           = "dcompress-$(Get-Date -Format 'yyyyMMddHHmmss')"
        scope        = $compressScope
        key          = "decay-digest-$(Get-Date -Format 'yyyy-MM-dd')"
        value        = ($compressValues -join "; ")
        type         = "persistent"
        created_at   = (Get-Date -Format "o")
        updated_at   = (Get-Date -Format "o")
        access_count = 0
        digest       = "decay-compressed"
    }

    $remaining = @($store.entries)
    foreach ($c in $toCompress) {
        $remaining = @($remaining | Where-Object { $_.id -ne $c.id })
    }
    $remaining += $digestEntry
    $store.entries = $remaining
    Write-ScopeStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[COMPRESS] Compressed $($toCompress.Count) entries into digest"
    return $true
}

function Invoke-ProtectEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [bool]$ShouldApply = $false
    )
    $pk = ("{0}/{1}" -f $ScopeName, $EntryKey)

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would protect entry: $pk"
        return $true
    }

    $decayState = Read-DecayStore -DatabasePath $DatabasePath
    if (-not $decayState) {
        $decayState = @{
            protected  = @{}
            meta       = @{ created_at = (Get-Date -Format "o"); version = 1 }
            last_decay = ""
        }
    }
    $decayState.protected[$pk] = @{ protected_at = (Get-Date -Format "o"); reason = "manual" }
    Write-DecayStore -DatabasePath $DatabasePath -Data $decayState
    Write-Host "[PROTECT] Protected: $pk"
    return $true
}

function Invoke-UnprotectEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [bool]$ShouldApply = $false
    )
    $pk = ("{0}/{1}" -f $ScopeName, $EntryKey)

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would unprotect entry: $pk"
        return $true
    }

    $decayState = Read-DecayStore -DatabasePath $DatabasePath
    if (-not $decayState) { Write-Host "[ERROR] Decay state not initialized"; return $false }
    if (-not $decayState.protected.ContainsKey($pk)) {
        Write-Host "[UNPROTECT] Entry not protected: $pk"
        return $true
    }
    $decayState.protected.Remove($pk)
    Write-DecayStore -DatabasePath $DatabasePath -Data $decayState
    Write-Host "[UNPROTECT] Unprotected: $pk"
    return $true
}

function Invoke-AutoDecay {
    param(
        [string]$DatabasePath,
        [bool]$ShouldApply = $false
    )
    Write-Host "[AUTODECAY] Step 1: Checking TTL expiration..."
    $expireResult = Invoke-Expire -DatabasePath $DatabasePath -ScopeName "" -OlderDays 0 -ShouldApply $ShouldApply

    Write-Host "[AUTODECAY] Step 2: Checking decay scores for compression..."
    $compressResult = Invoke-Compress -DatabasePath $DatabasePath -ScopeName "" -Threshold 0.8 -ShouldApply $ShouldApply

    if ($ShouldApply) {
        $decayState = Read-DecayStore -DatabasePath $DatabasePath
        if (-not $decayState) { $decayState = @{ protected = @{}; meta = @{ created_at = (Get-Date -Format "o"); version = 1 }; last_decay = "" } }
        $decayState.last_decay = (Get-Date -Format "o")
        Write-DecayStore -DatabasePath $DatabasePath -Data $decayState
    }

    Write-Host "[AUTODECAY] Complete."
    return $true
}

# --- SelfTest ---
function Invoke-SelfTest {
    $script:pass = 0
    $script:fail = 0

    function Assert-Test {
        param([string]$Label, [bool]$Condition)
        if ($Condition) { $script:pass++; Write-Host "[PASS] $Label" }
        else { $script:fail++; Write-Host "[FAIL] $Label" }
    }

    $testDir = Join-Path $env:TEMP "scope-decay-selftest-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    $testDb = Join-Path $testDir "scope-store.sqlite3"

    Write-Host "=== scope-decay.ps1 SelfTest ==="
    Write-Host ""

    # Test 1: Initialize
    Write-Host "--- Test 1: Initialize ---"
    $init = Initialize-Decay -DatabasePath $testDb
    Assert-Test "Init creates file" (Test-Path -LiteralPath (Get-DecayStorePath -DatabasePath $testDb))
    $decayState = Read-DecayStore -DatabasePath $testDb
    Assert-Test "Init has empty protected" ($decayState.protected.Count -eq 0)

    # Test 2: DecayScore fresh entry
    Write-Host "--- Test 2: DecayScore ---"
    $freshEntry = @{ scope = "project"; key = "rts-gas"; value = "Use Lyra GAS"; updated_at = (Get-Date -Format "o"); access_count = 5; created_at = (Get-Date -Format "o") }
    $score = Get-DecayScore -Entry $freshEntry
    Write-Host "  Fresh entry decay score: $score"
    Assert-Test "Fresh entry has low decay" ($score -lt 0.5)

    # Test 3: DecayScore stale entry (simulated old date)
    Write-Host "--- Test 3: DecayScore stale ---"
    $oldDate = (Get-Date).AddDays(-60).ToString("o")
    $staleEntry = @{ scope = "project"; key = "old-ref"; value = "Old value"; updated_at = $oldDate; access_count = 0; created_at = $oldDate }
    $staleScore = Get-DecayScore -Entry $staleEntry
    Write-Host "  Stale entry decay score: $staleScore"
    Assert-Test "Stale entry has high decay" ($staleScore -ge 0.5)

    # Test 4: IsExpired
    Write-Host "--- Test 4: IsExpired ---"
    Assert-Test "Fresh entry not expired" (-not (Get-IsExpired -Entry $freshEntry))
    $veryOldDate = (Get-Date).AddDays(-100).ToString("o")
    $expiredEntry = @{ scope = "project"; key = "expired-ref"; value = "Expired"; updated_at = $veryOldDate; access_count = 0; created_at = $veryOldDate }
    Assert-Test "Old project entry is expired" (Get-IsExpired -Entry $expiredEntry)

    # Test 5: Expire (dry-run)
    Write-Host "--- Test 5: Expire ---"
    # Create a scope store with expired entries
    $storeData = @{
        entries = @(
            @{ id = "e1"; scope = "session"; key = "temp-old"; value = "Old temp"; type = "local"; created_at = (Get-Date).AddDays(-1).ToString("o"); updated_at = (Get-Date).AddDays(-1).ToString("o"); access_count = 0; digest = "" },
            @{ id = "e2"; scope = "project"; key = "rts-current"; value = "Current ref"; type = "persistent"; created_at = (Get-Date -Format "o"); updated_at = (Get-Date -Format "o"); access_count = 3; digest = "" }
        )
        meta = @{ created_at = (Get-Date -Format "o"); version = 1 }
    }
    Write-ScopeStore -DatabasePath $testDb -Data $storeData
    $dryResult = Invoke-Expire -DatabasePath $testDb -ScopeName "" -OlderDays 0 -ShouldApply $false
    Assert-Test "Expire dry-run completes" $dryResult

    # Test 6: Expire (apply)
    Write-Host "--- Test 6: Expire apply ---"
    $applyResult = Invoke-Expire -DatabasePath $testDb -ScopeName "" -OlderDays 0 -ShouldApply $true
    Assert-Test "Expire apply completes" $applyResult
    $afterStore = Read-ScopeStore -DatabasePath $testDb
    $sessionEntries = @($afterStore.entries | Where-Object { $_.scope -eq "session" })
    Assert-Test "Session entries expired" ($sessionEntries.Count -eq 0)
    $projectEntries = @($afterStore.entries | Where-Object { $_.scope -eq "project" })
    Assert-Test "Project entry preserved" ($projectEntries.Count -eq 1)

    # Test 7: Protect
    Write-Host "--- Test 7: Protect ---"
    $protectResult = Invoke-ProtectEntry -DatabasePath $testDb -ScopeName "project" -EntryKey "rts-current" -ShouldApply $true
    Assert-Test "Protect succeeds" $protectResult
    $afterProtect = Read-DecayStore -DatabasePath $testDb
    Assert-Test "Protected entry recorded" ($afterProtect.protected.ContainsKey("project/rts-current"))

    # Test 8: Protected entry survives expire
    Write-Host "--- Test 8: Protected survives expire ---"
    # Add an old project entry that WOULD expire, but is protected
    $protectedOldDate = (Get-Date).AddDays(-100).ToString("o")
    $storeData2 = @{
        entries = @(
            @{ id = "e3"; scope = "project"; key = "rts-current"; value = "Current ref"; type = "persistent"; created_at = (Get-Date -Format "o"); updated_at = (Get-Date -Format "o"); access_count = 3; digest = "" },
            @{ id = "e4"; scope = "project"; key = "protected-old"; value = "Protected but old"; type = "persistent"; created_at = $protectedOldDate; updated_at = $protectedOldDate; access_count = 0; digest = "" }
        )
        meta = @{ created_at = (Get-Date -Format "o"); version = 1 }
    }
    Write-ScopeStore -DatabasePath $testDb -Data $storeData2
    # Protect the old one
    Invoke-ProtectEntry -DatabasePath $testDb -ScopeName "project" -EntryKey "protected-old" -ShouldApply $true | Out-Null
    Invoke-Expire -DatabasePath $testDb -ScopeName "project" -OlderDays 0 -ShouldApply $true | Out-Null
    $afterExpire = Read-ScopeStore -DatabasePath $testDb
    $protectedStillThere = @($afterExpire.entries | Where-Object { $_.key -eq "protected-old" })
    Assert-Test "Protected entry survives expire" ($protectedStillThere.Count -eq 1)

    # Test 9: Unprotect
    Write-Host "--- Test 9: Unprotect ---"
    $unprotectResult = Invoke-UnprotectEntry -DatabasePath $testDb -ScopeName "project" -EntryKey "protected-old" -ShouldApply $true
    Assert-Test "Unprotect succeeds" $unprotectResult
    $afterUnprotect = Read-DecayStore -DatabasePath $testDb
    Assert-Test "Entry no longer protected" (-not $afterUnprotect.protected.ContainsKey("project/protected-old"))

    # Test 10: DecayReport
    Write-Host "--- Test 10: DecayReport ---"
    $reportResult = Invoke-DecayReport -DatabasePath $testDb -ScopeName "project"
    Assert-Test "DecayReport completes" $reportResult

    Write-Host ""
    Write-Host "=== SelfTest Results: $script:pass passed, $script:fail failed ==="

    # Cleanup
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue

    if ($script:fail -gt 0) { return $false }
    return $true
}

# --- Parameter Dispatch ---

if ($Init) {
    $result = Initialize-Decay -DatabasePath $DbPath
    if (-not $result) { Write-Host "ERROR: Init failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($DecayReport) {
    $result = Invoke-DecayReport -DatabasePath $DbPath -ScopeName $Scope
    if (-not $result) { Write-Host "ERROR: DecayReport failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Expire) {
    $result = Invoke-Expire -DatabasePath $DbPath -ScopeName $Scope -OlderDays $OlderThanDays -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Expire failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Compress) {
    $result = Invoke-Compress -DatabasePath $DbPath -ScopeName $Scope -Threshold $DecayThreshold -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Compress failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Protect) {
    if (-not $Scope -or -not $Key) { Write-Host "ERROR: -Scope and -Key are required for Protect" -ForegroundColor Red; exit 1 }
    $result = Invoke-ProtectEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Protect failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Unprotect) {
    if (-not $Scope -or -not $Key) { Write-Host "ERROR: -Scope and -Key are required for Unprotect" -ForegroundColor Red; exit 1 }
    $result = Invoke-UnprotectEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Unprotect failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($AutoDecay) {
    $result = Invoke-AutoDecay -DatabasePath $DbPath -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: AutoDecay failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($SelfTest) {
    $result = Invoke-SelfTest
    if (-not $result) { exit 1 }
    exit 0
}

Write-Host "ERROR: No action specified. Use -Init, -DecayReport, -Expire, -Compress, -Protect, -Unprotect, -AutoDecay, or -SelfTest" -ForegroundColor Red
exit 1
