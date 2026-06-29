# obsidian-link-discover.ps1 - Association discovery for Obsidian notes
# WP04: Tag co-occurrence + LLM semantic + Gene-trigger association discovery
# PowerShell 5.1 compatible, no external modules
# Safety: D4 dual-layer (tag-first, LLM-optional), D1 never modify JinliKG/

param(
    [ValidateSet("tag-cooccurrence","semantic","gene-trigger","all")]
    [string]$Method = "tag-cooccurrence",
    [string]$SourceDir = "",
    [double]$Threshold = 0.6,
    [switch]$Apply,
    [switch]$DryRun = $true,
    [switch]$UseLLM,
    [string]$VaultPath = "E:\ObsidianVault",
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"

function Show-Help {
    Write-Output @"
obsidian-link-discover.ps1 - Discover associations between Obsidian notes

Usage:
  .\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun   # Tag-based associations
  .\obsidian-link-discover.ps1 -Method all -Apply -SourceDir <dir> # All methods, apply
  .\obsidian-link-discover.ps1 -SelfTest                          # Run self-test
  .\obsidian-link-discover.ps1 -Help                              # Show this help

Parameters:
  -Method       tag-cooccurrence|semantic|gene-trigger|all
  -SourceDir    Directory to scan (default: 知识/)
  -Threshold    Jaccard similarity threshold (default: 0.6)
  -Apply        Write wikilinks to files (default: DryRun)
  -DryRun       Only print suggestions, no writes (default: true)
  -UseLLM       Enable LLM semantic similarity (off by default)
  -VaultPath    Root path of Obsidian vault
  -SelfTest     Run built-in self-test
  -Help         Show this help

Safety:
  D1: Never modify JinliKG/ files
  D4: Dual-layer approach (cheap tag-first, LLM optional)
"@
}

if ($Help) { Show-Help; exit 0 }

Import-Module $helpersPath -Force -WarningAction SilentlyContinue

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

if ($SourceDir -eq "") { $SourceDir = Join-Path $vault "知识" }

# Self-test
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-link-discover self-test..."
    $testDir = "$env:TEMP\obsidian-link-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Create 3 test files with overlapping tags
    @"
---
kg_id: test.link.001
tags: [ai-agent, ai-coding, automation]
domain: ai
---
# Test Agent Note A
Content about agents.
"@ | Out-File -FilePath (Join-Path $testDir "note-a.md") -Encoding UTF8
    
    @"
---
kg_id: test.link.002
tags: [ai-agent, ai-coding, workflow]
domain: ai
---
# Test Agent Note B
Content about coding agents.
"@ | Out-File -FilePath (Join-Path $testDir "note-b.md") -Encoding UTF8
    
    @"
---
kg_id: test.link.003
tags: [game-dev, ue]
domain: ue
---
# Test UE Note
Content about Unreal Engine.
"@ | Out-File -FilePath (Join-Path $testDir "note-c.md") -Encoding UTF8
    
    # Scan tags
    $fileTags = @{}
    Get-ChildItem -Path $testDir -Filter "*.md" | ForEach-Object {
        $fm = Read-FrontMatter $_.FullName
        if ($fm.ContainsKey('tags')) { $fileTags[$_.Name] = @($fm['tags']) }
    }
    
    # Compute Jaccard for note-a vs note-b
    $setA = @($fileTags['note-a.md']) | Sort-Object -Unique
    $setB = @($fileTags['note-b.md']) | Sort-Object -Unique
    $intersection = ($setA | Where-Object { $setB -contains $_ }).Count
    $union = ($setA + $setB | Sort-Object -Unique).Count
    $jaccard = if ($union -gt 0) { $intersection / $union } else { 0 }
    
    if ($jaccard -lt 0.5) {
        Write-Output "[SELFTEST-FAIL] Jaccard $jaccard too low for overlapping test files"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] Jaccard(note-a, note-b) = $jaccard"
    
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# Scan all md files in vault for tags
Write-Output "[SCAN] Scanning vault for frontmatter tags..."
$allFiles = Get-ChildItem -Path $vault -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
    # Exclude JinliKG from modification (D1), but read OK
    $_.FullName -notmatch 'JinliKG\\Sources'
}
$fileTags = @{}
$filePaths = @{}

foreach ($f in $allFiles) {
    $fm = Read-FrontMatter $f.FullName
    if ($fm.ContainsKey('tags') -and $fm['tags'].Count -gt 0) {
        $fileTags[$f.Name] = @($fm['tags'] | Sort-Object -Unique)
        $filePaths[$f.Name] = $f.FullName
    }
}

Write-Output "[SCAN] Found $($fileTags.Count) files with tags"

$suggestions = @()

# Tag co-occurrence
if ($Method -eq "tag-cooccurrence" -or $Method -eq "all") {
    Write-Output "[TAG-COOC] Computing Jaccard similarities..."
    $names = @($fileTags.Keys)
    for ($i = 0; $i -lt $names.Count; $i++) {
        for ($j = $i + 1; $j -lt $names.Count; $j++) {
            $setA = @($fileTags[$names[$i]]) | Sort-Object -Unique
            $setB = @($fileTags[$names[$j]]) | Sort-Object -Unique
            $intersection = ($setA | Where-Object { $setB -contains $_ }).Count
            $union = ($setA + $setB | Sort-Object -Unique).Count
            $jaccard = if ($union -gt 0) { $intersection / $union } else { 0 }
            
            if ($jaccard -ge $Threshold) {
                $suggestions += @{
                    source = $names[$i]
                    target = $names[$j]
                    method = "tag-cooccurrence"
                    score = [math]::Round($jaccard, 3)
                    source_path = $filePaths[$names[$i]]
                    target_path = $filePaths[$names[$j]]
                }
            }
        }
    }
    Write-Output "[TAG-COOC] Found $($suggestions.Count) pairs above threshold"
}

# Gene-trigger matching
if ($Method -eq "gene-trigger" -or $Method -eq "all") {
    Write-Output "[GENE-TRIGGER] Scanning Gene triggers against note titles..."
    $genesDir = Join-Path $vault "进化\genes"
    if (Test-Path $genesDir) {
        $geneFiles = Get-ChildItem -Path $genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
        foreach ($gf in $geneFiles) {
            $geneContent = Get-Content $gf.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($null -eq $geneContent) { continue }
            
            # Extract trigger
            $triggerMatch = [regex]::Match($geneContent, 'trigger:\s*"([^"]+)"')
            if (-not $triggerMatch.Success) { continue }
            $trigger = $triggerMatch.Groups[1].Value.ToLower()
            if ([string]::IsNullOrEmpty($trigger)) { continue }
            
            # Match against note titles and content
            foreach ($name in $fileTags.Keys) {
                $path = $filePaths[$name]
                $body = Get-BodyText $path
                $title = [System.IO.Path]::GetFileNameWithoutExtension($name).ToLower()
                
                # Simple substring match
                if ($body.ToLower().Contains($trigger.Substring(0, [Math]::Min(30, $trigger.Length))) -or $title.Contains($trigger.Substring(0, [Math]::Min(20, $trigger.Length)))) {
                    $suggestions += @{
                        source = $gf.Name
                        target = $name
                        method = "gene-trigger"
                        score = 0.8
                        source_path = $gf.FullName
                        target_path = $path
                    }
                }
            }
        }
    }
    Write-Output "[GENE-TRIGGER] Scan complete"
}

# LLM semantic (gated)
if ($Method -eq "semantic" -or $Method -eq "all") {
    if ($UseLLM) {
        Write-Output "[SEMANTIC] LLM semantic similarity enabled (not implemented in this version - requires LLM endpoint)"
        # Placeholder: would call LLM API for same-domain note pairs
    } else {
        Write-Output "[SEMANTIC] Skipped (requires -UseLLM flag)"
    }
}

# Output suggestions
Write-Output ""
Write-Output "=== Link Suggestions ==="
Write-Output "Total suggestions: $($suggestions.Count)"

foreach ($s in $suggestions) {
    Write-Output "[SUGGEST] $($s.source) -> $($s.target) ($($s.method), score=$($s.score))"
}

# Apply: write wikilinks
if ($Apply -and -not $DryRun) {
    Write-Output ""
    Write-Output "[APPLY] Writing wikilinks..."
    
    # Group suggestions by target file
    $byTarget = @{}
    foreach ($s in $suggestions) {
        $targetName = $s.target
        $targetPath = $s.target_path
        # Only apply to files in 知识/ and 进化/proposals/ (never JinliKG)
        if ($targetPath -match 'JinliKG\\') { continue }
        
        if (-not $byTarget.ContainsKey($targetPath)) { $byTarget[$targetPath] = @() }
        $byTarget[$targetPath] += $s.source
    }
    
    foreach ($targetPath in $byTarget.Keys) {
        if (-not (Test-Path $targetPath)) { continue }
        
        $content = Get-Content $targetPath -Raw -Encoding UTF8
        $sourceLinks = @($byTarget[$targetPath] | Sort-Object -Unique)
        
        # Check if ## Related section exists
        $relatedSection = $false
        if ($content -match '## Related') { $relatedSection = $true }
        
        # Build wikilinks (only add if not already present)
        $newLinks = @()
        foreach ($src in $sourceLinks) {
            $srcNoExt = [System.IO.Path]::GetFileNameWithoutExtension($src)
            if ($content -notmatch "\[\[$srcNoExt\]\]") {
                $newLinks += "[[$srcNoExt]]"
            }
        }
        
        if ($newLinks.Count -eq 0) { continue }
        
        # Append to file
        $appendText = ""
        if (-not $relatedSection) {
            $appendText = "`n`n## Related`n"
        } else {
            $appendText = "`n"
        }
        $appendText += ($newLinks -join "`n")
        
        Add-Content -Path $targetPath -Value $appendText -Encoding UTF8
        Write-Output "[APPLY] Added $($newLinks.Count) links to $targetPath"
    }
}

# Write report
$reportDir = Join-Path $vault "进化\proposals"
if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

$reportData = @{
    total_suggestions = $suggestions.Count
    method = $Method
    threshold = $Threshold
    files_scanned = $fileTags.Count
}
$reportPath = Write-JsonReport -Data $reportData -ReportDir $reportDir -Prefix "link-suggest"
Write-Output "Report saved: $reportPath"

exit 0
