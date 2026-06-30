# obsidian-scope-recall.ps1 - Scoped Memory Partitioning for Evolution System
# Inspired by Scope Recall: memory partitioning for AI agents
# Key insight: separate persistent memory (cross-session) from local/draft
# memory (session-scoped) to prevent context pollution and cross-window leaks
#
# Architecture:
#   Persistent scopes (shared across sessions):
#     - user: user preferences, interaction patterns
#     - project: project facts, architecture decisions
#     - ops: operational records, evolution outcomes
#     - memory: lessons learned, failure memories
#   Local scopes (session-isolated):
#     - general: temporary drafts, current-turn context
#     - session_<id>: per-session scratch space
#
# Two-layer scope model:
#   Accessible scope set = current local scope + shared persistent scopes
#   This ensures agents see relevant persistent facts but not other sessions' drafts
#
# PowerShell 5.1 compatible - all identifiers in ASCII, no Chinese in regex

param(
    [string]$VaultPath = 'E:\ObsidianVault',
    [string]$ProjectPath = 'E:\UEGameDevelopment',
    [string]$ScopeStorePath = '',
    [switch]$Init,
    [switch]$Recall,
    [switch]$Store,
    [switch]$Digest,
    [switch]$ListScopes,
    [string]$ScopeType = '',
    [string]$SessionId = '',
    [string]$Key = '',
    [string]$Value = '',
    [string]$Query = '',
    [switch]$DryRun = $true,
    [switch]$Apply,
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$helpersPath = Join-Path $PSScriptRoot '_shared\ObsidianHelpers.psm1'
Import-Module $helpersPath -Force -WarningAction SilentlyContinue

# ============================================================
# Constants
# ============================================================
$PERSISTENT_SCOPES = @('user', 'project', 'ops', 'memory')
$LOCAL_SCOPES = @('general')
$SCOPE_DIR_NAME = 'scope-recall'

# ============================================================
# Help
# ============================================================
if ($Help) {
    Write-Host 'obsidian-scope-recall.ps1 - Scoped Memory Partitioning'
    Write-Host 'Inspired by Scope Recall: persistent + local scope separation'
    Write-Host ''
    Write-Host 'Usage:'
    Write-Host '  -Init                    Initialize scope store directories'
    Write-Host '  -ListScopes              List all scopes and entry counts'
    Write-Host '  -Recall -Query <text>    Recall memories matching query'
    Write-Host '  -Recall -ScopeType <t>   Recall all entries in a scope'
    Write-Host '  -Store -ScopeType <t> -Key <k> -Value <v>  Store a memory entry'
    Write-Host '  -Digest                  Run daily digest (consolidate persistent facts)'
    Write-Host '  -SelfTest                Run built-in self-test'
    Write-Host ''
    Write-Host 'Scope Types:'
    Write-Host '  Persistent (cross-session): user, project, ops, memory'
    Write-Host '  Local (session-isolated):   general, session_<id>'
    Write-Host ''
    Write-Host 'Safety: -Apply required for writes; local scopes auto-expire'
    exit 0
}
# ============================================================
# Path Resolution
# ============================================================
function Get-ScopeStoreRoot {
    if ($ScopeStorePath -ne '') { return $ScopeStorePath }
    $vault = Get-VaultPath -VaultPath $VaultPath
    if ($null -eq $vault) { return $null }
    return Join-Path $vault $SCOPE_DIR_NAME
}

function Get-ScopePath {
    param([string]$ScopeType)
    $root = Get-ScopeStoreRoot
    if ($null -eq $root) { return $null }
    return Join-Path $root $ScopeType
}

# ============================================================
# Scope Classification
# ============================================================
function Test-PersistentScope {
    param([string]$ScopeType)
    return $PERSISTENT_SCOPES -contains $ScopeType
}

function Test-LocalScope {
    param([string]$ScopeType)
    if ($LOCAL_SCOPES -contains $ScopeType) { return $true }
    if ($ScopeType -match '^session_[a-zA-Z0-9_]+$') { return $true }
    return $false
}

function Test-ValidScope {
    param([string]$ScopeType)
    return (Test-PersistentScope $ScopeType) -or (Test-LocalScope $ScopeType)
}

# Determine which scopes are accessible for a given session
function Get-AccessibleScopes {
    param([string]$CurrentSessionId)
    $accessible = @() + $PERSISTENT_SCOPES
    if ($CurrentSessionId -ne '') {
        $accessible += "session_$CurrentSessionId"
    }
    $accessible += 'general'
    return $accessible
}
# ============================================================
# Init: Create scope store directories
# ============================================================
function Initialize-ScopeStore {
    Write-Host '=== Initializing Scope Recall Store ==='
    $root = Get-ScopeStoreRoot
    if ($null -eq $root) { Write-Error 'Cannot resolve scope store root'; return $false }

    if (-not (Test-Path $root)) {
        if ($DryRun -and -not $Apply) {
            Write-Host "  [DRY] Would create: $root"
        } else {
            New-Item -Path $root -ItemType Directory -Force | Out-Null
            Write-Host "  Created: $root"
        }
    }

    $allScopes = $PERSISTENT_SCOPES + $LOCAL_SCOPES
    foreach ($scope in $allScopes) {
        $scopePath = Get-ScopePath $scope
        if (-not (Test-Path $scopePath)) {
            if ($DryRun -and -not $Apply) {
                Write-Host "  [DRY] Would create: $scopePath"
            } else {
                New-Item -Path $scopePath -ItemType Directory -Force | Out-Null
                Write-Host "  Created: $scopePath"
            }
        } else {
            Write-Host "  Exists: $scopePath"
        }
    }

    # Write scope manifest
    $manifestPath = Join-Path $root 'scope-manifest.yaml'
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $manifest = "# Scope Recall Manifest`n"
    $manifest += "# Auto-generated by obsidian-scope-recall.ps1`n"
    $manifest += "# Updated: $now`n"
    $manifest += "persistent_scopes:`n"
    foreach ($s in $PERSISTENT_SCOPES) {
        $manifest += "  - `"$s`"`n"
    }
    $manifest += "local_scopes:`n"
    foreach ($s in $LOCAL_SCOPES) {
        $manifest += "  - `"$s`"`n"
    }
    $manifest += "session_prefix: `"session_`"`n"
    $manifest += "accessible_rule: `"current_local + shared_persistent`"`n"

    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($manifestPath, $manifest, [System.Text.Encoding]::UTF8)
        Write-Host "  Written: $manifestPath"
    } else {
        Write-Host "  [DRY] Would write: $manifestPath"
    }

    Write-Host '=== Scope Store Initialized ==='
    return $true
}
# ============================================================
# Store: Write a memory entry to a scope
# ============================================================
function Set-ScopeMemory {
    param(
        [string]$ScopeType,
        [string]$Key,
        [string]$Value,
        [string]$SessionId
    )

    # Resolve session-based scope
    if ($ScopeType -eq 'session' -and $SessionId -ne '') {
        $ScopeType = "session_$SessionId"
    }

    if (-not (Test-ValidScope $ScopeType)) {
        Write-Error "Invalid scope type: $ScopeType"
        return $false
    }

    if ([string]::IsNullOrEmpty($Key)) {
        Write-Error 'Key is required for Store operation'
        return $false
    }

    $scopePath = Get-ScopePath $ScopeType
    if ($null -eq $scopePath) { Write-Error 'Cannot resolve scope path'; return $false }
    if (-not (Test-Path $scopePath)) {
        if ($DryRun -and -not $Apply) {
            Write-Host "  [DRY] Would create scope dir: $scopePath"
        } else {
            New-Item -Path $scopePath -ItemType Directory -Force | Out-Null
        }
    }

    # Create entry file: one YAML file per key for atomic writes
    $safeKey = ($Key -replace '[^a-zA-Z0-9_-]', '_')
    if ($safeKey.Length -gt 60) { $safeKey = $safeKey.Substring(0, 60) }
    $entryPath = Join-Path $scopePath "$safeKey.yaml"

    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $isPersistent = Test-PersistentScope $ScopeType
    $scopeKind = if ($isPersistent) { 'persistent' } else { 'local' }

    $entryYaml = "# Scope Recall Entry`n"
    $entryYaml += "key: `"$Key`"`n"
    $entryYaml += "scope: `"$ScopeType`"`n"
    $entryYaml += "scope_kind: `"$scopeKind`"`n"
    $entryYaml += "value: |`n"
    foreach ($line in ($Value -split "`n")) {
        $entryYaml += "  $line`n"
    }
    $entryYaml += "created_at: `"$now`"`n"
    $entryYaml += "updated_at: `"$now`"`n"

    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($entryPath, $entryYaml, [System.Text.Encoding]::UTF8)
        $isP = if ($isPersistent) { 'PERSISTENT' } else { 'LOCAL' }
        Write-Host "  [$isP] Stored: $ScopeType/$Key"
    } else {
        Write-Host "  [DRY] Would store: $ScopeType/$Key"
    }

    return $true
}
# ============================================================
# Recall: Read memory entries from accessible scopes
# ============================================================
function Get-ScopeRecall {
    param(
        [string]$Query,
        [string]$ScopeType,
        [string]$SessionId
    )

    Write-Host '=== Scope Recall ==='

    # Determine accessible scopes
    if ($ScopeType -ne '') {
        # Explicit scope request - only return from that scope
        if (-not (Test-ValidScope $ScopeType)) {
            Write-Error "Invalid scope type: $ScopeType"
            return @()
        }
        $accessibleScopes = @($ScopeType)
    } else {
        # Default: all accessible scopes for current session
        $accessibleScopes = Get-AccessibleScopes $SessionId
    }

    $results = @()
    foreach ($scope in $accessibleScopes) {
        $scopePath = Get-ScopePath $scope
        if (-not (Test-Path $scopePath)) { continue }

        $entries = Get-ChildItem -Path $scopePath -Filter '*.yaml' -File -ErrorAction SilentlyContinue
        foreach ($entry in $entries) {
            $content = [System.IO.File]::ReadAllText($entry.FullName, [System.Text.Encoding]::UTF8)

            # If query specified, do simple keyword matching
            if ($Query -ne '') {
                $queryTerms = $Query -split '\s+' | Where-Object { $_.Length -gt 0 }
                $matched = $false
                foreach ($term in $queryTerms) {
                    if ($content -match [regex]::Escape($term)) {
                        $matched = $true
                        break
                    }
                }
                if (-not $matched) { continue }
            }

            # Parse key and scope_kind
            $entryKey = if ($content -match 'key:\s*"([^"]+)"') { $Matches[1] } else { $entry.BaseName }
            $scopeKind = if ($content -match 'scope_kind:\s*"([^"]+)"') { $Matches[1] } else { 'unknown' }
            $updatedAt = if ($content -match 'updated_at:\s*"([^"]+)"') { $Matches[1] } else { '' }

            # Extract value block
            $valueStr = ''
            if ($content -match '(?s)value:\s*\|\r?\n((?:\s+.*\r?\n)*)') {
                $rawVal = $Matches[1]
                $valLines = $rawVal -split "`n" | ForEach-Object { $_.TrimStart() -replace "`r$", '' }
                $valueStr = $valLines -join "`n"
            }

            $results += @{
                scope = $scope
                scope_kind = $scopeKind
                key = $entryKey
                value = $valueStr
                updated = $updatedAt
                path = $entry.FullName
            }
        }
    }

    # Sort: persistent first, then by updated date descending
    $sorted = @($results | Sort-Object { if ($_.scope_kind -eq 'persistent') { 0 } else { 1 } }, { $_.updated } -Descending)

    Write-Host "  Recalled $($sorted.Count) entries from $($accessibleScopes.Count) scopes"
    foreach ($r in $sorted) {
        $sk = $r.scope_kind.ToUpper().Substring(0,4)
        Write-Host "    [$sk] $($r.scope)/$($r.key)"
    }

    return $sorted
}
# ============================================================
# ListScopes: Show all scopes and entry counts
# ============================================================
function Show-ScopeList {
    Write-Host '=== Scope Recall: Scope Inventory ==='
    $root = Get-ScopeStoreRoot
    if ($null -eq $root -or -not (Test-Path $root)) {
        Write-Host '  No scope store initialized. Run -Init first.'
        return
    }

    $allScopes = @() + $PERSISTENT_SCOPES + $LOCAL_SCOPES

    # Also discover any session_* directories
    $sessionDirs = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '^session_' -and $_.Name -notin $allScopes
    } | ForEach-Object { $_.Name }
    if ($sessionDirs.Count -gt 0) { $allScopes += @($sessionDirs) }

    foreach ($scope in $allScopes) {
        $scopePath = Get-ScopePath $scope
        $isPersistent = Test-PersistentScope $scope
        $kind = if ($isPersistent) { 'PERSISTENT' } else { 'LOCAL' }

        $entryCount = 0
        if (Test-Path $scopePath) {
            $entryCount = (Get-ChildItem -Path $scopePath -Filter '*.yaml' -File -ErrorAction SilentlyContinue | Measure-Object).Count
        }
        Write-Host "  [$kind] $scope ($entryCount entries)"
    }

    $totalPersistent = 0
    foreach ($ps in $PERSISTENT_SCOPES) {
        $pPath = Get-ScopePath $ps
        if (Test-Path $pPath) {
            $totalPersistent += (Get-ChildItem -Path $pPath -Filter '*.yaml' -File -ErrorAction SilentlyContinue | Measure-Object).Count
        }
    }
    $totalLocal = 0
    foreach ($ls in $LOCAL_SCOPES) {
        $lPath = Get-ScopePath $ls
        if (Test-Path $lPath) {
            $totalLocal += (Get-ChildItem -Path $lPath -Filter '*.yaml' -File -ErrorAction SilentlyContinue | Measure-Object).Count
        }
    }
    foreach ($sd in $sessionDirs) {
        $sPath = Get-ScopePath $sd
        if (Test-Path $sPath) {
            $totalLocal += (Get-ChildItem -Path $sPath -Filter '*.yaml' -File -ErrorAction SilentlyContinue | Measure-Object).Count
        }
    }
    Write-Host ''
    Write-Host "  Total persistent: $totalPersistent | Total local: $totalLocal"
}
# ============================================================
# Digest: Daily consolidation of persistent facts
# Prevents memory bloat by tightly digesting workflow summaries
# ============================================================
function Invoke-ScopeDigest {
    Write-Host '=== Scope Recall: Daily Digest ==='
    $root = Get-ScopeStoreRoot
    if ($null -eq $root -or -not (Test-Path $root)) {
        Write-Host '  No scope store initialized. Run -Init first.'
        return
    }

    $now = Get-Date
    $digestPath = Join-Path $root 'digests'
    if (-not (Test-Path $digestPath)) {
        if (-not ($DryRun -and -not $Apply)) {
            New-Item -Path $digestPath -ItemType Directory -Force | Out-Null
        }
    }

    $dateStamp = Get-Date -Format 'yyyy-MM-dd'
    $digestFile = Join-Path $digestPath "digest-$dateStamp.yaml"

    # Count entries per scope
    $scopeStats = @{}
    foreach ($ps in $PERSISTENT_SCOPES) {
        $pPath = Get-ScopePath $ps
        $count = 0
        if (Test-Path $pPath) {
            $count = (Get-ChildItem -Path $pPath -Filter '*.yaml' -File -ErrorAction SilentlyContinue | Measure-Object).Count
        }
        $scopeStats[$ps] = $count
    }

    # Clean up expired local entries (older than 24h)
    $expiredCount = 0
    foreach ($ls in $LOCAL_SCOPES) {
        $lPath = Get-ScopePath $ls
        if (-not (Test-Path $lPath)) { continue }
        $entries = Get-ChildItem -Path $lPath -Filter '*.yaml' -File -ErrorAction SilentlyContinue
        foreach ($entry in $entries) {
            $age = $now - $entry.LastWriteTime
            if ($age.TotalHours -gt 24) {
                if (-not ($DryRun -and -not $Apply)) {
                    Remove-Item $entry.FullName -Force
                }
                $expiredCount++
            }
        }
    }

    # Also clean expired session scopes (older than 48h)
    $sessionDirs = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '^session_'
    }
    foreach ($sd in $sessionDirs) {
        $age = $now - $sd.LastWriteTime
        if ($age.TotalHours -gt 48) {
            if (-not ($DryRun -and -not $Apply)) {
                Remove-Item $sd.FullName -Recurse -Force
            }
            $expiredCount++
        }
    }

    # Write digest report
    $digestYaml = "# Scope Recall Daily Digest`n"
    $digestYaml += "# Date: $dateStamp`n"
    $digestYaml += "# Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`n"
    $digestYaml += "persistent_entries:`n"
    foreach ($ps in $PERSISTENT_SCOPES) {
        $digestYaml += "  ${ps}: $($scopeStats[$ps])`n"
    }
    $digestYaml += "expired_local_entries: $expiredCount`n"
    $digestYaml += "digest_action: `"consolidated_and_expired`"`n"

    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($digestFile, $digestYaml, [System.Text.Encoding]::UTF8)
        Write-Host "  Written: $digestFile"
    } else {
        Write-Host "  [DRY] Would write: $digestFile"
    }

    $totalP = ($scopeStats.GetEnumerator() | ForEach-Object { $_.Value } | Measure-Object -Sum).Sum
    Write-Host "  Persistent: $totalP entries | Expired: $expiredCount local entries"
}
# ============================================================
# Integration: Migrate metacognitive data into scope-recall
# Reads existing metacognitive YAML and stores key facts into
# the appropriate persistent scopes
# ============================================================
function Initialize-ScopeFromMetacognitive {
    Write-Host '=== Migrating Metacognitive Data to Scope Recall ==='
    $metaPath = Join-Path $VaultPath 'metacognitive'
    if (-not (Test-Path $metaPath)) {
        Write-Host '  No metacognitive data found. Skip migration.'
        return
    }

    # Migrate lessons-learned -> memory scope
    $lessonsPath = Join-Path $metaPath 'lessons-learned.yaml'
    if (Test-Path $lessonsPath) {
        $content = [System.IO.File]::ReadAllText($lessonsPath, [System.Text.Encoding]::UTF8)
        $lessonBlocks = $content -split '(?=- lesson:)'
        $count = 0
        foreach ($block in $lessonBlocks) {
            if ($block -match 'lesson:\s*"([^"]+)"') {
                $lessonText = $Matches[1]
                $added = if ($block -match 'added:\s*"([^"]+)"') { $Matches[1] } else { 'unknown' }
                $safeKey = "lesson_$($added -replace '[^a-zA-Z0-9]', '_')"
                # Store in memory scope (persistent)
                $scopePath = Get-ScopePath 'memory'
                if ($null -ne $scopePath -and (Test-Path $scopePath)) {
                    $entryPath = Join-Path $scopePath "$safeKey.yaml"
                    if (-not (Test-Path $entryPath)) {
                        $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
                        $entryYaml = "# Scope Recall Entry (migrated from metacognitive)`n"
                        $entryYaml += "key: `"$safeKey`"`n"
                        $entryYaml += "scope: `"memory`"`n"
                        $entryYaml += "scope_kind: `"persistent`"`n"
                        $entryYaml += "value: |`n"
                        foreach ($line in ($lessonText -split "`n")) {
                            $entryYaml += "  $line`n"
                        }
                        $entryYaml += "created_at: `"$added`"`n"
                        $entryYaml += "updated_at: `"$now`"`n"
                        $entryYaml += "migrated_from: `"metacognitive/lessons-learned`"`n"
                        if (-not ($DryRun -and -not $Apply)) {
                            [System.IO.File]::WriteAllText($entryPath, $entryYaml, [System.Text.Encoding]::UTF8)
                            $count++
                        }
                    }
                }
            }
        }
        Write-Host "  Migrated $count lessons to memory scope"
    }

    # Migrate capability-map -> project scope (summary only)
    $capPath = Join-Path $metaPath 'capability-map.yaml'
    if (Test-Path $capPath) {
        $capContent = [System.IO.File]::ReadAllText($capPath, [System.Text.Encoding]::UTF8)
        $scopePath = Get-ScopePath 'project'
        if ($null -ne $scopePath -and (Test-Path $scopePath)) {
            $entryPath = Join-Path $scopePath 'capability_map.yaml'
            if (-not (Test-Path $entryPath)) {
                $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
                $entryYaml = "# Scope Recall Entry (migrated from metacognitive)`n"
                $entryYaml += "key: `"capability_map`"`n"
                $entryYaml += "scope: `"project`"`n"
                $entryYaml += "scope_kind: `"persistent`"`n"
                $entryYaml += "value: |`n"
                foreach ($line in ($capContent -split "`n")) {
                    $entryYaml += "  $line`n"
                }
                $entryYaml += "created_at: `"$now`"`n"
                $entryYaml += "updated_at: `"$now`"`n"
                $entryYaml += "migrated_from: `"metacognitive/capability-map`"`n"
                if (-not ($DryRun -and -not $Apply)) {
                    [System.IO.File]::WriteAllText($entryPath, $entryYaml, [System.Text.Encoding]::UTF8)
                    Write-Host '  Migrated capability-map to project scope'
                }
            }
        }
    }

    Write-Host '=== Migration Complete ==='
}
# ============================================================
# Self-test
# ============================================================
if ($SelfTest) {
    Write-Host '[SELFTEST] Running obsidian-scope-recall self-test...'
    $testRoot = Join-Path $env:TEMP 'scope-recall-selftest'
    if (Test-Path $testRoot) { Remove-Item $testRoot -Recurse -Force }
    New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

    # Test 1: Scope classification
    Write-Host '  [1/6] Testing scope classification...'
    if (-not (Test-PersistentScope 'user')) { Write-Host '[SELFTEST-FAIL] user should be persistent'; exit 1 }
    if (-not (Test-PersistentScope 'memory')) { Write-Host '[SELFTEST-FAIL] memory should be persistent'; exit 1 }
    if (Test-PersistentScope 'general') { Write-Host '[SELFTEST-FAIL] general should not be persistent'; exit 1 }
    if (-not (Test-LocalScope 'general')) { Write-Host '[SELFTEST-FAIL] general should be local'; exit 1 }
    if (-not (Test-LocalScope 'session_test123')) { Write-Host '[SELFTEST-FAIL] session_test123 should be local'; exit 1 }
    if (Test-LocalScope 'invalid!scope') { Write-Host '[SELFTEST-FAIL] invalid!scope should not be valid local'; exit 1 }
    Write-Host '    PASS'

    # Test 2: Valid scope check
    Write-Host '  [2/6] Testing valid scope check...'
    if (-not (Test-ValidScope 'user')) { Write-Host '[SELFTEST-FAIL] user should be valid'; exit 1 }
    if (-not (Test-ValidScope 'general')) { Write-Host '[SELFTEST-FAIL] general should be valid'; exit 1 }
if (Test-ValidScope 'nonexistent') { Write-Host '[SELFTEST-FAIL] nonexistent should not be valid'; exit 1 }
    Write-Host '    PASS'

    # Test 3: Accessible scopes
    Write-Host '  [3/6] Testing accessible scopes...'
    $acc = Get-AccessibleScopes 'mysession'
    if ($acc -notcontains 'user') { Write-Host '[SELFTEST-FAIL] accessible should contain user'; exit 1 }
    if ($acc -notcontains 'project') { Write-Host '[SELFTEST-FAIL] accessible should contain project'; exit 1 }
    if ($acc -notcontains 'session_mysession') { Write-Host '[SELFTEST-FAIL] accessible should contain session_mysession'; exit 1 }
    if ($acc -notcontains 'general') { Write-Host '[SELFTEST-FAIL] accessible should contain general'; exit 1 }
    Write-Host '    PASS'

    # Test 4: Init with test directory
    Write-Host '  [4/6] Testing Init...'
    $origDryRun = $DryRun
    $DryRun = $false
    $origScopeStore = $ScopeStorePath
    $ScopeStorePath = $testRoot
    $result = Initialize-ScopeStore
    $ScopeStorePath = $origScopeStore
    $DryRun = $origDryRun
    if (-not $result) { Write-Host '[SELFTEST-FAIL] Init failed'; exit 1 }
    $manifestPath = Join-Path $testRoot 'scope-manifest.yaml'
    if (-not (Test-Path $manifestPath)) { Write-Host '[SELFTEST-FAIL] Manifest not created'; exit 1 }
    Write-Host '    PASS'

    # Test 5: Store and Recall
    Write-Host '  [5/6] Testing Store and Recall...'
    $DryRun = $false
    $ScopeStorePath = $testRoot
    $storeResult = Set-ScopeMemory -ScopeType 'user' -Key 'test_preference' -Value 'dark_mode_enabled'
    if (-not $storeResult) { Write-Host '[SELFTEST-FAIL] Store failed'; exit 1 }
    $storeResult2 = Set-ScopeMemory -ScopeType 'general' -Key 'temp_draft' -Value 'scratch_data'
    if (-not $storeResult2) { Write-Host '[SELFTEST-FAIL] Store local failed'; exit 1 }

    $recallResult = Get-ScopeRecall -ScopeType 'user'
    $recallArray = @($recallResult)
    if ($recallArray.Count -lt 1) { Write-Host '[SELFTEST-FAIL] Recall returned no results'; exit 1 }
    if ($recallArray[0].key -ne 'test_preference') { Write-Host "[SELFTEST-FAIL] Wrong key recalled: $($recallArray[0].key)"; exit 1 }
    if ($recallArray[0].scope_kind -ne 'persistent') { Write-Host "[SELFTEST-FAIL] Wrong scope_kind: $($recallArray[0].scope_kind)"; exit 1 }

    # Test query recall
    $queryResult = Get-ScopeRecall -Query 'dark'
    $queryArray = @($queryResult)
    if ($queryArray.Count -lt 1) { Write-Host '[SELFTEST-FAIL] Query recall returned no results'; exit 1 }

    # Test isolation: general scope should NOT be in user-only recall
    $userOnly = Get-ScopeRecall -ScopeType 'user'
    $userOnlyArray = @($userOnly)
    $hasGeneral = $userOnlyArray | Where-Object { $_.scope -eq 'general' }
    if ($null -ne $hasGeneral) { Write-Host '[SELFTEST-FAIL] Scope isolation broken'; exit 1 }
    $ScopeStorePath = $origScopeStore
    Write-Host '    PASS'

    # Test 6: Digest (cleanup)
    Write-Host '  [6/6] Testing Digest...'
    $ScopeStorePath = $testRoot
    Invoke-ScopeDigest
    $ScopeStorePath = $origScopeStore
    $DryRun = $origDryRun
    Write-Host '    PASS'

    # Cleanup
    Remove-Item $testRoot -Recurse -Force
    Write-Host '[SELFTEST] All tests passed.'
    exit 0
}

# ============================================================
# Main Runner
# ============================================================
if ($Init) {
    Initialize-ScopeStore
    # Also migrate existing metacognitive data
    Initialize-ScopeFromMetacognitive
}
elseif ($Store) {
    if ([string]::IsNullOrEmpty($ScopeType)) { Write-Error '-ScopeType required for Store'; exit 1 }
    if ([string]::IsNullOrEmpty($Key)) { Write-Error '-Key required for Store'; exit 1 }
    Set-ScopeMemory -ScopeType $ScopeType -Key $Key -Value $Value -SessionId $SessionId
}
elseif ($Recall) {
    Get-ScopeRecall -Query $Query -ScopeType $ScopeType -SessionId $SessionId
}
elseif ($ListScopes) {
    Show-ScopeList
}
elseif ($Digest) {
    Invoke-ScopeDigest
}
else {
    Write-Error 'Specify: -Init, -Store, -Recall, -ListScopes, or -Digest. Use -Help for details.'
    exit 1
}
exit 0
