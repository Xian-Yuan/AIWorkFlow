# turn-closure.ps1 -- Turn Closure Audit for Jinli (Scope Recall pattern)
#
# Implements the conversation-end knowledge consolidation layer:
#   - Turn Closure: extract worth-remembering facts from current session
#   - Auto-promote: promote high-access session entries to persistent scopes
#   - Closure summary: generate a session closure digest
#   - Audit: verify no important knowledge is lost during context reset
#   - Flush: write extracted facts to appropriate persistent scopes
#
# Inspired by Scope Recall (BV19EE16aEn7) + Hermes memory architecture (BV17KoFBBEqM)
#
# Usage:
#   .\turn-closure.ps1 -Init
#   .\turn-closure.ps1 -Close -SessionKey task-rt1
#   .\turn-closure.ps1 -Audit -SessionKey task-rt1
#   .\turn-closure.ps1 -Promote -Scope session -Key rts-config -TargetScope project
#   .\turn-closure.ps1 -Flush -SessionKey task-rt1
#   .\turn-closure.ps1 -Summary -SessionKey task-rt1
#   .\turn-closure.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Close,
    [switch]$Audit,
    [switch]$Promote,
    [switch]$Flush,
    [switch]$Summary,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",

    [ValidateSet("user", "project", "ops", "memory")]
    [string]$TargetScope = "",

    [string]$Key = "",
    [string]$SessionKey = "",
    [int]$Limit = 20,
    [string]$ClosurePath = ""
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scopeStoreScript = Join-Path $PSScriptRoot "scope-store.ps1"
$scopeBridgeScript = Join-Path $PSScriptRoot "scope-bridge.ps1"

if (-not $ClosurePath) {
    $ClosurePath = Join-Path $repoRoot "Docs\Memory\turn-closure.json"
}

$scopeStoreOverride = ""

$persistentScopes = @("user", "project", "ops", "memory")
$localScopes = @("session", "general")

# --- Closure Data Structure ---

function Read-ClosureData {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{
            closures = @()
            promotions = @()
            audit_results = @()
            meta = @{ created_at = ""; version = 1 }
        }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $closuresArray = @()
        if ($parsed.closures -ne $null) {
            foreach ($c in $parsed.closures) {
                $promotedArray = @()
                if ($c.promoted -ne $null) {
                    foreach ($p in $c.promoted) {
                        $promotedArray += @{
                            from_scope = $p.from_scope
                            to_scope = $p.to_scope
                            key = $p.key
                            reason = $p.reason
                        }
                    }
                }
                $closuresArray += @{
                    session_key = $c.session_key
                    summary = $c.summary
                    promoted = $promotedArray
                    audited = $c.audited
                    created_at = $c.created_at
                }
            }
        }
        $promotionsArray = @()
        if ($parsed.promotions -ne $null) {
            foreach ($p in $parsed.promotions) {
                $promotionsArray += @{
                    from_scope = $p.from_scope
                    to_scope = $p.to_scope
                    key = $p.key
                    value = $p.value
                    reason = $p.reason
                    created_at = $p.created_at
                }
            }
        }
        $auditArray = @()
        if ($parsed.audit_results -ne $null) {
            foreach ($a in $parsed.audit_results) {
                $lostArray = @()
                if ($a.lost_keys -ne $null) {
                    foreach ($l in $a.lost_keys) { $lostArray += $l }
                }
                $preservedArray = @()
                if ($a.preserved_keys -ne $null) {
                    foreach ($pk in $a.preserved_keys) { $preservedArray += $pk }
                }
                $auditArray += @{
                    session_key = $a.session_key
                    lost_keys = $lostArray
                    preserved_keys = $preservedArray
                    coverage = $a.coverage
                    created_at = $a.created_at
                }
            }
        }
        return @{
            closures = $closuresArray
            promotions = $promotionsArray
            audit_results = $auditArray
            meta = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        }
    } catch {
        return @{
            closures = @()
            promotions = @()
            audit_results = @()
            meta = @{ created_at = ""; version = 1 }
        }
    }
}

function Write-ClosureData {
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

# --- Scope Store Helper ---

function Get-ScopeStoreEntries {
    param([string]$StorePath = "")

    if ($scopeStoreOverride) {
        $StorePath = $scopeStoreOverride
    } elseif (-not $StorePath) {
        $StorePath = Join-Path $repoRoot "Docs\Memory\scope-store.json"
    }

    if (-not (Test-Path -LiteralPath $StorePath)) {
        return @()
    }

    $raw = [System.IO.File]::ReadAllText($StorePath, [System.Text.Encoding]::UTF8)
    $parsed = $raw | ConvertFrom-Json
    $entries = @()
    if ($parsed.entries -ne $null) {
        foreach ($e in $parsed.entries) {
            $entries += @{
                id = $e.id
                scope = $e.scope
                key = $e.key
                value = $e.value
                scope_type = $e.scope_type
                access_count = [int]$e.access_count
                created_at = $e.created_at
                updated_at = $e.updated_at
                digest = $e.digest
            }
        }
    }
    return ,$entries
}

function Set-ScopeStoreEntries {
    param(
        [string]$StorePath = "",
        $Entries
    )

    if ($scopeStoreOverride) {
        $StorePath = $scopeStoreOverride
    } elseif (-not $StorePath) {
        $StorePath = Join-Path $repoRoot "Docs\Memory\scope-store.json"
    }

    $meta = @{ created_at = ""; version = 1 }
    if (Test-Path -LiteralPath $StorePath) {
        $raw = [System.IO.File]::ReadAllText($StorePath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.meta -ne $null) {
            $meta = @{ created_at = $parsed.meta.created_at; version = [int]$parsed.meta.version }
        }
    }

    $store = @{ entries = $Entries; meta = $meta }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($StorePath, ($store | ConvertTo-Json -Depth 10), $utf8NoBom)
}

# --- Core Operations ---

function Initialize-Closure {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        $data = @{
            closures = @()
            promotions = @()
            audit_results = @()
            meta = @{ created_at = (Get-Date -Format 'o'); version = 1 }
        }
        Write-ClosureData -Path $Path -Data $data
    }
    Write-Host ("[INIT] Turn closure audit initialized at: " + $Path)
    return $true
}

function Invoke-TurnClosure {
    param(
        [string]$ClosureDataPath,
        [string]$SKey
    )

    $entries = if ((Get-ScopeStoreEntries) -ne $null) { Get-ScopeStoreEntries } else { @() }
    $sessionEntries = @()
    $generalEntries = @()
    foreach ($e in $entries) {
        if ($e.scope -eq "session" -and $e.key -like ("*" + $SKey + "*")) {
            $sessionEntries += $e
        }
        if ($e.scope -eq "general" -and $e.key -like ("*" + $SKey + "*")) {
            $generalEntries += $e
        }
    }

    $promotedEntries = @()
    $promotionLog = @()
    foreach ($e in $sessionEntries) {
        if ([int]$e.access_count -ge 3) {
            $targetScope = "memory"
            $reason = "high-access auto-promote"
            if ($e.key -like "*rts-*" -or $e.key -like "*gas-*" -or $e.key -like "*ue-*") {
                $targetScope = "project"
                $reason = "project-key auto-promote"
            } elseif ($e.key -like "*pref-*" -or $e.key -like "*user-*") {
                $targetScope = "user"
                $reason = "user-key auto-promote"
            } elseif ($e.key -like "*ops-*" -or $e.key -like "*build-*" -or $e.key -like "*deploy-*") {
                $targetScope = "ops"
                $reason = "ops-key auto-promote"
            }

            $promotedEntries += @{
                entry = $e
                target_scope = $targetScope
                reason = $reason
            }
            $promotionLog += @{
                from_scope = $e.scope
                to_scope = $targetScope
                key = $e.key
                reason = $reason
            }
        }
    }

    if ($Apply -and $promotedEntries.Count -gt 0) {
        $allEntries = if ((Get-ScopeStoreEntries) -ne $null) { Get-ScopeStoreEntries } else { @() }
        foreach ($pe in $promotedEntries) {
            foreach ($ae in $allEntries) {
                if ($ae.scope -eq $pe.entry.scope -and $ae.key -eq $pe.entry.key) {
                    $ae.scope = $pe.target_scope
                    $ae.scope_type = "persistent"
                }
            }
        }
        Set-ScopeStoreEntries -Entries $allEntries
    }

    $summaryParts = @()
    $summaryParts += ("Session: " + $SKey)
    $summaryParts += ("Session entries: " + $sessionEntries.Count)
    $summaryParts += ("General entries: " + $generalEntries.Count)
    $summaryParts += ("Auto-promoted: " + $promotedEntries.Count)
    foreach ($pe in $promotedEntries) {
        $summaryParts += ("  " + $pe.entry.key + " -> " + $pe.target_scope + " (" + $pe.reason + ")")
    }
    $summaryText = $summaryParts -join "`n"

    $closure = Read-ClosureData -Path $ClosureDataPath

    $filtered = @()
    foreach ($c in $closure.closures) {
        if ($c.session_key -ne $SKey) {
            $filtered += $c
        }
    }
    $closure.closures = $filtered

    $closure.closures += @{
        session_key = $SKey
        summary = $summaryText
        promoted = $promotionLog
        audited = $false
        created_at = (Get-Date -Format 'o')
    }

    foreach ($pl in $promotionLog) {
        $closure.promotions += @{
            from_scope = $pl.from_scope
            to_scope = $pl.to_scope
            key = $pl.key
            value = ""
            reason = $pl.reason
            created_at = (Get-Date -Format 'o')
        }
    }

    if ($Apply) {
        Write-ClosureData -Path $ClosureDataPath -Data $closure
    }

    Write-Host ("[CLOSE] Session=" + $SKey)
    Write-Host ("  Session entries: " + $sessionEntries.Count)
    Write-Host ("  General entries: " + $generalEntries.Count)
    Write-Host ("  Auto-promoted: " + $promotedEntries.Count)
    foreach ($pe in $promotedEntries) {
        Write-Host ("    " + $pe.entry.key + " -> " + $pe.target_scope + " (" + $pe.reason + ")")
    }

    return @{
        session_key = $SKey
        session_entries = $sessionEntries.Count
        general_entries = $generalEntries.Count
        promoted = $promotedEntries.Count
        summary = $summaryText
    }
}

function Invoke-ClosureAudit {
    param(
        [string]$ClosureDataPath,
        [string]$SKey
    )

    $entries = if ((Get-ScopeStoreEntries) -ne $null) { Get-ScopeStoreEntries } else { @() }
    $sessionEntries = @()
    foreach ($e in $entries) {
        if ($e.scope -eq "session" -and $e.key -like ("*" + $SKey + "*")) {
            $sessionEntries += $e
        }
    }

    $closure = Read-ClosureData -Path $ClosureDataPath
    $closureRecord = $null
    foreach ($c in $closure.closures) {
        if ($c.session_key -eq $SKey) {
            $closureRecord = $c
            break
        }
    }

    $promotedKeys = @()
    if ($closureRecord -ne $null) {
        foreach ($p in $closureRecord.promoted) {
            $promotedKeys += $p.key
        }
    }

    $lostKeys = @()
    $preservedKeys = @()
    foreach ($e in $sessionEntries) {
        if ($promotedKeys -contains $e.key) {
            $preservedKeys += $e.key
        } else {
            $foundInPersistent = $false
            foreach ($pe in $entries) {
                if ($persistentScopes -contains $pe.scope -and $pe.key -eq $e.key) {
                    $foundInPersistent = $true
                    break
                }
            }
            if ($foundInPersistent) {
                $preservedKeys += $e.key
            } else {
                $lostKeys += $e.key
            }
        }
    }

    $totalKeys = $sessionEntries.Count
    $coverage = 1.0
    if ($totalKeys -gt 0) {
        $coverage = [math]::Round(($preservedKeys.Count / $totalKeys), 2)
    }

    $auditResult = @{
        session_key = $SKey
        lost_keys = $lostKeys
        preserved_keys = $preservedKeys
        coverage = $coverage
        created_at = (Get-Date -Format 'o')
    }

    $closure.audit_results += $auditResult

    foreach ($c in $closure.closures) {
        if ($c.session_key -eq $SKey) {
            $c.audited = $true
        }
    }

    if ($Apply) {
        Write-ClosureData -Path $ClosureDataPath -Data $closure
    }

    Write-Host ("[AUDIT] Session=" + $SKey)
    Write-Host ("  Total session keys: " + $totalKeys)
    Write-Host ("  Preserved: " + $preservedKeys.Count)
    Write-Host ("  Lost: " + $lostKeys.Count)
    Write-Host ("  Coverage: " + $coverage)

    if ($lostKeys.Count -gt 0) {
        Write-Host "  Lost keys:"
        foreach ($lk in $lostKeys) {
            Write-Host ("    - " + $lk)
        }
    }

    return $auditResult
}

function Invoke-Promote {
    param(
        [string]$ClosureDataPath,
        [string]$FromScope,
        [string]$EntryKey,
        [string]$ToScope
    )

    if (-not $Apply) {
        Write-Host ("[DRY-RUN] Would promote: " + $FromScope + "/" + $EntryKey + " -> " + $ToScope)
        return $true
    }

    $entries = if ((Get-ScopeStoreEntries) -ne $null) { Get-ScopeStoreEntries } else { @() }
    $found = $false
    $entryValue = ""
    foreach ($e in $entries) {
        if ($e.scope -eq $FromScope -and $e.key -eq $EntryKey) {
            $e.scope = $ToScope
            $e.scope_type = "persistent"
            $found = $true
            $entryValue = $e.value
            break
        }
    }

    if (-not $found) {
        Write-Host ("[PROMOTE] Entry not found: scope=" + $FromScope + " key=" + $EntryKey)
        return $false
    }

    Set-ScopeStoreEntries -Entries $entries

    $closure = Read-ClosureData -Path $ClosureDataPath
    $closure.promotions += @{
        from_scope = $FromScope
        to_scope = $ToScope
        key = $EntryKey
        value = $entryValue
        reason = "manual promote"
        created_at = (Get-Date -Format 'o')
    }
    Write-ClosureData -Path $ClosureDataPath -Data $closure

    Write-Host ("[PROMOTE] " + $FromScope + "/" + $EntryKey + " -> " + $ToScope)
    return $true
}

function Invoke-Flush {
    param(
        [string]$ClosureDataPath,
        [string]$SKey
    )

    $closeResult = Invoke-TurnClosure -ClosureDataPath $ClosureDataPath -SKey $SKey
    $auditResult = Invoke-ClosureAudit -ClosureDataPath $ClosureDataPath -SKey $SKey

    if ($Apply -and $auditResult.coverage -ge 0.5) {
        $entries = if ((Get-ScopeStoreEntries) -ne $null) { Get-ScopeStoreEntries } else { @() }
        $preservedKeys = @()
        foreach ($pk in $auditResult.preserved_keys) {
            $preservedKeys += $pk
        }

        $filtered = @()
        $removed = 0
        foreach ($e in $entries) {
            if ($e.scope -eq "session" -and $e.key -like ("*" + $SKey + "*") -and $preservedKeys -contains $e.key) {
                $removed++
            } else {
                $filtered += $e
            }
        }

        Set-ScopeStoreEntries -Entries $filtered
        Write-Host ("[FLUSH] Removed " + $removed + " preserved session entries")
    } elseif ($auditResult.coverage -lt 0.5) {
        Write-Host ("[FLUSH] WARNING: Coverage is low (" + $auditResult.coverage + "). Not removing session entries.")
        Write-Host "[FLUSH] Run -Promote for lost keys first, then -Flush again."
    }

    Write-Host ("[FLUSH] Session=" + $SKey + " Coverage=" + $auditResult.coverage)
    return @{
        close = $closeResult
        audit = $auditResult
    }
}

function Get-ClosureSummary {
    param(
        [string]$ClosureDataPath,
        [string]$SKey
    )

    $closure = Read-ClosureData -Path $ClosureDataPath

    $closureRecord = $null
    foreach ($c in $closure.closures) {
        if ($c.session_key -eq $SKey) {
            $closureRecord = $c
            break
        }
    }

    $latestAudit = $null
    foreach ($a in $closure.audit_results) {
        if ($a.session_key -eq $SKey) {
            $latestAudit = $a
        }
    }

    $sessionPromotions = @()
    if ($closureRecord -ne $null) {
        foreach ($p in $closureRecord.promoted) {
            $sessionPromotions += $p
        }
    }

    Write-Host ("=== Closure Summary: " + $SKey + " ===")

    if ($closureRecord -ne $null) {
        Write-Host ""
        Write-Host "Closure:"
        Write-Host ("  Created: " + $closureRecord.created_at)
        Write-Host ("  Audited: " + $closureRecord.audited)
        Write-Host ("  Promotions: " + $sessionPromotions.Count)
        foreach ($p in $sessionPromotions) {
            Write-Host ("    " + $p.from_scope + "/" + $p.key + " -> " + $p.to_scope + " (" + $p.reason + ")")
        }
    } else {
        Write-Host "  No closure record found."
    }

    if ($latestAudit -ne $null) {
        Write-Host ""
        Write-Host "Audit:"
        Write-Host ("  Coverage: " + $latestAudit.coverage)
        Write-Host ("  Preserved keys: " + $latestAudit.preserved_keys.Count)
        Write-Host ("  Lost keys: " + $latestAudit.lost_keys.Count)
        if ($latestAudit.lost_keys.Count -gt 0) {
            foreach ($lk in $latestAudit.lost_keys) {
                Write-Host ("    - " + $lk)
            }
        }
    } else {
        Write-Host "  No audit record found."
    }

    return @{
        closure = $closureRecord
        audit = $latestAudit
        promotions = $sessionPromotions
    }
}

# --- SelfTest ---

function Invoke-SelfTest {
    $testClosure = Join-Path $env:TEMP "turn-closure-selftest.json"
    $testScopeStore = Join-Path $env:TEMP "turn-closure-selftest-scope.json"
    Remove-Item -LiteralPath $testClosure -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testScopeStore -Force -ErrorAction SilentlyContinue

    $pass = 0
    $fail = 0

    $scopeData = @{
        entries = @(
            @{ id = 'tc01'; scope = 'project'; key = 'rts-gas'; value = 'Use Lyra GAS'; scope_type = 'persistent'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 1; digest = '' }
            @{ id = 'tc02'; scope = 'session'; key = 'task-rt1-config'; value = 'Config A'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 4; digest = '' }
            @{ id = 'tc03'; scope = 'session'; key = 'task-rt1-draft'; value = 'Draft notes'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 1; digest = '' }
            @{ id = 'tc04'; scope = 'session'; key = 'task-rt1-rts-setup'; value = 'Setup done'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 5; digest = '' }
            @{ id = 'tc05'; scope = 'general'; key = 'task-rt1-temp'; value = 'Temp'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 0; digest = '' }
            @{ id = 'tc06'; scope = 'user'; key = 'pref-theme'; value = 'dark'; scope_type = 'persistent'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 2; digest = '' }
            @{ id = 'tc07'; scope = 'session'; key = 'task-rt1-user-name'; value = 'BaBa'; scope_type = 'local'; created_at = '2026-01-01T00:00:00'; updated_at = '2026-01-01T00:00:00'; access_count = 3; digest = '' }
        )
        meta = @{ created_at = '2026-01-01T00:00:00'; version = 1 }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($testScopeStore, ($scopeData | ConvertTo-Json -Depth 10), $utf8NoBom)

    $origRepoRoot = $repoRoot
    $origClosurePath = $ClosurePath
    $origScopeStoreOverride = $scopeStoreOverride
    $script:repoRoot = $env:TEMP
    $script:ClosurePath = $testClosure
    $script:scopeStoreOverride = $testScopeStore

    # Test 1: Init
    try {
        $r = Initialize-Closure -Path $testClosure
        if ($r) { $pass++; Write-Host "[PASS] Init" } else { $fail++; Write-Host "[FAIL] Init" }
    } catch {
        $fail++; Write-Host ("[FAIL] Init - exception: " + $_)
    }

    # Test 2: Turn Closure - auto-promote high-access entries
    try {
        $script:Apply = $true
        $result = Invoke-TurnClosure -ClosureDataPath $testClosure -SKey "rt1"
        if ($result.promoted -ge 2 -and $result.session_entries -ge 3) {
            $pass++; Write-Host "[PASS] TurnClosure auto-promote"
        } else {
            $fail++; Write-Host ("[FAIL] TurnClosure - promoted=" + $result.promoted + " entries=" + $result.session_entries)
        }
    } catch {
        $fail++; Write-Host ("[FAIL] TurnClosure - exception: " + $_)
    }

    # Test 3: Key prefix-based scope targeting (rts-* -> project)
    try {
        $closure = Read-ClosureData -Path $testClosure
        $hasProjectPromote = $false
        foreach ($c in $closure.closures) {
            foreach ($p in $c.promoted) {
                if ($p.to_scope -eq "project") { $hasProjectPromote = $true }
            }
        }
        if ($hasProjectPromote) {
            $pass++; Write-Host "[PASS] Key prefix scope targeting"
        } else {
            $fail++; Write-Host "[FAIL] Key prefix scope targeting - no project promotion found"
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Key prefix - exception: " + $_)
    }

    # Test 4: Audit - detect lost keys
    try {
        $auditResult = Invoke-ClosureAudit -ClosureDataPath $testClosure -SKey "rt1"
        if ($auditResult.coverage -ge 0 -and $auditResult.coverage -le 1) {
            $pass++; Write-Host ("[PASS] Audit coverage=" + $auditResult.coverage)
        } else {
            $fail++; Write-Host ("[FAIL] Audit - coverage=" + $auditResult.coverage)
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Audit - exception: " + $_)
    }

    # Test 5: Manual promote
    try {
        [System.IO.File]::WriteAllText($testScopeStore, ($scopeData | ConvertTo-Json -Depth 10), $utf8NoBom)
        $r = Invoke-Promote -ClosureDataPath $testClosure -FromScope "session" -EntryKey "task-rt1-draft" -ToScope "memory"
        if ($r) {
            $pass++; Write-Host "[PASS] Manual promote"
        } else {
            $fail++; Write-Host "[FAIL] Manual promote"
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Manual promote - exception: " + $_)
    }

    # Test 6: Closure summary
    try {
        $summary = Get-ClosureSummary -ClosureDataPath $testClosure -SKey "rt1"
        if ($summary.closure -ne $null -and $summary.audit -ne $null) {
            $pass++; Write-Host "[PASS] Closure summary"
        } else {
            $fail++; Write-Host "[FAIL] Closure summary - missing data"
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Closure summary - exception: " + $_)
    }

    # Test 7: Flush preserves coverage check
    try {
        [System.IO.File]::WriteAllText($testScopeStore, ($scopeData | ConvertTo-Json -Depth 10), $utf8NoBom)
        $result = Invoke-Flush -ClosureDataPath $testClosure -SKey "rt1"
        if ($result.close -ne $null -and $result.audit -ne $null) {
            $pass++; Write-Host "[PASS] Flush"
        } else {
            $fail++; Write-Host "[FAIL] Flush - missing results"
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Flush - exception: " + $_)
    }

    # Test 8: Promotion scope mapping correctness
    try {
        $closure = Read-ClosureData -Path $testClosure
        $hasRtsProject = $false
        foreach ($c in $closure.closures) {
            foreach ($p in $c.promoted) {
                if ($p.key -like "*rts-*" -and $p.to_scope -eq "project") {
                    $hasRtsProject = $true
                }
            }
        }
        if ($hasRtsProject) {
            $pass++; Write-Host "[PASS] Scope mapping correctness"
        } else {
            $fail++; Write-Host "[FAIL] Scope mapping correctness"
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Scope mapping - exception: " + $_)
    }

    # Test 9: Non-existent session returns graceful result
    try {
        $result = Invoke-TurnClosure -ClosureDataPath $testClosure -SKey "nonexistent"
        if ($result.session_entries -eq 0 -and $result.promoted -eq 0) {
            $pass++; Write-Host "[PASS] Non-existent session"
        } else {
            $fail++; Write-Host ("[FAIL] Non-existent session - entries=" + $result.session_entries)
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Non-existent session - exception: " + $_)
    }

    # Test 10: Idempotent close
    try {
        [System.IO.File]::WriteAllText($testScopeStore, ($scopeData | ConvertTo-Json -Depth 10), $utf8NoBom)
        $result1 = Invoke-TurnClosure -ClosureDataPath $testClosure -SKey "rt1"
        $result2 = Invoke-TurnClosure -ClosureDataPath $testClosure -SKey "rt1"
        $closure = Read-ClosureData -Path $testClosure
        $count = 0
        foreach ($c in $closure.closures) {
            if ($c.session_key -eq "rt1") { $count++ }
        }
        if ($count -eq 1) {
            $pass++; Write-Host "[PASS] Idempotent close"
        } else {
            $fail++; Write-Host ("[FAIL] Idempotent close - count=" + $count)
        }
    } catch {
        $fail++; Write-Host ("[FAIL] Idempotent close - exception: " + $_)
    }

    $script:repoRoot = $origRepoRoot
    $script:ClosurePath = $origClosurePath
    $script:scopeStoreOverride = $origScopeStoreOverride

    Remove-Item -LiteralPath $testClosure -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testScopeStore -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host ("=== SelfTest Results: " + $pass + " passed, " + $fail + " failed ===")
    return ($fail -eq 0)
}

# --- Main Dispatch ---

if ($SelfTest) {
    $result = Invoke-SelfTest
    if (-not $result) { exit 1 }
    exit 0
}

if ($Init) {
    $result = Initialize-Closure -Path $ClosurePath
    if (-not $result) { exit 1 }
    exit 0
}

if ($Close) {
    if (-not $SessionKey) {
        Write-Host "ERROR: -Close requires -SessionKey" -ForegroundColor Red
        exit 1
    }
    $result = Invoke-TurnClosure -ClosureDataPath $ClosurePath -SKey $SessionKey
    exit 0
}

if ($Audit) {
    if (-not $SessionKey) {
        Write-Host "ERROR: -Audit requires -SessionKey" -ForegroundColor Red
        exit 1
    }
    $result = Invoke-ClosureAudit -ClosureDataPath $ClosurePath -SKey $SessionKey
    exit 0
}

if ($Promote) {
    if (-not $Scope -or -not $Key -or -not $TargetScope) {
        Write-Host "ERROR: -Promote requires -Scope, -Key, and -TargetScope" -ForegroundColor Red
        exit 1
    }
    $result = Invoke-Promote -ClosureDataPath $ClosurePath -FromScope $Scope -EntryKey $Key -ToScope $TargetScope
    if (-not $result) { exit 1 }
    exit 0
}

if ($Flush) {
    if (-not $SessionKey) {
        Write-Host "ERROR: -Flush requires -SessionKey" -ForegroundColor Red
        exit 1
    }
    $result = Invoke-Flush -ClosureDataPath $ClosurePath -SKey $SessionKey
    exit 0
}

if ($Summary) {
    if (-not $SessionKey) {
        Write-Host "ERROR: -Summary requires -SessionKey" -ForegroundColor Red
        exit 1
    }
    $result = Get-ClosureSummary -ClosureDataPath $ClosurePath -SKey $SessionKey
    exit 0
}

Write-Host "ERROR: No action specified. Use -Init, -Close, -Audit, -Promote, -Flush, -Summary, or -SelfTest" -ForegroundColor Red
exit 1



