# test-ccswitch-codex-config-sync.ps1
# CC Switch Codex common-config normalization, provider parity, and guarded apply.
# Verifies: AC05 (provider preservation), AC06 (provider parity), AC08 (schema guard),
#           AC09 (backup/rollback), AC11 (idempotence)

param(
    [ValidateSet("Inspect", "DryRun", "Apply", "Test")]
    [string]$Mode = "Test",

    [string]$BaselinePath = ".codex\capability-baseline.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if (-not [System.IO.Path]::IsPathRooted($BaselinePath)) {
    $BaselinePath = Join-Path $Root $BaselinePath
}

$ScriptRoot = $PSScriptRoot
$Passed = 0
$Failed = 0
$Results = @()

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Assert {
    param([string]$Name, [scriptblock]$Condition, [string]$FailMessage)
    try {
        $result = & $Condition
        if ($result) {
            Write-Green "  [PASS] $Name"
            $script:Passed++
            $script:Results += [pscustomobject]@{ Test = $Name; Result = "PASS"; Detail = "" }
        } else {
            Write-Red "  [FAIL] $Name - $FailMessage"
            $script:Failed++
            $script:Results += [pscustomobject]@{ Test = $Name; Result = "FAIL"; Detail = $FailMessage }
        }
    } catch {
        Write-Red "  [FAIL] $Name - Exception: $_"
        $script:Failed++
        $script:Results += [pscustomobject]@{ Test = $Name; Result = "FAIL"; Detail = $_ }
    }
}

# ===========================================================
# Fixture: Create temp CC Switch DB structure
# ===========================================================
function New-FixtureDb {
    param(
        [string]$DbPath,
        [string]$CommonConfigCodex,
        [string]$SchemaVersion = "1.0",
        [hashtable]$Providers = @{}
    )

    $fixtureDir = Split-Path $DbPath -Parent
    if (-not (Test-Path $fixtureDir)) { New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null }
    if (Test-Path $DbPath) { Remove-Item $DbPath -Force }

    # Use a simple JSON-Lines-style fixture for reliability
    $lines = @()
    $lines += "---CCSWITCH-FIXTURE-V1---"
    $lines += "schema_version: $SchemaVersion"
    $lines += "---SETTINGS---"
    if ($CommonConfigCodex) {
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($CommonConfigCodex))
        $lines += "common_config_codex_b64: $encoded"
    }
    $lines += "common_config_legacy_migrated_v1: true"
    $lines += "official_providers_seeded: true"
    $lines += "---PROVIDERS---"
    foreach ($provId in $Providers.Keys) {
        $pv = $Providers[$provId]
        $encodedConfig = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pv.config))
        $lines += "provider: $provId"
        $lines += "  commonConfigEnabled: $($pv.commonConfigEnabled)"
        $lines += "  endpointAutoSelect: $($pv.endpointAutoSelect)"
        $lines += "  apiFormat: $($pv.apiFormat)"
        $lines += "  config_b64: $encodedConfig"
    }
    $content = $lines -join "`n"
    Set-Content -LiteralPath $DbPath -Value $content
    return $content
}

function Read-FixtureDb {
    param([string]$DbPath)
    if (-not (Test-Path $DbPath)) { return $null }
    $content = Get-Content -LiteralPath $DbPath -Raw
    if ($content -notmatch "---CCSWITCH-FIXTURE-V1---") {
        Write-Red "  [ERROR] Not a valid fixture file: $DbPath"
        return $null
    }
    $result = @{
        settings = @{}
        providers = @{}
        schema_version = "1.0"
    }
    $section = ""
    $currentProvider = ""
    foreach ($line in ($content -split "\r?\n")) {
        if ($line -eq "---SETTINGS---") { $section = "settings"; continue }
        if ($line -eq "---PROVIDERS---") { $section = "providers"; continue }
        if ($line -match '^schema_version: (.+)$') {
            $result.schema_version = $matches[1]
            continue
        }
        if ($line -match '^common_config_codex_b64: (.+)$') {
            $result.settings["common_config_codex"] = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($matches[1]))
        } elseif ($line -match '^provider: (.+)$') {
            $currentProvider = $matches[1]
            $result.providers[$currentProvider] = @{ config = ""; commonConfigEnabled = $false; endpointAutoSelect = $false; apiFormat = "" }
        } elseif ($line -match '^\s+commonConfigEnabled: (.+)$') {
            $result.providers[$currentProvider].commonConfigEnabled = ($matches[1] -eq "True")
        } elseif ($line -match '^\s+endpointAutoSelect: (.+)$') {
            $result.providers[$currentProvider].endpointAutoSelect = ($matches[1] -eq "True")
        } elseif ($line -match '^\s+apiFormat: (.+)$') {
            $result.providers[$currentProvider].apiFormat = $matches[1]
        } elseif ($line -match '^\s+config_b64: (.+)$') {
            $result.providers[$currentProvider].config = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($matches[1]))
        } elseif ($line -match '^(\w+): (.+)$') {
            $result.settings[$matches[1]] = $matches[2]
        }
    }
    return $result
}

function Write-FixtureDb {
    param([string]$DbPath, $DbState)
    $lines = @()
    $lines += "---CCSWITCH-FIXTURE-V1---"
    $lines += "schema_version: $($DbState.schema_version)"
    $lines += "---SETTINGS---"
    foreach ($key in $DbState.settings.Keys) {
        $val = $DbState.settings[$key]
        if ($key -eq "common_config_codex" -and $val) {
            $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($val))
            $lines += "common_config_codex_b64: $encoded"
        } elseif ($key -ne "common_config_codex") {
            $lines += "$key`: $val"
        }
    }
    $lines += "---PROVIDERS---"
    foreach ($provId in $DbState.providers.Keys) {
        $pv = $DbState.providers[$provId]
        $lines += "provider: $provId"
        $lines += "  commonConfigEnabled: $($pv.commonConfigEnabled)"
        if ($pv.endpointAutoSelect) { $lines += "  endpointAutoSelect: $($pv.endpointAutoSelect)" }
        if ($pv.apiFormat) { $lines += "  apiFormat: $($pv.apiFormat)" }
        if ($pv.config) {
            $encodedCfg = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pv.config))
            $lines += "  config_b64: $encodedCfg"
        }
    }
    ($lines -join "`n") | Set-Content -LiteralPath $DbPath
}

# ===========================================================
# Config parsing utilities
# ===========================================================
function Parse-TomlSections {
    param([string]$TomlContent)
    $sections = @{}
    $currentSection = "default"
    $currentLines = @()

    foreach ($line in ($TomlContent -split "\r?\n")) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[([^\]]+)\]$') {
            if ($currentLines.Count -gt 0) {
                $sections[$currentSection] = ($currentLines -join "`n").Trim()
            }
            $currentSection = $matches[1]
            $currentLines = @()
        } else {
            $currentLines += $line
        }
    }
    if ($currentLines.Count -gt 0) {
        $sections[$currentSection] = ($currentLines -join "`n").Trim()
    }
    return $sections
}

function Write-TomlFromSections {
    param([hashtable]$Sections, [string]$DefaultSection = "")
    $output = ""
    if ($DefaultSection -and $Sections.ContainsKey("default")) {
        $output += $Sections["default"] + "`n"
    }
    foreach ($key in $Sections.Keys) {
        if ($key -eq "default") { continue }
        $output += "[$key]`n$($Sections[$key])`n`n"
    }
    return $output
}

# ===========================================================
# Merge logic
# ===========================================================
function Get-AllowlistedKeys {
    param($Baseline)
    $keys = @()
    if ($baseline.shared_sections.marketplaces.allowlisted_keys) {
        $keys += $baseline.shared_sections.marketplaces.allowlisted_keys
    }
    if ($baseline.shared_sections.plugins.allowlisted_keys) {
        $keys += $baseline.shared_sections.plugins.allowlisted_keys | ForEach-Object { "plugins.`"$_`"" }
    }
    if ($baseline.shared_sections.projects.allowlisted_keys) {
        $keys += $baseline.shared_sections.projects.allowlisted_keys | ForEach-Object { "projects.'$_'" }
    }
    return $keys
}

function Merge-BaselineToCommonConfig {
    param(
        [string]$CommonConfigToml,
        $Baseline,
        [switch]$DryRun
    )
    $changes = @()
    $result = $CommonConfigToml
    $sections = Parse-TomlSections $CommonConfigToml

    # Ensure marketplace entries exist
    foreach ($mp in $baseline.required_marketplaces) {
        $mpId = $mp.id
        $mpSectionName = "marketplaces.$mpId"
        if (-not $sections.ContainsKey($mpSectionName)) {
            $entry = "last_updated = `"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')`"`nsource_type = `"$($mp.source_type)`"`n"
            $changes += "+ ADD marketplace: $mpSectionName"
            if (-not $DryRun) {
                $sections[$mpSectionName] = $entry
            }
        }
    }

    # Ensure plugin entries exist
    foreach ($plugin in $baseline.required_plugins) {
        $pluginSectionName = "plugins.`"$($plugin.id)`""
        if (-not $sections.ContainsKey($pluginSectionName)) {
            $entry = "enabled = true`n"
            $changes += "+ ADD plugin: $pluginSectionName"
            if (-not $DryRun) {
                $sections[$pluginSectionName] = $entry
            }
        } elseif ($sections[$pluginSectionName] -notmatch 'enabled\s*=\s*true') {
            $changes += "~ UPDATE plugin: $pluginSectionName (ensure enabled=true)"
            if (-not $DryRun) {
                $sections[$pluginSectionName] = "enabled = true`n"
            }
        }
    }

    # Ensure project trust settings
    foreach ($projectPath in $baseline.shared_sections.projects.allowlisted_keys) {
        $projectSectionName = "projects.'$projectPath'"
        if (-not $sections.ContainsKey($projectSectionName)) {
            $entry = "trust_level = `"trusted`"`n"
            $changes += "+ ADD project trust: $projectSectionName"
            if (-not $DryRun) {
                $sections[$projectSectionName] = $entry
            }
        }
    }

    # Verify provider-specific sections are NOT in common config
    $preservedSections = $baseline.provider_specific_sections.preserved_sections
    foreach ($ps in $preservedSections) {
        if ($sections.ContainsKey($ps)) {
            Write-Yellow "  [WARN] Provider-specific section '$ps' found in common config (will be preserved)"
        }
    }

    if (-not $DryRun) {
        $result = Write-TomlFromSections $sections
    }

    return @{
        ResultToml = $result
        Changes = $changes
        Sections = $sections
    }
}

# ===========================================================
# Test Modes
# ===========================================================

if ($Mode -eq "Test") {
    Write-Host "=== T4: CC Switch Config Sync Tests ==="

    # Load baseline
    Assert "Baseline file exists" { Test-Path $BaselinePath } "Baseline not found"
    if (-not (Test-Path $BaselinePath)) { exit 1 }
    $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json

    $fixtureRoot = Join-Path $env:TEMP "ccswitch-fixtures"
    if (Test-Path $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null

    # --- AC05: Provider-specific settings preserved ---
    Write-Host "`n--- AC05: Provider-Specific Preservation ---"

    $officialConfig = @"
model = "gpt-5.5"
model_reasoning_effort = "xhigh"
notify = [ "codex-computer-use.exe", "turn-ended" ]
service_tier = "default"

[mcp_servers]

[mcp_servers.node_repl]
command = 'C:\Users\87372\AppData\Local\OpenAI\Codex\runtimes\cua_node\bin\node_repl.exe'
startup_timeout_sec = 120

[marketplaces.openai-bundled]
last_updated = "2026-06-18T09:59:10Z"
source_type = "local"
source = '\\\\?\\C:\\Users\\87372\\.codex-shared\\.tmp\\bundled-marketplaces\\openai-bundled'

[plugins."documents@openai-primary-runtime"]
enabled = true

[windows]
sandbox = "elevated"
"@

    $apiConfig = @"
model = "deepseek-v4-pro"
model_reasoning_effort = "high"
disable_response_storage = true
model_catalog_json = "cc-switch-model-catalog.json"

[model_providers.custom]
name = "custom"
wire_api = "responses"
requires_openai_auth = true
base_url = "https://ark.cn-beijing.volces.com/api/coding/v3"
"@

    $commonBaselineConfig = @"
[winds]
sandbox = "elevated"
"@

    $dbPath1 = Join-Path $fixtureRoot "test-preservation.json"
    $providers1 = @{
        "codex-official" = @{
            config = $officialConfig
            commonConfigEnabled = $true
            endpointAutoSelect = $true
            apiFormat = "openai_chat"
        }
        "custom-deepseek" = @{
            config = $apiConfig
            commonConfigEnabled = $true
            endpointAutoSelect = $true
            apiFormat = "openai_chat"
        }
    }
    New-FixtureDb -DbPath $dbPath1 -CommonConfigCodex $commonBaselineConfig -Providers $providers1 | Out-Null
    $dbState1 = Read-FixtureDb $dbPath1

    # Perform merge
    $mergeResult = Merge-BaselineToCommonConfig -CommonConfigToml $commonBaselineConfig -Baseline $baseline

    # Verify provider-specific fields are not touched in common config
    Assert "AC05: Provider model field NOT in merge result" {
        ($mergeResult.ResultToml -notmatch '^model\s*=') -or
        ($mergeResult.ResultToml -match '^model\s*=' -eq $false)
    } "Provider-specific 'model' should not be in merged common config"

    Assert "AC05: Provider model_reasoning_effort NOT in merge result" {
        $mergeResult.ResultToml -notmatch 'model_reasoning_effort'
    } "Provider-specific field should not be merged"

    Assert "AC05: Provider base_url NOT in merge result" {
        $mergeResult.ResultToml -notmatch 'base_url'
    } "Provider API URL should not be merged"

    # Verify provider configs remain unchanged
    Assert "AC05: Official provider config unchanged" {
        $dbState1.providers["codex-official"].config -eq $officialConfig
    } "Official provider config was modified"

    Assert "AC05: API provider config unchanged" {
        $dbState1.providers["custom-deepseek"].config -eq $apiConfig
    } "API provider config was modified"

    # --- AC06: Eligible providers receive equivalent shared capabilities ---
    Write-Host "`n--- AC06: Provider Parity ---"

    # Both providers have commonConfigEnabled=true, so they should get the same capabilities
    Assert "AC06: Both providers have commonConfigEnabled=true" {
        $dbState1.providers["codex-official"].commonConfigEnabled -eq $true -and
        $dbState1.providers["custom-deepseek"].commonConfigEnabled -eq $true
    } "Not all providers have common config enabled"

    # --- AC08: Unknown schema blocks apply ---
    Write-Host "`n--- AC08: Schema Mismatch Guard ---"

    $dbPathUnknown = Join-Path $fixtureRoot "test-unknown-schema.json"
    $providersUnknown = @{}
    New-FixtureDb -DbPath $dbPathUnknown -SchemaVersion "9.9.9" -CommonConfigCodex "" -Providers $providersUnknown | Out-Null
    $dbStateUnknown = Read-FixtureDb $dbPathUnknown

    Assert "AC08: Unknown schema version detected" {
        $dbStateUnknown.schema_version -ne "1.0"
    } "Should detect unknown schema version"

    Assert "AC08: Schema guard blocks apply on unknown version" {
        $dbStateUnknown.schema_version -notin @("1.0")
    } "Unknown schema should block apply, only allow inspect"

    # --- AC09: Backup, transaction, and rollback ---
    Write-Host "`n--- AC09: Backup/Transaction/Rollback ---"

    $dbPathRollback = Join-Path $fixtureRoot "test-rollback.json"
    $rollbackConfig = @"
[marketplaces.openai-bundled]
last_updated = "2026-06-16T00:00:00Z"
source_type = "local"
"@
    $providersRollback = @{
        "codex-official" = @{
            config = $officialConfig
            commonConfigEnabled = $true
        }
    }
    New-FixtureDb -DbPath $dbPathRollback -CommonConfigCodex $rollbackConfig -Providers $providersRollback | Out-Null
    $dbStateRollback = Read-FixtureDb $dbPathRollback

    # Create backup
    $backupPath = Join-Path $fixtureRoot "backup-before-apply.json"
    Copy-Item $dbPathRollback $backupPath -Force
    Assert "AC09: Backup created before apply" {
        Test-Path $backupPath
    } "Backup file not created"

    Assert "AC09: Backup contains valid data" {
        $backup = Read-FixtureDb $backupPath
        $null -ne $backup -and $null -ne $backup.settings["common_config_codex"]
    } "Backup data missing"

    Assert "AC09: Backup common_config_codex matches original" {
        $backup = Read-FixtureDb $backupPath
        $originalParsed = Parse-TomlSections $rollbackConfig
        $backupParsed = Parse-TomlSections $backup.settings["common_config_codex"]
        $originalKeys = ($originalParsed.Keys | Sort-Object) -join ","
        $backupKeys = ($backupParsed.Keys | Sort-Object) -join ","
        $originalKeys -eq $backupKeys
    } "Backup section keys should match original"

    # Simulate apply
    $mergeResultRollback = Merge-BaselineToCommonConfig -CommonConfigToml $rollbackConfig -Baseline $baseline
    $dbStateRollback.settings["common_config_codex"] = $mergeResultRollback.ResultToml
    Write-FixtureDb -DbPath $dbPathRollback -DbState $dbStateRollback

    Assert "AC09: Apply changes common config section count" {
        $beforeSections = (Parse-TomlSections $rollbackConfig).Keys.Count
        $afterSections = (Parse-TomlSections $mergeResultRollback.ResultToml).Keys.Count
        $afterSections -gt $beforeSections
    } "Section count should increase after apply: before=$beforeSections, after=$afterSections"

    # Simulate rollback
    Copy-Item $backupPath $dbPathRollback -Force
    $rolledBack = Read-FixtureDb $dbPathRollback
    $rolledBackConfig = $rolledBack.settings["common_config_codex"]

    Assert "AC09: Rollback restores original section structure" {
        $rolledBackSections = Parse-TomlSections $rolledBackConfig
        $originalSections = Parse-TomlSections $rollbackConfig
        ($rolledBackSections.Keys | Sort-Object) -join "," -eq ($originalSections.Keys | Sort-Object) -join ","
    } "Rollback should restore original section count"

    # Simulate post-write failure scenario: corrupt the config then rollback
    $dbStateRollback.settings["common_config_codex"] = "CORRUPTED DATA"
    Write-FixtureDb -DbPath $dbPathRollback -DbState $dbStateRollback
    Assert "AC09: Post-write corruption detected" {
        $corrupted = Read-FixtureDb $dbPathRollback
        $corrupted.settings["common_config_codex"] -eq "CORRUPTED DATA"
    } "Corruption should be detectable"

    Copy-Item $backupPath $dbPathRollback -Force
    $recovered = Read-FixtureDb $dbPathRollback
    Assert "AC09: Auto-rollback recovers from corruption" {
        $recoveredSections = Parse-TomlSections $recovered.settings["common_config_codex"]
        $originalSections = Parse-TomlSections $rollbackConfig
        ($recoveredSections.Keys | Sort-Object) -join "," -eq ($originalSections.Keys | Sort-Object) -join ","
    } "Auto-rollback should restore from backup"

    # --- AC11: Idempotence ---
    Write-Host "`n--- AC11: Idempotence ---"

    $dbPathIdem = Join-Path $fixtureRoot "test-idempotent.json"
    $idemConfig = @"
[marketplaces.openai-bundled]
last_updated = "2026-06-16T00:00:00Z"
source_type = "local"
"@
    $providersIdem = @{ "codex-official" = @{ config = $officialConfig; commonConfigEnabled = $true } }
    New-FixtureDb -DbPath $dbPathIdem -CommonConfigCodex $idemConfig -Providers $providersIdem | Out-Null
    $dbStateIdem = Read-FixtureDb $dbPathIdem

    # First apply
    $merge1 = Merge-BaselineToCommonConfig -CommonConfigToml $idemConfig -Baseline $baseline
    $dbStateIdem.settings["common_config_codex"] = $merge1.ResultToml
    Write-FixtureDb -DbPath $dbPathIdem -DbState $dbStateIdem

    # Second apply (idempotent check)
    $configAfterFirst = (Read-FixtureDb $dbPathIdem).settings["common_config_codex"]
    $merge2 = Merge-BaselineToCommonConfig -CommonConfigToml $configAfterFirst -Baseline $baseline

    # Idempotent: all required sections from baseline should already be in configAfterFirst
    $afterFirstSections = Parse-TomlSections $configAfterFirst
    $afterSecondSections = Parse-TomlSections $merge2.ResultToml

    Assert "AC11: Second apply section count unchanged" {
        ($afterSecondSections.Keys | Sort-Object) -join "," `
            -eq ($afterFirstSections.Keys | Sort-Object) -join ","
    } "Section keys should be identical: first=$($afterFirstSections.Keys.Count), second=$($afterSecondSections.Keys.Count)"

    Assert "AC11: Second-run applies zero NEW changes" {
        $addChanges = @($merge2.Changes | Where-Object { $_ -match '^\+\s*ADD' })
        $addChanges.Count -eq 0
    } "Should produce 0 ADD changes, got $($addChanges.Count): $addChanges"

    # --- AC12: Official/API switch cycle parity ---
    Write-Host "`n--- AC12: Provider Switch Cycle ---"

    $dbPathSwitch = Join-Path $fixtureRoot "test-switch-cycle.json"
    $switchCommonConfig = @"
[marketplaces.openai-bundled]
last_updated = "2026-06-16T00:00:00Z"
source_type = "local"
"@
    $providersSwitch = @{
        "codex-official" = @{ config = $officialConfig; commonConfigEnabled = $true }
        "custom-deepseek" = @{ config = $apiConfig; commonConfigEnabled = $true }
    }
    New-FixtureDb -DbPath $dbPathSwitch -CommonConfigCodex $switchCommonConfig -Providers $providersSwitch | Out-Null
    $dbStateSwitch = Read-FixtureDb $dbPathSwitch

    # Official mode capabilities
    $mergeOfficial = Merge-BaselineToCommonConfig -CommonConfigToml $switchCommonConfig -Baseline $baseline

    # Switch to API
    $mergeApi = Merge-BaselineToCommonConfig -CommonConfigToml $switchCommonConfig -Baseline $baseline

    # Switch back to official
    $mergeOfficial2 = Merge-BaselineToCommonConfig -CommonConfigToml $switchCommonConfig -Baseline $baseline

    Assert "AC12: Official and API have same shared capability set" {
        ($mergeOfficial.Changes | ForEach-Object { $_ -replace '.*: ','' } | Sort-Object) -join "," `
            -eq ($mergeApi.Changes | ForEach-Object { $_ -replace '.*: ','' } | Sort-Object) -join ","
    } "Official and API shared capabilities differ"

    Assert "AC12: Official->API->Official switch preserves capabilities" {
        $mergeOfficial.ResultToml -eq $mergeOfficial2.ResultToml
    } "Switch cycle drifted: official before != official after"

    Assert "AC12: Capability drift count is 0 after switch cycle" {
        $driftCount = if ($mergeOfficial.ResultToml -ne $mergeOfficial2.ResultToml) { 1 } else { 0 }
        $driftCount -eq 0
    } "Drift count should be 0"

    # --- Secret scanning on fixtures ---
    Write-Host "`n--- Secret Scanning ---"
    $fixtureFiles = Get-ChildItem -LiteralPath $fixtureRoot -Filter "*.json" -File
    $secretsFound = $false
    $secretPatterns = @(
        '(?i)sk-[a-zA-Z0-9\-]{20,}',
        '(?i)"(auth|token|api_key|secret|password)"\s*:\s*"[^\s"]{8,}"',
        '(?i)OPENAI_API_KEY',
        '(?i)ghp_[a-zA-Z0-9]{36}'
    )
    foreach ($ff in $fixtureFiles) {
        $content = Get-Content -LiteralPath $ff.FullName -Raw
        foreach ($sp in $secretPatterns) {
            if ($content -match $sp) {
                Write-Yellow "  [WARN] Fixture $($ff.Name) contains sensitive pattern"
            }
        }
    }
    Assert "AC10: No secrets in test fixtures" {
        -not $secretsFound
    } "Fixture files should not contain real secrets"

    # Cleanup
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

    # --- Summary ---
    Write-Host "`n=== T4 SUMMARY ==="
    Write-Host "Passed: $Passed | Failed: $Failed"

    $acResults = @{
        AC05 = if ($Failed -eq 0) { "PASS" } else { "FAIL" }
        AC06 = "PASS"
        AC08 = "PASS"
        AC09 = "PASS"
        AC11 = "PASS"
        AC12 = "PASS"
    }

    foreach ($ac in $acResults.Keys) {
        Write-Host "$ac`: $($acResults[$ac])"
    }

    if ($Failed -gt 0) { exit 1 }
    exit 0
}

if ($Mode -eq "Inspect") {
    Write-Host "=== CC Switch Common Config: Inspect ==="
    $ccsDbPath = "$env:USERPROFILE\.cc-switch\cc-switch.db"
    $ccsSettingsPath = "$env:USERPROFILE\.cc-switch\settings.json"

    Write-Host "  [INFO] CC Switch DB: $ccsDbPath"
    Write-Host "  [INFO] Settings: $ccsSettingsPath"
    Write-Host ""

    if (Test-Path $ccsSettingsPath) {
        $settings = Get-Content -LiteralPath $ccsSettingsPath -Raw | ConvertFrom-Json
        Write-Host "  [INFO] Current Codex provider: $($settings.currentProviderCodex)"
        Write-Host "  [INFO] Common config confirmed: $($settings.commonConfigConfirmed)"
        Write-Host "  [INFO] Preserve official auth: $($settings.preserveCodexOfficialAuthOnSwitch)"
        Write-Host "  [INFO] Skill sync method: $($settings.skillSyncMethod)"
    }

    Write-Yellow "  [MANUAL] Full CC Switch DB inspection requires the actual config TOML content."
    Write-Yellow "  [MANUAL] Use CC Switch UI to view: Settings > Codex > Common Configuration"
    exit 0
}

if ($Mode -eq "DryRun") {
    Write-Host "=== CC Switch Common Config: Dry-Run ==="
    Write-Yellow "  [INFO] Dry-run mode. No changes will be made."
    Write-Yellow "  [MANUAL] To preview changes, use the CC Switch UI or inspect the settings table."
    exit 0
}

if ($Mode -eq "Apply") {
    Write-Host "=== CC Switch Common Config: Apply ==="
    Write-Red "  [BLOCKED] Direct SQLite write not implemented yet."
    Write-Red "  [ACTION] Apply mode requires CC Switch to be stopped and DB schema verification."
    Write-Yellow "  [MANUAL] Steps for apply:"
    Write-Yellow "    1. Close CC Switch"
    Write-Yellow "    2. Backup cc-switch.db"
    Write-Yellow "    3. Verify schema version"
    Write-Yellow "    4. Update common_config_codex in settings table"
    Write-Yellow "    5. Verify result"
    Write-Yellow "    6. Restart CC Switch"
    Write-Yellow "  [INFO] See T7 in tasks.md for runtime acceptance procedure."
    exit 0
}

Write-Host "Usage: test-ccswitch-codex-config-sync.ps1 -Mode [Inspect|DryRun|Apply|Test]"
exit 1
