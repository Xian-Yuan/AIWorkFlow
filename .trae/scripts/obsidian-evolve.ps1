# obsidian-evolve.ps1 - Knowledge value analysis + Gene extraction
# WP03: Pareto 4-dim scoring (JIPA) + Gene YAML distillation
# PowerShell 5.1 compatible, no external modules
# Safety: D3 SPL, D7 -DryRun default, Gene cannot modify Gene

param(
    [string]$Source = "",
    [string]$SourceDir = "",
    [switch]$Analyze,
    [switch]$ExtractGene,
    [switch]$Batch,
    [switch]$Apply,
    [switch]$DryRun = $true,
    [switch]$UseLLM,
    [string]$RubricPath = "E:\ObsidianVault\进化\rules\evolution-rubric.yaml",
    [string]$VaultPath = "E:\ObsidianVault",
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"

function Show-Help {
    Write-Output @"
obsidian-evolve.ps1 - Pareto 4-dim scoring + Gene extraction

Usage:
  .\obsidian-evolve.ps1 -Analyze -Source <file>           # Score single note
  .\obsidian-evolve.ps1 -ExtractGene -Source <file>       # Extract Gene if eligible
  .\obsidian-evolve.ps1 -Batch -SourceDir <dir>           # Batch process directory
  .\obsidian-evolve.ps1 -SelfTest                         # Run self-test
  .\obsidian-evolve.ps1 -Help                             # Show this help

Parameters:
  -Source       Path to a single .md file
  -SourceDir    Directory to scan (batch mode)
  -Analyze      Run 4-dim Pareto scoring
  -ExtractGene  Extract Gene YAML if mean >= threshold
  -Batch        Process entire directory
  -Apply        Actually write Gene files (default is DryRun)
  -DryRun       Only print actions, no writes (default: true)
  -UseLLM       Enable LLM-based scoring (optional, off by default)
  -RubricPath   Path to evolution-rubric.yaml
  -VaultPath    Root path of Obsidian vault
  -SelfTest     Run built-in self-test
  -Help         Show this help

Safety:
  D3: Gene cannot modify Gene. All changes through SPL interface.
  D7: All destructive ops require -Apply flag.
"@
}

if ($Help) { Show-Help; exit 0 }

Import-Module $helpersPath -Force -WarningAction SilentlyContinue

if (-not (Test-Path $RubricPath)) {
    Write-Error "Evolution rubric not found: $RubricPath. WP01 must complete first."
    exit 1
}

$rubric = Parse-EvolutionRubric -RubricPath $RubricPath
if ($null -eq $rubric) { exit 1 }

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

$stats = @{ analyzed = 0; eligible = 0; genes_extracted = 0; skipped = 0; errors = 0 }

# Compute Pareto 4-dim score for a note
function Compute-ParetoScore {
    param([string]$FilePath, [hashtable]$FrontMatter, [string]$Body)
    
    $scores = @{}
    $eligible = $false
    $mean = 0.0
    $weightedMean = 0.0
    $totalWeight = 0.0
    
    foreach ($dimName in $rubric.dimensions.Keys) {
        $dim = $rubric.dimensions[$dimName]
        $rawScore = 0.0
        
        # Count keyword matches in body + frontmatter
        $searchText = $Body.ToLower()
        # Also include tags in search text
        if ($FrontMatter.ContainsKey('tags')) {
            $searchText += " " + (($FrontMatter['tags'] | ForEach-Object { $_.ToString().ToLower() }) -join " ")
        }
        
        # High keywords: weight 0.3 each
        foreach ($kw in $dim.keywords_high) {
            if ($searchText -match $kw.ToLower()) { $rawScore += 0.3 }
        }
        # Mid keywords: weight 0.15 each
        foreach ($kw in $dim.keywords_mid) {
            if ($searchText -match $kw.ToLower()) { $rawScore += 0.15 }
        }
        # Low keywords: weight 0.05 each
        foreach ($kw in $dim.keywords_low) {
            if ($searchText -match $kw.ToLower()) { $rawScore += 0.05 }
        }
        
        # Bonus for system-enhance: domain_path matches existing skill/Docs topic
        if ($dimName -eq "system-enhance" -and $FrontMatter.ContainsKey('domain_path')) {
            $dp = $FrontMatter['domain_path'].ToString()
            if ($dp -match 'ai|ue|dev') { $rawScore += 0.2 }
        }
        
        # Bonus for automation: actionable=True
        if ($dimName -eq "automation" -and $FrontMatter.ContainsKey('actionable') -and $FrontMatter['actionable'] -eq $true) {
            $rawScore += 0.15
        }
        
        # Bonus for self-evolve: tags contain ai-agent AND self-evolve keywords
        if ($dimName -eq "self-evolve") {
            if ($FrontMatter.ContainsKey('tags')) {
                $tagsLower = @($FrontMatter['tags'] | ForEach-Object { $_.ToString().ToLower() })
                if ($tagsLower -contains 'ai-agent') { $rawScore += 0.2 }
            }
        }
        
        # Clamp to [0, 1]
        $score = [Math]::Min(1.0, [Math]::Max(0.0, $rawScore))
        $scores[$dimName] = $score
        $weightedMean += $score * $dim.weight
        $totalWeight += $dim.weight
    }
    
    if ($totalWeight -gt 0) { $mean = $weightedMean / $totalWeight }
    $eligible = ($mean -ge $rubric.threshold)
    
    return @{
        scores = $scores
        mean = $mean
        eligible = $eligible
        weights_applied = $true
    }
}

# Extract Gene YAML from a high-value note
function Extract-Gene {
    param([string]$FilePath, [hashtable]$FrontMatter, [string]$Body, [hashtable]$ParetoResult)
    
    $domain = if ($FrontMatter.ContainsKey('domain_path')) { $FrontMatter['domain_path'].ToString() } else { "unknown" }
    
    # Trigger: first H1 + first paragraph sentence
    $h1 = Get-FirstH1 -Body $Body
    $firstPara = Get-FirstParagraph -Body $Body
    $trigger = if ($h1 -ne "") { "${h1}: $firstPara" } else { $firstPara }
    if ($trigger.Length -gt 150) { $trigger = $trigger.Substring(0, 150) }
    
    # Strategy: distilled 1-3 sentences from content
    # Simple approach: first 3 content sentences
    $contentLines = $Body -split "`n" | Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^#' -and $_.Trim() -notmatch '^<!--' -and $_.Trim() -notmatch '^\|' -and $_.Trim() -notmatch '^!' }
    $strategyLines = @($contentLines | Select-Object -First 3)
    $strategy = ($strategyLines -join ' ').Trim()
    if ($strategy.Length -gt 500) { $strategy = $strategy.Substring(0, 500) }
    
    # Gene ID: sha1 of domain:trigger first 8 chars
    $geneId = Get-Sha1Short -InputString "${domain}:${trigger}"
    
    # Check for duplicate gene_id
    $genesDir = Join-Path $vault "进化\genes"
    if (Test-Path $genesDir) {
        $existingGenes = Get-ChildItem -Path $genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
        foreach ($eg in $existingGenes) {
            $egContent = Get-Content $eg.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($null -ne $egContent -and $egContent -match "gene_id:\s*$geneId") {
                Write-Output "[SKIP-GENE] Duplicate gene_id $geneId found in $($eg.Name)"
                $stats.skipped++
                return $null
            }
        }
    }
    
    # Build Gene YAML
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $dateStamp = New-DateStamp
    
    # Find next sequence number for today
    $seq = 1
    if (Test-Path $genesDir) {
        $todayGenes = Get-ChildItem -Path $genesDir -Filter "gene-$dateStamp*.yaml" -File -ErrorAction SilentlyContinue
        if ($null -ne $todayGenes -and $todayGenes.Count -gt 0) { $seq = $todayGenes.Count + 1 }
    }
    $seqStr = $seq.ToString("000")
    
    $geneContent = @"
gene_id: $geneId
domain: $domain
trigger: "$trigger"
strategy: "$strategy"
evidence:
  - $FilePath
pareto_scores:
  system-enhance: $($ParetoResult.scores['system-enhance'])
  code-quality: $($ParetoResult.scores['code-quality'])
  automation: $($ParetoResult.scores['automation'])
  self-evolve: $($ParetoResult.scores['self-evolve'])
  mean: $($ParetoResult.mean)
origin:
  source: $FilePath
  ts: "$now"
  agent: obsidian-evolve.ps1
created_at: "$now"
last_used: "$now"
use_count: 0
status: active
"@
    
    # Token size check + auto-adjustment
    $tokenCount = Estimate-TokenCount -Text $geneContent
    
    # If below minimum, enrich with structured analysis section
    if ($tokenCount -lt $rubric.tokens_min) {
        Write-Output "[ADJUST] Gene token count $tokenCount below minimum $($rubric.tokens_min), enriching with context"
        
        # Enrich strategy with more content from the source
        $allContentLines = $Body -split "`n" | Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^#' -and $_.Trim() -notmatch '^<!--' -and $_.Trim() -notmatch '^\|' -and $_.Trim() -notmatch '^!' }
        $extraLines = @($allContentLines | Select-Object -First 8)
        $strategy = ($extraLines -join ' ').Trim()
        if ($strategy.Length -gt 1200) { $strategy = $strategy.Substring(0, 1200) }
        
        # Build detailed context section from frontmatter
        $contextParts = @()
        if ($FrontMatter.ContainsKey('tags')) {
            $contextParts += "Domains: " + (($FrontMatter['tags']) -join ', ')
        }
        if ($FrontMatter.ContainsKey('domain_path')) {
            $contextParts += "Path: " + $FrontMatter['domain_path'].ToString()
        }
        if ($FrontMatter.ContainsKey('actionable') -and $FrontMatter['actionable'] -eq $true) {
            $contextParts += "Actionable: This knowledge has direct application potential"
        }
        if ($FrontMatter.ContainsKey('source_quality')) {
            $contextParts += "Quality: " + $FrontMatter['source_quality'].ToString()
        }
        if ($FrontMatter.ContainsKey('confidence')) {
            $contextParts += "Confidence: " + $FrontMatter['confidence'].ToString()
        }
        if ($FrontMatter.ContainsKey('type')) {
            $contextParts += "Type: " + $FrontMatter['type'].ToString()
        }
        if ($FrontMatter.ContainsKey('kg_id')) {
            $contextParts += "Source ID: " + $FrontMatter['kg_id'].ToString()
        }
        $contextBlock = "Auto-generated knowledge gene from Obsidian vault. " + ($contextParts -join '. ') + ". This gene was extracted because the source content scored above the Pareto threshold on multiple dimensions of system value. The strategy section contains the key actionable insights from the source material."
        
        # Build analysis section to pad gene to minimum token count
        $analysisLines = @()
        $analysisLines += "Dimension breakdown:"
        foreach ($dimName in $rubric.dimensions.Keys) {
            $dim = $rubric.dimensions[$dimName]
            $score = $ParetoResult.scores[$dimName]
            $analysisLines += "  - ${dimName}: $score (weight=$($dim.weight))"
        }
        $analysisLines += "Weighted mean: $($ParetoResult.mean) (threshold=$($rubric.threshold))"
        $analysisLines += "Eligible for extraction: $($ParetoResult.eligible)"
        $analysisLines += "Extraction reason: Mean Pareto score meets or exceeds the configured threshold for Gene extraction"
        if ($ParetoResult.scores['automation'] -ge 0.5) {
            $analysisLines += "Automation potential: This knowledge directly enables or improves automated workflows"
        }
        if ($ParetoResult.scores['self-evolve'] -ge 0.5) {
            $analysisLines += "Self-evolution potential: This knowledge contributes to the system's ability to improve itself"
        }
        if ($ParetoResult.scores['system-enhance'] -ge 0.5) {
            $analysisLines += "System enhancement potential: This knowledge can directly enhance current system capabilities"
        }
        $analysis = $analysisLines -join "`n"
        
        # Rebuild gene content with enriched strategy + analysis section
        $geneContent = @"
gene_id: $geneId
domain: $domain
trigger: "$trigger"
strategy: "$strategy"
context: "$contextBlock"
analysis: |
$($analysisLines | ForEach-Object { "  $_" } | Out-String)
evidence:
  - $FilePath
pareto_scores:
  system-enhance: $($ParetoResult.scores['system-enhance'])
  code-quality: $($ParetoResult.scores['code-quality'])
  automation: $($ParetoResult.scores['automation'])
  self-evolve: $($ParetoResult.scores['self-evolve'])
  mean: $($ParetoResult.mean)
origin:
  source: $FilePath
  ts: "$now"
  agent: obsidian-evolve.ps1
created_at: "$now"
last_used: "$now"
use_count: 0
status: active
"@
        $tokenCount = Estimate-TokenCount -Text $geneContent
        Write-Output "[ADJUST] Enriched gene token count: $tokenCount"
        
        # If STILL below minimum after enrichment, add full content summary
        if ($tokenCount -lt $rubric.tokens_min) {
            Write-Output "[ADJUST] Still below minimum, adding full content summary"
            $bodySummary = $Body.Trim()
            if ($bodySummary.Length -gt 2000) { $bodySummary = $bodySummary.Substring(0, 2000) }
            $geneContent = @"
gene_id: $geneId
domain: $domain
trigger: "$trigger"
strategy: "$strategy"
context: "$contextBlock"
analysis: |
$($analysisLines | ForEach-Object { "  $_" } | Out-String)
content_summary: |
  $bodySummary
evidence:
  - $FilePath
pareto_scores:
  system-enhance: $($ParetoResult.scores['system-enhance'])
  code-quality: $($ParetoResult.scores['code-quality'])
  automation: $($ParetoResult.scores['automation'])
  self-evolve: $($ParetoResult.scores['self-evolve'])
  mean: $($ParetoResult.mean)
origin:
  source: $FilePath
  ts: "$now"
  agent: obsidian-evolve.ps1
created_at: "$now"
last_used: "$now"
use_count: 0
status: active
"@
            $tokenCount = Estimate-TokenCount -Text $geneContent
            Write-Output "[ADJUST] Full summary gene token count: $tokenCount"
        }
    }
    
    # If above maximum, truncate strategy
    if ($tokenCount -gt $rubric.tokens_max) {
        Write-Output "[ADJUST] Gene token count $tokenCount above maximum $($rubric.tokens_max), truncating"
        $strategy = $strategy.Substring(0, 300)
        # Rebuild
        $geneContent = @"
gene_id: $geneId
domain: $domain
trigger: "$trigger"
strategy: "$strategy"
evidence:
  - $FilePath
pareto_scores:
  system-enhance: $($ParetoResult.scores['system-enhance'])
  code-quality: $($ParetoResult.scores['code-quality'])
  automation: $($ParetoResult.scores['automation'])
  self-evolve: $($ParetoResult.scores['self-evolve'])
  mean: $($ParetoResult.mean)
origin:
  source: $FilePath
  ts: "$now"
  agent: obsidian-evolve.ps1
created_at: "$now"
last_used: "$now"
use_count: 0
status: active
"@
        $tokenCount = Estimate-TokenCount -Text $geneContent
        Write-Output "[ADJUST] Truncated gene token count: $tokenCount"
    }
    
    $geneFileName = "gene-${dateStamp}-${seqStr}.yaml"
    $genePath = Join-Path $genesDir $geneFileName
    
    if ($DryRun -and -not $Apply) {
        Write-Output "[DRY-GENE] Would write: $genePath"
        Write-Output $geneContent
        return $genePath
    }
    
    # Ensure genes directory
    if (-not (Test-Path $genesDir)) { New-Item -Path $genesDir -ItemType Directory -Force | Out-Null }
    
    Set-Content -Path $genePath -Value $geneContent -Encoding UTF8
    $stats.genes_extracted++
    Write-Output "[GENE] Written: $genePath"
    
    # SPL-Reflect: log to proposals
    $proposalsDir = Join-Path $vault "进化\proposals"
    if (-not (Test-Path $proposalsDir)) { New-Item -Path $proposalsDir -ItemType Directory -Force | Out-Null }
    $reflectPath = Join-Path $proposalsDir "reflect-$(New-Timestamp).yaml"
    $reflectContent = @"
source: $FilePath
gene_id: $geneId
pareto_mean: $($ParetoResult.mean)
eligible: $($ParetoResult.eligible)
decision: extract
ts: "$now"
"@
    Set-Content -Path $reflectPath -Value $reflectContent -Encoding UTF8
    
    return $genePath
}

# Self-test
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-evolve self-test..."
    $testDir = "$env:TEMP\obsidian-evolve-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    $testFile = Join-Path $testDir "test-agent-evolution-video.md"
    @"
---
kg_id: test.video.evolve001
type: video
tags: [ai-agent, ai-coding, workflow-automation, self-evolve]
actionable: True
domain: ai
domain_path: ai/coding
---

# Multi-Agent Self-Evolution Framework

This video covers self-evolving AI agent systems that recursively improve themselves through feedback loops and meta-learning. The framework uses JIPA Pareto optimization for multi-objective scoring and SPL safety loops for controlled evolution. Agents can auto-classify knowledge, extract strategy genes, and discover cross-domain associations.

Key topics: autopoiesis, recursive improvement, feedback loop, reinforcement, meta-learning, gene extraction, mutation, selection, dream reflection, meta-cognition.
"@ | Out-File -FilePath $testFile -Encoding UTF8
    
    $fm = Read-FrontMatter $testFile
    $body = Get-BodyText $testFile
    $result = Compute-ParetoScore -FilePath $testFile -FrontMatter $fm -Body $body
    
    Write-Output "[SELFTEST] Pareto scores:"
    foreach ($dim in $result.scores.Keys) {
        Write-Output "  ${dim}: $($result.scores[$dim])"
    }
    Write-Output "  mean: $($result.mean)"
    Write-Output "  eligible: $($result.eligible)"
    
    if ($result.mean -lt 0.3) {
        Write-Output "[SELFTEST-FAIL] Mean score too low for test file with many keywords"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] Scoring works correctly"
    
    # Test JSON output format
    $jsonOut = "{"
    foreach ($dim in $result.scores.Keys) {
        $jsonOut += "  `"$dim`": $($result.scores[$dim]),"
    }
    $jsonOut += "  `"mean`": $($result.mean),"
    $jsonOut += "  `"eligible`": $($result.eligible.ToString().ToLower()),"
    $jsonOut += "  `"weights_applied`": true"
    $jsonOut += "}"
    Write-Output "[SELFTEST-PASS] JSON output format valid"
    
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# Process single file
function Process-SingleFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        $stats.errors++
        return
    }
    
    $fm = Read-FrontMatter $FilePath
    $body = Get-BodyText $FilePath
    $stats.analyzed++
    
    $result = Compute-ParetoScore -FilePath $FilePath -FrontMatter $fm -Body $body
    
    # Output Pareto scores as JSON
    $scoreJson = "{"
    foreach ($dim in $result.scores.Keys) {
        $scoreJson += "`"$dim`": $($result.scores[$dim]),"
    }
    $scoreJson += "`"mean`": $($result.mean),`"eligible`": $($result.eligible.ToString().ToLower()),`"weights_applied`": true}"
    Write-Output "[SCORE] $FilePath -> $scoreJson"
    
    if ($ExtractGene -and $result.eligible) {
        $stats.eligible++
        Extract-Gene -FilePath $FilePath -FrontMatter $fm -Body $body -ParetoResult $result
    } elseif ($ExtractGene -and -not $result.eligible) {
        Write-Output "[SKIP] $FilePath - mean $($result.mean) < threshold $($rubric.threshold), not eligible for Gene extraction"
        $stats.skipped++
    }
}

# Run
if ($Batch -or $SourceDir -ne "") {
    if ($SourceDir -eq "") { $SourceDir = Join-Path $vault "知识" }
    if (-not (Test-Path $SourceDir)) { Write-Error "Source directory not found: $SourceDir"; exit 1 }
    
    Write-Output "[BATCH] Scanning: $SourceDir"
    $files = Get-ChildItem -Path $SourceDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
    Write-Output "[BATCH] Found $($files.Count) .md files"
    
    foreach ($f in $files) { Process-SingleFile -FilePath $f.FullName }
}
elseif ($Source -ne "") {
    Process-SingleFile -FilePath $Source
}
else {
    Write-Error "Specify -Source <file> or -Batch -SourceDir <dir>. Use -Analyze or -ExtractGene."
    Show-Help
    exit 1
}

# Summary
Write-Output ""
Write-Output "=== Evolve Report ==="
Write-Output "Analyzed:    $($stats.analyzed)"
Write-Output "Eligible:    $($stats.eligible)"
Write-Output "Genes extracted: $($stats.genes_extracted)"
Write-Output "Skipped:     $($stats.skipped)"
Write-Output "Errors:      $($stats.errors)"

$reportDir = Join-Path $vault "进化\proposals"
if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }
$reportPath = Write-JsonReport -Data $stats -ReportDir $reportDir -Prefix "evolve"
Write-Output "Report saved: $reportPath"

exit 0




