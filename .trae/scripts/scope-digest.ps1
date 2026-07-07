# scope-digest.ps1 -- Nightly Digest for Scope Recall (Jinli)
#
# Implements the nightly digest pattern from Scope Recall:
#   - Consolidate: group persistent scope entries by key-prefix, merge values into summaries
#   - Desensitize: redact sensitive patterns (API keys, tokens, file paths, emails) from digest values
#   - Archive: move consolidated originals to archive section (auditability, not deletion)
#   - DigestReport: show what was consolidated, desensitized, archived
#   - AutoDigest: one-pass pipeline -- detect bloat -> consolidate -> desensitize -> archive -> report
#
# Design principles:
#   1. SQLite/JSON truth source stays auditable -- originals are archived, never deleted
#   2. Digest entries are marked with digest=true and linked to archived originals
#   3. Protected entries (from scope-decay) are never digested
#   4. Desensitization replaces sensitive patterns with [REDACTED:type] markers
#
# Usage:
#   .\scope-digest.ps1 -Init
#   .\scope-digest.ps1 -Digest -Scope project -Apply
#   .\scope-digest.ps1 -DigestReport
#   .\scope-digest.ps1 -AutoDigest -Apply
#   .\scope-digest.ps1 -Desensitize -Text "my-api-key-sk-1234567890"
#   .\scope-digest.ps1 -Archive -Scope project -Key rts-old-ref -Apply
#   .\scope-digest.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Digest,
    [switch]$DigestReport,
    [switch]$AutoDigest,
    [switch]$Desensitize,
    [switch]$Archive,
    [switch]$Restore,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general", "")]
    [string]$Scope = "",

    [string]$Key = "",
    [string]$Value = "",
    [string]$Text = "",
    [int]$Threshold = 10,
    [int]$ConsolidateCount = 5,
    [string]$DbPath = "",
    [string]$DecayDbPath = ""
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$persistentScopes = @("user", "project", "ops", "memory")

if (-not $DbPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.json"
}

if (-not $DecayDbPath) {
    $decayPath = $DbPath -replace 'scope-store\.json$', 'scope-decay.json'
    $DecayDbPath = $decayPath
}

# --- JSON I/O (PS5.1 compatible) ---

function Read-DigestStore {
    param([string]$DatabasePath)

    if (-not (Test-Path -LiteralPath $DatabasePath)) {
        return @{ entries = @(); archive = @(); digests = @(); meta = @{ created_at = ""; version = 1; last_digest = "" } }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($DatabasePath, [System.Text.Encoding]::UTF8)
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

        $archiveArray = @()
        if ($parsed.archive -ne $null) {
            foreach ($a in $parsed.archive) {
                $ht = @{
                    id = $a.id
                    scope = $a.scope
                    key = $a.key
                    value = $a.value
                    scope_type = $a.scope_type
                    created_at = $a.created_at
                    updated_at = $a.updated_at
                    access_count = [int]$a.access_count
                    digest = $a.digest
                    archived_at = $a.archived_at
                    digest_id = $a.digest_id
                }
                $archiveArray += $ht
            }
        }

        $digestsArray = @()
        if ($parsed.digests -ne $null) {
            foreach ($d in $parsed.digests) {
                $ht = @{
                    id = $d.id
                    scope = $d.scope
                    key_prefix = $d.key_prefix
                    summary = $d.summary
                    source_count = [int]$d.source_count
                    source_ids = $d.source_ids
                    created_at = $d.created_at
                    desensitized = [bool]$d.desensitized
                }
                $digestsArray += $ht
            }
        }

        $metaHt = @{
            created_at = $parsed.meta.created_at
            version = [int]$parsed.meta.version
            last_digest = $parsed.meta.last_digest
        }

        return @{ entries = $entriesArray; archive = $archiveArray; digests = $digestsArray; meta = $metaHt }
    } catch {
        return @{ entries = @(); archive = @(); digests = @(); meta = @{ created_at = ""; version = 1; last_digest = "" } }
    }
}

function Write-DigestStore {
    param(
        [string]$DatabasePath,
        $Data
    )

    $dir = Split-Path -Parent $DatabasePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($DatabasePath, $json, $utf8NoBom)
}

# --- Decay Store Reader (for protected entries) ---

function Read-DecayProtected {
    param([string]$DecayDbPath)

    if (-not (Test-Path -LiteralPath $DecayDbPath)) {
        return @{}
    }

    try {
        $raw = [System.IO.File]::ReadAllText($DecayDbPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $protected = @{}
        if ($parsed.protected -ne $null) {
            foreach ($prop in $parsed.protected.PSObject.Properties) {
                $protected[$prop.Name] = $prop.Value
            }
        }
        return $protected
    } catch {
        return @{}
    }
}

# --- Desensitization ---

function Invoke-DesensitizeText {
    param([string]$Text)

    $result = $Text

    # API keys: sk- followed by 20+ alphanumeric chars
    $result = [regex]::Replace($result, 'sk-[A-Za-z0-9]{20,}', '[REDACTED:api-key]')

    # Bearer tokens
    $result = [regex]::Replace($result, 'Bearer\s+[A-Za-z0-9\-_\.]{20,}', '[REDACTED:bearer-token]')

    # Generic tokens: token= or api_key= followed by value
    $result = [regex]::Replace($result, '(?:token|api_key|apikey|secret|password)\s*[=:]\s*[A-Za-z0-9\-_]{16,}', '[REDACTED:secret]')

    # File paths with drive letters (Windows)
    $result = [regex]::Replace($result, '[A-Z]:\\[A-Za-z0-9_\-\.\s\\]+', '[REDACTED:path]')

    # Email addresses
    $result = [regex]::Replace($result, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[REDACTED:email]')

    # IP addresses (non-loopback)
    $result = [regex]::Replace($result, '\b(?!127\.0\.0\.1|0\.0\.0\.0)(?:\d{1,3}\.){3}\d{1,3}\b', '[REDACTED:ip]')

    return $result
}

# --- Key Prefix Extraction ---

function Get-KeyPrefix {
    param([string]$Key)

    # Split on hyphens, take first two segments as prefix group
    # e.g. "rts-gas-setup" -> "rts-gas", "task-rt1-config" -> "task-rt1"
    $parts = $Key -split '-'
    if ($parts.Count -ge 2) {
        return ($parts[0] + '-' + $parts[1])
    }
    return $Key
}

# --- Core Functions ---

function Initialize-Digest {
    param([string]$DatabasePath)

    $store = @{
        entries = @()
        archive = @()
        digests = @()
        meta = @{
            created_at = (Get-Date -Format "o")
            version = 1
            last_digest = ""
        }
    }
    Write-DigestStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[INIT] Digest store initialized at: $DatabasePath"
    return $true
}

function Invoke-DigestScope {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [int]$BloatThreshold = 10,
        [int]$ConsolidateTopN = 5,
        [string[]]$ProtectedKeys = @(),
        [bool]$ShouldApply = $false
    )

    $store = Read-DigestStore -DatabasePath $DatabasePath
    $scopeEntries = @()
    foreach ($e in $store.entries) {
        if ($e.scope -eq $ScopeName) {
            $scopeEntries += $e
        }
    }

    if ($scopeEntries.Count -le $BloatThreshold) {
        Write-Host "[DIGEST] Scope=$ScopeName has $($scopeEntries.Count) entries (threshold=$BloatThreshold). No digestion needed."
        return @{ digested = 0; scope = $ScopeName; reason = "below-threshold" }
    }

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would digest $($scopeEntries.Count) entries in scope=$ScopeName (threshold=$BloatThreshold)"
        # PS5.1: Sort-Object -Property name does NOT work on hashtables; must use expression
        $sorted = @($scopeEntries | Sort-Object -Property { $_.updated_at })
        $toDigest = @($sorted | Select-Object -First $ConsolidateTopN)
        Write-Host "  Would consolidate top $ConsolidateTopN oldest entries:"
        foreach ($e in $toDigest) {
            $pk = "$ScopeName/$($e.key)"
            $protectedTag = ""
            if ($ProtectedKeys -contains $pk) { $protectedTag = " [PROTECTED]" }
            Write-Host ("    {0} = {1}{2}" -f $e.key, $e.value, $protectedTag)
        }
        return @{ digested = 0; scope = $ScopeName; reason = "dry-run" }
    }

    # Sort by updated_at ascending (oldest first)
    # PS5.1: Sort-Object -Property name does NOT work on hashtables; must use expression
    $sorted = @($scopeEntries | Sort-Object -Property { $_.updated_at })
    $toDigest = @($sorted | Select-Object -First $ConsolidateTopN)

    # Filter out protected entries
    $digestable = @()
    $skippedProtected = 0
    foreach ($e in $toDigest) {
        $pk = "$ScopeName/$($e.key)"
        if ($ProtectedKeys -contains $pk) {
            $skippedProtected++
            continue
        }
        $digestable += $e
    }

    if ($digestable.Count -eq 0) {
        Write-Host "[DIGEST] Scope=$ScopeName all candidate entries are protected. Skipping."
        return @{ digested = 0; scope = $ScopeName; reason = "all-protected" }
    }

    # Group by key prefix
    $prefixGroups = @{}
    foreach ($e in $digestable) {
        $prefix = Get-KeyPrefix -Key $e.key
        if (-not $prefixGroups.ContainsKey($prefix)) {
            $prefixGroups[$prefix] = @()
        }
        $prefixGroups[$prefix] += $e
    }

    $digestId = "digest-" + (Get-Date -Format "yyyyMMddHHmmss") + "-" + (Get-Random -Maximum 9999).ToString("D4")
    $digestTime = (Get-Date -Format "o")
    $totalDigested = 0
    $totalDesensitized = 0
    $newDigests = @()

    foreach ($prefix in $prefixGroups.Keys) {
        $group = @($prefixGroups[$prefix])
        if ($group.Count -eq 0) { continue }

        # Build summary from group values
        $summaryParts = @()
        foreach ($e in $group) {
            $summaryParts += "$($e.key): $($e.value)"
        }
        $rawSummary = $summaryParts -join " | "

        # Desensitize the summary
        $cleanSummary = Invoke-DesensitizeText -Text $rawSummary
        $wasDesensitized = ($cleanSummary -ne $rawSummary)
        if ($wasDesensitized) { $totalDesensitized++ }

        $sourceIds = @()
        foreach ($e in $group) { $sourceIds += $e.id }

        $digestEntry = @{
            id = $digestId + "-" + $prefix
            scope = $ScopeName
            key_prefix = $prefix
            summary = $cleanSummary
            source_count = $group.Count
            source_ids = $sourceIds
            created_at = $digestTime
            desensitized = $wasDesensitized
        }
        $newDigests += $digestEntry
        $totalDigested += $group.Count

        Write-Host "[DIGEST] Consolidated $ScopeName/$prefix : $($group.Count) entries -> 1 summary"
        if ($wasDesensitized) {
            Write-Host "  [DESENSITIZE] Redacted sensitive patterns from summary"
        }
    }

    # Move originals to archive
    $digestableIds = @()
    foreach ($e in $digestable) { $digestableIds += $e.id }

    $newArchive = @()
    foreach ($e in $digestable) {
        $archived = @{
            id = $e.id
            scope = $e.scope
            key = $e.key
            value = $e.value
            scope_type = $e.scope_type
            created_at = $e.created_at
            updated_at = $e.updated_at
            access_count = $e.access_count
            digest = $e.digest
            archived_at = $digestTime
            digest_id = $digestId
        }
        $newArchive += $archived
    }

    # Remove digested entries from active list
    $remainingEntries = @()
    foreach ($e in $store.entries) {
        if ($digestableIds -notcontains $e.id) {
            $remainingEntries += $e
        }
    }

    # Write back
    $store.entries = $remainingEntries
    $store.archive = @($store.archive + $newArchive)
    $store.digests = @($store.digests + $newDigests)
    $store.meta.last_digest = $digestTime

    Write-DigestStore -DatabasePath $DatabasePath -Data $store

    Write-Host "[DIGEST] Scope=${ScopeName}: $totalDigested entries consolidated, $totalDesensitized summaries desensitized, $($newArchive.Count) originals archived"

    return @{
        digested = $totalDigested
        scope = $ScopeName
        digest_id = $digestId
        desensitized = $totalDesensitized
        archived = $newArchive.Count
        skipped_protected = $skippedProtected
    }
}

function Invoke-DigestReport {
    param([string]$DatabasePath)

    $store = Read-DigestStore -DatabasePath $DatabasePath

    Write-Host ""
    Write-Host "=== Scope Digest Report ==="
    Write-Host ""

    # Entries by scope
    $scopeCounts = @{}
    foreach ($e in $store.entries) {
        if (-not $scopeCounts.ContainsKey($e.scope)) {
            $scopeCounts[$e.scope] = 0
        }
        $scopeCounts[$e.scope]++
    }

    Write-Host "--- Active Entries ---"
    foreach ($scope in ($scopeCounts.Keys | Sort-Object)) {
        $count = $scopeCounts[$scope]
        $thresholdTag = ""
        if ($persistentScopes -contains $scope -and $count -gt 10) {
            $thresholdTag = " [BLOATED]"
        }
        Write-Host ("  {0}: {1} entries{2}" -f $scope, $count, $thresholdTag)
    }

    Write-Host ""
    Write-Host "--- Digest Summaries ---"
    if ($store.digests.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($d in $store.digests) {
            $desensitizeTag = ""
            if ($d.desensitized) { $desensitizeTag = " [DESENSITIZED]" }
            $preview = $d.summary
            if ($preview.Length -gt 80) { $preview = $preview.Substring(0, 77) + "..." }
            Write-Host ("  [{0}] {1}/{2} sources={3}{4}" -f $d.id, $d.scope, $d.key_prefix, $d.source_count, $desensitizeTag)
            Write-Host ("    {0}" -f $preview)
        }
    }

    Write-Host ""
    Write-Host "--- Archive ---"
    if ($store.archive.Count -eq 0) {
        Write-Host "  (empty)"
    } else {
        Write-Host ("  {0} archived entries" -f $store.archive.Count)
        $archivedScopes = @{}
        foreach ($a in $store.archive) {
            if (-not $archivedScopes.ContainsKey($a.scope)) {
                $archivedScopes[$a.scope] = 0
            }
            $archivedScopes[$a.scope]++
        }
        foreach ($scope in ($archivedScopes.Keys | Sort-Object)) {
            Write-Host ("    {0}: {1} archived" -f $scope, $archivedScopes[$scope])
        }
    }

    Write-Host ""
    Write-Host "Total: $($store.entries.Count) active, $($store.digests.Count) digests, $($store.archive.Count) archived"
    if ($store.meta.last_digest) {
        Write-Host "Last digest: $($store.meta.last_digest)"
    } else {
        Write-Host "Last digest: (never)"
    }
    Write-Host "=== End Digest Report ==="

    return $true
}

function Invoke-AutoDigest {
    param(
        [string]$DatabasePath,
        [string]$DecayDbPath,
        [int]$BloatThreshold = 10,
        [int]$ConsolidateTopN = 5,
        [bool]$ShouldApply = $false
    )

    Write-Host "[AUTODIGEST] Step 1: Loading protected entries from decay store..."
    $protected = Read-DecayProtected -DecayDbPath $DecayDbPath
    $protectedKeys = @()
    foreach ($k in $protected.Keys) { $protectedKeys += $k }
    Write-Host "[AUTODIGEST] Found $($protectedKeys.Count) protected entries"

    Write-Host "[AUTODIGEST] Step 2: Scanning persistent scopes for bloat..."
    $store = Read-DigestStore -DatabasePath $DatabasePath

    $scopeCounts = @{}
    foreach ($e in $store.entries) {
        if ($persistentScopes -contains $e.scope) {
            if (-not $scopeCounts.ContainsKey($e.scope)) {
                $scopeCounts[$e.scope] = 0
            }
            $scopeCounts[$e.scope]++
        }
    }

    $bloatedScopes = @()
    foreach ($scope in $persistentScopes) {
        $count = 0
        if ($scopeCounts.ContainsKey($scope)) { $count = $scopeCounts[$scope] }
        if ($count -gt $BloatThreshold) {
            $bloatedScopes += $scope
            Write-Host "[AUTODIGEST] Scope=$scope is bloated ($count entries > threshold $BloatThreshold)"
        }
    }

    if ($bloatedScopes.Count -eq 0) {
        Write-Host "[AUTODIGEST] No bloated scopes found. All within threshold."
        return @{ scopes_digested = 0; total_digested = 0; reason = "no-bloat" }
    }

    Write-Host "[AUTODIGEST] Step 3: Digesting bloated scopes..."
    $totalDigested = 0
    $results = @()
    foreach ($scope in $bloatedScopes) {
        $result = Invoke-DigestScope `
            -DatabasePath $DatabasePath `
            -ScopeName $scope `
            -BloatThreshold $BloatThreshold `
            -ConsolidateTopN $ConsolidateTopN `
            -ProtectedKeys $protectedKeys `
            -ShouldApply $ShouldApply
        $results += $result
        if ($result.digested -gt 0) { $totalDigested += $result.digested }
    }

    Write-Host "[AUTODIGEST] Step 4: Generating report..."
    if ($ShouldApply) {
        Invoke-DigestReport -DatabasePath $DatabasePath | Out-Null
    }

    Write-Host "[AUTODIGEST] Complete."
    return @{
        scopes_digested = $bloatedScopes.Count
        total_digested = $totalDigested
        results = $results
    }
}

function Invoke-ArchiveEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [bool]$ShouldApply = $false
    )

    $store = Read-DigestStore -DatabasePath $DatabasePath
    $found = $null
    foreach ($e in $store.entries) {
        if ($e.scope -eq $ScopeName -and $e.key -eq $EntryKey) {
            $found = $e
            break
        }
    }

    if (-not $found) {
        Write-Host "[ARCHIVE] Entry not found: $ScopeName/$EntryKey"
        return $false
    }

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would archive: $ScopeName/$EntryKey = $($found.value)"
        return $true
    }

    $archiveTime = (Get-Date -Format "o")
    $archived = @{
        id = $found.id
        scope = $found.scope
        key = $found.key
        value = $found.value
        scope_type = $found.scope_type
        created_at = $found.created_at
        updated_at = $found.updated_at
        access_count = $found.access_count
        digest = $found.digest
        archived_at = $archiveTime
        digest_id = "manual"
    }

    $store.archive += $archived
    $remaining = @()
    foreach ($e in $store.entries) {
        if ($e.id -ne $found.id) { $remaining += $e }
    }
    $store.entries = $remaining

    Write-DigestStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[ARCHIVE] Archived: $ScopeName/$EntryKey"
    return $true
}

function Invoke-RestoreEntry {
    param(
        [string]$DatabasePath,
        [string]$ScopeName,
        [string]$EntryKey,
        [bool]$ShouldApply = $false
    )

    $store = Read-DigestStore -DatabasePath $DatabasePath
    $found = $null
    foreach ($a in $store.archive) {
        if ($a.scope -eq $ScopeName -and $a.key -eq $EntryKey) {
            $found = $a
            break
        }
    }

    if (-not $found) {
        Write-Host "[RESTORE] Archived entry not found: $ScopeName/$EntryKey"
        return $false
    }

    if (-not $ShouldApply) {
        Write-Host "[DRY-RUN] Would restore: $ScopeName/$EntryKey from archive"
        return $true
    }

    $restored = @{
        id = $found.id
        scope = $found.scope
        key = $found.key
        value = $found.value
        scope_type = $found.scope_type
        created_at = $found.created_at
        updated_at = $found.updated_at
        access_count = $found.access_count
        digest = $found.digest
    }

    $store.entries += $restored
    $remainingArchive = @()
    foreach ($a in $store.archive) {
        if ($a.id -ne $found.id) { $remainingArchive += $a }
    }
    $store.archive = $remainingArchive

    Write-DigestStore -DatabasePath $DatabasePath -Data $store
    Write-Host "[RESTORE] Restored: $ScopeName/$EntryKey from archive"
    return $true
}

# --- SelfTest ---

function Invoke-SelfTest {
    $script:passCount = 0
    $script:failCount = 0

    function Assert-Test {
        param([string]$Name, [bool]$Condition)
        if ($Condition) {
            Write-Host "  [PASS] $Name"
            $script:passCount++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $script:failCount++
        }
    }

    $testDir = Join-Path $env:TEMP "scope-digest-selftest-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    $testDb = Join-Path $testDir "scope-store.json"
    $testDecayDb = Join-Path $testDir "scope-decay.json"

    Write-Host "=== scope-digest.ps1 SelfTest ==="
    Write-Host ""

    # Test 1: Initialize
    Write-Host "--- Test 1: Initialize ---"
    $initResult = Initialize-Digest -DatabasePath $testDb
    Assert-Test "Init returns true" $initResult
    $store = Read-DigestStore -DatabasePath $testDb
    Assert-Test "Init creates file" (Test-Path -LiteralPath $testDb)
    Assert-Test "Init has empty entries" ($store.entries.Count -eq 0)
    Assert-Test "Init has empty archive" ($store.archive.Count -eq 0)
    Assert-Test "Init has empty digests" ($store.digests.Count -eq 0)
    Assert-Test "Init has version 1" ($store.meta.version -eq 1)

    # Test 2: Desensitize
    Write-Host "--- Test 2: Desensitize ---"
    $desens1 = Invoke-DesensitizeText -Text "my key is sk-1234567890abcdefghijklmnopqrst"
    Assert-Test "API key redacted" ($desens1 -match '\[REDACTED:api-key\]')

    $desens2 = Invoke-DesensitizeText -Text "token=abcdef1234567890abcdef1234567890"
    Assert-Test "Token redacted" ($desens2 -match '\[REDACTED:secret\]')

    $desens3 = Invoke-DesensitizeText -Text "path is C:\Users\secret\data\file.txt"
    Assert-Test "Path redacted" ($desens3 -match '\[REDACTED:path\]')

    $desens4 = Invoke-DesensitizeText -Text "contact: alice@example.com"
    Assert-Test "Email redacted" ($desens4 -match '\[REDACTED:email\]')

    $desens5 = Invoke-DesensitizeText -Text "server at 192.168.1.100"
    Assert-Test "IP redacted" ($desens5 -match '\[REDACTED:ip\]')

    $desens6 = Invoke-DesensitizeText -Text "Bearer abcdef1234567890abcdef1234567890"
    Assert-Test "Bearer token redacted" ($desens6 -match '\[REDACTED:bearer-token\]')

    $desens7 = Invoke-DesensitizeText -Text "no secrets here just normal text"
    Assert-Test "Clean text unchanged" ($desens7 -eq "no secrets here just normal text")

    # Test 3: Key Prefix Extraction
    Write-Host "--- Test 3: Key Prefix Extraction ---"
    $prefix1 = Get-KeyPrefix -Key "rts-gas-setup"
    Assert-Test "rts-gas-setup -> rts-gas" ($prefix1 -eq "rts-gas")

    $prefix2 = Get-KeyPrefix -Key "task-rt1-config"
    Assert-Test "task-rt1-config -> task-rt1" ($prefix2 -eq "task-rt1")

    $prefix3 = Get-KeyPrefix -Key "simple"
    Assert-Test "simple -> simple" ($prefix3 -eq "simple")

    # Test 4: Digest Below Threshold
    Write-Host "--- Test 4: Digest Below Threshold ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @(
        @{ id = "e1"; scope = "project"; key = "rts-gas-01"; value = "Use Lyra GAS"; scope_type = "persistent"; created_at = "2026-01-01T00:00:00"; updated_at = "2026-01-01T00:00:00"; access_count = 1; digest = "" }
        @{ id = "e2"; scope = "project"; key = "rts-gas-02"; value = "GAS Setup"; scope_type = "persistent"; created_at = "2026-01-02T00:00:00"; updated_at = "2026-01-02T00:00:00"; access_count = 0; digest = "" }
    )
    Write-DigestStore -DatabasePath $testDb -Data $store
    $digestResult = Invoke-DigestScope -DatabasePath $testDb -ScopeName "project" -BloatThreshold 10 -ConsolidateTopN 5 -ProtectedKeys @() -ShouldApply $true
    Assert-Test "Below threshold: 0 digested" ($digestResult.digested -eq 0)
    Assert-Test "Below threshold reason" ($digestResult.reason -eq "below-threshold")

    # Test 5: Digest With Bloat
    Write-Host "--- Test 5: Digest With Bloat ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $entries = @()
    for ($i = 1; $i -le 12; $i++) {
        $dateStr = "2026-01-{0:D2}T00:00:00" -f $i
        $entries += @{
            id = "e$($i+2)"
            scope = "project"
            key = "rts-gas-{0:D2}" -f $i
            value = "GAS note $i"
            scope_type = "persistent"
            created_at = $dateStr
            updated_at = $dateStr
            access_count = $i
            digest = ""
        }
    }
    $store.entries = $entries
    Write-DigestStore -DatabasePath $testDb -Data $store
    $digestResult = Invoke-DigestScope -DatabasePath $testDb -ScopeName "project" -BloatThreshold 10 -ConsolidateTopN 5 -ProtectedKeys @() -ShouldApply $true
    Assert-Test "Bloat: 5 digested" ($digestResult.digested -eq 5)
    Assert-Test "Bloat: 5 archived" ($digestResult.archived -eq 5)

    $storeAfter = Read-DigestStore -DatabasePath $testDb
    Assert-Test "Active entries reduced" ($storeAfter.entries.Count -eq 7)
    Assert-Test "Archive has entries" ($storeAfter.archive.Count -eq 5)
    Assert-Test "Digests created" ($storeAfter.digests.Count -ge 1)
    Assert-Test "Last digest timestamp set" ($storeAfter.meta.last_digest -ne "")

    # Test 6: Digest With Protected
    Write-Host "--- Test 6: Digest With Protected ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @()
    $store.archive = @()
    $store.digests = @()
    for ($i = 1; $i -le 12; $i++) {
        $dateStr = "2026-01-{0:D2}T00:00:00" -f $i
        $store.entries += @{
            id = "p$i"
            scope = "project"
            key = "rts-ai-{0:D2}" -f $i
            value = "AI note $i"
            scope_type = "persistent"
            created_at = $dateStr
            updated_at = $dateStr
            access_count = $i
            digest = ""
        }
    }
    Write-DigestStore -DatabasePath $testDb -Data $store
    $protectedKeys = @("project/rts-ai-01", "project/rts-ai-02", "project/rts-ai-03")
    $digestResult = Invoke-DigestScope -DatabasePath $testDb -ScopeName "project" -BloatThreshold 10 -ConsolidateTopN 5 -ProtectedKeys $protectedKeys -ShouldApply $true
    Assert-Test "Protected: 2 digested (5-3 protected)" ($digestResult.digested -eq 2)
    Assert-Test "Protected: 3 skipped" ($digestResult.skipped_protected -eq 3)

    # Test 7: Desensitization in Digest
    Write-Host "--- Test 7: Desensitization in Digest ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @()
    $store.archive = @()
    $store.digests = @()
    for ($i = 1; $i -le 12; $i++) {
        $dateStr = "2026-01-{0:D2}T00:00:00" -f $i
        $store.entries += @{
            id = "s$i"
            scope = "project"
            key = "cfg-api-{0:D2}" -f $i
            value = "key sk-1234567890abcdefghijklmnopqrst path C:\secret\config"
            scope_type = "persistent"
            created_at = $dateStr
            updated_at = $dateStr
            access_count = $i
            digest = ""
        }
    }
    Write-DigestStore -DatabasePath $testDb -Data $store
    $digestResult = Invoke-DigestScope -DatabasePath $testDb -ScopeName "project" -BloatThreshold 10 -ConsolidateTopN 5 -ProtectedKeys @() -ShouldApply $true
    $storeAfter = Read-DigestStore -DatabasePath $testDb
    $hasDesensitized = $false
    foreach ($d in $storeAfter.digests) {
        if ($d.desensitized) { $hasDesensitized = $true; break }
    }
    Assert-Test "Digest marked desensitized" $hasDesensitized

    $summaryClean = $true
    foreach ($d in $storeAfter.digests) {
        if ($d.summary -match 'sk-[A-Za-z0-9]{20,}') { $summaryClean = $false; break }
    }
    Assert-Test "No raw API keys in summaries" $summaryClean

    # Test 8: Archive and Restore
    Write-Host "--- Test 8: Archive and Restore ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @(
        @{ id = "ar1"; scope = "ops"; key = "deploy-config"; value = "Deploy config"; scope_type = "persistent"; created_at = "2026-01-01T00:00:00"; updated_at = "2026-01-01T00:00:00"; access_count = 0; digest = "" }
    )
    $store.archive = @()
    $store.digests = @()
    Write-DigestStore -DatabasePath $testDb -Data $store

    $archiveResult = Invoke-ArchiveEntry -DatabasePath $testDb -ScopeName "ops" -EntryKey "deploy-config" -ShouldApply $true
    Assert-Test "Archive succeeds" $archiveResult
    $storeAfter = Read-DigestStore -DatabasePath $testDb
    Assert-Test "Entry moved to archive" ($storeAfter.entries.Count -eq 0)
    Assert-Test "Archive has 1 entry" ($storeAfter.archive.Count -eq 1)

    $restoreResult = Invoke-RestoreEntry -DatabasePath $testDb -ScopeName "ops" -EntryKey "deploy-config" -ShouldApply $true
    Assert-Test "Restore succeeds" $restoreResult
    $storeFinal = Read-DigestStore -DatabasePath $testDb
    Assert-Test "Entry restored to active" ($storeFinal.entries.Count -eq 1)
    Assert-Test "Archive empty after restore" ($storeFinal.archive.Count -eq 0)

    # Test 9: DigestReport
    Write-Host "--- Test 9: DigestReport ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @(
        @{ id = "r1"; scope = "project"; key = "rts-config"; value = "RTS Config"; scope_type = "persistent"; created_at = "2026-01-01T00:00:00"; updated_at = "2026-01-01T00:00:00"; access_count = 1; digest = "" }
    )
    $store.digests = @(
        @{ id = "digest-test"; scope = "project"; key_prefix = "rts-config"; summary = "Test summary"; source_count = 3; source_ids = @("r1","r2","r3"); created_at = "2026-01-01T00:00:00"; desensitized = $false }
    )
    $store.archive = @(
        @{ id = "r2"; scope = "project"; key = "rts-old"; value = "Old value"; scope_type = "persistent"; created_at = "2026-01-01T00:00:00"; updated_at = "2026-01-01T00:00:00"; access_count = 0; digest = ""; archived_at = "2026-01-02T00:00:00"; digest_id = "digest-test" }
    )
    Write-DigestStore -DatabasePath $testDb -Data $store
    $reportResult = Invoke-DigestReport -DatabasePath $testDb
    Assert-Test "DigestReport completes" $reportResult

    # Test 10: AutoDigest
    Write-Host "--- Test 10: AutoDigest ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @()
    $store.archive = @()
    $store.digests = @()
    for ($i = 1; $i -le 12; $i++) {
        $dateStr = "2026-01-{0:D2}T00:00:00" -f $i
        $store.entries += @{
            id = "ad$i"
            scope = "project"
            key = "auto-test-{0:D2}" -f $i
            value = "Auto test $i"
            scope_type = "persistent"
            created_at = $dateStr
            updated_at = $dateStr
            access_count = $i
            digest = ""
        }
    }
    Write-DigestStore -DatabasePath $testDb -Data $store

    # Create decay store with a protected entry
    $decayStore = @{
        protected = @{ "project/auto-test-01" = @{ protected_at = "2026-01-01T00:00:00"; reason = "manual" } }
        meta = @{ created_at = "2026-01-01T00:00:00"; version = 1; last_decay = "" }
    }
    $decayJson = ($decayStore | ConvertTo-Json -Depth 10)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($testDecayDb, $decayJson, $utf8NoBom)

    $autoResult = Invoke-AutoDigest -DatabasePath $testDb -DecayDbPath $testDecayDb -BloatThreshold 10 -ConsolidateTopN 5 -ShouldApply $true
    Assert-Test "AutoDigest detects bloat" ($autoResult.scopes_digested -ge 1)
    Assert-Test "AutoDigest digests entries" ($autoResult.total_digested -gt 0)

    $storeAfter = Read-DigestStore -DatabasePath $testDb
    Assert-Test "AutoDigest created digests" ($storeAfter.digests.Count -ge 1)
    Assert-Test "AutoDigest archived originals" ($storeAfter.archive.Count -gt 0)
    $protectedStillThere = @($storeAfter.entries | Where-Object { $_.key -eq "auto-test-01" })
    Assert-Test "AutoDigest respected protected" ($protectedStillThere.Count -eq 1)

    # Test 11: Dry Run
    Write-Host "--- Test 11: Dry Run ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @()
    $store.archive = @()
    $store.digests = @()
    for ($i = 1; $i -le 12; $i++) {
        $dateStr = "2026-02-{0:D2}T00:00:00" -f $i
        $store.entries += @{
            id = "dr$i"
            scope = "memory"
            key = "dry-run-{0:D2}" -f $i
            value = "Dry run $i"
            scope_type = "persistent"
            created_at = $dateStr
            updated_at = $dateStr
            access_count = $i
            digest = ""
        }
    }
    Write-DigestStore -DatabasePath $testDb -Data $store
    $dryResult = Invoke-DigestScope -DatabasePath $testDb -ScopeName "memory" -BloatThreshold 10 -ConsolidateTopN 5 -ProtectedKeys @() -ShouldApply $false
    Assert-Test "Dry run: 0 digested" ($dryResult.digested -eq 0)
    Assert-Test "Dry run reason" ($dryResult.reason -eq "dry-run")
    $storeUnchanged = Read-DigestStore -DatabasePath $testDb
    Assert-Test "Dry run: entries unchanged" ($storeUnchanged.entries.Count -eq 12)
    Assert-Test "Dry run: no archive" ($storeUnchanged.archive.Count -eq 0)

    # Test 12: Non-persistent scope ignored
    Write-Host "--- Test 12: Non-persistent scope ---"
    $store = Read-DigestStore -DatabasePath $testDb
    $store.entries = @(
        @{ id = "n1"; scope = "session"; key = "temp-01"; value = "Temp"; scope_type = "local"; created_at = "2026-01-01T00:00:00"; updated_at = "2026-01-01T00:00:00"; access_count = 0; digest = "" }
    )
    Write-DigestStore -DatabasePath $testDb -Data $store
    $autoResult = Invoke-AutoDigest -DatabasePath $testDb -DecayDbPath $testDecayDb -BloatThreshold 10 -ConsolidateTopN 5 -ShouldApply $true
    Assert-Test "Session scope not digested" ($autoResult.scopes_digested -eq 0)

    # Cleanup
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "=== SelfTest Results: $script:passCount passed, $script:failCount failed ==="

    if ($script:failCount -gt 0) { return $false } else { return $true }
}

# --- Main ---

if ($Init) {
    $result = Initialize-Digest -DatabasePath $DbPath
    if (-not $result) { Write-Host "ERROR: Init failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Desensitize) {
    if (-not $Text) { Write-Host "ERROR: -Text is required for Desensitize" -ForegroundColor Red; exit 1 }
    $cleaned = Invoke-DesensitizeText -Text $Text
    Write-Host $cleaned
    exit 0
}

if ($Digest) {
    if (-not $Scope) { Write-Host "ERROR: -Scope is required for Digest" -ForegroundColor Red; exit 1 }
    $protected = Read-DecayProtected -DecayDbPath $DecayDbPath
    $protectedKeys = @()
    foreach ($k in $protected.Keys) { $protectedKeys += $k }
    $result = Invoke-DigestScope -DatabasePath $DbPath -ScopeName $Scope -BloatThreshold $Threshold -ConsolidateTopN $ConsolidateCount -ProtectedKeys $protectedKeys -ShouldApply $Apply
    if ($result -eq $false) { Write-Host "ERROR: Digest failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($DigestReport) {
    $result = Invoke-DigestReport -DatabasePath $DbPath
    if (-not $result) { Write-Host "ERROR: Report failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($AutoDigest) {
    $result = Invoke-AutoDigest -DatabasePath $DbPath -DecayDbPath $DecayDbPath -BloatThreshold $Threshold -ConsolidateTopN $ConsolidateCount -ShouldApply $Apply
    if ($result -eq $false) { Write-Host "ERROR: AutoDigest failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Archive) {
    if (-not $Scope -or -not $Key) { Write-Host "ERROR: -Scope and -Key are required for Archive" -ForegroundColor Red; exit 1 }
    $result = Invoke-ArchiveEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Archive failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($Restore) {
    if (-not $Scope -or -not $Key) { Write-Host "ERROR: -Scope and -Key are required for Restore" -ForegroundColor Red; exit 1 }
    $result = Invoke-RestoreEntry -DatabasePath $DbPath -ScopeName $Scope -EntryKey $Key -ShouldApply $Apply
    if (-not $result) { Write-Host "ERROR: Restore failed" -ForegroundColor Red; exit 1 }
    exit 0
}

if ($SelfTest) {
    $result = Invoke-SelfTest
    if (-not $result) { exit 1 } else { exit 0 }
}

Write-Host "ERROR: No action specified. Use -Init, -Digest, -DigestReport, -AutoDigest, -Desensitize, -Archive, -Restore, or -SelfTest" -ForegroundColor Red
exit 1
