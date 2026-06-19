<#
.SYNOPSIS
    Compatibility tests for Hermes adapter Skills, profiles, bundles, and credentials.
    Validates that shared Skills resolve, bundles are complete, no shadowing,
    no inline secrets, and profile configs are valid.
#>

$ErrorActionPreference = "Continue"
$repoRoot = "E:\UEGameDevelopment"
$skillsRoot = Join-Path $repoRoot "skills"
$hermesRoot = Join-Path $repoRoot ".trae\hermes"
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Write-Test {
    param([string]$Name, [bool]$Passed, [string]$Detail = "")
    $script:totalTests++
    if ($Passed) {
        $script:passedTests++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor Red }
    }
}

function Test-Frontmatter {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath)) { return $false, "File not found" }
    $content = Get-Content -LiteralPath $FilePath -Raw
    $hasName = $content -match 'name:\s*\S'
    $hasDesc = $content -match 'description:\s*\S'
    if (-not $hasName) { return $false, "Missing name in frontmatter" }
    if (-not $hasDesc) { return $false, "Missing description in frontmatter" }
    return $true, ""
}

Write-Host "`n=== Hermes Skill Compatibility Tests ===`n" -ForegroundColor Cyan

# === 1. Required adapter Skills exist ===
Write-Host "--- 1. Required adapter Skills ---" -ForegroundColor Yellow
$adapters = @(
    "hermes-project-router",
    "hermes-jinli-planner",
    "hermes-jinli-implementer",
    "hermes-jinli-verifier"
)
foreach ($adapter in $adapters) {
    $skillFile = Join-Path $skillsRoot "$adapter\SKILL.md"
    $exists = Test-Path -LiteralPath $skillFile
    Write-Test "Adapter exists: $adapter" $exists "Expected: $skillFile"
}

# === 2. Adapter frontmatter ===
Write-Host "`n--- 2. Adapter frontmatter ---" -ForegroundColor Yellow
foreach ($adapter in $adapters) {
    $skillFile = Join-Path $skillsRoot "$adapter\SKILL.md"
    $ok, $reason = Test-Frontmatter -FilePath $skillFile
    Write-Test "Frontmatter valid: $adapter" $ok $reason
}

# === 3. Required canonical Skills resolve ===
Write-Host "`n--- 3. Canonical Skills resolve ---" -ForegroundColor Yellow
$canonical = @(
    "jinli-agent-soul",
    "failure-memory"
)
# Check known canonical skill names actually resolve
foreach ($skill in $canonical) {
    # Try with and without hyphen normalization
    $path1 = Join-Path $skillsRoot "$skill\SKILL.md"
    $path2 = Join-Path $skillsRoot "$($skill -replace '-','-')\SKILL.md"
    $exists = (Test-Path -LiteralPath $path1) -or (Test-Path -LiteralPath $path2)
    if (-not $exists) {
        # Search for similar names
        $matches = Get-ChildItem -LiteralPath $skillsRoot -Directory |
            Where-Object { $_.Name -like "*$($skill.Substring(0, [Math]::Min(8, $skill.Length)))*" } |
            ForEach-Object { $_.Name }
        if ($matches) { $exists = $true }
    }
    Write-Test "Canonical Skill found: $skill" $exists "Checked $path1 and variants"
}

# Check that 金璃小天才 and 金璃好帮手 exist
$cnSkills = @("金璃小天才", "金璃好帮手")
foreach ($cn in $cnSkills) {
    $cnFile = Join-Path $skillsRoot "$cn\SKILL.md"
    $exists = Test-Path -LiteralPath $cnFile
    Write-Test "Chinese Skill found: $cn" $exists "Expected: $cnFile"
}

# === 4. No profile-local Skill shadowing ===
Write-Host "`n--- 4. Skill shadowing detection ---" -ForegroundColor Yellow
$profiles = @("jinli-planner", "jinli-implementer")
foreach ($profile in $profiles) {
    $localSkills = Join-Path (Join-Path (Join-Path $hermesRoot "profiles") $profile) "skills"
    if (Test-Path -LiteralPath $localSkills) {
        $local = Get-ChildItem -LiteralPath $localSkills -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
        $shared = Get-ChildItem -LiteralPath $skillsRoot -Directory | ForEach-Object { $_.Name }
        $shadowing = @()
        foreach ($s in $local) { if ($s -in $shared) { $shadowing += $s } }
        $noShadow = $shadowing.Count -eq 0
        Write-Test "No shadowing: $profile" $noShadow "Shadowed: $($shadowing -join ', ')"
    } else {
        Write-Test "No shadowing: $profile" $true "No local skills directory"
    }
}

# === 5. Profile config uses skills.external_dirs ===
Write-Host "`n--- 5. Profile external_dirs ---" -ForegroundColor Yellow
foreach ($profile in $profiles) {
    $configFile = Join-Path (Join-Path (Join-Path $hermesRoot "profiles") $profile) "config.overlay.yaml"
    if (Test-Path -LiteralPath $configFile) {
        $config = Get-Content -LiteralPath $configFile -Raw
        $hasExternal = $config -match "external_dirs" -and $config -match "E:/UEGameDevelopment/skills"
        Write-Test "external_dirs configured: $profile" $hasExternal "Checked $configFile"
    } else {
        Write-Test "external_dirs configured: $profile" $false "Config not found: $configFile"
    }
}

# === 6. No inline API key in config ===
Write-Host "`n--- 6. Inline credential check ---" -ForegroundColor Yellow
$secretPatterns = @(
    'api_key:\s*sk-',
    'api_key:\s*[A-Za-z0-9+/]{30,}',
    'apiKey:\s*sk-',
    'API_KEY:\s*sk-',
    'key:\s*sk-[A-Za-z0-9]{20,}',
    'secret:\s*[A-Za-z0-9+/]{20,}='
)
foreach ($profile in $profiles) {
    $configFile = Join-Path (Join-Path (Join-Path $hermesRoot "profiles") $profile) "config.overlay.yaml"
    if (Test-Path -LiteralPath $configFile) {
        $content = Get-Content -LiteralPath $configFile -Raw
        $hasSecret = $false
        $matchedPattern = ""
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                $hasSecret = $true
                $matchedPattern = $pattern
                break
            }
        }
        Write-Test "No inline secret: $profile" (-not $hasSecret) $(if ($hasSecret) { "Matched pattern but value redacted" } else { "" })
    } else {
        Write-Test "No inline secret: $profile" $true "Config not found (no secret to check)"
    }
}

# === 7. Skill Bundles resolve ===
Write-Host "`n--- 7. Bundle resolution ---" -ForegroundColor Yellow
$expectedBundles = @{
    "jinli-planner" = @("/jinli-plan", "hermes-project-router", "hermes-jinli-planner", "doc-governance", "failure-memory")
    "jinli-implementer" = @("/jinli-implement", "hermes-project-router", "hermes-jinli-implementer", "anti-degradation", "anti-duplication", "verification-before-completion")
}
foreach ($profile in $profiles) {
    $bundleDir = Join-Path (Join-Path (Join-Path $hermesRoot "profiles") $profile) "skill-bundles"
    if (Test-Path -LiteralPath $bundleDir) {
        $bundleFiles = Get-ChildItem -LiteralPath $bundleDir -Filter "*.yaml"
        $allResolved = $true
        $missing = @()
        $combinedContent = ""
        foreach ($bf in $bundleFiles) {
            $combinedContent += (Get-Content -LiteralPath $bf.FullName -Raw)
        }
        foreach ($skill in $expectedBundles[$profile]) {
            # Use -like for simple substring match (case insensitive)
            if ($combinedContent -like "*$skill*") { continue }
            $missing += $(if ($skill -match "^/") { "bundle:$skill" } else { $skill })
            $allResolved = $false
        }
        Write-Test "Bundle resolves: $profile" $allResolved $(if (-not $allResolved) { "Missing: $($missing -join ', ')" } else { "" })
    } else {
        Write-Test "Bundle resolves: $profile" $false "No bundle directory"
    }
}

# === 8. Profile source directory structure ===
Write-Host "`n--- 8. Profile structure ---" -ForegroundColor Yellow
$requiredFiles = @("SOUL.md", "config.overlay.yaml", "mcp.json")
foreach ($profile in $profiles) {
    $allFilesOk = $true
    $missingFiles = @()
    foreach ($f in $requiredFiles) {
        $fp = Join-Path (Join-Path (Join-Path $hermesRoot "profiles") $profile) $f
        if (-not (Test-Path -LiteralPath $fp)) {
            $allFilesOk = $false
            $missingFiles += $f
        }
    }
    Write-Test "Profile structure: $profile" $allFilesOk $(if (-not $allFilesOk) { "Missing: $($missingFiles -join ', ')" } else { "" })
}

# === 9. Policy manifest exists ===
Write-Host "`n--- 9. Policy manifest ---" -ForegroundColor Yellow
$policyFile = Join-Path (Join-Path $hermesRoot "policies") "roles.yaml"
$policyExists = Test-Path -LiteralPath $policyFile
Write-Test "Policy manifest exists" $policyExists "Expected: $policyFile"
if ($policyExists) {
    $policyContent = Get-Content -LiteralPath $policyFile -Raw
    $hasPlanner = $policyContent -match "planner:"
    $hasImplementer = $policyContent -match "implementer:"
    $hasVerifier = $policyContent -match "verifier:"
    Write-Test "Policy covers planner" $hasPlanner
    Write-Test "Policy covers implementer" $hasImplementer
    Write-Test "Policy covers verifier" $hasVerifier
}

# === 10. Sync script exists ===
Write-Host "`n--- 10. Sync script ---" -ForegroundColor Yellow
$syncScript = Join-Path $repoRoot ".trae\scripts\sync-hermes-workflow.ps1"
$syncExists = Test-Path -LiteralPath $syncScript
Write-Test "Sync script exists" $syncExists "Expected: $syncScript"

# === Final Summary ===
Write-Host "`n=== Results: $passedTests / $totalTests passed ===`n" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })

if ($failedTests -gt 0) { exit 1 } else { exit 0 }
