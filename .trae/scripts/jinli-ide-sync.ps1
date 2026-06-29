# jinli-ide-sync.ps1
# Single source of truth driven sync tool for the Jinli MCP server across IDEs.
# Reads `Project/Jinli/config/ide-registry.json` and reports / repairs drift on
# Codex, OpenCode, and Trae MCP configs.
#
# Modes:
#   check   -> read-only drift detection across all registered IDEs (default)
#   apply   -> auto-sync only IDEs with auto_sync=true (currently OpenCode); backup first
#   doctor  -> explain WHY a specific IDE cannot call Jinli, including manual_step
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-ide-sync.ps1 check  -Ide all
#   powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-ide-sync.ps1 apply  -Ide opencode
#   powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-ide-sync.ps1 doctor -Ide codex
#
# Authority scope:
#   - NEVER writes to C:\Users\87372\.codex\**  (forbidden)
#   - NEVER writes to C:\Users\87372\plugins\jinli-soul-core\**  (forbidden)
#   - NEVER writes to Project\Jinli\services\**  (forbidden)
#   - Only auto-syncs IDEs where registry.ides.<ide>.auto_sync == true
#   - Trae is intentionally manual-only (conservative)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("check","apply","doctor")]
    [string]$Mode = "check",

    [Parameter(Mandatory=$false)]
    [Alias("Ide")]
    [string]$TargetIde = "all",

    [Parameter(Mandatory=$false)]
    [string]$RegistryPath = "",

    [Parameter(Mandatory=$false)]
    [string]$OutputJson
)

$ErrorActionPreference = "Stop"

# Resolve registry path
if ([string]::IsNullOrEmpty($RegistryPath)) {
    # Default: <workspace>/Project/Jinli/config/ide-registry.json
    # $PSScriptRoot is .../.trae/scripts, so two levels up gives workspace root
    $WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $RegistryPath = Join-Path $WorkspaceRoot "Project\Jinli\config\ide-registry.json"
} elseif (-not [System.IO.Path]::IsPathRooted($RegistryPath)) {
    $RegistryPath = Join-Path (Get-Location) $RegistryPath
}

if (-not (Test-Path -LiteralPath $RegistryPath)) {
    Write-Host "[FATAL] Registry not found at $RegistryPath" -ForegroundColor Red
    exit 2
}

# ---------------------------------------------------------------------------
# Load registry
# ---------------------------------------------------------------------------
try {
    $registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "[FATAL] Failed to parse registry JSON: $_" -ForegroundColor Red
    exit 2
}

$server = $registry.server
$serverId = $server.id
$desiredCommand = $server.node_command
$desiredArgs = @($server.node_args)
$desiredCwd = $server.node_cwd

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Format-Args {
    param([string[]]$Arr)
    if ($null -eq $Arr) { return "" }
    return ($Arr -join " ")
}

function Read-CodexTomlSection {
    param(
        [string]$TomlPath,
        [string]$SectionHeader  # e.g. "[mcp_servers.jinli_soul_core]"
    )
    if (-not (Test-Path -LiteralPath $TomlPath)) {
        return @{ present = $false; reason = "config not found" }
    }
    $content = Get-Content -LiteralPath $TomlPath -Raw

    # Escape section header for regex
    $escapedHeader = [regex]::Escape($SectionHeader)

    # Match from header up to next section header [xxx] or EOF
    $pattern = '(?ms)' + $escapedHeader + '\s*\r?\n(.*?)(?=^\s*\[[^\]]+\]|\z)'
    $m = [regex]::Match($content, $pattern)
    if (-not $m.Success) {
        return @{ present = $false; reason = "section header not found" }
    }

    $body = $m.Groups[1].Value

    # Simple key/value extraction (string + array-of-strings only)
    $command = $null
    if ($body -match '(?m)^\s*command\s*=\s*[\''"]?(?<v>[^\r\n\''"]+)[\''"]?') {
        $command = $matches["v"].Trim()
    }
    $cwd = $null
    if ($body -match '(?m)^\s*cwd\s*=\s*[\''"]?(?<v>[^\r\n\''"]+)[\''"]?') {
        $cwd = $matches["v"].Trim()
    }
    $args = @()
    # Inline array on a single line: args = ["a","b"]
    if ($body -match '(?ms)\bargs\s*=\s*\[(?<arr>[^\]]*)\]') {
        $arrBody = $matches["arr"]
        $inlineMatches = [regex]::Matches($arrBody, '[\''"](?<v>[^\''"]*)[\''"]')
        foreach ($im in $inlineMatches) {
            $args += $im.Groups["v"].Value
        }
    }
    return @{
        present = $true
        command = $command
        args = $args
        cwd = $cwd
        body = $body.Trim()
    }
}

function Read-OpenCodeJsonSection {
    param([string]$JsonPath)
    if (-not (Test-Path -LiteralPath $JsonPath)) {
        return @{ present = $false; reason = "config not found" }
    }
    try {
        $cfg = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json
    } catch {
        return @{ present = $false; reason = "config not valid JSON: $_" }
    }
    if (-not $cfg.mcpServers) {
        return @{ present = $false; reason = "no mcpServers section" }
    }
    $entry = $cfg.mcpServers.jinli_soul_core
    if (-not $entry) {
        return @{ present = $false; reason = "jinli_soul_core entry missing" }
    }
    return @{
        present = $true
        command = $entry.command
        args = @($entry.args)
        cwd = $entry.cwd
    }
}

function Compare-Section {
    param(
        [hashtable]$Current,
        [string]$DesiredCommand,
        [string[]]$DesiredArgs,
        [string]$DesiredCwd
    )
    if (-not $Current.present) {
        return @{
            matches = $false
            reason = $Current.reason
        }
    }
    $cmdMatch = ($Current.command -eq $DesiredCommand)
    $argsList = @($Current.args)
    $argsMatch = ($argsList.Count -eq $DesiredArgs.Count)
    if ($argsMatch) {
        for ($i = 0; $i -lt $DesiredArgs.Count; $i++) {
            if ($argsList[$i] -ne $DesiredArgs[$i]) {
                $argsMatch = $false
                break
            }
        }
    }
    $cwdMatch = ($Current.cwd -eq $DesiredCwd)
    if ($cmdMatch -and $argsMatch -and $cwdMatch) {
        return @{ matches = $true }
    }
    return @{
        matches = $false
        command_match = $cmdMatch
        args_match = $argsMatch
        cwd_match = $cwdMatch
        current_command = $Current.command
        current_args = $argsList
        current_cwd = $Current.cwd
    }
}

function Backup-Config {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $backupDir = Join-Path $PSScriptRoot "backups"
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $baseName = Split-Path -Leaf $Path
    $backupName = "$($baseName).bak-$timestamp"
    $backupPath = Join-Path $backupDir $backupName
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    return $backupPath
}

# ---------------------------------------------------------------------------
# Iterate IDEs
# ---------------------------------------------------------------------------

$results = [ordered]@{}
$humanLines = @()
$anyDrift = $false

foreach ($ideName in ($registry.ides.PSObject.Properties.Name | Sort-Object)) {
    if ($TargetIde -ne "all" -and $TargetIde -ne $ideName) { continue }

    $ide = $registry.ides.$ideName
    $cfgPath = $ide.config_file

    # Load current section
    $current = $null
    if ($ide.config_format -eq "toml") {
        $current = Read-CodexTomlSection -TomlPath $cfgPath -SectionHeader $ide.section
    } elseif ($ide.config_format -eq "json") {
        $current = Read-OpenCodeJsonSection -JsonPath $cfgPath
    } else {
        $current = @{ present = $false; reason = "unknown config_format: $($ide.config_format)" }
    }

    $cmp = Compare-Section -Current $current -DesiredCommand $desiredCommand -DesiredArgs $desiredArgs -DesiredCwd $desiredCwd

    $status = if ($cmp.matches) { "ok" } else { "drift" }

    $resultEntry = [ordered]@{
        status = $status
        installed = $current.present
        auto_sync = [bool]$ide.auto_sync
        config_file = $cfgPath
        config_format = $ide.config_format
    }

    if ($cmp.matches) {
        $resultEntry.current = @{
            command = $current.command
            args = @($current.args)
            cwd = $current.cwd
        }
        $resultEntry.action = "none"
    } else {
        $anyDrift = $true
        $resultEntry.expected = @{
            command = $desiredCommand
            args = $desiredArgs
            cwd = $desiredCwd
        }
        $resultEntry.diff = @{
            reason = if ($current.present) { "values do not match registry" } else { $current.reason }
        }
        if ($current.present) {
            $resultEntry.diff.current_command = $current.command
            $resultEntry.diff.current_args = @($current.args)
            $resultEntry.diff.current_cwd = $current.cwd
        }
        if ($ide.auto_sync) {
            $resultEntry.action = "auto_sync_available"
        } else {
            $resultEntry.action = "manual_required"
            $resultEntry.manual_step = $ide.manual_step
            $resultEntry.reason_for_manual = $ide.reason_for_manual_only
        }
    }

    # doctor mode: attach explainability
    if ($Mode -eq "doctor") {
        $resultEntry.diagnosis = @{
            installed = $current.present
            enabled = $current.present
            runtime_callable = $current.present
            plugin_package_present = (Test-Path -LiteralPath $server.package_root)
            server_mjs_present = (Test-Path -LiteralPath (Join-Path $server.package_root "mcp\server.mjs"))
            node_executable_present = (Test-Path -LiteralPath $server.node_command)
        }
    }

    # apply mode: do the write when allowed
    if ($Mode -eq "apply") {
        if (-not $ide.auto_sync) {
            $resultEntry.apply_outcome = "skipped_manual_only"
            $resultEntry.apply_reason = "auto_sync=false for this IDE; manual step required"
        } elseif ($cmp.matches) {
            $resultEntry.apply_outcome = "noop_already_in_sync"
        } else {
            # Build the new mcpServers block for JSON-based configs
            $backupPath = Backup-Config -Path $cfgPath
            $resultEntry.apply_backup = $backupPath

            try {
                $cfgRaw = Get-Content -LiteralPath $cfgPath -Raw
                $cfgObj = $cfgRaw | ConvertFrom-Json

                if (-not $cfgObj.mcpServers) {
                    # Need to add mcpServers property — easiest: rebuild as PSCustomObject
                    $newObj = [PSCustomObject]@{
                        mcpServers = [PSCustomObject]@{
                            jinli_soul_core = [PSCustomObject]@{
                                command = $desiredCommand
                                args = $desiredArgs
                                cwd = $desiredCwd
                            }
                        }
                    }
                    $newJson = $newObj | ConvertTo-Json -Depth 10
                } else {
                    $cfgObj.mcpServers | Add-Member -NotePropertyName "jinli_soul_core" -NotePropertyValue ([PSCustomObject]@{
                        command = $desiredCommand
                        args = $desiredArgs
                        cwd = $desiredCwd
                    }) -Force
                    $newJson = $cfgObj | ConvertTo-Json -Depth 10
                }

                Set-Content -LiteralPath $cfgPath -Value $newJson -Encoding UTF8

                # Re-verify after write
                $verify = Read-OpenCodeJsonSection -JsonPath $cfgPath
                $verifyCmp = Compare-Section -Current $verify -DesiredCommand $desiredCommand -DesiredArgs $desiredArgs -DesiredCwd $desiredCwd
                if ($verifyCmp.matches) {
                    $resultEntry.apply_outcome = "success"
                    $resultEntry.status = "ok"
                } else {
                    $resultEntry.apply_outcome = "verify_failed"
                    $resultEntry.apply_verify_reason = "post-write section did not match registry"
                }
            } catch {
                $resultEntry.apply_outcome = "error"
                $resultEntry.apply_error = "$_"
            }
        }
    }

    $results[$ideName] = $resultEntry
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

$payload = [ordered]@{
    mode = $Mode
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    registry_version = $registry.version
    registry_path = $RegistryPath
    server_id = $serverId
    results = $results
}

if ($OutputJson) {
    $payload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputJson -Encoding UTF8
    Write-Host "JSON report written: $OutputJson" -ForegroundColor DarkGray
}

# Human-readable output
Write-Host ""
Write-Host "=== jinli-ide-sync :: $Mode ===" -ForegroundColor Cyan
Write-Host "Registry : $RegistryPath (v$($registry.version))"
Write-Host "Server   : $serverId  ($($server.node_command) $($server.node_args -join ' '))"
Write-Host "Time     : $($payload.timestamp)"
Write-Host ""

foreach ($ideName in ($results.Keys | Sort-Object)) {
    $r = $results[$ideName]
    $icon = if ($r.status -eq "ok") { "[OK]   " } else { "[DRIFT]" }
    $color = if ($r.status -eq "ok") { "Green" } else { "Yellow" }
    Write-Host ("{0,-8} {1,-10} installed={2,-5} auto_sync={3,-5} action={4}" -f $icon, $ideName, $r.installed, $r.auto_sync, $r.action) -ForegroundColor $color

    if ($r.status -ne "ok") {
        if ($r.diff.reason) {
            Write-Host ("         reason: {0}" -f $r.diff.reason) -ForegroundColor DarkYellow
        }
        if ($r.expected) {
            Write-Host ("         expected: command={0} args=[{1}] cwd={2}" -f $r.expected.command, ($r.expected.args -join " "), $r.expected.cwd) -ForegroundColor DarkGray
        }
        if ($r.manual_step) {
            Write-Host ("         manual_step: {0}" -f $r.manual_step) -ForegroundColor Yellow
        }
    }

    if ($Mode -eq "doctor") {
        $d = $r.diagnosis
        Write-Host ("         plugin_pkg_present    : {0}" -f $d.plugin_package_present)
        Write-Host ("         server_mjs_present    : {0}" -f $d.server_mjs_present)
        Write-Host ("         node_exe_present      : {0}" -f $d.node_executable_present)
    }

    if ($Mode -eq "apply" -and $r.apply_outcome) {
        Write-Host ("         apply_outcome: {0}" -f $r.apply_outcome) -ForegroundColor DarkCyan
        if ($r.apply_backup) {
            Write-Host ("         backup       : {0}" -f $r.apply_backup) -ForegroundColor DarkCyan
        }
        if ($r.apply_error) {
            Write-Host ("         apply_error  : {0}" -f $r.apply_error) -ForegroundColor Red
        }
    }
}

Write-Host ""
if ($anyDrift) {
    Write-Host "[SUMMARY] drift detected on one or more IDEs; see manual_step / apply_outcome above." -ForegroundColor Yellow
} else {
    Write-Host "[SUMMARY] all registered IDEs in sync with registry." -ForegroundColor Green
}

# Exit codes:
#   0 = all OK (check/doctor); apply succeeded for all auto_sync ide
#   1 = drift detected (check/doctor); nothing to apply
#   3 = apply was attempted but verify failed or error
#   4 = registry missing or invalid
$exitCode = 0
if ($Mode -eq "apply") {
    foreach ($r in $results.Values) {
        if ($r.apply_outcome -eq "verify_failed" -or $r.apply_outcome -eq "error") {
            $exitCode = 3
            break
        }
    }
}
if ($exitCode -eq 0 -and $anyDrift -and $Mode -ne "apply") {
    # check/doctor with drift is informational, not failure; keep exit 0
    $exitCode = 0
}
exit $exitCode
