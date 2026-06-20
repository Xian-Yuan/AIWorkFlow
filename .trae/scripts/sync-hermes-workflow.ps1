<#
.SYNOPSIS
    Synchronize repository-owned Hermes profile sources to the runtime.
.DESCRIPTION
    Copies repository-owned profile/plugin/bundle/policy files to the Hermes
    runtime under .tools/hermes-worker, preserving user-owned state (.env,
    memories, sessions, logs).
.PARAMETER Check
    Check-only mode. Reports drift without modifying files.
.PARAMETER Apply
    Apply synchronization: copy repository sources to runtime.
.PARAMETER Profile
    Optional profile name filter (jinli-planner, jinli-implementer).
.EXAMPLE
    .\sync-hermes-workflow.ps1 -Check
.EXAMPLE
    .\sync-hermes-workflow.ps1 -Apply -Profile jinli-planner
#>

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Apply,
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = "E:\UEGameDevelopment"
$sourceRoot = Join-Path $repoRoot ".trae\hermes"
$runtimeRoot = Join-Path $repoRoot ".tools\hermes-worker"

# === Helper Functions ===

function Write-Summary {
    param([string]$Status, [string]$Message)
    $color = if ($Status -eq "PASS") { "Green" }
             elseif ($Status -eq "FAIL") { "Red" }
             elseif ($Status -eq "WARN") { "Yellow" }
             else { "White" }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Test-InlineSecret {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath)) { return $false }
    $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
    # Check for common inline secret patterns
    $patterns = @(
        'api_key:\s+sk-',                    # api_key with OpenAI-style value
        'api_key:\s+[A-Za-z0-9+/]{20,}',     # api_key with base64 value
        'apiKey:\s+sk-',                     # camelCase variant
        'key:\s+sk-[A-Za-z0-9]{10,}',        # key with OpenAI-style value
        'secret:\s+sk-',                     # secret with key value
        'password:\s+[^\s${]{8,}'             # password with non-env-var value
        'key:\s*sk-',             # OpenAI-style keys
        'key:\s*[A-Za-z0-9+/]{20,}={0,2}'  # base64-looking values
    )
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            return $true
        }
    }
    return $false
}

function Test-SkillShadowing {
    param([string]$ProfileDir)
    $localSkills = Join-Path $ProfileDir "skills"
    if (-not (Test-Path -LiteralPath $localSkills)) { return @() }
    $sharedRoot = Join-Path $repoRoot "skills"
    $sharedSkills = Get-ChildItem -LiteralPath $sharedRoot -Directory | ForEach-Object { $_.Name }
    $local = Get-ChildItem -LiteralPath $localSkills -Directory | ForEach-Object { $_.Name }
    $shadowed = @()
    foreach ($s in $local) {
        if ($s -in $sharedSkills) {
            $shadowed += $s
        }
    }
    return $shadowed
}

function Get-FileHashSafe {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath)) { return $null }
    try {
        return (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash
    } catch {
        return "ERROR"
    }
}

# === Main Logic ===

if (-not $Check -and -not $Apply) {
    Write-Host "Usage: sync-hermes-workflow.ps1 -Check | -Apply [-Profile <name>]"
    exit 1
}

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    Write-Summary "FAIL" "Source directory not found: $sourceRoot"
    exit 1
}

# Discover profiles to sync
$profiles = @()
if ($Profile) {
    $p = Join-Path (Join-Path $sourceRoot "profiles") $Profile
    if (Test-Path -LiteralPath $p) { $profiles += $Profile }
    else { Write-Summary "FAIL" "Profile not found: $Profile"; exit 1 }
} else {
    $pd = Join-Path $sourceRoot "profiles"
    if (Test-Path -LiteralPath $pd) {
        $profiles = Get-ChildItem -LiteralPath $pd -Directory | ForEach-Object { $_.Name }
    }
}

if ($profiles.Count -eq 0) {
    Write-Summary "FAIL" "No profiles found"
    exit 1
}

$allChecksPassed = $true
$summary = @()

foreach ($profileName in $profiles) {
    Write-Host "`n=== Profile: $profileName ===" -ForegroundColor Cyan
    $sourceProfile = Join-Path (Join-Path $sourceRoot "profiles") $profileName

    # 1. Check profile source exists and has required files
    $requiredFiles = @("SOUL.md", "config.overlay.yaml", "mcp.json")
    $missingSource = @()
    foreach ($f in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $sourceProfile $f))) {
            $missingSource += $f
        }
    }
    if ($missingSource.Count -gt 0) {
        Write-Summary "FAIL" "Missing source files: $($missingSource -join ', ')"
        $allChecksPassed = $false
        $summary += "FAIL: $profileName missing source: $($missingSource -join ', ')"
        continue
    }
    Write-Summary "PASS" "Source files present"

    # 2. Check for inline secrets in source
    $configFile = Join-Path $sourceProfile "config.overlay.yaml"
    if (Test-InlineSecret -FilePath $configFile) {
        Write-Summary "FAIL" "Inline secret detected in $configFile"
        $allChecksPassed = $false
        $summary += "FAIL: $profileName inline secret"
    } else {
        Write-Summary "PASS" "No inline secrets in source config"
    }

    # 3. Check for external_dirs configuration
    $configContent = Get-Content -LiteralPath $configFile -Raw
    if ($configContent -notmatch "external_dirs" -or $configContent -notmatch "E:/UEGameDevelopment/skills") {
        Write-Summary "FAIL" "skills.external_dirs not configured correctly"
        $allChecksPassed = $false
        $summary += "FAIL: $profileName external_dirs missing"
    } else {
        Write-Summary "PASS" "skills.external_dirs configured"
    }

    # 4. Check skill bundles exist
    $bundleDir = Join-Path $sourceProfile "skill-bundles"
    if (-not (Test-Path -LiteralPath $bundleDir)) {
        Write-Summary "WARN" "No skill-bundles directory"
        $summary += "WARN: $profileName no bundles"
    } else {
        $bundles = Get-ChildItem -LiteralPath $bundleDir -Filter "*.yaml" | ForEach-Object { $_.Name }
        Write-Summary "PASS" "Skill bundles: $($bundles -join ', ')"
    }

    # 5. Check for skill shadowing
    $shadowed = Test-SkillShadowing -ProfileDir $sourceProfile
    if ($shadowed.Count -gt 0) {
        Write-Summary "FAIL" "Skill shadowing detected: $($shadowed -join ', ')"
        $allChecksPassed = $false
        $summary += "FAIL: $profileName shadowing: $($shadowed -join ', ')"
    } else {
        Write-Summary "PASS" "No skill shadowing"
    }

    $summary += "PASS: $profileName profile valid"
}

# === Runtime Sync (Apply mode) ===
if ($Apply) {
    Write-Host "`n=== Applying Synchronization ===" -ForegroundColor Cyan

    foreach ($profileName in $profiles) {
    $sourceProfile = Join-Path (Join-Path $sourceRoot "profiles") $profileName
        $runtimeProfile = Join-Path (Join-Path $runtimeRoot "profiles") $profileName

        if (-not (Test-Path -LiteralPath $runtimeProfile)) {
            New-Item -ItemType Directory -Path $runtimeProfile -Force | Out-Null
            Write-Summary "INFO" "Created runtime profile: $runtimeProfile"
        }

        # Copy SOUL.md
        Copy-Item -LiteralPath (Join-Path $sourceProfile "SOUL.md") `
                  -Destination (Join-Path $runtimeProfile "SOUL.md") -Force
        Write-Summary "PASS" "Synced SOUL.md"

        # Merge config.overlay.yaml -> config.yaml (preserving user .env)
        $sourceConfig = Join-Path $sourceProfile "config.overlay.yaml"
        $runtimeConfig = Join-Path $runtimeProfile "config.yaml"
        Copy-Item -LiteralPath $sourceConfig -Destination $runtimeConfig -Force
        Write-Summary "PASS" "Synced config (overlay)"

        # Copy mcp.json
        Copy-Item -LiteralPath (Join-Path $sourceProfile "mcp.json") `
                  -Destination (Join-Path $runtimeProfile "mcp.json") -Force
        Write-Summary "PASS" "Synced mcp.json"

        # Copy skill bundles
        $sourceBundles = Join-Path $sourceProfile "skill-bundles"
        $runtimeBundles = Join-Path $runtimeProfile "skill-bundles"
        if (Test-Path -LiteralPath $sourceBundles) {
            if (-not (Test-Path -LiteralPath $runtimeBundles)) {
                New-Item -ItemType Directory -Path $runtimeBundles -Force | Out-Null
            }
            Copy-Item -LiteralPath "$sourceBundles\*" -Destination $runtimeBundles -Force
            Write-Summary "PASS" "Synced skill bundles"
        }

        # Preserve user-owned .env (never overwrite)
        $envFile = Join-Path $runtimeProfile ".env"
        if (-not (Test-Path -LiteralPath $envFile)) {
            # Create .env from parent .env if available, otherwise empty template
            $parentEnv = Join-Path $runtimeRoot ".env"
            if (Test-Path -LiteralPath $parentEnv) {
                Copy-Item -LiteralPath $parentEnv -Destination $envFile
                Write-Summary "INFO" "Copied parent .env to profile"
            } else {
                "# Add your API keys here - never commit this file`nMODEL_PROVIDER=`nMODEL_NAME=`nAPI_KEY=`n" |
                    Set-Content -LiteralPath $envFile
                Write-Summary "INFO" "Created template .env"
            }
        } else {
            Write-Summary "PASS" "Preserved existing .env"
        }
    }

    # Sync plugin to runtime if plugin source exists
    $pluginSource = Join-Path (Join-Path $sourceRoot "plugins") "jinli-workflow-guard"
    if (Test-Path -LiteralPath $pluginSource) {
        $runtimePlugins = Join-Path (Join-Path $runtimeRoot "plugins") "jinli-workflow-guard"
        if (-not (Test-Path -LiteralPath $runtimePlugins)) {
            New-Item -ItemType Directory -Path $runtimePlugins -Force | Out-Null
        }
        Copy-Item -LiteralPath "$pluginSource\*" -Destination $runtimePlugins -Force -Exclude "__pycache__"
        Write-Summary "PASS" "Synced guard plugin"
    }
}

# === Final Summary ===
Write-Host "`n=== Sync Summary ===" -ForegroundColor Cyan
$passed = ($summary | Where-Object { $_ -match "^PASS" }).Count
$failed = ($summary | Where-Object { $_ -match "^FAIL" }).Count
$warns  = ($summary | Where-Object { $_ -match "^WARN" }).Count
Write-Host "Passed: $passed, Failed: $failed, Warnings: $warns"
foreach ($line in $summary) {
    if ($line -match "^FAIL") {
        Write-Host $line -ForegroundColor Red
    } elseif ($line -match "^WARN") {
        Write-Host $line -ForegroundColor Yellow
    } else {
        Write-Host $line -ForegroundColor Green
    }
}

if ($failed -gt 0) { exit 1 } else { exit 0 }
