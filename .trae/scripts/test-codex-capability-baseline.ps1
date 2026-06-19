# test-codex-capability-baseline.ps1
# Validates capability-baseline.json schema, secret exclusion, and structure.
# Verifies: AC04 (baseline valid + secret-free), AC10 (no secret values in artifacts)

param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$BaselinePath = Join-Path $Root ".codex\capability-baseline.json"
$Passed = 0
$Failed = 0
$Warnings = 0
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

function Assert-Warn {
    param([string]$Name, [scriptblock]$Condition, [string]$WarnMessage)
    try {
        $result = & $Condition
        if ($result) {
            Write-Green "  [PASS] $Name"
            $script:Passed++
            $script:Results += [pscustomobject]@{ Test = $Name; Result = "PASS"; Detail = "" }
        } else {
            Write-Yellow "  [WARN] $Name - $WarnMessage"
            $script:Warnings++
            $script:Results += [pscustomobject]@{ Test = $Name; Result = "WARN"; Detail = $WarnMessage }
        }
    } catch {
        Write-Red "  [FAIL] $Name - Exception: $_"
        $script:Failed++
        $script:Results += [pscustomobject]@{ Test = $Name; Result = "FAIL"; Detail = $_ }
    }
}

# ===========================================================
# AC04: Capability baseline is valid and secret-free
# ===========================================================
Write-Host "=== T1: Baseline Schema Validation (AC04) ==="

# T1.1: Baseline file exists
Assert "Baseline file exists" { Test-Path $BaselinePath } "File not found at $BaselinePath"

if (Test-Path $BaselinePath) {
    try {
        $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
    } catch {
        Write-Red "  [FAIL] Baseline JSON parse error: $_"
        $script:Failed++
        Write-Host ""
        Write-Host "=== SUMMARY ==="
        Write-Host "Passed: $Passed | Failed: $Failed | Warnings: $Warnings"
        if ($Failed -gt 0) { exit 1 } else { exit 0 }
    }

    # T1.2: Schema version present
    Assert "Schema version field exists" {
        $null -ne $baseline.version -and $baseline.version -ne ""
    } "version field missing or empty"

    # T1.3: Schema version semantic
    Assert "Schema version follows semver" {
        $baseline.version -match '^\d+\.\d+\.\d+$'
    } "version '$($baseline.version)' does not match semver pattern"

    # T1.4: $schema field present
    Assert "`$schema field exists" {
        $null -ne $baseline.'$schema' -and $baseline.'$schema' -ne ""
    } '$schema field missing or empty'

    # T1.5: merge_policy is allowlist
    Assert "Merge policy is allowlist" {
        $baseline.merge_policy -eq "allowlist"
    } "merge_policy is '$($baseline.merge_policy)', expected 'allowlist'"

    # T1.6: Project skill canonical source defined
    Assert "Project skill canonical source exists" {
        $null -ne $baseline.project_skill -and
        $null -ne $baseline.project_skill.canonical_source -and
        $baseline.project_skill.canonical_source -ne ""
    } "project_skill.canonical_source missing or empty"

    # T1.7: Codex adapter path defined
    Assert "Codex adapter path exists" {
        $null -ne $baseline.project_skill.codex_adapter -and
        $baseline.project_skill.codex_adapter -ne ""
    } "project_skill.codex_adapter missing or empty"

    # T1.8: Adapter type is junction
    Assert "Adapter type is junction" {
        $baseline.project_skill.adapter_type -eq "junction"
    } "adapter_type is '$($baseline.project_skill.adapter_type)', expected 'junction'"

    # T1.9: Required marketplaces exist
    Assert "Required marketplaces section exists" {
        $null -ne $baseline.required_marketplaces -and $baseline.required_marketplaces.Count -gt 0
    } "required_marketplaces missing or empty"

    # T1.10: Required plugins exist
    Assert "Required plugins section exists" {
        $null -ne $baseline.required_plugins -and $baseline.required_plugins.Count -gt 0
    } "required_plugins missing or empty"

    # T1.11: Shared sections defined
    Assert "Shared sections defined" {
        $null -ne $baseline.shared_sections -and
        $null -ne $baseline.shared_sections.marketplaces -and
        $null -ne $baseline.shared_sections.plugins
    } "shared_sections missing required subsections"

    # T1.12: Provider-specific sections declared
    Assert "Provider-specific sections declared" {
        $null -ne $baseline.provider_specific_sections -and
        $null -ne $baseline.provider_specific_sections.preserved_sections -and
        $baseline.provider_specific_sections.preserved_sections.Count -gt 0
    } "provider_specific_sections.preserved_sections missing or empty"

    # T1.13: Secret exclusions declared
    Assert "Secret exclusions declared" {
        $null -ne $baseline.secret_exclusions -and
        $null -ne $baseline.secret_exclusions.excluded_patterns -and
        $baseline.secret_exclusions.excluded_patterns.Count -gt 0
    } "secret_exclusions missing or empty"

    # T1.14: Validation checks declared
    Assert "Validation checks declared" {
        $null -ne $baseline.validation -and
        $null -ne $baseline.validation.required_checks -and
        $baseline.validation.required_checks.Count -gt 0
    } "validation.required_checks missing or empty"

    # T1.15: No hardcoded skill count
    Assert "No hardcoded numeric skill count in baseline" {
        $baselineRaw = Get-Content -LiteralPath $BaselinePath -Raw
        $baselineRaw -notmatch '"(skill_count|total_skills|active_skills)"\s*:\s*\d+' -and
        $baselineRaw -notmatch '"count"\s*:\s*(52|56)\b'
    } "Baseline contains hardcoded skill count (52, 56, or skill_count field)"

    # T1.16: jinli-soul-core@personal is in required plugins
    Assert "jinli-soul-core@personal in required plugins" {
        $found = $false
        foreach ($plugin in $baseline.required_plugins) {
            if ($plugin.id -eq "jinli-soul-core@personal") { $found = $true; break }
        }
        $found
    } "jinli-soul-core@personal not found in required_plugins"
}

# ===========================================================
# AC10: Secret scanning - no secret values in artifacts
# ===========================================================
Write-Host "`n=== T1: Secret Scanning (AC10) ==="

$secretPatterns = @(
    @{ Pattern = '(?i)api[_-]?key\s*[=:]\s*["'']?[\w\-\.]{20,}["'']?'; Label = "API key assignment" },
    @{ Pattern = '(?i)sk-[a-zA-Z0-9\-]{20,}'; Label = "OpenAI-style secret key (sk-...) prefix" },
    @{ Pattern = '(?i)Bearer\s+[a-zA-Z0-9\-\._~\+\/]{20,}='; Label = "Bearer token" },
    @{ Pattern = '(?i)"(token|auth|secret|password)"\s*:\s*"[^\s"]{8,}"'; Label = "Named secret field with value" },
    @{ Pattern = '(?i)ghp_[a-zA-Z0-9]{36}'; Label = "GitHub personal access token" },
    @{ Pattern = '(?i)gho_[a-zA-Z0-9]{36}'; Label = "GitHub OAuth token" },
    @{ Pattern = '(?i)AKIA[0-9A-Z]{16}'; Label = "AWS access key" },
    @{ Pattern = '(?i)"private_key"\s*:\s*"-----BEGIN'; Label = "Private key PEM" },
    @{ Pattern = '(?i)eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'; Label = "JWT token" }
)

# Scan baseline file
$baselineContent = Get-Content -LiteralPath $BaselinePath -Raw
$secretsFound = $false
foreach ($sp in $secretPatterns) {
    if ($baselineContent -match $sp.Pattern) {
        Write-Red "  [FAIL] Baseline contains potential secret: $($sp.Label)"
        $secretsFound = $true
        $script:Failed++
        $script:Results += [pscustomobject]@{ Test = "Secret scan: $($sp.Label)"; Result = "FAIL"; Detail = "Found in baseline" }
    }
}
if (-not $secretsFound) {
    Write-Green "  [PASS] Baseline secret scan clean"
    $script:Passed++
    $script:Results += [pscustomobject]@{ Test = "Baseline secret scan"; Result = "PASS"; Detail = "No secrets found" }
}

# Scan test output directory for secrets
$testScriptDir = $PSScriptRoot
$scriptFiles = @(
    (Join-Path $testScriptDir "test-codex-capability-baseline.ps1"),
    (Join-Path $testScriptDir "test-codex-skill-discovery.ps1"),
    (Join-Path $testScriptDir "test-ccswitch-codex-config-sync.ps1"),
    (Join-Path $testScriptDir "validate-codex-capabilities.ps1")
)
# Exclude self from scan (contains regex patterns for secret detection)
$secretScanExclude = @(
    (Join-Path $testScriptDir "test-codex-capability-baseline.ps1")
)
$secretsFoundScripts = $false
foreach ($sf in $scriptFiles) {
    if ($sf -in $secretScanExclude) { continue }
    if (Test-Path $sf) {
        $content = Get-Content -LiteralPath $sf -Raw
        foreach ($sp in $secretPatterns) {
            if ($content -match $sp.Pattern) {
                Write-Red "  [FAIL] Script $(Split-Path $sf -Leaf) contains potential secret: $($sp.Label)"
                $secretsFoundScripts = $true
                $script:Failed++
            }
        }
    }
}
if (-not $secretsFoundScripts) {
    Write-Green "  [PASS] Test script secret scan clean"
    $script:Passed++
    $script:Results += [pscustomobject]@{ Test = "Script secret scan"; Result = "PASS"; Detail = "No secrets found" }
}

# Verify redacted value placeholder is used consistently
Assert "Redacted placeholder declared in baseline" {
    $baseline.secret_exclusions.redacted_value_placeholder -eq "<REDACTED>"
} "redacted_value_placeholder missing or wrong value"

# ===========================================================
# Negative fixture: invalid baseline JSON
# ===========================================================
Write-Host "`n=== T1: Negative Fixtures ==="

$fixtureDir = Join-Path $env:TEMP "codex-baseline-fixtures"
if (Test-Path $fixtureDir) { Remove-Item -LiteralPath $fixtureDir -Recurse -Force }
New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

# Fixture: Missing version
$missingVersion = @{
    '$schema' = "capability-baseline-schema-1.0.0"
    merge_policy = "allowlist"
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $fixtureDir "missing-version.json") -Value $missingVersion
Assert "Negative: missing version detected" {
    try {
        $j = Get-Content (Join-Path $fixtureDir "missing-version.json") -Raw | ConvertFrom-Json
        $null -eq $j.version -or $j.version -eq ""
    } catch { $false }
} "Should detect missing version field"

# Fixture: Non-allowlist merge policy
$badPolicy = @{
    '$schema' = "capability-baseline-schema-1.0.0"
    version = "1.0.0"
    merge_policy = "overwrite"
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $fixtureDir "bad-policy.json") -Value $badPolicy
Assert "Negative: non-allowlist merge policy detected" {
    try {
        $j = Get-Content (Join-Path $fixtureDir "bad-policy.json") -Raw | ConvertFrom-Json
        $j.merge_policy -ne "allowlist"
    } catch { $false }
} "Should detect non-allowlist merge policy"

# Fixture: Contains hardcoded count
$hardcodedCount = @{
    '$schema' = "capability-baseline-schema-1.0.0"
    version = "1.0.0"
    merge_policy = "allowlist"
    skill_count = 56
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $fixtureDir "hardcoded-count.json") -Value $hardcodedCount
Assert "Negative: hardcoded skill count detected" {
    $raw = Get-Content (Join-Path $fixtureDir "hardcoded-count.json") -Raw
    $raw -match '"skill_count"\s*:\s*\d+'
} "Should detect hardcoded skill_count field"

# Fixture: Contains mock secret (should be detected)
$secretFixturePath = Join-Path $fixtureDir "with-secret.json"
Set-Content -LiteralPath $secretFixturePath -Value '{ "$schema": "capability-baseline-schema-1.0.0", "version": "1.0.0", "merge_policy": "allowlist", "description": "Test with sk-proj-1234567890abcdef1234567890abcdef" }'
$secretFixtureContent = Get-Content -LiteralPath $secretFixturePath -Raw
Assert "Negative: secret pattern detected in fixture" {
    $secretFixtureContent -match '(?i)sk-[a-zA-Z0-9\-]{20,}'
} "Should detect OpenAI-style secret key in fixture"

# Cleanup
Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue

# ===========================================================
# Summary
# ===========================================================
Write-Host "`n=== T1 SUMMARY ==="
Write-Host "Passed: $Passed | Failed: $Failed | Warnings: $Warnings"
$ac04Result = if ($Failed -eq 0) { "PASS" } else { "FAIL" }
$ac10Result = if (-not $secretsFound) { "PASS" } else { "FAIL" }
Write-Host "AC04 (baseline valid + secret-free): $ac04Result"
Write-Host "AC10 (secret scanning): $ac10Result"

if ($Failed -gt 0) { exit 1 }
exit 0
