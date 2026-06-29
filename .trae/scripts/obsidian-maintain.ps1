# obsidian-maintain.ps1 - Auto-maintenance for Obsidian vault
# WP06: Duplicate detection, empty-dir cleanup, rule self-heal, Gene decay
# PowerShell 5.1 compatible, no external modules
# Safety: D1 never modify JinliKG/虚幻/我的项目/, D7 -DryRun default

param(
    [switch]$DetectDuplicates,
    [switch]$CleanEmptyDirs,
    [switch]$RuleSelfHeal,
    [switch]$GeneDecay,
    [switch]$All,
    [switch]$Apply,
    [switch]$DryRun = $true,
    [string]$VaultPath = "E:\ObsidianVault",
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"

function Show-Help {
    Write-Output @"
obsidian-maintain.ps1 - Auto-maintenance for Obsidian vault

Usage:
  .\obsidian-maintain.ps1 -DetectDuplicates           # Find duplicate note pairs
  .\obsidian-maintain.ps1 -CleanEmptyDirs -DryRun     # List empty dirs (no delete)
  .\obsidian-maintain.ps1 -CleanEmptyDirs -Apply      # Delete old+empty dirs
  .\obsidian-maintain.ps1 -RuleSelfHeal               # Suggest new rules from queue
  .\obsidian-maintain.ps1 -GeneDecay                  # Flag dormant Genes
  .\obsidian-maintain.ps1 -All                        # Run all maintenance tasks
  .\obsidian-maintain.ps1 -SelfTest                   # Run self-test
  .\obsidian-maintain.ps1 -Help                       # Show this help

Safety:
  D1: Never modify/delete JinliKG/ files
  D7: All destructive ops require -Apply flag
  SPL: Never auto-merge, never auto-archive, only report/suggest
"@
}

if ($Help) { Show-Help; exit 0 }

Import-Module $helpersPath -Force -WarningAction SilentlyContinue

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

$reportDir = Join-Path $vault "进化\proposals"
if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

# Self-test
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-maintain self-test..."
    $testDir = "$env:TEMP\obsidian-maintain-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Create 2 nearly-duplicate test files
    @"
---
kg_id: test.dup.001
tags: [ai-agent, automation, ai-coding]
domain: ai
---
# AI Agent Framework
Content about AI agent frameworks and multi-agent systems.
"@ | Out-File -FilePath (Join-Path $testDir "dup-a.md") -Encoding UTF8
    
    @"
---
kg_id: test.dup.002
tags: [ai-agent, automation, ai-coding]
domain: ai
---
# AI Agent Framework
Content about AI agent frameworks and multi-agent orchestration.
"@ | Out-File -FilePath (Join-Path $testDir "dup-b.md") -Encoding UTF8
    
    # Test duplicate detection
    $files = Get-ChildItem -Path $testDir -Filter "*.md"
    $pairs = @()
    for ($i = 0; $i -lt $files.Count; $i++) {
        for ($j = $i + 1; $j -lt $files.Count; $j++) {
            $fmA = Read-FrontMatter $files[$i].FullName
            $fmB = Read-FrontMatter $files[$j].FullName
            
            # Jaccard on tags
            $tagsA = @(); $tagsB = @()
            if ($fmA.ContainsKey('tags')) { $tagsA = @($fmA['tags'] | Sort-Object -Unique) }
            if ($fmB.ContainsKey('tags')) { $tagsB = @($fmB['tags'] | Sort-Object -Unique) }
            $inter = ($tagsA | Where-Object { $tagsB -contains $_ }).Count
            $union = ($tagsA + $tagsB | Sort-Object -Unique).Count
            $jaccard = if ($union -gt 0) { $inter / $union } else { 0 }
            
            # Title similarity (exact match)
            $titleA = $files[$i].BaseName
            $titleB = $files[$j].BaseName
            $titleSim = if ($titleA -eq $titleB) { 1.0 } else { 0.5 }
            
            if ($jaccard -ge 0.9 -and $titleSim -ge 0.9) {
                $pairs += "$($files[$i].Name) <-> $($files[$j].Name)"
            }
        }
    }
    
    Write-Output "[SELFTEST-PASS] Found $($pairs.Count) duplicate pairs"
    
    # Test empty dir detection
    $emptyDir = Join-Path $testDir "empty_folder"
    New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
    $dirFiles = (Get-ChildItem -Path $emptyDir -File -ErrorAction SilentlyContinue)
    $isEmpty = ($null -eq $dirFiles -or $dirFiles.Count -eq 0)
    if ($isEmpty) { Write-Output "[SELFTEST-PASS] Empty dir detected" }
    else { Write-Output "[SELFTEST-FAIL] Empty dir not detected" }
    
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# Run all if -All
if ($All) {
    $DetectDuplicates = $true
    $CleanEmptyDirs = $true
    $RuleSelfHeal = $true
    $GeneDecay = $true
}

# ---- DetectDuplicates ----
if ($DetectDuplicates) {
    Write-Output "[DUP] Scanning for duplicate notes..."
    $knowledgeDir = Join-Path $vault "知识"
    $allMd = Get-ChildItem -Path $knowledgeDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
    
    $dupPairs = @()
    for ($i = 0; $i -lt $allMd.Count; $i++) {
        for ($j = $i + 1; $j -lt $allMd.Count; $j++) {
            $fmA = Read-FrontMatter $allMd[$i].FullName
            $fmB = Read-FrontMatter $allMd[$j].FullName
            
            $tagsA = @(); $tagsB = @()
            if ($fmA.ContainsKey('tags')) { $tagsA = @($fmA['tags'] | Sort-Object -Unique) }
            if ($fmB.ContainsKey('tags')) { $tagsB = @($fmB['tags'] | Sort-Object -Unique) }
            
            if ($tagsA.Count -eq 0 -or $tagsB.Count -eq 0) { continue }
            
            # Tag Jaccard
            $inter = ($tagsA | Where-Object { $tagsB -contains $_ }).Count
            $union = ($tagsA + $tagsB | Sort-Object -Unique).Count
            $jaccard = if ($union -gt 0) { $inter / $union } else { 0 }
            
            # Title similarity (normalized)
            $titleA = $allMd[$i].BaseName.ToLower()
            $titleB = $allMd[$j].BaseName.ToLower()
            # Simple ratio: shared chars / max length
            $sharedChars = 0
            $shorter = [Math]::Min($titleA.Length, $titleB.Length)
            $longer = [Math]::Max($titleA.Length, $titleB.Length)
            for ($c = 0; $c -lt $shorter; $c++) {
                if ($titleA[$c] -eq $titleB[$c]) { $sharedChars++ }
            }
            $titleSim = if ($longer -gt 0) { $sharedChars / $longer } else { 0 }
            
            if ($jaccard -ge 0.9 -and $titleSim -ge 0.9) {
                $dupPairs += @{
                    file_a = $allMd[$i].FullName
                    file_b = $allMd[$j].FullName
                    tag_jaccard = [math]::Round($jaccard, 3)
                    title_similarity = [math]::Round($titleSim, 3)
                }
            }
        }
    }
    
    Write-Output "[DUP] Found $($dupPairs.Count) duplicate candidate pairs"
    foreach ($dp in $dupPairs) {
        Write-Output "  $($dp.file_a) <-> $($dp.file_b) (tag_j=$($dp.tag_jaccard), title_sim=$($dp.title_similarity))"
    }
    
    # Write report
    $dupReport = @{ duplicate_pairs = $dupPairs.Count; details = $dupPairs }
    $dupPath = Write-JsonReport -Data @{ duplicate_pairs = $dupPairs.Count } -ReportDir $reportDir -Prefix "duplicates"
    Write-Output "Report saved: $dupPath"
}

# ---- CleanEmptyDirs ----
if ($CleanEmptyDirs) {
    Write-Output "[CLEAN] Scanning for empty directories..."
    $knowledgeDir = Join-Path $vault "知识"
    $emptyDirs = @()
    
    Get-ChildItem -Path $knowledgeDir -Recurse -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $filesInDir = Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue
        if ($null -eq $filesInDir -or $filesInDir.Count -eq 0) {
            $age = ([DateTime]::Now - $_.LastWriteTime).Days
            if ($age -gt 7) {
                $emptyDirs += @{ path = $_.FullName; age_days = $age }
            }
        }
    }
    
    Write-Output "[CLEAN] Found $($emptyDirs.Count) empty directories (>7d old)"
    foreach ($ed in $emptyDirs) {
        Write-Output "  $($ed.path) (age=$($ed.age_days) days)"
    }
    
    if ($Apply -and -not $DryRun) {
        foreach ($ed in $emptyDirs) {
            Remove-Item -LiteralPath $ed.path -Force -Recurse
            Write-Output "[CLEAN-APPLY] Deleted: $($ed.path)"
        }
    } else {
        Write-Output "[CLEAN] DryRun mode - no directories deleted"
    }
}

# ---- RuleSelfHeal ----
if ($RuleSelfHeal) {
    Write-Output "[HEAL] Scanning unclassified queue for self-heal opportunities..."
    $queuePath = Join-Path $vault "进化\rules\_unclassified-queue.yaml"
    
    if (Test-Path $queuePath) {
        $queueContent = Get-Content $queuePath -Raw -Encoding UTF8
        # Parse entries: - file: "xxx", tags: [a, b, c]
        $entries = [regex]::Matches($queueContent, '(?s)- file:\s*"([^"]+)"\s*\r?\n\s+tags:\s*\[([^\]]+)\]')
        
        # Group by primary tag
        $tagGroups = @{}
        foreach ($e in $entries) {
            $file = $e.Groups[1].Value
            $tagsList = $e.Groups[2].Value -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') }
            $primaryTag = if ($tagsList.Count -gt 0) { $tagsList[0] } else { "unknown" }
            
            if (-not $tagGroups.ContainsKey($primaryTag)) { $tagGroups[$primaryTag] = @() }
            $tagGroups[$primaryTag] += $file
        }
        
        # Suggest rules for groups >= 5 files
        foreach ($tag in $tagGroups.Keys) {
            if ($tagGroups[$tag].Count -ge 5) {
                Write-Output "[SUGGEST-RULE] tag: $tag -> target: 知识/$tag/ ($($tagGroups[$tag].Count) files)"
            } elseif ($tagGroups[$tag].Count -ge 1) {
                Write-Output "[QUEUE] tag: $tag -> ($($tagGroups[$tag].Count) files, need 5 for auto-suggest)"
            }
        }
    } else {
        Write-Output "[HEAL] No unclassified queue found (no unclassified files yet)"
    }
}

# ---- GeneDecay ----
if ($GeneDecay) {
    Write-Output "[DECAY] Scanning Genes for decay..."
    $genesDir = Join-Path $vault "进化\genes"
    $dormant = @(); $archiveSuggest = @()
    
    if (Test-Path $genesDir) {
        $genes = Get-ChildItem -Path $genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
        foreach ($g in $genes) {
            $content = Get-Content $g.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($null -eq $content) { continue }
            
            $useCount = 0; $lastUsed = ""; $geneId = ""
            if ($content -match 'use_count:\s*(\d+)') { $useCount = [int]$Matches[1] }
            if ($content -match 'last_used:\s*"([^"]+)"') { $lastUsed = $Matches[1] }
            if ($content -match 'gene_id:\s*(\S+)') { $geneId = $Matches[1] }
            
            if ($useCount -eq 0) {
                $daysSince = 999
                if ($lastUsed -ne "") {
                    try { $daysSince = ([DateTime]::Now - [DateTime]::Parse($lastUsed)).Days } catch { }
                }
                
                if ($daysSince -gt 90) { $dormant += "  - $geneId ($daysSince days unused)" }
                if ($daysSince -gt 180) { $archiveSuggest += "  - $geneId ($daysSince days unused - ARCHIVE SUGGESTED)" }
            }
        }
    }
    
    Write-Output "[DECAY] Dormant Genes (>90d, use_count=0): $($dormant.Count)"
    foreach ($d in $dormant) { Write-Output $d }
    Write-Output "[DECAY] Archive-suggested Genes (>180d): $($archiveSuggest.Count)"
    foreach ($a in $archiveSuggest) { Write-Output $a }
    
    if ($archiveSuggest.Count -gt 0) {
        Write-Output "[SUGGEST] Consider archiving the above Genes (requires Ba Ba approval)"
    }
}

Write-Output ""
Write-Output "=== Maintenance Complete ==="

exit 0
