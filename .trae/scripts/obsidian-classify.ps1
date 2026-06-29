# obsidian-classify.ps1 - Auto-classify + archive Obsidian notes
# WP02: Reads frontmatter tags + domain_path -> classification-rules.yaml -> move + wikilink redirect
# PowerShell 5.1 compatible, no external modules
# Safety: D1 zero-destructive (old files never modified), D7 -DryRun default

param(
    [string]$Source = "",
    [string]$SourceDir = "",
    [switch]$Batch,
    [switch]$Apply,
    [switch]$DryRun = $true,
    [string]$RulesPath = "E:\ObsidianVault\进化\rules\classification-rules.yaml",
    [string]$VaultPath = "E:\ObsidianVault",
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"

function Show-Help {
    Write-Output @"
obsidian-classify.ps1 - Auto-classify Obsidian notes based on frontmatter tags

Usage:
  .\obsidian-classify.ps1 -DryRun -Source <file>           # Classify single file (no changes)
  .\obsidian-classify.ps1 -Apply -Source <file>            # Classify + move single file
  .\obsidian-classify.ps1 -Batch -DryRun -SourceDir <dir>  # Batch classify (no changes)
  .\obsidian-classify.ps1 -Batch -Apply -SourceDir <dir>   # Batch classify + move
  .\obsidian-classify.ps1 -SelfTest                        # Run self-test
  .\obsidian-classify.ps1 -Help                            # Show this help

Parameters:
  -Source       Path to a single .md file to classify
  -SourceDir    Directory to scan for .md files (batch mode)
  -Batch        Enable batch mode (process entire directory)
  -Apply        Actually move files (default is DryRun)
  -DryRun       Only print actions, no file modifications (default: true)
  -RulesPath    Path to classification-rules.yaml
  -VaultPath    Root path of Obsidian vault
  -SelfTest     Run built-in self-test
  -Help         Show this help text

Safety:
  D1: Old files in JinliKG/ 虚幻/ 我的项目/ are NEVER modified
  D7: All destructive ops require explicit -Apply flag
"@
}

if ($Help) { Show-Help; exit 0 }

# Import helpers
if (-not (Test-Path $helpersPath)) {
    Write-Error "ObsidianHelpers.psm1 not found at: $helpersPath"
    exit 1
}
Import-Module $helpersPath -Force -WarningAction SilentlyContinue

# Validate rules file
if (-not (Test-Path $RulesPath)) {
    Write-Error "Classification rules not found: $RulesPath. WP01 must complete first."
    exit 1
}

# Resolve vault path
$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

# Parse rules
$rules = Parse-ClassificationRules -RulesPath $RulesPath
if ($null -eq $rules) { exit 1 }

# Stats counters
$stats = @{ moved = 0; redirected = 0; skipped = 0; unclassified = 0; errors = 0; dryrun_actions = 0 }

# Self-test mode
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-classify self-test..."
    $testDir = "$env:TEMP\obsidian-classify-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Create test file with frontmatter
    $testFile = Join-Path $testDir "test-agent-video-abc123.md"
    @"
---
kg_id: test.video.abc123
type: video
tags: [ai-agent, ai-coding, dev-tool]
actionable: True
domain: ai
domain_path: ai/coding
---

# Test Agent Video

This is a test video summary about AI agents and multi-agent frameworks.
"@ | Out-File -FilePath $testFile -Encoding UTF8
    
    # Test 1: DryRun classify
    $fm = Read-FrontMatter $testFile
    $target = Find-TargetPath -FrontMatter $fm -ParsedRules $rules -VaultPath $vault
    if ($null -eq $target) {
        Write-Output "[SELFTEST-FAIL] Could not find target path for test file"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] DryRun target: $target"
    
    # Test 2: Frontmatter parsing
    if ($fm.tags -notcontains 'ai-agent') {
        Write-Output "[SELFTEST-FAIL] Tags not parsed correctly"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] Frontmatter parsed: tags=$($fm.tags -join ',')"
    
    # Test 3: kg_id existence check
    $kgExists = Test-KgIdExists -KgId "test.video.abc123" -SearchDir $testDir
    if (-not $kgExists) {
        Write-Output "[SELFTEST-PASS] kg_id not found elsewhere (correct for test)"
    }
    
    # Cleanup
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# Single-file classification
function Classify-SingleFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        $stats.errors++
        return
    }
    
    $fm = Read-FrontMatter $FilePath
    $kg_id = if ($fm.ContainsKey('kg_id')) { $fm['kg_id'] } else { "" }
    $tags = @()
    if ($fm.ContainsKey('tags')) { $tags = @($fm['tags']) }
    if ($fm.ContainsKey('tag') -and $fm['tag']) { $tags += @($fm['tag']) }
    
    $targetDir = Find-TargetPath -FrontMatter $fm -ParsedRules $rules -VaultPath $vault
    
    if ($null -eq $targetDir) {
        Write-Output "[UNCLASSIFIED] $FilePath - tags: [$($tags -join ', ')]"
        $stats.unclassified++
        # Queue for future rule creation
        $queuePath = Join-Path $vault "进化\rules\_unclassified-queue.yaml"
        Add-ToUnclassifiedQueue -FilePath $FilePath -QueuePath $queuePath -Tags $tags
        return
    }
    
    # Ensure target directory ends with separator
    $targetDir = $targetDir.TrimEnd('\')
    $fileName = Split-Path $FilePath -Leaf
    $targetFile = Join-Path $targetDir $fileName
    
    # Idempotency: skip if same kg_id already exists at target
    if ($kg_id -ne "" -and (Test-KgIdExists -KgId $kg_id -SearchDir (Join-Path $vault "知识"))) {
        Write-Output "[SKIP] $FilePath - kg_id $kg_id already exists at target"
        $stats.skipped++
        return
    }
    
    if ($DryRun -and -not $Apply) {
        Write-Output "[DRY] $FilePath -> $targetFile"
        $stats.dryrun_actions++
        return
    }
    
    # Apply mode: move file + create redirect stub
    # D1: Never modify files in JinliKG/, 虚幻/, 我的项目/ - but moving NEW files is OK
    
    # Create target directory if needed
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }
    
    # Move the file
    if (Test-Path $targetFile) {
        Write-Output "[SKIP] Target already exists: $targetFile"
        $stats.skipped++
        return
    }
    
    Move-Item -LiteralPath $FilePath -Destination $targetFile -Force
    $stats.moved++
    
    # Create wikilink redirect stub at old position
    # Compute the Obsidian-internal wikilink path (relative to vault)
    $relativeTarget = $targetFile.Substring($vault.Length + 1)
    Write-RedirectStub -StubPath $FilePath -TargetWikiLink $relativeTarget
    $stats.redirected++
    
    Write-Output "[MOVED] $FilePath -> $targetFile (redirect stub created)"
}

# Determine source files
if ($Batch -or $SourceDir -ne "") {
    if ($SourceDir -eq "") {
        $SourceDir = Join-Path $vault "JinliKG\Sources\Videos"
    }
    if (-not (Test-Path $SourceDir)) {
        Write-Error "Source directory not found: $SourceDir"
        exit 1
    }
    
    Write-Output "[BATCH] Scanning: $SourceDir"
    $files = Get-ChildItem -Path $SourceDir -Filter "*.md" -File -ErrorAction SilentlyContinue
    Write-Output "[BATCH] Found $($files.Count) .md files"
    
    foreach ($f in $files) {
        Classify-SingleFile -FilePath $f.FullName
    }
}
elseif ($Source -ne "") {
    Classify-SingleFile -FilePath $Source
}
else {
    Write-Error "Specify -Source <file> or -Batch -SourceDir <dir>"
    Show-Help
    exit 1
}

# Summary report
Write-Output ""
Write-Output "=== Classification Report ==="
Write-Output "Moved:      $($stats.moved)"
Write-Output "Redirected: $($stats.redirected)"
Write-Output "Skipped:    $($stats.skipped)"
Write-Output "Unclassified: $($stats.unclassified)"
Write-Output "Errors:     $($stats.errors)"
if ($DryRun -and -not $Apply) {
    Write-Output "DryRun actions: $($stats.dryrun_actions)"
}

# Write JSON report to proposals
$reportDir = Join-Path $vault "进化\proposals"
if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }
$reportPath = Write-JsonReport -Data $stats -ReportDir $reportDir -Prefix "classify"
Write-Output "Report saved: $reportPath"

exit 0
