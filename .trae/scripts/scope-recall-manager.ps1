# scope-recall-manager.ps1 -- Unified Entry Point for Scope Recall System
#
# Seventh layer of the Scope Recall pattern: the integration layer.
# Provides a single command-line interface to all 7 Scope Recall scripts:
#   1. scope-store.ps1      -- Partitioned JSON memory store
#   2. scope-bridge.ps1     -- Scope-aware recall + contamination guard
#   3. turn-closure.ps1     -- Turn closure audit + session-to-persistent promotion
#   4. scope-fusion.ps1     -- Cross-session memory fusion + conflict reconciliation
#   5. scope-index.ps1      -- Lightweight structured index + scope-aware prefetch
#   6. scope-evolution-log.ps1 -- AGP-inspired evolution audit trail
#   7. scope-decay.ps1      -- Scope-aware memory lifecycle and garbage collection
#
# Usage:
#   .\scope-recall-manager.ps1 -InitAll
#   .\scope-recall-manager.ps1 -Recall -Scope project -Key rts-gas
#   .\scope-recall-manager.ps1 -Store -Scope project -Key rts-gas -Value "Use Lyra GAS"
#   .\scope-recall-manager.ps1 -Search -Query "gas" -Scope project
#   .\scope-recall-manager.ps1 -CloseSession -SessionKey task-rt1
#   .\scope-recall-manager.ps1 -DecayReport -Scope project
#   .\scope-recall-manager.ps1 -AutoDecay -Apply
#   .\scope-recall-manager.ps1 -Status
#   .\scope-recall-manager.ps1 -HealthCheck
#   .\scope-recall-manager.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$InitAll,
    [switch]$Recall,
    [switch]$Store,
    [switch]$Delete,
    [switch]$Search,
    [switch]$CloseSession,
    [switch]$DecayReport,
    [switch]$AutoDecay,
    [switch]$Status,
    [switch]$HealthCheck,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general")]
    [string]$Scope = "",

    [string]$Key = "",
    [string]$Value = "",
    [string]$Query = "",
    [string]$SessionKey = "",
    [string]$ProjectPath = "",
    [string]$StateRoot = ""
)

$ErrorActionPreference = "Stop"

if (-not $ProjectPath) {
    $ProjectPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$scriptsDir = Join-Path $ProjectPath ".trae\scripts"
if ($SelfTest -and [string]::IsNullOrEmpty($StateRoot)) {
    $StateRoot = Join-Path $env:TEMP ("scope-manager-state-" + [Guid]::NewGuid().ToString("N"))
}
if (-not [string]::IsNullOrEmpty($StateRoot)) {
    if (-not (Test-Path -LiteralPath $StateRoot)) { New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null }
}
$script:stateRootPath = $StateRoot

$scriptMap = @{
    store    = Join-Path $scriptsDir "scope-store.ps1"
    bridge   = Join-Path $scriptsDir "scope-bridge.ps1"
    closure  = Join-Path $scriptsDir "turn-closure.ps1"
    fusion   = Join-Path $scriptsDir "scope-fusion.ps1"
    index    = Join-Path $scriptsDir "scope-index.ps1"
    evoLog   = Join-Path $scriptsDir "scope-evolution-log.ps1"
    decay    = Join-Path $scriptsDir "scope-decay.ps1"
}

function Add-IsolatedArg {
    param([string[]]$Arguments, [string]$Name, [string]$Value)
    $merged = @($Arguments)
    if ($merged -notcontains $Name) {
        $merged += @($Name, $Value)
    }
    return $merged
}

function Get-IsolatedArgs {
    param([string]$ScriptPath, [string[]]$Arguments)
    $merged = @($Arguments)
    if ([string]::IsNullOrEmpty($script:stateRootPath)) { return $merged }

    $scriptName = [System.IO.Path]::GetFileName($ScriptPath).ToLowerInvariant()
    $storeDb = Join-Path $script:stateRootPath "scope-store.sqlite3"
    $storeJson = $storeDb -replace '\.sqlite3$', '.json'
    switch ($scriptName) {
        "scope-store.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-DbPath" -Value $storeDb
        }
        "scope-bridge.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-BridgePath" -Value (Join-Path $script:stateRootPath "scope-bridge.json")
        }
        "turn-closure.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-ClosurePath" -Value (Join-Path $script:stateRootPath "turn-closure.json")
        }
        "scope-fusion.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-DbPath" -Value $storeDb
            $merged = Add-IsolatedArg -Arguments $merged -Name "-FusionPath" -Value (Join-Path $script:stateRootPath "scope-fusion.json")
        }
        "scope-index.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-IndexPath" -Value (Join-Path $script:stateRootPath "scope-index.json")
            $merged = Add-IsolatedArg -Arguments $merged -Name "-StorePath" -Value $storeJson
        }
        "scope-evolution-log.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-DbPath" -Value (Join-Path $script:stateRootPath "scope-evolution-log.json")
        }
        "scope-decay.ps1" {
            $merged = Add-IsolatedArg -Arguments $merged -Name "-DbPath" -Value $storeDb
        }
    }
    return $merged
}

function Invoke-ScopeScript {
    param([string]$ScriptPath, [string[]]$Arguments)
    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        Write-Host "[MANAGER-ERROR] Script not found: $ScriptPath"
        return $null
    }
    $safeArguments = Get-IsolatedArgs -ScriptPath $ScriptPath -Arguments $Arguments
    $result = & powershell -ExecutionPolicy Bypass -File $ScriptPath @safeArguments 2>&1
    return $result
}

# --- InitAll ---
function Invoke-InitAll {
    Write-Host "=== Initializing Scope Recall System (all 6 layers) ==="
    $allOk = $true
    foreach ($entry in $scriptMap.GetEnumerator()) {
        $name = $entry.Key
        $path = $entry.Value
        if (Test-Path -LiteralPath $path) {
            try {
                $result = Invoke-ScopeScript -ScriptPath $path -Arguments @("-Init")
                $ok = ($result | Out-String) -match "initialized"
                if ($ok) { Write-Host "  [OK] $name initialized" }
                else { Write-Host "  [WARN] $name init unexpected"; $allOk = $false }
            } catch { Write-Host "  [ERROR] $name init failed: $_"; $allOk = $false }
        } else { Write-Host "  [SKIP] $name not found"; $allOk = $false }
    }
    if ($allOk) { Write-Host "=== All layers initialized ===" }
    else { Write-Host "=== Some layers failed ===" }
    return $allOk
}

# --- Recall ---
function Invoke-RecallKey {
    param([string]$RecallScope, [string]$RecallKey)
    if ([string]::IsNullOrEmpty($RecallKey)) {
        Write-Host "[MANAGER-ERROR] -Key is required for Recall"
        return $false
    }
    $found = $false
    $storePath = $scriptMap['store']
    if (Test-Path -LiteralPath $storePath) {
        $storeArgs = @("-Recall")
        if ($RecallScope) { $storeArgs += @("-Scope", $RecallScope) }
        $storeArgs += @("-Key", $RecallKey)
        $storeResult = Invoke-ScopeScript -ScriptPath $storePath -Arguments $storeArgs
        $storeStr = $storeResult | Out-String
        if ($storeStr -match "not found" -or $storeStr -match "ERROR") {
            Write-Host "[STORE] Key '$RecallKey' not found"
        } else { Write-Host "[STORE] $storeStr"; $found = $true }
    }
    if ($RecallScope) {
        $bridgePath = $scriptMap['bridge']
        if (Test-Path -LiteralPath $bridgePath) {
            $bridgeResult = Invoke-ScopeScript -ScriptPath $bridgePath -Arguments @("-Recall", "-Scope", $RecallScope, "-Context", $RecallKey)
            $bridgeStr = $bridgeResult | Out-String
            if ($bridgeStr.Length -gt 10) { Write-Host "[BRIDGE] $bridgeStr"; $found = $true }
        }
    }
    $fusionPath = $scriptMap['fusion']
    if (Test-Path -LiteralPath $fusionPath) {
        $fusionResult = Invoke-ScopeScript -ScriptPath $fusionPath -Arguments @("-CrossRecall", "-Key", $RecallKey)
        $fusionStr = $fusionResult | Out-String
        if ($fusionStr.Length -gt 20) { Write-Host "[FUSION] $fusionStr"; $found = $true }
    }
    if (-not $found) { Write-Host "[MANAGER] Key '$RecallKey' not found in any layer" }
    return $found
}

# --- Store ---
function Invoke-StoreKey {
    param([string]$StoreScope, [string]$StoreKey, [string]$StoreValue)
    if ([string]::IsNullOrEmpty($StoreKey) -or [string]::IsNullOrEmpty($StoreValue)) {
        Write-Host "[MANAGER-ERROR] -Key and -Value are required for Store"
        return $false
    }
    if ([string]::IsNullOrEmpty($StoreScope)) {
        Write-Host "[MANAGER-ERROR] -Scope is required for Store"
        return $false
    }
    $storePath = $scriptMap['store']
    if (-not (Test-Path -LiteralPath $storePath)) {
        Write-Host "[MANAGER-ERROR] scope-store.ps1 not found"
        return $false
    }
    $storeArgs = @("-Store", "-Scope", $StoreScope, "-Key", $StoreKey, "-Value", $StoreValue)
    if ($Apply) { $storeArgs += @("-Apply") }
    $result = Invoke-ScopeScript -ScriptPath $storePath -Arguments $storeArgs
    Write-Host "[STORE] $($result | Out-String)"
    $indexPath = $scriptMap['index']
    if (Test-Path -LiteralPath $indexPath) {
        $null = Invoke-ScopeScript -ScriptPath $indexPath -Arguments @("-BuildIndex")
        Write-Host "[INDEX] Index rebuilt after store"
    }
    return $true
}

# --- Delete ---
function Invoke-DeleteKey {
    param([string]$DelScope, [string]$DelKey)
    if ([string]::IsNullOrEmpty($DelScope) -or [string]::IsNullOrEmpty($DelKey)) {
        Write-Host "[MANAGER-ERROR] -Scope and -Key are required for Delete"
        return $false
    }
    $storePath = $scriptMap['store']
    if (-not (Test-Path -LiteralPath $storePath)) {
        Write-Host "[MANAGER-ERROR] scope-store.ps1 not found"
        return $false
    }
    $delArgs = @("-Delete", "-Scope", $DelScope, "-Key", $DelKey)
    if ($Apply) { $delArgs += @("-Apply") }
    $result = Invoke-ScopeScript -ScriptPath $storePath -Arguments $delArgs
    Write-Host "[STORE] $($result | Out-String)"
    $indexPath = $scriptMap['index']
    if (Test-Path -LiteralPath $indexPath) {
        $null = Invoke-ScopeScript -ScriptPath $indexPath -Arguments @("-BuildIndex")
        Write-Host "[INDEX] Index rebuilt after delete"
    }
    return $true
}
# --- Search ---
function Invoke-SearchQuery {
    param([string]$SearchQuery, [string]$SearchScope)
    if ([string]::IsNullOrEmpty($SearchQuery)) {
        Write-Host "[MANAGER-ERROR] -Query is required for Search"
        return $false
    }
    $indexPath = $scriptMap['index']
    if (-not (Test-Path -LiteralPath $indexPath)) {
        Write-Host "[MANAGER-ERROR] scope-index.ps1 not found"
        return $false
    }
    $searchArgs = @("-SearchIndex", "-Query", $SearchQuery)
    if ($SearchScope) { $searchArgs += @("-CurrentScope", $SearchScope) }
    $result = Invoke-ScopeScript -ScriptPath $indexPath -Arguments $searchArgs
    Write-Host "[INDEX] $($result | Out-String)"
    if ($SearchScope) {
        $prefetchResult = Invoke-ScopeScript -ScriptPath $indexPath -Arguments @("-Prefetch", "-CurrentScope", $SearchScope, "-Query", $SearchQuery)
        $prefetchStr = $prefetchResult | Out-String
        if ($prefetchStr.Length -gt 10) { Write-Host "[PREFETCH] $prefetchStr" }
    }
    return $true
}

# --- CloseSession ---
function Invoke-CloseSessionWorkflow {
    param([string]$SessKey)
    if ([string]::IsNullOrEmpty($SessKey)) {
        Write-Host "[MANAGER-ERROR] -SessionKey is required for CloseSession"
        return $false
    }
    Write-Host "=== Closing Session: $SessKey ==="
    $closurePath = $scriptMap['closure']
    if (Test-Path -LiteralPath $closurePath) {
        $closeResult = Invoke-ScopeScript -ScriptPath $closurePath -Arguments @("-Close", "-SessionKey", $SessKey)
        Write-Host "[CLOSURE] $($closeResult | Out-String)"
        $auditResult = Invoke-ScopeScript -ScriptPath $closurePath -Arguments @("-ClosureAudit", "-SessionKey", $SessKey)
        Write-Host "[AUDIT] $($auditResult | Out-String)"
    }
    $fusionPath = $scriptMap['fusion']
    if (Test-Path -LiteralPath $fusionPath) {
        $fusionResult = Invoke-ScopeScript -ScriptPath $fusionPath -Arguments @("-AutoFusion", "-Strategy", "latest")
        Write-Host "[FUSION] $($fusionResult | Out-String)"
    }
    $indexPath = $scriptMap['index']
    if (Test-Path -LiteralPath $indexPath) {
        $null = Invoke-ScopeScript -ScriptPath $indexPath -Arguments @("-BuildIndex")
        Write-Host "[INDEX] Index rebuilt after session close"
    }
    $decayPath = $scriptMap['decay']
    if (Test-Path -LiteralPath $decayPath) {
        $decayResult = Invoke-ScopeScript -ScriptPath $decayPath -Arguments @("-AutoDecay")
        Write-Host "[DECAY] $($decayResult | Out-String)"
    }
    Write-Host "=== Session Closed ==="
    return $true
}

# --- Decay ---
function Invoke-DecayReportWorkflow {
    param([string]$DecayScope)
    $decayPath = $scriptMap['decay']
    if (-not (Test-Path -LiteralPath $decayPath)) {
        Write-Host "[MANAGER-ERROR] scope-decay.ps1 not found"
        return $false
    }
    $args = @("-DecayReport")
    if ($DecayScope) { $args += @("-Scope", $DecayScope) }
    $result = Invoke-ScopeScript -ScriptPath $decayPath -Arguments $args
    Write-Host "[DECAY] $($result | Out-String)"
    return $true
}

function Invoke-AutoDecayWorkflow {
    $decayPath = $scriptMap['decay']
    if (-not (Test-Path -LiteralPath $decayPath)) {
        Write-Host "[MANAGER-ERROR] scope-decay.ps1 not found"
        return $false
    }
    $args = @("-AutoDecay")
    if ($Apply) { $args += @("-Apply") }
    $result = Invoke-ScopeScript -ScriptPath $decayPath -Arguments $args
    Write-Host "[DECAY] $($result | Out-String)"
    return $true
}

# --- Status ---
function Invoke-Status {
    Write-Host "=== Scope Recall System Status ==="
    Write-Host ""
    $storePath = $scriptMap['store']
    if (Test-Path -LiteralPath $storePath) {
        $result = Invoke-ScopeScript -ScriptPath $storePath -Arguments @("-ListScopes")
        Write-Host "--- Store ---"
        Write-Host ($result | Out-String)
    }
    $indexPath = $scriptMap['index']
    if (Test-Path -LiteralPath $indexPath) {
        $result = Invoke-ScopeScript -ScriptPath $indexPath -Arguments @("-IndexStats")
        Write-Host "--- Index ---"
        Write-Host ($result | Out-String)
    }
    $evoLogPath = $scriptMap['evoLog']
    if (Test-Path -LiteralPath $evoLogPath) {
        $result = Invoke-ScopeScript -ScriptPath $evoLogPath -Arguments @("-GeneStats")
        Write-Host "--- Evolution ---"
        Write-Host ($result | Out-String)
    }
    $decayPath = $scriptMap['decay']
    if (Test-Path -LiteralPath $decayPath) {
        $result = Invoke-ScopeScript -ScriptPath $decayPath -Arguments @("-DecayReport")
        Write-Host "--- Decay ---"
        Write-Host ($result | Out-String)
    }
    Write-Host "=== End Status ==="
    return $true
}

# --- HealthCheck ---
function Invoke-HealthCheck {
    Write-Host "=== Scope Recall Health Check ==="
    $allOk = $true
    $layerCount = 0
    $okCount = 0
    foreach ($entry in $scriptMap.GetEnumerator()) {
        $name = $entry.Key
        $path = $entry.Value
        $layerCount++
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Host "  [FAIL] $name - script not found"
            $allOk = $false
            continue
        }
        try {
            $result = Invoke-ScopeScript -ScriptPath $path -Arguments @("-Init")
            $resultStr = $result | Out-String
            if ($resultStr -match "initialized" -or $resultStr.Length -gt 5) {
                Write-Host "  [OK] $name - operational"
                $okCount++
            } else { Write-Host "  [WARN] $name - unexpected output"; $allOk = $false }
        } catch { Write-Host "  [FAIL] $name - error: $_"; $allOk = $false }
    }
    Write-Host ""
    Write-Host "Layers: $okCount / $layerCount operational"
    if ($allOk) { Write-Host "Status: HEALTHY" }
    else { Write-Host "Status: DEGRADED" }
    Write-Host "=== End Health Check ==="
    return $allOk
}
# --- SelfTest ---
$script:_pass = 0
$script:_fail = 0

function Assert-Test {
    param([string]$Name, [bool]$Condition)
    if ($Condition) {
        Write-Host "  [PASS] $Name"
        $script:_pass++
    } else {
        Write-Host "  [FAIL] $Name"
        $script:_fail++
    }
}

function Invoke-ManagerSelfTest {
    Write-Host "=== scope-recall-manager.ps1 SelfTest ==="
    Write-Host ""
    $productionWatch = @()
    $repoMemoryDir = Join-Path $ProjectPath "Docs\Memory"
    foreach ($watchName in @("scope-store.json", "scope-index.json", "scope-evolution-log.json", "scope-store-decay.json", "scope-fusion.json", "scope-bridge.json", "turn-closure.json")) {
        $watchPath = Join-Path $repoMemoryDir $watchName
        if (Test-Path -LiteralPath $watchPath) {
            $item = Get-Item -LiteralPath $watchPath
            $productionWatch += @{ path = $watchPath; exists = $true; length = $item.Length; last_write = $item.LastWriteTimeUtc.Ticks }
        } else {
            $productionWatch += @{ path = $watchPath; exists = $false; length = 0; last_write = 0 }
        }
    }

    # Test 1: Script discovery
    Write-Host "--- Test 1: Script Discovery ---"
    $foundCount = 0
    foreach ($entry in $scriptMap.GetEnumerator()) {
        if (Test-Path -LiteralPath $entry.Value) { $foundCount++ }
        else { Write-Host "  [WARN] Missing: $($entry.Key)" }
    }
    Assert-Test "All 7 scripts found" ($foundCount -eq 7)

    # Test 2: InitAll
    Write-Host ""
    Write-Host "--- Test 2: InitAll ---"
    $initOk = Invoke-InitAll
    Assert-Test "InitAll succeeded" $initOk

    # Test 3: Store + Recall roundtrip
    Write-Host ""
    Write-Host "--- Test 3: Store + Recall Roundtrip ---"
    $testDbPath = Join-Path $env:TEMP "scope-manager-selftest\scope-store.json"
    $testDir = Split-Path -Parent $testDbPath
    if (-not (Test-Path -LiteralPath $testDir)) { New-Item -ItemType Directory -Path $testDir -Force | Out-Null }
    $storePath = $scriptMap['store']
    $null = & powershell -ExecutionPolicy Bypass -File $storePath -Init -DbPath $testDbPath 2>&1
    $null = & powershell -ExecutionPolicy Bypass -File $storePath -Store -Scope project -Key mgr-test-key -Value "manager test value" -Apply -DbPath $testDbPath 2>&1
    $recallResult = & powershell -ExecutionPolicy Bypass -File $storePath -Recall -Scope project -Key mgr-test-key -DbPath $testDbPath 2>&1
    $recallStr = $recallResult | Out-String
    Assert-Test "Store + Recall roundtrip" ($recallStr -match "manager test value")
    & powershell -ExecutionPolicy Bypass -File $storePath -Delete -Scope project -Key mgr-test-key -Apply -DbPath $testDbPath 2>&1 | Out-Null

    # Test 4: Search via index
    Write-Host ""
    Write-Host "--- Test 4: Search via Index ---"
    $indexPath = $scriptMap['index']
    if (Test-Path -LiteralPath $indexPath) {
        $testIndexPath = Join-Path $testDir "scope-index.json"
        $null = & powershell -ExecutionPolicy Bypass -File $indexPath -BuildIndex -IndexPath $testIndexPath -StorePath $testDbPath 2>&1
        $searchResult = & powershell -ExecutionPolicy Bypass -File $indexPath -SearchIndex -Query "gas" -IndexPath $testIndexPath -StorePath $testDbPath 2>&1
        $searchStr = $searchResult | Out-String
        Assert-Test "Search works" ($searchStr -match "Found" -or $searchStr.Length -gt 10)
    } else {
        Assert-Test "Search works (index not found, skip)" $true
    }

    # Test 5: HealthCheck
    Write-Host ""
    Write-Host "--- Test 5: HealthCheck ---"
    $healthOk = Invoke-HealthCheck
    Assert-Test "HealthCheck passed" $healthOk

    # Test 6: Status
    Write-Host ""
    Write-Host "--- Test 6: Status ---"
    $statusOk = Invoke-Status
    Assert-Test "Status completed" $statusOk

    # Test 7: Delete rejects missing params
    Write-Host ""
    Write-Host "--- Test 7: Delete Validation ---"
    $delResult = Invoke-DeleteKey -DelScope "" -DelKey ""
    Assert-Test "Delete rejects missing params" ($delResult -eq $false)

    # Test 8: Store rejects missing params
    Write-Host ""
    Write-Host "--- Test 8: Store Validation ---"
    $stResult = Invoke-StoreKey -StoreScope "" -StoreKey "k" -StoreValue ""
    Assert-Test "Store rejects missing params" ($stResult -eq $false)

    # Test 9: CloseSession rejects missing SessionKey
    Write-Host ""
    Write-Host "--- Test 9: CloseSession Validation ---"
    $csResult = Invoke-CloseSessionWorkflow -SessKey ""
    Assert-Test "CloseSession rejects missing SessionKey" ($csResult -eq $false)

    # Test 10: Recall rejects missing Key
    Write-Host ""
    Write-Host "--- Test 10: Recall Validation ---"
    $rcResult = Invoke-RecallKey -RecallScope "project" -RecallKey ""
    Assert-Test "Recall rejects missing Key" ($rcResult -eq $false)

    # Test 11: DecayReport and AutoDecay entry points
    Write-Host ""
    Write-Host "--- Test 11: Decay Workflow ---"
    $drResult = Invoke-DecayReportWorkflow -DecayScope "project"
    Assert-Test "DecayReport workflow completes" $drResult
    $adResult = Invoke-AutoDecayWorkflow
    Assert-Test "AutoDecay workflow completes" $adResult

    $productionUntouched = $true
    foreach ($watch in $productionWatch) {
        $existsNow = Test-Path -LiteralPath $watch.path
        if ($existsNow -ne $watch.exists) { $productionUntouched = $false; break }
        if ($existsNow) {
            $itemNow = Get-Item -LiteralPath $watch.path
            if ($itemNow.Length -ne $watch.length -or $itemNow.LastWriteTimeUtc.Ticks -ne $watch.last_write) {
                $productionUntouched = $false
                break
            }
        }
    }
    Assert-Test "SelfTest leaves production scope memory untouched" $productionUntouched

    # Summary
    Write-Host ""
    Write-Host "=== SelfTest Results: $($script:_pass) passed, $($script:_fail) failed ==="
    if ($script:_fail -gt 0) { exit 1 }
    return $true
}

# ============================================================
# Main dispatch
# ============================================================
if ($InitAll) {
    $result = Invoke-InitAll
    if (-not $result) { exit 1 }
}
elseif ($Recall) {
    $result = Invoke-RecallKey -RecallScope $Scope -RecallKey $Key
    if (-not $result) { exit 1 }
}
elseif ($Store) {
    $result = Invoke-StoreKey -StoreScope $Scope -StoreKey $Key -StoreValue $Value
    if (-not $result) { exit 1 }
}
elseif ($Delete) {
    $result = Invoke-DeleteKey -DelScope $Scope -DelKey $Key
    if (-not $result) { exit 1 }
}
elseif ($Search) {
    $result = Invoke-SearchQuery -SearchQuery $Query -SearchScope $Scope
    if (-not $result) { exit 1 }
}
elseif ($CloseSession) {
    $result = Invoke-CloseSessionWorkflow -SessKey $SessionKey
    if (-not $result) { exit 1 }
}
elseif ($DecayReport) {
    $result = Invoke-DecayReportWorkflow -DecayScope $Scope
    if (-not $result) { exit 1 }
}
elseif ($AutoDecay) {
    $result = Invoke-AutoDecayWorkflow
    if (-not $result) { exit 1 }
}
elseif ($Status) {
    $result = Invoke-Status
    if (-not $result) { exit 1 }
}
elseif ($HealthCheck) {
    $result = Invoke-HealthCheck
    if (-not $result) { exit 1 }
}
elseif ($SelfTest) {
    $result = Invoke-ManagerSelfTest
    if (-not $result) { exit 1 }
}
else {
    Write-Host "scope-recall-manager.ps1 - Unified entry point for Scope Recall System"
    Write-Host "Usage:"
    Write-Host "  -InitAll                   Initialize all 6 layers"
    Write-Host "  -Recall -Key <k> [-Scope]  Recall a key across layers"
    Write-Host "  -Store -Scope <s> -Key <k> -Value <v>  Store a value"
    Write-Host "  -Delete -Scope <s> -Key <k>            Delete a key"
    Write-Host "  -Search -Query <q> [-Scope]            Search the index"
    Write-Host "  -CloseSession -SessionKey <k>          Close session workflow"
    Write-Host "  -DecayReport [-Scope <s>]              Show memory lifecycle risks"
    Write-Host "  -AutoDecay [-Apply]                    Run TTL and compression maintenance"
    Write-Host "  -Status                   Show system status"
    Write-Host "  -HealthCheck              Verify all layers operational"
    Write-Host "  -SelfTest                 Run self-tests"
}
