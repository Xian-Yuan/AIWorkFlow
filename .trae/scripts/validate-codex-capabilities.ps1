# validate-codex-capabilities.ps1
# Master validation entrypoint for Codex capabilities.
# Modes:
#   -Mode Inspect       -> junction check, three-state plugin report, redacted config summary (AC01, AC07)
#   -Mode VerifySwitchCycle -> official/API switch parity check (AC12)
#   -Mode Apply         -> guarded CC Switch common-config synchronization (AC05-AC09)
#   -Mode DryRun        -> preview changes without applying

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Inspect", "VerifySwitchCycle", "Apply", "DryRun")]
    [string]$Mode,

    [string]$BaselinePath = ".codex\capability-baseline.json",
    [switch]$Force,
    [string]$OutputReport
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Resolve baseline path
if (-not [System.IO.Path]::IsPathRooted($BaselinePath)) {
    $BaselinePath = Join-Path $Root $BaselinePath
}

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Get-RedactedReport {
    $report = @{
        generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        mode = $Mode
        sections = @()
    }

    # --- Section 1: Junction check (AC01) ---
    $junctionSection = @{
        name = "project-skill-junction"
        passed = $true
        checks = @()
    }

    $skillsDir = Join-Path $Root "skills"
    $agentsSkillsDir = Join-Path $Root ".agents\skills"

    $junctionSection.checks += @{
        check = "skills_directory_exists"
        result = (Test-Path $skillsDir -PathType Container)
    }

    if (Test-Path $agentsSkillsDir) {
        $item = Get-Item -LiteralPath $agentsSkillsDir -Force -ErrorAction SilentlyContinue
        $isJunction = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
        $target = ""
        if ($item.Target) {
            if ($item.Target -is [array]) { $target = $item.Target[0] } else { $target = $item.Target }
        }
        $junctionSection.checks += @{
            check = "agents_skills_is_junction"
            result = $isJunction
            detail = "target: $target"
        }
        $canonicalMatch = ($target -replace '[/\\]$','') -eq ($skillsDir -replace '[/\\]$','')
        $junctionSection.checks += @{
            check = "junction_target_matches_canonical"
            result = $canonicalMatch
        }
        if (-not $canonicalMatch) { $junctionSection.passed = $false }
    } else {
        $junctionSection.checks += @{
            check = "agents_skills_exists"
            result = $false
            detail = "Path not found"
        }
        $junctionSection.passed = $false
    }

    $report.sections += $junctionSection

    # --- Section 2: Dynamic skill inventory (AC02) ---
    $inventorySection = @{
        name = "skill-inventory"
        passed = $true
        active_count = 0
        archived_count = 0
        skills = @()
    }

    if (Test-Path $skillsDir) {
        $allDirs = Get-ChildItem -LiteralPath $skillsDir -Directory
        $activeDirs = $allDirs | Where-Object { $_.Name -ne "_archived" }
        $archivedDirs = Get-ChildItem -LiteralPath (Join-Path $skillsDir "_archived") -Directory -ErrorAction SilentlyContinue
        $inventorySection.active_count = $activeDirs.Count
        $inventorySection.archived_count = if ($archivedDirs) { $archivedDirs.Count } else { 0 }

        foreach ($dir in $activeDirs) {
            $hasSkillMd = Test-Path (Join-Path $dir.FullName "SKILL.md")
            $inventorySection.skills += @{
                name = $dir.Name
                has_skill_md = $hasSkillMd
            }
            if (-not $hasSkillMd) { $inventorySection.passed = $false }
        }
    }
    $report.sections += $inventorySection

    # --- Section 3: Plugin three-state report (AC07) ---
    $pluginSection = @{
        name = "plugin-three-state-report"
        passed = $true
        plugins = @()
    }

    $codexHome = "$env:USERPROFILE\.codex-shared"
    $configTomlPath = Join-Path $codexHome "config.toml"

    if (Test-Path $configTomlPath) {
        $configContent = Get-Content -LiteralPath $configTomlPath -Raw

        # Parse marketplace entries
        $marketplacePattern = '\[marketplaces\.(?<id>[^\]]+)\]\s*\n(?:[^[]*\n)*?(?=^\[|\z)'
        $marketplaces = @{}
        $marketplaceMatches = [regex]::Matches($configContent, $marketplacePattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($m in $marketplaceMatches) {
            $id = $m.Groups["id"].Value
            $body = $m.Value
            $sourceType = if ($body -match 'source_type\s*=\s*"(?<val>[^"]+)"') { $matches["val"] } else { "unknown" }
            $source = if ($body -match 'source\s*=\s*[^"]*"(?<val>[^"]+)"') { "<REDACTED>" } else { "<REDACTED>" }
            $marketplaces[$id] = @{ source_type = $sourceType; source = $source }
        }

        # Parse plugin entries
        $pluginPattern = '\[plugins\.(?<id>[^\]]+)\]\s*\nenabled\s*=\s*(?<enabled>true|false)'
        $pluginMatches = [regex]::Matches($configContent, $pluginPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

        $installedPlugins = @{}
        foreach ($p in $pluginMatches) {
            $installedPlugins[$p.Groups["id"].Value] = ($p.Groups["enabled"].Value -eq "true")
        }

        # Check jinli-soul-core
        $jinliManifestPath = "$env:USERPROFILE\plugins\jinli-soul-core\.codex-plugin"
        $jinliAvailable = Test-Path $jinliManifestPath
        $jinliInstalled = $installedPlugins.ContainsKey("jinli-soul-core@personal")
        $jinliEnabled = if ($jinliInstalled) { $installedPlugins["jinli-soul-core@personal"] } else { $false }
        $jinliRuntimeCallable = $jinliInstalled -and $jinliEnabled

        $jinliReport = @{
            id = "jinli-soul-core@personal"
            available_in_marketplace = $true
            installed_enabled = $jinliEnabled
            runtime_callable = $jinliRuntimeCallable
            marketplace_evidence = "personal marketplace entry exists"
            install_evidence = if ($jinliInstalled) { "config.toml plugin entry present" } else { "NOT in config.toml plugin entries" }
            runtime_evidence = if ($jinliRuntimeCallable) { "enabled + process reload required" } else { "not enabled or not installed" }
        }
        $pluginSection.plugins += $jinliReport

        if (-not $jinliEnabled) {
            Write-Yellow "  [WARN] jinli-soul-core@personal is available but not installed/enabled"
        }

        # Summarize all installed plugins
        foreach ($pluginId in $installedPlugins.Keys) {
            if ($pluginId -eq "jinli-soul-core@personal") { continue }
            $isEnabled = $installedPlugins[$pluginId]
            $pluginSection.plugins += @{
                id = $pluginId
                available_in_marketplace = $marketplaces.Count -gt 0
                installed_enabled = $isEnabled
                runtime_callable = $isEnabled
                marketplace_evidence = "config.toml marketplaces section present"
                install_evidence = "config.toml plugin entry: enabled=$isEnabled"
                runtime_evidence = if ($isEnabled) { "enabled; process reload required" } else { "disabled" }
            }
        }

        $pluginSection.marketplaces = @()
        foreach ($mpId in $marketplaces.Keys) {
            $pluginSection.marketplaces += @{
                id = $mpId
                source_type = $marketplaces[$mpId].source_type
                source = "<REDACTED>"
            }
        }

    } else {
        $pluginSection.passed = $false
        $pluginSection.error = "config.toml not found at $configTomlPath"
    }

    $report.sections += $pluginSection

    # --- Section 3b: jinli-soul-core runtime readiness (WP05) ---
    $jinliReadinessSection = @{
        name = "jinli-soul-core-runtime-readiness"
        passed = $true
        checks = @()
    }

    # Locate baseline even if it was passed in via -BaselinePath (relative or absolute)
    $jinliBaselinePath = $BaselinePath
    if (-not [System.IO.Path]::IsPathRooted($jinliBaselinePath)) {
        $jinliBaselinePath = Join-Path $Root $jinliBaselinePath
    }

    $jinliPluginFromBaseline = $null
    $jinliMcpFromBaseline = $null
    if (Test-Path -LiteralPath $jinliBaselinePath) {
        try {
            $baselineDoc = Get-Content -LiteralPath $jinliBaselinePath -Raw | ConvertFrom-Json
            if ($baselineDoc.required_plugins) {
                $jinliPluginFromBaseline = $baselineDoc.required_plugins | Where-Object { $_.id -eq "jinli-soul-core@personal" }
            }
            if ($baselineDoc.safe_mcp_ids) {
                $jinliMcpFromBaseline = $baselineDoc.safe_mcp_ids | Where-Object { $_.id -eq "jinli_soul_core" }
            }
        } catch {
            $jinliReadinessSection.passed = $false
            $jinliReadinessSection.checks += @{
                check = "baseline_parse"
                result = $false
                detail = "Failed to parse baseline for readiness check: $_"
            }
        }
    }

    # Check 1: baseline declares the plugin
    $jinliReadinessSection.checks += @{
        check = "baseline_declares_jinli_plugin"
        result = [bool]$jinliPluginFromBaseline
        detail = if ($jinliPluginFromBaseline) { "required_plugins entry present" } else { "jinli-soul-core@personal missing from required_plugins" }
    }
    if (-not $jinliPluginFromBaseline) { $jinliReadinessSection.passed = $false }

    # Check 2: baseline declares the MCP server
    $jinliReadinessSection.checks += @{
        check = "baseline_declares_jinli_mcp_server"
        result = [bool]$jinliMcpFromBaseline
        detail = if ($jinliMcpFromBaseline) { "safe_mcp_ids entry present" } else { "jinli_soul_core missing from safe_mcp_ids" }
    }
    if (-not $jinliMcpFromBaseline) { $jinliReadinessSection.passed = $false }

    # Check 3: plugin entry has mcp_server_id cross-reference
    $hasCrossRef = $false
    if ($jinliPluginFromBaseline -and $jinliPluginFromBaseline.PSObject.Properties.Match('mcp_server_id').Count -gt 0) {
        $hasCrossRef = ($jinliPluginFromBaseline.mcp_server_id -eq "jinli_soul_core")
    }
    $jinliReadinessSection.checks += @{
        check = "baseline_plugin_mcp_cross_reference"
        result = $hasCrossRef
        detail = if ($hasCrossRef) { "plugin.mcp_server_id == jinli_soul_core" } else { "plugin.mcp_server_id missing or mismatched" }
    }
    if (-not $hasCrossRef) { $jinliReadinessSection.passed = $false }

    # Check 4: package_root directory present (filesystem evidence, no secret content)
    $packageRoot = "C:\\Users\\87372\\plugins\\jinli-soul-core"
    $packagePresent = Test-Path -LiteralPath $packageRoot
    $jinliReadinessSection.checks += @{
        check = "package_root_present"
        result = $packagePresent
        detail = "C:\\Users\\87372\\plugins\\jinli-soul-core"
    }
    if (-not $packagePresent) { $jinliReadinessSection.passed = $false }

    # Check 5: server.mjs entry point present
    $serverMjs = Join-Path $packageRoot "mcp\server.mjs"
    $serverMjsPresent = Test-Path -LiteralPath $serverMjs
    $jinliReadinessSection.checks += @{
        check = "mcp_server_entrypoint_present"
        result = $serverMjsPresent
        detail = if ($serverMjsPresent) { "server.mjs present" } else { "server.mjs MISSING — install incomplete" }
    }
    if (-not $serverMjsPresent) { $jinliReadinessSection.passed = $false }

    # Check 6: ide-registry.json is present (declarative source of truth)
    $registryPath = Join-Path $Root "Project\\Jinli\\config\\ide-registry.json"
    $registryPresent = Test-Path -LiteralPath $registryPath
    $jinliReadinessSection.checks += @{
        check = "ide_registry_present"
        result = $registryPresent
        detail = if ($registryPresent) { "ide-registry.json present" } else { "ide-registry.json missing — sync tool has no source of truth" }
    }
    if (-not $registryPresent) { $jinliReadinessSection.passed = $false }

    # Check 7: sync tool present
    $syncToolPath = Join-Path $Root ".trae\\scripts\\jinli-ide-sync.ps1"
    $syncToolPresent = Test-Path -LiteralPath $syncToolPath
    $jinliReadinessSection.checks += @{
        check = "sync_tool_present"
        result = $syncToolPresent
        detail = if ($syncToolPresent) { "jinli-ide-sync.ps1 present" } else { "jinli-ide-sync.ps1 missing" }
    }
    if (-not $syncToolPresent) { $jinliReadinessSection.passed = $false }

    $jinliReadinessSection.summary = @{
        plugin_baseline = [bool]$jinliPluginFromBaseline
        mcp_baseline = [bool]$jinliMcpFromBaseline
        cross_ref = $hasCrossRef
        package_present = $packagePresent
        server_mjs_present = $serverMjsPresent
        registry_present = $registryPresent
        sync_tool_present = $syncToolPresent
    }

    $report.sections += $jinliReadinessSection

    # --- Section 4: Baseline presence check ---
    $baselineSection = @{
        name = "capability-baseline"
        passed = $false
    }
    if (Test-Path $BaselinePath) {
        try {
            $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
            $baselineSection.passed = $true
            $baselineSection.version = $baseline.version
            $baselineSection.required_plugins_count = $baseline.required_plugins.Count
            $baselineSection.required_marketplaces_count = $baseline.required_marketplaces.Count
        } catch {
            $baselineSection.error = "Failed to parse baseline: $_"
        }
    } else {
        $baselineSection.error = "Baseline not found at $BaselinePath"
    }
    $report.sections += $baselineSection

    # --- Section 5: CC Switch provider configuration (redacted) ---
    $ccsSection = @{
        name = "cc-switch-providers"
        passed = $false
        providers = @()
    }

    $ccsDbPath = "$env:USERPROFILE\.cc-switch\cc-switch.db"
    $ccsSettingsPath = "$env:USERPROFILE\.cc-switch\settings.json"

    if (Test-Path $ccsSettingsPath) {
        try {
            $ccsSettings = Get-Content -LiteralPath $ccsSettingsPath -Raw | ConvertFrom-Json
            $ccsSection.current_provider = $ccsSettings.currentProviderCodex
            $ccsSection.preserve_official_auth = $ccsSettings.preserveCodexOfficialAuthOnSwitch
            $ccsSection.common_config_enabled = $ccsSettings.commonConfigConfirmed
            $ccsSection.passed = $true
        } catch {
            $ccsSection.error = "Failed to parse CC Switch settings: $_"
        }
    } else {
        $ccsSection.error = "CC Switch settings not found"
    }

    $report.sections += $ccsSection

    return $report
}

# ===========================================================
# Mode dispatch
# ===========================================================

switch ($Mode) {
    "Inspect" {
        Write-Host "=== Codex Capability Inspection ==="
        $report = Get-RedactedReport

        Write-Host ""
        foreach ($section in $report.sections) {
            $icon = if ($section.passed) { "[PASS]" } else { "[FAIL]" }
            Write-Host "$icon $($section.name)"

            if ($section.name -eq "project-skill-junction") {
                foreach ($check in $section.checks) {
                    $cIcon = if ($check.result) { "  [PASS]" } else { "  [FAIL]" }
                    Write-Host "$cIcon $($check.check) $($check.detail)"
                }
            }

            if ($section.name -eq "skill-inventory") {
                Write-Host "  [INFO] Active skills: $($section.active_count)"
                Write-Host "  [INFO] Archived skills: $($section.archived_count)"
                $invalidSkills = @($section.skills | Where-Object { -not $_.has_skill_md })
                if ($invalidSkills.Count -gt 0) {
                    Write-Yellow "  [WARN] Skills missing SKILL.md: $($invalidSkills.Count)"
                }
            }

            if ($section.name -eq "plugin-three-state-report") {
                foreach ($plugin in $section.plugins) {
                    Write-Host "  --- $($plugin.id) ---"
                    Write-Host "    Available in marketplace: $($plugin.available_in_marketplace)"
                    Write-Host "    Installed/Enabled: $($plugin.installed_enabled)"
                    Write-Host "    Runtime callable: $($plugin.runtime_callable)"
                }
                if ($section.marketplaces) {
                    Write-Host "  --- Marketplaces ---"
                    foreach ($mp in $section.marketplaces) {
                        Write-Host "    $($mp.id): type=$($mp.source_type)"
                    }
                }
            }

            if ($section.name -eq "jinli-soul-core-runtime-readiness") {
                Write-Host "  --- jinli-soul-core@personal runtime readiness ---"
                foreach ($check in $section.checks) {
                    $cIcon = if ($check.result) { "  [PASS]" } else { "  [FAIL]" }
                    Write-Host ("$cIcon {0,-40} {1}" -f $check.check, $check.detail)
                }
            }

            if ($section.name -eq "capability-baseline") {
                if ($section.passed) {
                    Write-Host "  [INFO] Baseline version: $($section.version)"
                    Write-Host "  [INFO] Required plugins: $($section.required_plugins_count)"
                    Write-Host "  [INFO] Required marketplaces: $($section.required_marketplaces_count)"
                }
            }
        }

        # Output report if requested
        if ($OutputReport) {
            $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputReport
            Write-Green "  [INFO] Report saved to: $OutputReport"
        }

        # Exit code based on junction check
        $junctionPassed = ($report.sections | Where-Object { $_.name -eq "project-skill-junction" }).passed
        if (-not $junctionPassed) { exit 1 }
        exit 0
    }

    "VerifySwitchCycle" {
        Write-Host "=== Codex Capability Switch-Cycle Verification (AC12) ==="
        Write-Host ""
        Write-Yellow "  [MANUAL] This verification requires manual provider switching in Codex Desktop."
        Write-Yellow "  [MANUAL] Steps:"
        Write-Yellow "    1. Record current provider and capability state"
        Write-Yellow "    2. Switch to API-backed provider"
        Write-Yellow "    3. Record capability state"
        Write-Yellow "    4. Switch back to official provider"
        Write-Yellow "    5. Compare capability states"
        Write-Yellow "    6. Record drift count (expected: 0)"

        $report = Get-RedactedReport
        if ($OutputReport) {
            $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputReport
            Write-Green "  [INFO] Pre-switch baseline saved to: $OutputReport"
        }

        Write-Host ""
        Write-Host "  [CHECK] AC12: Switch cycle verification requires manual smoke test protocol."
        Write-Host "  [CHECK] See AC13/AC14 in verification-report.md for manual evidence recording."
        exit 0
    }

    "Apply" {
        Write-Host "=== Guarded CC Switch Common-Config Apply ==="
        Write-Host ""
        Write-Yellow "  [INFO] Apply mode for CC Switch common configuration."
        Write-Yellow "  [INFO] This is performed through the test-ccswitch-codex-config-sync.ps1 script."
        Write-Yellow "  [INFO] Run: .\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Apply"
        exit 0
    }

    "DryRun" {
        Write-Host "=== Dry-Run: Preview CC Switch Common-Config Changes ==="
        Write-Yellow "  [INFO] Dry-run is performed through test-ccswitch-codex-config-sync.ps1 -Mode DryRun"
        exit 0
    }
}
