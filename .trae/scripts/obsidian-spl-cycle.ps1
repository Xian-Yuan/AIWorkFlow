# obsidian-spl-cycle.ps1 - SPL 5-step evolution cycle engine
# Autogenesis AGP-inspired: Reflect -> Select -> Improve -> Evaluate -> Commit
# v2: Integrates Intrinsic Metacognitive Learning (arxiv 2506.05109)
#   - Metacognitive Knowledge: self-assess capabilities vs Gene strategies
#   - Metacognitive Planning: decide what/how to improve from knowledge gaps
#   - Metacognitive Evaluation: reflect on evolution outcomes to improve future cycles
# PowerShell 5.1 compatible, no external modules
# Safety: SPL-Commit requires approval; SPL-Improve never modifies Gene directly

param(
    [string]$GeneId = "",
    [string]$GeneDir = "E:\ObsidianVault\进化\genes",
    [string]$VaultPath = "E:\ObsidianVault",
    [string]$ProjectPath = "E:\UEGameDevelopment",
    [string]$StrategiesPath = "E:\ObsidianVault\进化\rules\evolution-strategies.yaml",
    [string]$ResourceRegistryPath = "E:\ObsidianVault\进化\rules\resource-registry.yaml",
    [switch]$Reflect,
    [switch]$Select,
    [switch]$Improve,
    [switch]$Evaluate,
    [switch]$Commit,
    [switch]$FullCycle,
    [switch]$AutoCommit,
    [switch]$DryRun = $true,
    [switch]$Apply,
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"
Import-Module $helpersPath -Force -WarningAction SilentlyContinue

if ($Help) {
    Write-Output "obsidian-spl-cycle.ps1 - SPL 5-step evolution cycle (v2)"
    Write-Output "Steps: Reflect -> Select -> Improve -> Evaluate -> Commit"
    Write-Output "Usage: -Reflect | -Select | -Improve | -Evaluate | -Commit | -FullCycle"
    Write-Output "Safety: -Apply required for writes; -AutoCommit for unattended commit"
    exit 0
}

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

$script:genesDir = Join-Path $vault "进化\genes"
$script:proposalsDir = Join-Path $vault "进化\proposals"
$script:enactedDir = Join-Path $vault "进化\enacted"


# ============================================================
# Dynamic Criteria Reader (Integration with Metacognitive Layer)
# Reads dynamic-criteria.yaml from metacognitive output
# Falls back to defaults if not available
# ============================================================
function Read-DynamicCriteria {
   $metaPath = Join-Path $VaultPath "metacognitive"
   if (-not (Test-Path $metaPath)) { $metaPath = Join-Path $VaultPath ([char]0x8FDB + [char]0x5316 + "\metacognitive") }
   $critPath = Join-Path $metaPath "dynamic-criteria.yaml"
   if (-not (Test-Path $critPath)) {
       Write-Host "[META] No dynamic-criteria.yaml found, using defaults"
       return @{
           system_enhance_weight = 0.30
           automation_weight = 0.30
           code_quality_weight = 0.20
           self_evolve_weight = 0.20
           threshold = 0.60
       }
   }
   $content = [System.IO.File]::ReadAllText($critPath, [System.Text.Encoding]::UTF8)
   $criteria = @{
       system_enhance_weight = 0.30
       automation_weight = 0.30
       code_quality_weight = 0.20
       self_evolve_weight = 0.20
       threshold = 0.60
   }
   if ($content -match 'system_enhance_weight:\s*([\d.]+)') { $criteria['system_enhance_weight'] = [double]$Matches[1] }
   if ($content -match 'automation_weight:\s*([\d.]+)') { $criteria['automation_weight'] = [double]$Matches[1] }
   if ($content -match 'code_quality_weight:\s*([\d.]+)') { $criteria['code_quality_weight'] = [double]$Matches[1] }
   if ($content -match 'self_evolve_weight:\s*([\d.]+)') { $criteria['self_evolve_weight'] = [double]$Matches[1] }
   if ($content -match 'threshold:\s*([\d.]+)') { $criteria['threshold'] = [double]$Matches[1] }
   Write-Host "[META] Dynamic criteria loaded: sys=$($criteria['system_enhance_weight']) auto=$($criteria['automation_weight']) evolve=$($criteria['self_evolve_weight']) threshold=$($criteria['threshold'])"
   return $criteria
}
if (-not (Test-Path $script:genesDir)) { Write-Error "No genes directory. Run obsidian-evolve.ps1 first."; exit 1 }

# ============================================================
# YAML Parsers
# ============================================================
function Parse-GeneYaml {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    if ([string]::IsNullOrEmpty($content)) { return $null }
    $gene = @{}
    if ($content -match 'gene_id:\s*(\S+)') { $gene['gene_id'] = $Matches[1].Trim('"') }
    if ($content -match 'domain:\s*(\S+)') { $gene['domain'] = $Matches[1].Trim('"') }
    if ($content -match 'trigger:\s*"([^"]*)"') { $gene['trigger'] = $Matches[1] }
    elseif ($content -match 'trigger:\s*(.+)$') { $gene['trigger'] = $Matches[1].Trim().Trim('"') }
    if ($content -match 'strategy:\s*"?([^"\n]+)"?') { $gene['strategy'] = $Matches[1].Trim().Trim('"') }
    if ($content -match 'system-enhance:\s*([\d.]+)') { $gene['pareto_system_enhance'] = [double]$Matches[1] }
    if ($content -match 'code-quality:\s*([\d.]+)') { $gene['pareto_code_quality'] = [double]$Matches[1] }
    if ($content -match 'automation:\s*([\d.]+)') { $gene['pareto_automation'] = [double]$Matches[1] }
    if ($content -match 'self-evolve:\s*([\d.]+)') { $gene['pareto_self_evolve'] = [double]$Matches[1] }
    if ($content -match 'mean:\s*([\d.]+)') { $gene['pareto_mean'] = [double]$Matches[1] }
    if ($content -match 'use_count:\s*(\d+)') { $gene['use_count'] = [int]$Matches[1] }
    return $gene
}

function Parse-StrategiesYaml {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @{ directions = @() } }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    if ([string]::IsNullOrEmpty($content)) { return @{ directions = @() } }
    $directions = @()
    $lines = $content -split "`n"
    $currentDir = $null
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\s*-\s*name:\s*"([^"]+)"') {
            $currentDir = @{ name = $Matches[1]; keywords = @(); targets = @(); impact_weight = 0.5 }
        } elseif ($null -ne $currentDir) {
            if ($trimmed -match 'keywords:\s*\[([^\]]+)\]') {
                $currentDir.keywords = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') } | Where-Object { $_ -ne '' }
            } elseif ($trimmed -match 'targets:\s*\[([^\]]+)\]') {
                $currentDir.targets = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') } | Where-Object { $_ -ne '' }
            } elseif ($trimmed -match 'impact_weight:\s*([\d.]+)') {
                $currentDir.impact_weight = [double]$Matches[1]
                $directions += $currentDir
                $currentDir = $null
            }
        }
    }
    return @{ directions = $directions }
}

function Parse-ResourceRegistry {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @{ resources = @() } }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    if ([string]::IsNullOrEmpty($content)) { return @{ resources = @() } }
    $resources = @()
    $lines = $content -split "`n"
    $currentRes = $null
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\s*-\s*type:\s*"(\w+)"') {
            $currentRes = @{ type = $Matches[1]; name = ''; path = ''; description = '' }
        } elseif ($null -ne $currentRes) {
            if ($trimmed -match 'name:\s*"([^"]+)"') { $currentRes.name = $Matches[1] }
            elseif ($trimmed -match 'path:\s*"([^"]+)"') { $currentRes.path = $Matches[1] }
            elseif ($trimmed -match 'description:\s*"([^"]+)"') { $currentRes.description = $Matches[1]; $resources += $currentRes; $currentRes = $null }
        }
    }
    return @{ resources = $resources }
}

function Get-GeneSaturationPenalty {
    param([int]$UseCount)
    if ($UseCount -le 0) { return 0.0 }
    return [Math]::Min(0.50, [double]$UseCount * 0.01)
}

# ============================================================
# SPL-Reflect: Metacognitive Knowledge - assess what Genes can improve
# ============================================================
function Run-SPLReflect {
   $script:dynamicCriteria = Read-DynamicCriteria
    $genes = Get-ChildItem -Path $script:genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
    if ($null -eq $genes -or $genes.Count -eq 0) {
        Write-Host "[REFLECT] No genes found."
        return @()
    }
    Write-Host "[REFLECT] Scanning $($genes.Count) genes..."
    $strategies = Parse-StrategiesYaml -FilePath $StrategiesPath
    $registry = Parse-ResourceRegistry -FilePath $ResourceRegistryPath
    $relevantGenes = @()
    
    foreach ($g in $genes) {
        $gene = Parse-GeneYaml -FilePath $g.FullName
        if ($null -eq $gene) { continue }
        $geneId = $gene['gene_id']
        $domain = $gene['domain']
        $trigger = if ($gene.ContainsKey('trigger')) { $gene['trigger'] } else { "" }
        $strategy = if ($gene.ContainsKey('strategy')) { $gene['strategy'] } else { "" }
        $mean = if ($gene.ContainsKey('pareto_mean')) { $gene['pareto_mean'] } else { 0 }
        $useCount = if ($gene.ContainsKey('use_count')) { $gene['use_count'] } else { 0 }
        
        # Metacognitive Knowledge: match Gene to improvement directions
        $improvementDirections = @()
        if ($strategies.directions.Count -gt 0) {
            foreach ($dir in $strategies.directions) {
                $score = 0
                $searchText = "${trigger} ${strategy}".ToLower()
                foreach ($kw in $dir.keywords) { if ($searchText -match [regex]::Escape($kw.ToLower())) { $score += 0.3 } }
                foreach ($target in $dir.targets) { if ($domain -match [regex]::Escape($target.ToLower())) { $score += 0.2 } }
                 if ($gene.ContainsKey('pareto_system_enhance') -and $gene['pareto_system_enhance'] -ge $script:dynamicCriteria['threshold']) {
                     if ($dir.name -match 'system|intel|smart') { $score += $script:dynamicCriteria['system_enhance_weight'] }
                }
                 if ($gene.ContainsKey('pareto_automation') -and $gene['pareto_automation'] -ge $script:dynamicCriteria['threshold']) {
                     if ($dir.name -match 'automat') { $score += $script:dynamicCriteria['automation_weight'] }
                }
                 if ($gene.ContainsKey('pareto_self_evolve') -and $gene['pareto_self_evolve'] -ge $script:dynamicCriteria['threshold']) {
                     if ($dir.name -match 'evolve|self') { $score += $script:dynamicCriteria['self_evolve_weight'] }
                }
                $score = [Math]::Min(1.0, $score)
                if ($score -ge 0.3) { $improvementDirections += $dir.name }
            }
        } else {
            # Fallback from Pareto scores
            if ($gene.ContainsKey('pareto_system_enhance') -and $gene['pareto_system_enhance'] -ge 0.5) { $improvementDirections += "system-enhance" }
            if ($gene.ContainsKey('pareto_automation') -and $gene['pareto_automation'] -ge 0.5) { $improvementDirections += "automation" }
            if ($gene.ContainsKey('pareto_self_evolve') -and $gene['pareto_self_evolve'] -ge 0.5) { $improvementDirections += "self-evolve" }
        }
        
        # Search related notes for context aggregation
        $relatedNotes = @()
        if ($trigger -ne "") {
            $terms = $trigger -split "[\W]+" | Where-Object { $_.Trim().Length -gt 2 } | Select-Object -First 5
            foreach ($term in $terms) {
                $escaped = $term.Trim() -replace '[\[\]\(\)]', ''
                if ($escaped.Length -lt 2) { continue }
                $found = Get-ChildItem -Path (Join-Path $vault "知识") -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
                    $body = Get-BodyText $_.FullName
                    $body -match [regex]::Escape($escaped)
                } | Select-Object -First 3
                foreach ($f in $found) { $relatedNotes += $f.FullName }
            }
        }
        
        # Search system Docs for relevance
        $systemHits = @()
        if ($strategy -ne "") {
            $strategyTerms = $strategy -split "[\W]+" | Where-Object { $_.Trim().Length -gt 3 } | Select-Object -First 3
            foreach ($term in $strategyTerms) {
                $escaped = $term.Trim() -replace '[\[\]\(\)]', ''
                if ($escaped.Length -lt 3) { continue }
                $found = Get-ChildItem -Path "$ProjectPath\Docs\AI" -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
                    try { $c = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8); $null -ne $c -and $c -match [regex]::Escape($escaped) } catch { $false }
                } | Select-Object -First 2
                foreach ($f in $found) { $systemHits += $f.FullName }
            }
        }
        
        # Check resource overlap (avoid re-implementing existing)
        $existingOverlap = @()
        if ($null -ne $registry -and $registry.ContainsKey('resources')) {
            foreach ($res in $registry.resources) {
                $searchStr = "${trigger} ${strategy}".ToLower()
                if ($res.description -ne "" -and $searchStr -match [regex]::Escape($res.description.ToLower())) {
                    $existingOverlap += "$($res.type)/$($res.name)"
                }
            }
        }
        
        $relevance = @{
            gene_id = $geneId
            domain = $domain
            trigger = $trigger
            pareto_mean = $mean
            improvement_directions = @($improvementDirections | Select-Object -Unique)
            related_notes = @($relatedNotes | Select-Object -Unique)
            system_hits = @($systemHits | Select-Object -Unique)
            existing_overlap = @($existingOverlap | Select-Object -Unique)
            use_count = $useCount
            file_path = $g.FullName
        }
        $relevantGenes += $relevance
        
        # Update Gene use_count (mark as reflected upon)
        if (-not $DryRun -or $Apply) {
            $gc = [System.IO.File]::ReadAllText($g.FullName, [System.Text.Encoding]::UTF8)
            $newUseCount = 1
            if ($gc -match 'use_count:\s*(\d+)') { $newUseCount = [int]$Matches[1] + 1 }
            $gc = $gc -replace "use_count:\s*\d+", "use_count: $newUseCount"
            $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
            $gc = $gc -replace "last_used:\s*`"[^`"]*`"", "last_used: `"$now`""
            [System.IO.File]::WriteAllText($g.FullName, $gc, [System.Text.Encoding]::UTF8)
        }
        
        Write-Host "[REFLECT] Gene ${geneId}: dirs=$($improvementDirections -join ','), related=$($relatedNotes.Count), system=$($systemHits.Count)"
    }
    return $relevantGenes
}

# ============================================================
# SPL-Select: Metacognitive Planning - choose most impactful Gene
# ============================================================
function Run-SPLSelect {
    param([array]$RelevantGenes)
   if ($null -eq $script:dynamicCriteria) { $script:dynamicCriteria = Read-DynamicCriteria }
    if ($RelevantGenes.Count -eq 0) { Write-Host "[SELECT] No genes."; return $null }
    $bestGene = $null; $bestScore = -999999
    foreach ($rg in $RelevantGenes) {
        $baseScore = 0
       $baseScore += $rg.improvement_directions.Count * $script:dynamicCriteria['system_enhance_weight']
       $baseScore += $rg.pareto_mean * $script:dynamicCriteria['automation_weight']
        $baseScore += [Math]::Min($rg.related_notes.Count, 5) * 0.05
        $baseScore += [Math]::Min($rg.system_hits.Count, 3) * 0.1
        if ($rg.existing_overlap.Count -eq 0) { $baseScore += 0.15 }
        $useCount = 0
        if ($rg.ContainsKey('use_count')) { $useCount = [int]$rg.use_count }
        $saturationPenalty = Get-GeneSaturationPenalty -UseCount $useCount
        $score = $baseScore - $saturationPenalty
        Write-Host "[SELECT] Gene $($rg.gene_id): base=$baseScore saturation=$saturationPenalty use_count=$useCount score=$score"
        if ($score -gt $bestScore) { $bestScore = $score; $bestGene = $rg }
    }
    if ($null -ne $bestGene) { Write-Host "[SELECT] Selected $($bestGene.gene_id) (score=$bestScore)" }
    return $bestGene
}

# ============================================================
# SPL-Improve: Generate improvement proposal
# ============================================================
function Run-SPLImprove {
    param([hashtable]$SelectedGene)
    if ($null -eq $SelectedGene) { Write-Host "[IMPROVE] No gene selected."; return $null }
    Write-Host "[IMPROVE] Generating proposal for $($SelectedGene.gene_id)..."
    
    $primaryDirection = if ($SelectedGene.improvement_directions.Count -gt 0) { $SelectedGene.improvement_directions[0] } else { "system-enhance" }
    
    # Load full Gene data for rich proposal content
    $geneFilePath = $SelectedGene.file_path
    $geneStrategy = ""
    $geneTrigger = if ($SelectedGene.ContainsKey('trigger')) { $SelectedGene.trigger } else { "" }
    $evidencePaths = @()
    $evidenceContent = @()
    
    if (-not [string]::IsNullOrEmpty($geneFilePath) -and (Test-Path $geneFilePath)) {
        $geneFull = [System.IO.File]::ReadAllText($geneFilePath, [System.Text.Encoding]::UTF8)
        
        # Extract multi-line strategy
        $inStrategy = $false
        $stratLines = @()
        foreach ($gline in $geneFull -split "`n") {
            if ($gline -match '^strategy:\s*"') { $inStrategy = $true; $stratLines += $gline -replace '^strategy:\s*"', ''; continue }
            if ($inStrategy -and $gline -match '^[a-z_]+:') { $inStrategy = $false; continue }
            if ($inStrategy) { $stratLines += $gline.TrimEnd() }
        }
        $geneStrategy = ($stratLines -join "`n").Trim().Trim('"')
        
        # Extract evidence paths
        $inEvidence = $false
        foreach ($gline in $geneFull -split "`n") {
            if ($gline -match '^evidence:') { $inEvidence = $true; continue }
            if ($inEvidence -and $gline -match '^\s+-\s+(.+)') { $evidencePaths += $Matches[1].Trim() }
            elseif ($inEvidence -and $gline -match '^[a-z_]') { $inEvidence = $false }
        }
        
        # Load evidence previews (first 400 chars each)
        foreach ($evPath in $evidencePaths) {
            if (Test-Path $evPath) {
                try {
                    $evBody = [System.IO.File]::ReadAllText($evPath, [System.Text.Encoding]::UTF8)
                    if ($evBody.Length -gt 400) { $evBody = $evBody.Substring(0, 400) + "..." }
                    $evidenceContent += @{ path = $evPath; preview = $evBody }
                } catch { }
            }
        }
    }
    
    # Generate context-aware steps based on Gene strategy (not empty templates)
    $strategySnippet = if ($geneStrategy.Length -gt 80) { $geneStrategy.Substring(0, 80) + "..." } else { $geneStrategy }
    
    # Map direction to target system components
    $targetMap = @{
        "intelligence" = @{ files = @("skills/", ".trae/scripts/obsidian-spl-cycle.ps1"); desc = "Improve skill routing and context retrieval" }
        "automation" = @{ files = @(".trae/scripts/obsidian-*.ps1"); desc = "Add new automation or reduce manual steps" }
        "humanize" = @{ files = @("Soul Core config", "response patterns"); desc = "Improve interaction quality and warmth" }
        "self_evolve" = @{ files = @(".trae/scripts/obsidian-self-improve.ps1", "obsidian-metacognitive.ps1"); desc = "Improve the self-improvement cycle itself" }
        "memory" = @{ files = @("Docs/Memory/", ".trae/scripts/memory-retrieve.ps1", ".trae/scripts/obsidian-scope-recall.ps1"); desc = "Enhance memory architecture and recall with scoped partitioning" }
        "skill" = @{ files = @("skills/"); desc = "Create new skills from knowledge gaps" }
    }
    
    $targetInfo = $targetMap[$primaryDirection]
    if ($null -eq $targetInfo) { $targetInfo = @{ files = @(".trae/scripts/"); desc = "Enhance system in $primaryDirection direction" } }
    
    # Build steps that reference actual Gene content
    $proposalSteps = @(
        "Read and analyze Gene strategy: $strategySnippet",
        "Identify specific code changes in $($targetInfo.files -join ', ') based on Gene knowledge",
        "Implement the change with -SelfTest switch and -Apply safety flag",
        "Run all obsidian self-tests to verify no regression",
        "If tests pass: git commit. If fail: fix (up to 5 rounds), then rollback if stuck"
    )
    
    # Build evidence block for proposal
    $evidenceBlock = ""
    if ($evidenceContent.Count -gt 0) {
        $evidenceBlock = "`n"
        foreach ($ev in $evidenceContent) {
            $preview = $ev.preview -replace "`n", " " -replace "\s+", " "
            if ($preview.Length -gt 200) { $preview = $preview.Substring(0, 200) + "..." }
            $evidenceBlock += "  - $($ev.path): $preview`n"
        }
    }
    
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $dateStamp = New-DateStamp
    $proposalId = Get-Sha1Short -InputString "proposal:$($SelectedGene.gene_id):$dateStamp"
    
    $proposal = @{
        proposal_id = $proposalId
        source_gene = $SelectedGene.gene_id
        improvement_direction = $primaryDirection
        all_directions = @($SelectedGene.improvement_directions)
        steps = $proposalSteps
        context_sources = @($SelectedGene.related_notes | Select-Object -First 5)
        system_sources = @($SelectedGene.system_hits | Select-Object -First 3)
        overlap_warning = @($SelectedGene.existing_overlap)
        pareto_mean = $SelectedGene.pareto_mean
        gene_strategy = $geneStrategy
        evidence_preview = $evidenceBlock
        target_files = @($targetInfo.files)
        status = "proposed"
        created_at = $now
    }
    
    # Write proposal YAML with Gene strategy and evidence
    $stepsYaml = ($proposalSteps | ForEach-Object { "  - $_" }) -join "`n"
    $ctxYaml = if ($proposal.context_sources.Count -gt 0) { ($proposal.context_sources | ForEach-Object { "  - $_" }) -join "`n" } else { "  - none" }
    $sysYaml = if ($proposal.system_sources.Count -gt 0) { ($proposal.system_sources | ForEach-Object { "  - $_" }) -join "`n" } else { "  - none" }
    $overlapYaml = if ($proposal.overlap_warning.Count -gt 0) { $proposal.overlap_warning -join ', ' } else { "none" }
    $targetYaml = ($targetInfo.files | ForEach-Object { "  - $_" }) -join "`n"
    
    # Escape strategy for YAML (use literal block scalar)
    $strategyYaml = $geneStrategy
    if ($strategyYaml.Length -gt 500) { $strategyYaml = $strategyYaml.Substring(0, 500) + "..." }
    
    $proposalContent = "proposal_id: `"$proposalId`"`nsource_gene: `"$($SelectedGene.gene_id)`"`nimprovement_direction: `"$primaryDirection`"`nsteps:`n$stepsYaml`ncontext_sources:`n$ctxYaml`nsystem_sources:`n$sysYaml`noverlap_warning: [$overlapYaml]`npareto_mean: $($SelectedGene.pareto_mean)`ngene_strategy: |-`n  $strategyYaml`nevidence_preview: |-$evidenceBlock`ntarget_files:`n$targetYaml`nstatus: proposed`ncreated_at: `"$now`""
    
    $proposalPath = Join-Path $script:proposalsDir "proposal-spl-${dateStamp}-$proposalId.yaml"
    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($proposalPath, $proposalContent, [System.Text.Encoding]::UTF8)
        Write-Host "[PROPOSAL] Written: $proposalPath"
    } else {
        Write-Host "[DRY-PROPOSAL] Would write: $proposalPath"
    }
    
    # Write implementation detail with Gene strategy
    $ctxBlocks = @()
    foreach ($notePath in $SelectedGene.related_notes) {
        if (Test-Path $notePath) {
            $body = Get-BodyText $notePath
            if ($body.Length -gt 300) { $body = $body.Substring(0, 300) }
            $ctxBlocks += "- $notePath`: $body"
        }
    }
    $ctxText = if ($ctxBlocks.Count -gt 0) { $ctxBlocks -join "`n" } else { "No local context available" }
    
    $evidenceText = ""
    foreach ($ev in $evidenceContent) {
        $evidenceText += "`n### $($ev.path)`n$($ev.preview)`n"
    }
    
    $implDetail = "# Implementation Detail for $proposalId`n`n## Source Gene`n- ID: $($SelectedGene.gene_id)`n- Domain: $($SelectedGene.domain)`n- Direction: $primaryDirection`n`n## Gene Strategy`n$geneStrategy`n`n## Evidence`n$evidenceText`n`n## Context`n$ctxText`n`n## Steps`n$(($proposalSteps | ForEach-Object { "- $_" }) -join "`n")`n`n## Target Files`n$(($targetInfo.files | ForEach-Object { "- $_" }) -join "`n")`n`n## Self-Test Plan`n- Verify no existing system breakage`n- Verify Gene YAML not modified directly`n- Verify new capability works`n- Verify -SelfTest switch included`n"
    $implPath = Join-Path $script:proposalsDir "impl-detail-$proposalId.md"
    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($implPath, $implDetail, [System.Text.Encoding]::UTF8)
        Write-Host "[IMPL] Written: $implPath"
    }
    
    return $proposal
}

# ============================================================
# SPL-Evaluate: Metacognitive Evaluation - assess proposal feasibility
# ============================================================
function Run-SPLEvaluate {
    param([hashtable]$Proposal)
    if ($null -eq $Proposal) { return @{ feasible = $false; feasibility_score = 0; risks = @("No proposal"); needs_web_search = $false } }
    Write-Host "[EVALUATE] Evaluating $($Proposal.proposal_id)..."
    
    $risks = @(); $feasibility = 0.5
    $overlapCount = if ($Proposal.ContainsKey('overlap_warning')) { @($Proposal.overlap_warning).Count } else { 0 }
    $ctxCount = if ($Proposal.ContainsKey('context_sources')) { @($Proposal.context_sources).Count } else { 0 }
    $sysCount = if ($Proposal.ContainsKey('system_sources')) { @($Proposal.system_sources).Count } else { 0 }
    $mean = if ($Proposal.ContainsKey('pareto_mean')) { $Proposal.pareto_mean } else { 0.5 }
    $stepsCount = if ($Proposal.ContainsKey('steps')) { @($Proposal.steps).Count } else { 4 }
    
    if ($overlapCount -gt 0) { $risks += "Overlap: $($Proposal.overlap_warning -join ', ')"; $feasibility -= 0.1 }
    if ($ctxCount -lt 2) { $risks += "Insufficient context ($ctxCount notes)"; $feasibility -= 0.15 }
    if ($mean -lt 0.6) { $risks += "Low pareto mean ($mean)"; $feasibility -= 0.2 }
    if ($stepsCount -gt 5) { $risks += "Too many steps ($stepsCount)"; $feasibility -= 0.1 }
    if ($ctxCount -ge 3) { $feasibility += 0.1 }
    if ($sysCount -ge 1) { $feasibility += 0.1 }
    if ($mean -ge 0.7) { $feasibility += 0.15 }
    $feasibility = [Math]::Min(1.0, [Math]::Max(0.0, $feasibility))
    
    $needsWebSearch = ($ctxCount -lt 2 -and $sysCount -lt 1)
    if ($needsWebSearch) { $risks += "Need web search for: $($Proposal.improvement_direction)" }
    
    $evaluation = @{ proposal_id = $Proposal.proposal_id; feasible = ($feasibility -ge 0.4); feasibility_score = $feasibility; risks = $risks; needs_web_search = $needsWebSearch }
    Write-Host "[EVALUATE] Feasibility: $feasibility, Risks: $($risks.Count), WebSearch: $needsWebSearch"
    return $evaluation
}

# ============================================================
# SPL-Commit: Execute the proposal
# ============================================================
function Run-SPLCommit {
    param([hashtable]$Proposal, [hashtable]$Evaluation)
    if ($null -eq $Proposal) { Write-Host "[COMMIT] No proposal."; return @{ committed = $false } }
    if ($null -ne $Evaluation -and -not $Evaluation.feasible) {
        Write-Host "[COMMIT] BLOCKED: Not feasible ($($Evaluation.feasibility_score))."
        return @{ committed = $false }
    }
    if (-not $AutoCommit -and -not $Apply) {
        Write-Host "[COMMIT] Ready but requires approval. Use -AutoCommit -Apply."
        return @{ committed = $false }
    }
    Write-Host "[COMMIT] Executing $($Proposal.proposal_id)..."
    
    # Mark as committed
    $found = Get-ChildItem -Path $script:proposalsDir -Filter "proposal-spl-*-$($Proposal.proposal_id).yaml" -File -ErrorAction SilentlyContinue
    if ($null -ne $found -and $found.Count -gt 0) {
        $content = [System.IO.File]::ReadAllText($found[0].FullName, [System.Text.Encoding]::UTF8)
        $content = $content -replace "status:\s*proposed", "status: committed"
        [System.IO.File]::WriteAllText($found[0].FullName, $content, [System.Text.Encoding]::UTF8)
    }
    
    # Copy to enacted
    if (Test-Path $script:enactedDir) {
        if ($null -ne $found -and $found.Count -gt 0) {
            Copy-Item -Path $found[0].FullName -Destination (Join-Path $script:enactedDir "proposal-spl-$($Proposal.proposal_id).yaml") -Force
        }
    }
    
    Write-Host "[COMMIT] Proposal committed."
    return @{ committed = $true; proposal_id = $Proposal.proposal_id }
}

# ============================================================
# Full Cycle
# ============================================================
function Run-FullCycle {
    Write-Host "=== SPL Full Cycle (v2) ==="
    Write-Host ""
    Write-Host "--- Step 1: SPL-Reflect (Metacognitive Knowledge) ---"
    $relevantGenes = Run-SPLReflect
    if ($relevantGenes.Count -eq 0) { Write-Host "[CYCLE] No genes. End."; return }
    if ($GeneId -ne "") { $relevantGenes = @($relevantGenes | Where-Object { $_.gene_id -eq $GeneId }) }
    Write-Host "--- Step 2: SPL-Select (Metacognitive Planning) ---"
    $selectedGene = Run-SPLSelect -RelevantGenes $relevantGenes
    if ($null -eq $selectedGene) { Write-Host "[CYCLE] No selection. End."; return }
    Write-Host "--- Step 3: SPL-Improve ---"
    $proposal = Run-SPLImprove -SelectedGene $selectedGene
    if ($null -eq $proposal) { Write-Host "[CYCLE] No proposal. End."; return }
    Write-Host "--- Step 4: SPL-Evaluate (Metacognitive Evaluation) ---"
    $evaluation = Run-SPLEvaluate -Proposal $proposal
    Write-Host "--- Step 5: SPL-Commit ---"
    $commitResult = Run-SPLCommit -Proposal $proposal -Evaluation $evaluation
    Write-Host ""
    Write-Host "=== Cycle Complete: Gene=$($selectedGene.gene_id) Proposal=$($proposal.proposal_id) Feasible=$($evaluation.feasible) Committed=$($commitResult.committed) ==="
    
    # Generate cycle report
    [void](Write-JsonReport -Data @{ cycle = "full"; gene = $selectedGene.gene_id; proposal = $proposal.proposal_id; feasible = $evaluation.feasible; committed = $commitResult.committed } -ReportDir $script:proposalsDir -Prefix "spl-cycle")
}

# ============================================================
# Self-test
# ============================================================
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-spl-cycle self-test..."
    $testDir = "$env:TEMP\obsidian-spl-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path "$testDir\进化\genes" -ItemType Directory -Force | Out-Null
    New-Item -Path "$testDir\进化\proposals" -ItemType Directory -Force | Out-Null
    New-Item -Path "$testDir\进化\enacted" -ItemType Directory -Force | Out-Null
    
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $testGeneContent = "gene_id: test001`ndomain: ai/agent-arch`ntrigger: `"Self-evolving agent systems with feedback loops`"`nstrategy: `"Implement recursive self-improvement with SPL safety`"`npareto_scores:`n  system-enhance: 0.8`n  code-quality: 0.5`n  automation: 0.7`n  self-evolve: 0.9`n  mean: 0.675`nuse_count: 0`nstatus: active"
    [System.IO.File]::WriteAllText("$testDir\进化\genes\gene-test.yaml", $testGeneContent, [System.Text.Encoding]::UTF8)
    
    # Test Parse-GeneYaml
    $gene = Parse-GeneYaml -FilePath "$testDir\进化\genes\gene-test.yaml"
    if ($null -eq $gene -or -not $gene.ContainsKey('gene_id')) { Write-Output "[SELFTEST-FAIL] Parse-GeneYaml"; exit 1 }
    Write-Output "[SELFTEST-PASS] Parse-GeneYaml: gene_id=$($gene['gene_id']), mean=$($gene['pareto_mean'])"
    
    # Test SPL-Improve with a manually constructed gene
    $testGene = @{ gene_id = "test001"; domain = "ai/agent-arch"; trigger = "Self-evolving agent systems"; pareto_mean = 0.675; improvement_directions = @("自我进化", "更自动化"); related_notes = @(); system_hits = @(); existing_overlap = @(); use_count = 0 }
    
    # Temporarily redirect output dir
    $origGenesDir = $script:genesDir
    $origProposalsDir = $script:proposalsDir
    $origEnactedDir = $script:enactedDir
    $script:genesDir = "$testDir\进化\genes"
    $script:proposalsDir = "$testDir\进化\proposals"
    $script:enactedDir = "$testDir\进化\enacted"
    
    $testProposal = Run-SPLImprove -SelectedGene $testGene
    if ($null -eq $testProposal) { Write-Output "[SELFTEST-FAIL] Proposal generation"; exit 1 }
    if (-not ($testProposal -is [hashtable])) { Write-Output "[SELFTEST-FAIL] Proposal not hashtable: $($testProposal.GetType())"; exit 1 }
    Write-Output "[SELFTEST-PASS] Proposal: $($testProposal.proposal_id)"
    
    # Test Evaluate
    $testEval = Run-SPLEvaluate -Proposal $testProposal
    if ($null -eq $testEval) { Write-Output "[SELFTEST-FAIL] Evaluation null"; exit 1 }
    Write-Output "[SELFTEST-PASS] Evaluation: feasible=$($testEval.feasible), score=$($testEval.feasibility_score)"
    
    # Test Select
    $selected = Run-SPLSelect -RelevantGenes @($testGene)
    if ($null -eq $selected) { Write-Output "[SELFTEST-FAIL] Select"; exit 1 }
    Write-Output "[SELFTEST-PASS] Select: $($selected.gene_id)"

    # Test saturation penalty: same-value high-use Gene should yield to fresher option
    $staleGene = @{ gene_id = "stale001"; improvement_directions = @("自我进化", "更自动化"); pareto_mean = 0.675; related_notes = @(); system_hits = @(); existing_overlap = @(); use_count = 50 }
    $freshGene = @{ gene_id = "fresh001"; improvement_directions = @("自我进化", "更自动化"); pareto_mean = 0.675; related_notes = @(); system_hits = @(); existing_overlap = @(); use_count = 0 }
    $selectedFresh = Run-SPLSelect -RelevantGenes @($staleGene, $freshGene)
    if ($null -eq $selectedFresh -or $selectedFresh.gene_id -ne "fresh001") { Write-Output "[SELFTEST-FAIL] Saturation penalty"; exit 1 }
    Write-Output "[SELFTEST-PASS] Saturation penalty selected: $($selectedFresh.gene_id)"
    
    # Restore dirs
    $script:genesDir = $origGenesDir
    $script:proposalsDir = $origProposalsDir
    $script:enactedDir = $origEnactedDir
    
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

# ============================================================
# Run requested step
# ============================================================
if ($Reflect) { Run-SPLReflect }
elseif ($FullCycle) { Run-FullCycle }
elseif ($Select -and $GeneId -ne "") {
    Run-SPLSelect -RelevantGenes @(@{ gene_id = $GeneId; improvement_directions = @("system-enhance"); pareto_mean = 0.5; related_notes = @(); system_hits = @(); existing_overlap = @() })
}
elseif ($Improve -and $GeneId -ne "") {
    Run-SPLImprove -SelectedGene @{ gene_id = $GeneId; domain = "unknown"; trigger = ""; pareto_mean = 0.5; improvement_directions = @("system-enhance"); related_notes = @(); system_hits = @(); existing_overlap = @() }
}
elseif ($Evaluate -and $GeneId -ne "") {
    Run-SPLEvaluate -Proposal @{ proposal_id = $GeneId; overlap_warning = @(); context_sources = @(); system_sources = @(); pareto_mean = 0.5; improvement_direction = "system-enhance"; steps = @("s1","s2","s3","s4") }
}
elseif ($Commit -and $GeneId -ne "") {
    Run-SPLCommit -Proposal @{ proposal_id = $GeneId; improvement_direction = "system-enhance" } -Evaluation @{ feasible = $true; feasibility_score = 0.8; risks = @(); needs_web_search = $false }
}
else { Write-Error "Specify: -Reflect, -Select, -Improve, -Evaluate, -Commit, or -FullCycle. Use -Help."; exit 1 }
exit 0
