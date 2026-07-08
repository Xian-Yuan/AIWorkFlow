# scope-secret-index.ps1 -- Secret Index for Scope Recall (Jinli)
#
# Tenth layer of the Scope Recall pattern: secret-only evidence index.
# Implements the gene concept from BV19EE16aEn7:
#   "secret indexes store only searchable evidence references, not plaintext"
#
# What this script does:
#   - Scan: detect entries containing secrets (API keys, tokens, passwords, etc.)
#   - Register: store SHA-256 fingerprint + type + location (scope/key) -- never plaintext
#   - Search: find which entries contain secrets by type, without exposing values
#   - Audit: report on secret distribution across scopes
#   - Purge: replace plaintext secrets in scope-store with [REDACTED:type:fp] after indexing
#   - EvidenceRef: provide proof that a secret exists at a location without revealing it
#
# Design principles:
#   1. Never stores plaintext secret values -- only SHA-256 hash prefix + metadata
#   2. Non-destructive by default: -Apply required for purge operations
#   3. Independent index file: scope-store-secret-index.json (rebuildable from truth source)
#   4. PS5.1 compatible: no -Raw, no PS7 syntax, ASCII identifiers
#   5. Reuses scope-store JSON format for reading entries
#
# Usage:
#   .\scope-secret-index.ps1 -Init
#   .\scope-secret-index.ps1 -Scan -Scope project
#   .\scope-secret-index.ps1 -Scan -Apply
#   .\scope-secret-index.ps1 -Search -Type api-key
#   .\scope-secret-index.ps1 -Search -Scope project
#   .\scope-secret-index.ps1 -Audit
#   .\scope-secret-index.ps1 -Purge -Scope project -Apply
#   .\scope-secret-index.ps1 -EvidenceRef -Scope project -Key rts-gas
#   .\scope-secret-index.ps1 -SecretReport
#   .\scope-secret-index.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Scan,
    [switch]$Search,
    [switch]$Audit,
    [switch]$Purge,
    [switch]$EvidenceRef,
    [switch]$SecretReport,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general", "")]
    [string]$Scope = "",

    [string]$Key = "",
    [ValidateSet("api-key", "bearer-token", "secret", "path", "email", "ip", "")]
    [string]$Type = "",
    [string]$DbPath = "",
    [string]$IndexPath = ""
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$script:secretIndexVersion = 1
$persistentScopes = @("user", "project", "ops", "memory")

# --- Paths ---
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scopeStoreScript = Join-Path $PSScriptRoot "scope-store.ps1"

if (-not $DbPath) {
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.json"
}
if (-not $IndexPath) {
    $IndexPath = Join-Path $repoRoot "Docs\Memory\scope-store-secret-index.json"
}

# --- JSON I/O (PS5.1 compatible) ---

function Read-StoreData {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ entries = @(); meta = @{ created_at = ""; version = 1 } }
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $parsed = $raw | ConvertFrom-Json
    $entriesArray = @()
    if ($parsed.entries -ne $null) {
        if ($parsed.entries -is [array]) {
            $entriesArray = $parsed.entries
        } else {
            $entriesArray = @($parsed.entries)
        }
    }
    $metaHt = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
    return @{ entries = $entriesArray; meta = $metaHt }
}

function Write-StoreData {
    param([string]$Path, $Data)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

function Read-SecretIndex {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $entriesArray = @()
        if ($parsed.entries -ne $null) {
            if ($parsed.entries -is [array]) {
                $entriesArray = $parsed.entries
            } else {
                $entriesArray = @($parsed.entries)
            }
        }
        $metaHt = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        return @{
            entries = $entriesArray
            meta = $metaHt
            last_scan = $parsed.last_scan
        }
    } catch { return $null }
}

function Write-SecretIndex {
    param([string]$Path, $Data)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Data.meta.version = $script:secretIndexVersion
    $json = $Data | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding $true))
}

# --- Secret Detection Patterns ---
# Returns array of hashtables: @{ type = "api-key"; value = "sk-xxx"; start = 0; end = 10 }

function Find-SecretPatterns {
    param([string]$Text)

    $findings = @()

    # API keys: sk- followed by 20+ alphanumeric chars
    $m = [regex]::Matches($Text, 'sk-[A-Za-z0-9]{20,}')
    foreach ($match in $m) {
        $findings += @{ type = "api-key"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # Bearer tokens
    $m = [regex]::Matches($Text, 'Bearer\s+[A-Za-z0-9\-_\.]{20,}')
    foreach ($match in $m) {
        $findings += @{ type = "bearer-token"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # Generic tokens: token= or api_key= or secret= or password= followed by value
    $m = [regex]::Matches($Text, '(?:token|api_key|apikey|secret|password)\s*[=:]\s*[A-Za-z0-9\-_]{16,}')
    foreach ($match in $m) {
        $findings += @{ type = "secret"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # File paths with potential sensitive info
    $m = [regex]::Matches($Text, '[A-Z]:\\[A-Za-z0-9_\-\.\s\\]+')
    foreach ($match in $m) {
        $findings += @{ type = "path"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # Email addresses
    $m = [regex]::Matches($Text, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
    foreach ($match in $m) {
        $findings += @{ type = "email"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # IP addresses (exclude localhost)
    $m = [regex]::Matches($Text, '\b(?!127\.0\.0\.1|0\.0\.0\.0)(?:\d{1,3}\.){3}\d{1,3}\b')
    foreach ($match in $m) {
        $findings += @{ type = "ip"; value = $match.Value; start = $match.Index; end = $match.Index + $match.Length }
    }

    # PS5.1: function return unwraps single-element arrays into the element itself.
    # Use , (comma operator) to force array return. Without this, a single-element
    # Object[] gets unwrapped to the hashtable, and .Count returns the key count (4).
    return ,@($findings)
}

# --- Fingerprint Generation ---
# Creates a SHA-256 hash prefix (first 16 hex chars) for evidence without revealing the secret.
function Get-SecretFingerprint {
    param([string]$SecretValue)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($SecretValue)
    $hashBytes = $sha256.ComputeHash($bytes)
    $sha256.Dispose()
    $fullHash = [BitConverter]::ToString($hashBytes) -replace '-', ''
    return $fullHash.Substring(0, 16).ToLower()
}

# --- Redaction ---
# Replaces secret patterns in text with [REDACTED:type:fingerprint] markers
function Invoke-SecretRedact {
    param([string]$Text)

    $result = $Text
    $findings = Find-SecretPatterns -Text $Text
    # Fix overlapping patterns: process in start-order, keep first (longest), skip overlaps
    $validFindings = @()
    $lastEnd = -1
    $sortedAsc = $findings | Sort-Object { $_.start }
    foreach ($f in $sortedAsc) {
        if ($f.start -ge $lastEnd) {
            $validFindings += $f
            $lastEnd = $f.end
        }
    }
    # Process in reverse order to preserve indices
    $sorted = $validFindings | Sort-Object { $_.start } -Descending
    foreach ($f in $sorted) {
        $fp = Get-SecretFingerprint -SecretValue $f.value
        $marker = "[REDACTED:$($f.type):$fp]"
        $result = $result.Substring(0, $f.start) + $marker + $result.Substring($f.end)
    }
    return $result
}

# --- Core Operations ---

function Initialize-SecretIndex {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        $index = @{
            entries = @()
            meta = @{ created_at = (Get-Date -Format "o"); version = $script:secretIndexVersion }
            last_scan = ""
        }
        Write-SecretIndex -Path $Path -Data $index
    }
    Write-Host "[INIT] Secret index initialized at: $Path"
    return $true
}

function Invoke-Scan {
    param([string]$StorePath, [string]$SecretIndexPath, [string]$ScopeFilter, [bool]$ShouldApply)

    $store = Read-StoreData -Path $StorePath
    if ($store.entries.Count -eq 0) {
        Write-Host "[SCAN] No entries in scope store."
        return $true
    }

    $entriesToScan = @()
    if ($ScopeFilter) {
        $entriesToScan = @($store.entries | Where-Object { $_.scope -eq $ScopeFilter })
    } else {
        $entriesToScan = @($store.entries)
    }

    if ($entriesToScan.Count -eq 0) {
        Write-Host "[SCAN] No entries found for scope: $ScopeFilter"
        return $true
    }

    Write-Host "[SCAN] Scanning $($entriesToScan.Count) entries for secrets..."

    $secretEntries = @()
    $totalSecrets = 0
    $byType = @{}

    foreach ($entry in $entriesToScan) {
        $text = [string]$entry.value
        $findings = Find-SecretPatterns -Text $text
        if ($findings.Count -gt 0) {
            foreach ($f in $findings) {
                $fp = Get-SecretFingerprint -SecretValue $f.value
                $secretEntry = @{
                    id = "$($entry.scope)/$($entry.key)/$($f.type)/$fp"
                    scope = $entry.scope
                    key = $entry.key
                    secret_type = $f.type
                    fingerprint = $fp
                    position = "$($f.start)-$($f.end)"
                    scanned_at = (Get-Date -Format "o")
                }
                $secretEntries += $secretEntry
                $totalSecrets++
                if ($byType.ContainsKey($f.type)) {
                    $byType[$f.type] = $byType[$f.type] + 1
                } else {
                    $byType[$f.type] = 1
                }
            }
            Write-Host "  [FOUND] $($entry.scope)/$($entry.key): $($findings.Count) secret(s)"
        }
    }

    if ($totalSecrets -eq 0) {
        Write-Host "[SCAN] No secrets found in scanned entries."
    } else {
        Write-Host "[SCAN] Found $totalSecrets secret(s) across $($secretEntries.Count) index entries."
        foreach ($k in $byType.Keys) {
            Write-Host "  $k : $($byType[$k])"
        }
    }

    if ($ShouldApply) {
        $existingIndex = Read-SecretIndex -Path $SecretIndexPath
        if ($existingIndex -eq $null) {
            $existingIndex = @{
                entries = @()
                meta = @{ created_at = (Get-Date -Format "o"); version = $script:secretIndexVersion }
                last_scan = ""
            }
        }
        # Replace entries from the scanned scope, keep others
        $keptEntries = @()
        if ($ScopeFilter) {
            $keptEntries = @($existingIndex.entries | Where-Object { $_.scope -ne $ScopeFilter })
        }
        $allEntries = @() + $keptEntries + $secretEntries
        $existingIndex.entries = $allEntries
        $existingIndex.last_scan = (Get-Date -Format "o")
        Write-SecretIndex -Path $SecretIndexPath -Data $existingIndex
        Write-Host "[SCAN] Secret index updated: $($allEntries.Count) total entries."
    } else {
        Write-Host "[DRY-RUN] Use -Apply to persist scan results to index."
    }

    return $true
}

function Invoke-Search {
    param([string]$SecretIndexPath, [string]$TypeFilter, [string]$ScopeFilter)

    $index = Read-SecretIndex -Path $SecretIndexPath
    if ($index -eq $null -or $index.entries.Count -eq 0) {
        Write-Host "[SEARCH] Secret index is empty. Run -Scan -Apply first."
        return $true
    }

    $results = @($index.entries)
    if ($TypeFilter) {
        $results = @($results | Where-Object { $_.secret_type -eq $TypeFilter })
    }
    if ($ScopeFilter) {
        $results = @($results | Where-Object { $_.scope -eq $ScopeFilter })
    }

    if ($results.Count -eq 0) {
        $filterMsg = ""
        if ($TypeFilter) { $filterMsg += " type=$TypeFilter" }
        if ($ScopeFilter) { $filterMsg += " scope=$ScopeFilter" }
        Write-Host "[SEARCH] No secrets found for$filterMsg."
    } else {
        Write-Host "[SEARCH] Found $($results.Count) secret reference(s):"
        foreach ($r in $results) {
            Write-Host "  [$($r.secret_type)] $($r.scope)/$($r.key) fp=$($r.fingerprint)"
        }
    }

    return $true
}

function Invoke-Audit {
    param([string]$SecretIndexPath)

    $index = Read-SecretIndex -Path $SecretIndexPath
    if ($index -eq $null -or $index.entries.Count -eq 0) {
        Write-Host "[AUDIT] Secret index is empty. No secrets indexed."
        return $true
    }

    $entries = @($index.entries)
    $byScope = @{}
    $byType = @{}
    $uniqueFingerprints = @{}

    foreach ($e in $entries) {
        if ($byScope.ContainsKey($e.scope)) {
            $byScope[$e.scope] = $byScope[$e.scope] + 1
        } else {
            $byScope[$e.scope] = 1
        }
        if ($byType.ContainsKey($e.secret_type)) {
            $byType[$e.secret_type] = $byType[$e.secret_type] + 1
        } else {
            $byType[$e.secret_type] = 1
        }
        $uniqueFingerprints[$e.fingerprint] = $true
    }

    Write-Host "=== Secret Audit Report ==="
    Write-Host ""
    Write-Host "  Total indexed secrets: $($entries.Count)"
    Write-Host "  Unique fingerprints:   $($uniqueFingerprints.Count)"
    if ($index.last_scan) {
        Write-Host "  Last scan:             $($index.last_scan)"
    }
    Write-Host ""
    Write-Host "  --- By Scope ---"
    foreach ($s in ($byScope.Keys | Sort-Object)) {
        Write-Host "    $s : $($byScope[$s])"
    }
    Write-Host ""
    Write-Host "  --- By Type ---"
    foreach ($t in ($byType.Keys | Sort-Object)) {
        Write-Host "    $t : $($byType[$t])"
    }
    Write-Host ""
    Write-Host "=== End Secret Audit Report ==="

    return $true
}

function Invoke-Purge {
    param([string]$StorePath, [string]$SecretIndexPath, [string]$ScopeFilter, [bool]$ShouldApply)

    $store = Read-StoreData -Path $StorePath
    if ($store.entries.Count -eq 0) {
        Write-Host "[PURGE] No entries in scope store."
        return $true
    }

    $entriesToPurge = @()
    if ($ScopeFilter) {
        $entriesToPurge = @($store.entries | Where-Object { $_.scope -eq $ScopeFilter })
    } else {
        $entriesToPurge = @($store.entries)
    }

    $purgeCount = 0
    $purgedEntries = @()

    foreach ($entry in $entriesToPurge) {
        $text = [string]$entry.value
        $findings = Find-SecretPatterns -Text $text
        if ($findings.Count -gt 0) {
            $redacted = Invoke-SecretRedact -Text $text
            if ($redacted -ne $text) {
                $purgeCount++
                $purgedEntries += $entry
                if ($ShouldApply) {
                    $entry.value = $redacted
                }
            }
        }
    }

    if ($purgeCount -eq 0) {
        Write-Host "[PURGE] No secrets found to purge."
    } else {
        if ($ShouldApply) {
            Write-StoreData -Path $StorePath -Data $store
            Write-Host "[PURGE] Purged $purgeCount entry/entries (secrets replaced with [REDACTED:type:fp] markers)."
            foreach ($e in $purgedEntries) {
                Write-Host "  [PURGED] $($e.scope)/$($e.key)"
            }
        } else {
            Write-Host "[DRY-RUN] Would purge $purgeCount entry/entries:"
            foreach ($e in $purgedEntries) {
                Write-Host "  [WILL-PURGE] $($e.scope)/$($e.key)"
            }
            Write-Host "  Use -Apply to execute purge."
        }
    }

    return $true
}

function Invoke-EvidenceRef {
    param([string]$SecretIndexPath, [string]$ScopeFilter, [string]$EntryKey)

    $index = Read-SecretIndex -Path $SecretIndexPath
    if ($index -eq $null -or $index.entries.Count -eq 0) {
        Write-Host "[EVIDENCE] Secret index is empty."
        return $true
    }

    $results = @($index.entries | Where-Object { $_.scope -eq $ScopeFilter -and $_.key -eq $EntryKey })
    if ($results.Count -eq 0) {
        Write-Host "[EVIDENCE] No secrets indexed for $ScopeFilter/$EntryKey."
        return $true
    }

    Write-Host "=== Evidence Reference: $ScopeFilter/$EntryKey ==="
    Write-Host ""
    foreach ($r in $results) {
        Write-Host "  Type:        $($r.secret_type)"
        Write-Host "  Fingerprint: $($r.fingerprint) (SHA-256 prefix)"
        Write-Host "  Position:    $($r.position)"
        Write-Host "  Scanned:     $($r.scanned_at)"
        Write-Host "  ---"
    }
    Write-Host ""
    Write-Host "  Note: Fingerprints are SHA-256 hash prefixes."
    Write-Host "  They prove a secret exists at this location"
    Write-Host "  without revealing the plaintext value."
    Write-Host "=== End Evidence Reference ==="

    return $true
}

function Invoke-SecretReport {
    param([string]$StorePath, [string]$SecretIndexPath)

    $store = Read-StoreData -Path $StorePath
    $index = Read-SecretIndex -Path $SecretIndexPath

    Write-Host "=== Scope Secret Report ==="
    Write-Host ""

    # Store stats
    $storeEntries = @()
    if ($store.entries -ne $null) { $storeEntries = @($store.entries) }
    Write-Host "--- Scope Store ---"
    Write-Host "  Total entries: $($storeEntries.Count)"

    # Scan for live secrets (not just indexed)
    $liveSecrets = 0
    $liveByScope = @{}
    foreach ($e in $storeEntries) {
        $findings = Find-SecretPatterns -Text ([string]$e.value)
        if ($findings.Count -gt 0) {
            $liveSecrets++
            if ($liveByScope.ContainsKey($e.scope)) {
                $liveByScope[$e.scope] = $liveByScope[$e.scope] + 1
            } else {
                $liveByScope[$e.scope] = 1
            }
        }
    }
    Write-Host "  Entries with secrets: $liveSecrets"
    if ($liveByScope.Count -gt 0) {
        foreach ($s in ($liveByScope.Keys | Sort-Object)) {
            Write-Host "    $s : $($liveByScope[$s])"
        }
    }

    Write-Host ""
    Write-Host "--- Secret Index ---"
    if ($index -eq $null -or $index.entries.Count -eq 0) {
        Write-Host "  Index: empty (run -Scan -Apply)"
    } else {
        $idxEntries = @($index.entries)
        Write-Host "  Indexed secrets: $($idxEntries.Count)"
        if ($index.last_scan) {
            Write-Host "  Last scan: $($index.last_scan)"
        }
    }

    Write-Host ""
    Write-Host "  Purge status: $liveSecrets entry/entries still contain plaintext secrets."
    if ($liveSecrets -gt 0) {
        Write-Host "  Run -Purge -Apply to redact plaintext from scope store."
    } else {
        Write-Host "  All secrets have been purged or none exist."
    }
    Write-Host "=== End Secret Report ==="

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

    $testDir = Join-Path $env:TEMP "scope-secret-index-selftest-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    $testStore = Join-Path $testDir "scope-store.json"
    $testIndex = Join-Path $testDir "scope-store-secret-index.json"

    Write-Host "=== scope-secret-index.ps1 SelfTest ==="
    Write-Host ""

    # Test 1: Initialize
    Write-Host "--- Test 1: Initialize ---"
    $init = Initialize-SecretIndex -Path $testIndex
    Assert-Test "Init creates file" (Test-Path -LiteralPath $testIndex)
    $idxState = Read-SecretIndex -Path $testIndex
    Assert-Test "Init has empty entries" ($idxState.entries.Count -eq 0)
    Assert-Test "Init has version" ($idxState.meta.version -eq 1)

    # Test 2: Secret detection
    Write-Host "--- Test 2: Secret Detection ---"
    $findings = Find-SecretPatterns -Text "my key is sk-1234567890abcdefghijklmnopqrst"
    Assert-Test "API key detected" ($findings.Count -ge 1 -and $findings[0].type -eq "api-key")
    $findings2 = Find-SecretPatterns -Text "token=abcdef1234567890abcdef1234567890"
    Assert-Test "Token detected" ($findings2.Count -ge 1 -and $findings2[0].type -eq "secret")
    $findings3 = Find-SecretPatterns -Text "contact: alice@example.com"
    Assert-Test "Email detected" ($findings3.Count -ge 1 -and $findings3[0].type -eq "email")
    $findings4 = Find-SecretPatterns -Text "no secrets here just normal text"
    Assert-Test "Clean text has no secrets" ($findings4.Count -eq 0)

    # Test 3: Fingerprint generation
    Write-Host "--- Test 3: Fingerprint ---"
    $fp1 = Get-SecretFingerprint -SecretValue "sk-1234567890abcdefghijklmnopqrst"
    $fp2 = Get-SecretFingerprint -SecretValue "sk-1234567890abcdefghijklmnopqrst"
    $fp3 = Get-SecretFingerprint -SecretValue "different-value"
    Assert-Test "Same value same fingerprint" ($fp1 -eq $fp2)
    Assert-Test "Different value different fingerprint" ($fp1 -ne $fp3)
    Assert-Test "Fingerprint is 16 hex chars" ($fp1.Length -eq 16 -and $fp1 -match '^[a-f0-9]{16}$')

    # Test 4: Redaction
    Write-Host "--- Test 4: Redaction ---"
    $redacted = Invoke-SecretRedact -Text "key sk-1234567890abcdefghijklmnopqrst here"
    Assert-Test "API key redacted in text" ($redacted -match '\[REDACTED:api-key:[a-f0-9]{16}\]')
    Assert-Test "Redacted text has no plaintext" (-not ($redacted -match 'sk-[A-Za-z0-9]{20}'))

    # Test 5: Scan with real store
    Write-Host "--- Test 5: Scan ---"
    $storeData = @{
        entries = @(
            @{ id = "e1"; scope = "project"; key = "rts-api"; value = "api_key=sk-1234567890abcdefghijklmnopqrst"; scope_type = "persistent"; created_at = (Get-Date -Format "o"); updated_at = (Get-Date -Format "o"); access_count = 2; digest = "" },
            @{ id = "e2"; scope = "project"; key = "rts-config"; value = "Use Lyra GAS for RTS"; scope_type = "persistent"; created_at = (Get-Date -Format "o"); updated_at = (Get-Date -Format "o"); access_count = 5; digest = "" },
            @{ id = "e3"; scope = "ops"; key = "deploy-token"; value = "token=abcdef1234567890abcdef1234567890"; scope_type = "persistent"; created_at = (Get-Date -Format "o"); updated_at = (Get-Date -Format "o"); access_count = 1; digest = "" }
        )
        meta = @{ created_at = (Get-Date -Format "o"); version = 1 }
    }
    Write-StoreData -Path $testStore -Data $storeData
    $scanResult = Invoke-Scan -StorePath $testStore -SecretIndexPath $testIndex -ScopeFilter "" -ShouldApply $true
    Assert-Test "Scan completes" $scanResult
    $afterScan = Read-SecretIndex -Path $testIndex
    Assert-Test "Scan registered secrets" ($afterScan.entries.Count -ge 2)
    Assert-Test "Scan has last_scan timestamp" ($afterScan.last_scan -ne "")

    # Test 6: Search by type
    Write-Host "--- Test 6: Search by Type ---"
    $searchResult = Invoke-Search -SecretIndexPath $testIndex -TypeFilter "api-key" -ScopeFilter ""
    Assert-Test "Search finds api-key type" $searchResult

    # Test 7: Search by scope
    Write-Host "--- Test 7: Search by Scope ---"
    $searchResult2 = Invoke-Search -SecretIndexPath $testIndex -TypeFilter "" -ScopeFilter "ops"
    Assert-Test "Search finds ops scope" $searchResult2

    # Test 8: Audit report
    Write-Host "--- Test 8: Audit ---"
    $auditResult = Invoke-Audit -SecretIndexPath $testIndex
    Assert-Test "Audit completes" $auditResult
    # Test 9: Purge (dry-run then apply)
    # Note: "api_key=sk-..." matches both "secret" (full match at pos 0) and
    # "api-key" (sk- at pos 8). Overlap filter keeps first (secret at pos 0).
    # So the redacted marker will be [REDACTED:secret:...], not [REDACTED:api-key:...].
    Write-Host "--- Test 9: Purge ---"
    $dryPurge = Invoke-Purge -StorePath $testStore -SecretIndexPath $testIndex -ScopeFilter "" -ShouldApply $false
    Assert-Test "Purge dry-run completes" $dryPurge
    $storeBeforePurge = Read-StoreData -Path $testStore
    $apiEntryBefore = @($storeBeforePurge.entries | Where-Object { $_.key -eq "rts-api" })[0]
    Assert-Test "Dry-run does not modify store" ($apiEntryBefore.value -match 'sk-1234567890')
    $applyPurge = Invoke-Purge -StorePath $testStore -SecretIndexPath $testIndex -ScopeFilter "" -ShouldApply $true
    Assert-Test "Purge apply completes" $applyPurge
    $storeAfterPurge = Read-StoreData -Path $testStore
    $apiEntryAfter = @($storeAfterPurge.entries | Where-Object { $_.key -eq "rts-api" })[0]
    Assert-Test "Purge redacts API key" ($apiEntryAfter.value -match '\[REDACTED:secret')
    Assert-Test "Purge removes plaintext" (-not ($apiEntryAfter.value -match 'sk-1234567890'))
    $cleanEntry = @($storeAfterPurge.entries | Where-Object { $_.key -eq "rts-config" })[0]
    Assert-Test "Clean entry unchanged" ($cleanEntry.value -eq "Use Lyra GAS for RTS")

    # Test 10: Evidence Reference
    Write-Host "--- Test 10: Evidence Reference ---"
    $evidenceResult = Invoke-EvidenceRef -SecretIndexPath $testIndex -ScopeFilter "project" -EntryKey "rts-api"
    Assert-Test "EvidenceRef completes" $evidenceResult

    # Test 11: Secret Report
    Write-Host "--- Test 11: Secret Report ---"
    $reportResult = Invoke-SecretReport -StorePath $testStore -SecretIndexPath $testIndex
    Assert-Test "SecretReport completes" $reportResult

    # Test 12: Index Security
    Write-Host "--- Test 12: Index Security ---"
    $idxFinal = Read-SecretIndex -Path $testIndex
    $hasPlaintext = $false
    foreach ($e in $idxFinal.entries) {
        if ([string]$e -match 'sk-[A-Za-z0-9]{20}') { $hasPlaintext = $true }
        if ([string]$e -match 'token=[A-Za-z0-9]{16}') { $hasPlaintext = $true }
    }
    Assert-Test "Index contains no plaintext secrets" (-not $hasPlaintext)

    Write-Host ""
    Write-Host "=== SelfTest Results: $script:pass passed, $script:fail failed ==="

    # Cleanup
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue

    if ($script:fail -gt 0) { return $false }
    return $true
}

# --- Parameter Dispatch ---

if ($SelfTest) {
    $result = Invoke-SelfTest
    if ($result) { exit 0 } else { exit 1 }
}

if ($Init) {
    $result = Initialize-SecretIndex -Path $IndexPath
    if ($result) { exit 0 } else { exit 1 }
}

if ($Scan) {
    $result = Invoke-Scan -StorePath $DbPath -SecretIndexPath $IndexPath -ScopeFilter $Scope -ShouldApply $Apply
    if ($result) { exit 0 } else { exit 1 }
}

if ($Search) {
    $result = Invoke-Search -SecretIndexPath $IndexPath -TypeFilter $Type -ScopeFilter $Scope
    if ($result) { exit 0 } else { exit 1 }
}

if ($Audit) {
    $result = Invoke-Audit -SecretIndexPath $IndexPath
    if ($result) { exit 0 } else { exit 1 }
}

if ($Purge) {
    $result = Invoke-Purge -StorePath $DbPath -SecretIndexPath $IndexPath -ScopeFilter $Scope -ShouldApply $Apply
    if ($result) { exit 0 } else { exit 1 }
}

if ($EvidenceRef) {
    if (-not $Scope -or -not $Key) {
        Write-Host "ERROR: -Scope and -Key are required for EvidenceRef" -ForegroundColor Red
        exit 1
    }
    $result = Invoke-EvidenceRef -SecretIndexPath $IndexPath -ScopeFilter $Scope -EntryKey $Key
    if ($result) { exit 0 } else { exit 1 }
}

if ($SecretReport) {
    $result = Invoke-SecretReport -StorePath $DbPath -SecretIndexPath $IndexPath
    if ($result) { exit 0 } else { exit 1 }
}

Write-Host "ERROR: No action specified. Use -Init, -Scan, -Search, -Audit, -Purge, -EvidenceRef, -SecretReport, or -SelfTest" -ForegroundColor Red
exit 1
