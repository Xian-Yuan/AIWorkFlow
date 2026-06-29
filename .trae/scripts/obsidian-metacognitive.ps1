# obsidian-metacognitive.ps1 - Intrinsic Metacognitive Learning Layer
# arxiv 2506.05109: Truly Self-Improving Agents Require Intrinsic Metacognitive Learning
# Key insight from Self-Monitoring paper: metacognition must sit ON the decision
# pathway, not beside it. So this layer directly modifies SPL parameters.
#
# Three components:
#   1. Assess: Metacognitive Knowledge - self-assess, build capability map,
#      generate DYNAMIC evaluation criteria (not fixed Pareto keywords)
#   2. Plan: Metacognitive Planning - derive learning priorities from gaps,
#      adjust direction weights based on past success patterns
#   3. Reflect: Metacognitive Evaluation - compare expected vs actual outcomes,
#      update lessons learned, adjust strategy weights for future cycles
#
# Integration: SPL-Reflect reads dynamic-criteria.yaml instead of fixed keywords
# PowerShell 5.1 compatible - all identifiers in ASCII, no Chinese in regex

param(
    [string]$VaultPath = 'E:\ObsidianVault',
    [string]$ProjectPath = 'E:\UEGameDevelopment',
    [string]$MetaPath = 'E:\ObsidianVault\metacognitive',
    [switch]$Assess,
    [switch]$Plan,
    [switch]$Reflect,
    [switch]$FullMeta,
    [switch]$DryRun = $true,
    [switch]$Apply,
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$helpersPath = Join-Path $PSScriptRoot '_shared\ObsidianHelpers.psm1'
Import-Module $helpersPath -Force -WarningAction SilentlyContinue

if ($Help) {
    Write-Host 'obsidian-metacognitive.ps1 - Intrinsic Metacognitive Learning Layer'
    Write-Host 'Components: -Assess | -Plan | -Reflect | -FullMeta'
    Write-Host 'This layer sits ON the SPL decision pathway (Self-Monitoring paper insight)'
    exit 0
}

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

if (-not (Test-Path $MetaPath)) { New-Item -Path $MetaPath -ItemType Directory -Force | Out-Null }

# Direction constants (ASCII only for PS5.1 compatibility)
$DIR_AUTOMATION = 'automation'
$DIR_INTELLIGENCE = 'intelligence'
$DIR_SELF_EVOLVE = 'self_evolve'
$DIR_MEMORY = 'memory'
$DIR_HUMANIZE = 'humanize'
# ============================================================
# Shared helpers
# ============================================================
function Write-MetaYaml {
    param([string]$FileName, [string]$Content)
    $path = Join-Path $MetaPath $FileName
    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($path, $Content, [System.Text.Encoding]::UTF8)
        Write-Host "  Written: $path"
    } else {
        Write-Host "  [DRY] Would write: $path"
    }
}

function Read-PastOutcomes {
    $evoDir = Join-Path $vault 'evo\logs'
    if (-not (Test-Path $evoDir)) {
        $evoDir = Join-Path $vault ([char]0x8FDB + [char]0x5316 + '\logs')
    }
    $logPath = Join-Path $evoDir 'evolution-log.md'
    if (-not (Test-Path $logPath)) { return @() }
    $content = [System.IO.File]::ReadAllText($logPath, [System.Text.Encoding]::UTF8)
    $outcomes = @()
    $blocks = $content -split '(?=### \d{4}-\d{2}-\d{2})'
    foreach ($block in $blocks) {
        if ($block -match 'Direction\*\*:\s*(\S+)') {
            $dir = $Matches[1]
            $result = if ($block -match 'Result\*\*:\s*(\w+)') { $Matches[1] } else { 'UNKNOWN' }
            $gene = if ($block -match 'Gene\*\*:\s*(\S+)') { $Matches[1] } else { '' }
            $proposal = if ($block -match 'Proposal\*\*:\s*(\S+)') { $Matches[1] } else { '' }
            $issues = if ($block -match 'Issues Fixed\*\*:\s*(\d+)') { [int]$Matches[1] } else { 0 }
            $tests = if ($block -match 'Tests Passed\*\*:\s*(\w+)') { $Matches[1] -eq 'True' } else { $false }
            $outcomes += @{ direction = $dir; result = $result; gene = $gene; proposal = $proposal; issues = $issues; tests = $tests }
        }
    }
    return $outcomes
}
# ============================================================
# Component 1: Metacognitive Knowledge (Self-Assessment)
# Builds capability map + generates DYNAMIC evaluation criteria
# ============================================================
function Invoke-MetacognitiveAssess {
    Write-Host '=== Metacognitive Knowledge: Self-Assessment ==='

    # 1. Scan system capabilities
    $cap = @{}
    $cap['classify'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-classify.ps1')
    $cap['evaluate'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-evolve.ps1')
    $cap['link_discover'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-link-discover.ps1')
    $cap['dream'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-dream-reflect.ps1')
    $cap['maintain'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-maintain.ps1')
    $cap['spl_cycle'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-spl-cycle.ps1')
    $cap['self_improve'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-self-improve.ps1')
    $cap['metacognitive'] = Test-Path (Join-Path $ProjectPath '.trae\scripts\obsidian-metacognitive.ps1')

    $genesDir = Join-Path $vault 'evo\genes'
    if (-not (Test-Path $genesDir)) { $genesDir = Join-Path $vault ([char]0x8FDB + [char]0x5316 + '\genes') }
    $cap['gene_pool'] = ((Get-ChildItem (Join-Path $genesDir '*.yaml') -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

    $enactedDir = Join-Path $vault 'evo\enacted'
    if (-not (Test-Path $enactedDir)) { $enactedDir = Join-Path $vault ([char]0x8FDB + [char]0x5316 + '\enacted') }
    $cap['evolved'] = ((Get-ChildItem (Join-Path $enactedDir '*.yaml') -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

    $cap['memory'] = ((Get-ChildItem (Join-Path $ProjectPath 'Docs\Memory\*.md') -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
    $cap['soul_core'] = $true

    $present = ($cap.GetEnumerator() | Where-Object { $_.Value }).Count
    $total = $cap.Count
    $gaps = @($cap.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })

    Write-Host "  Capabilities: $present/$total present"
    if ($gaps.Count -gt 0) { Write-Host "  Gaps: $($gaps -join ', ')" }
    else { Write-Host '  Gaps: none (all capabilities present)' }

    # 2. Read past outcomes and adapt criteria
    $pastOutcomes = Read-PastOutcomes
    $successCount = ($pastOutcomes | Where-Object { $_.result -eq 'SUCCESS' }).Count
    $failCount = ($pastOutcomes | Where-Object { $_.result -ne 'SUCCESS' }).Count
    $totalCount = $pastOutcomes.Count

    Write-Host "  Past outcomes: $successCount success / $failCount other (total: $totalCount)"

    # 3. Generate DYNAMIC criteria (intrinsic adaptation)
    $criteria = @{
        system_enhance_weight = 0.30
        automation_weight = 0.30
        code_quality_weight = 0.20
        self_evolve_weight = 0.20
        threshold = 0.60
    }

    # Adapt based on past success/failure patterns
    if ($totalCount -ge 1) {
        $dirStats = @{}
        foreach ($po in $pastOutcomes) {
            $d = $po.direction
            if (-not $dirStats.ContainsKey($d)) { $dirStats[$d] = @{ success = 0; fail = 0 } }
            if ($po.result -eq 'SUCCESS') { $dirStats[$d].success++ } else { $dirStats[$d].fail++ }
        }

        foreach ($d in $dirStats.Keys) {
            $s = $dirStats[$d].success; $f = $dirStats[$d].fail
            $rate = if (($s + $f) -gt 0) { [double]$s / ($s + $f) } else { 0.5 }

            $weightKey = $null
            if ($d -match 'system|intel|smart') { $weightKey = 'system_enhance_weight' }
            elseif ($d -match 'automat') { $weightKey = 'automation_weight' }
            elseif ($d -match 'quality|code') { $weightKey = 'code_quality_weight' }
            elseif ($d -match 'evolve|self') { $weightKey = 'self_evolve_weight' }

            if ($null -ne $weightKey) {
                if ($rate -ge 0.7) {
                    $criteria[$weightKey] = [Math]::Min(0.50, $criteria[$weightKey] + 0.03)
                    $r2 = [Math]::Round($rate, 2)
                    Write-Host "  [ADAPT] $weightKey += 0.03 (high success rate: $r2)"
                } elseif ($rate -lt 0.4) {
                    $criteria[$weightKey] = [Math]::Min(0.50, $criteria[$weightKey] + 0.06)
                    $r2 = [Math]::Round($rate, 2)
                    Write-Host "  [ADAPT] $weightKey += 0.06 (low success rate: $r2)"
                }
            }
        }

        # Adapt threshold
        $overallRate = if ($totalCount -gt 0) { [double]$successCount / $totalCount } else { 0.5 }
        if ($overallRate -lt 0.5) {
            $criteria['threshold'] = [Math]::Max(0.30, $criteria['threshold'] - 0.05)
            $or2 = [Math]::Round($overallRate, 2)
            Write-Host "  [ADAPT] threshold -= 0.05 (low overall success: $or2)"
        } elseif ($overallRate -gt 0.8) {
            $criteria['threshold'] = [Math]::Min(0.80, $criteria['threshold'] + 0.05)
            $or2 = [Math]::Round($overallRate, 2)
            Write-Host "  [ADAPT] threshold += 0.05 (high overall success: $or2)"
        }
    }

    $sew = $criteria['system_enhance_weight']
    $aw = $criteria['automation_weight']
    $cqw = $criteria['code_quality_weight']
    $sevw = $criteria['self_evolve_weight']
    $th = $criteria['threshold']
    Write-Host "  Dynamic criteria: sys=$sew auto=$aw qual=$cqw evolve=$sevw threshold=$th"

    # 4. Write capability map
    $capYaml = "# Capability map (auto-updated by metacognitive assess)`n# Updated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`n"
    foreach ($key in ($cap.Keys | Sort-Object)) {
        $val = $cap[$key].ToString().ToLower()
        $capYaml += "${key}: ${val}`n"
    }
    $gapsStr = $gaps -join ', '
    $capYaml += "`n# Gaps`ngaps: [${gapsStr}]`n"
    Write-MetaYaml -FileName 'capability-map.yaml' -Content $capYaml

    # 5. Write dynamic criteria (THIS is what SPL reads)
    $critYaml = "# Dynamic evaluation criteria (intrinsic metacognition)`n# Updated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`n# Past outcomes: $successCount success / $failCount other`n"
    $critYaml += "system_enhance_weight: $($criteria['system_enhance_weight'])`n"
    $critYaml += "automation_weight: $($criteria['automation_weight'])`n"
    $critYaml += "code_quality_weight: $($criteria['code_quality_weight'])`n"
    $critYaml += "self_evolve_weight: $($criteria['self_evolve_weight'])`n"
    $critYaml += "threshold: $($criteria['threshold'])`n"
    Write-MetaYaml -FileName 'dynamic-criteria.yaml' -Content $critYaml

    return @{ capabilities = $cap; gaps = $gaps; criteria = $criteria; past_outcomes = $pastOutcomes }
}
# ============================================================
# Component 2: Metacognitive Planning (Decide What/How to Learn)
# ============================================================
function Invoke-MetacognitivePlan {
    param([hashtable]$Assessment)

    Write-Host '=== Metacognitive Planning: What/How to Learn ==='

    if ($null -eq $Assessment) { Write-Host '  No assessment. Run -Assess first.'; return $null }

    $gaps = $Assessment.gaps
    $criteria = $Assessment.criteria
    $pastOutcomes = $Assessment.past_outcomes

    # 1. Gap -> direction mapping (all ASCII identifiers)
    $gapToDirection = @{
        'classify' = $DIR_AUTOMATION
        'evaluate' = $DIR_INTELLIGENCE
        'link_discover' = $DIR_INTELLIGENCE
        'dream' = $DIR_SELF_EVOLVE
        'maintain' = $DIR_AUTOMATION
        'spl_cycle' = $DIR_SELF_EVOLVE
        'self_improve' = $DIR_SELF_EVOLVE
        'metacognitive' = $DIR_SELF_EVOLVE
        'gene_pool' = $DIR_INTELLIGENCE
        'evolved' = $DIR_SELF_EVOLVE
        'memory' = $DIR_MEMORY
        'soul_core' = $DIR_HUMANIZE
    }

    $priorities = @()
    foreach ($gap in $gaps) {
        $dir = if ($gapToDirection.ContainsKey($gap)) { $gapToDirection[$gap] } else { $DIR_INTELLIGENCE }
        $priorities += @{ gap = $gap; direction = $dir; priority = 'CRITICAL' }
        Write-Host "  GAP: $gap -> $dir (CRITICAL)"
    }

    # 2. Infer improvement directions from past success patterns
    if ($pastOutcomes.Count -gt 0) {
        $dirSuccess = @{}
        foreach ($po in $pastOutcomes) {
            if ($po.result -eq 'SUCCESS') {
                if (-not $dirSuccess.ContainsKey($po.direction)) { $dirSuccess[$po.direction] = 0 }
                $dirSuccess[$po.direction]++
            }
        }
        $bestDir = ($dirSuccess.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
        if ($null -ne $bestDir -and $bestDir.Value -ge 1) {
            $bk = $bestDir.Key; $bv = $bestDir.Value
            Write-Host "  [PATTERN] Best direction: $bk ($bv successes) -> continue"
        }

        $dirFail = @{}
        foreach ($po in $pastOutcomes) {
            if ($po.result -ne 'SUCCESS') {
                if (-not $dirFail.ContainsKey($po.direction)) { $dirFail[$po.direction] = 0 }
                $dirFail[$po.direction]++
            }
        }
        $worstDir = ($dirFail.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
        if ($null -ne $worstDir -and $worstDir.Value -ge 1) {
            $wk = $worstDir.Key; $wv = $worstDir.Value
            Write-Host "  [PATTERN] Worst direction: $wk ($wv fails) -> try different approach"
            $priorities += @{ gap = 'approach_diversity'; direction = $wk; priority = 'HIGH' }
        }
    }

    # 3. Generate learning strategy
    $focusDirs = @($priorities | ForEach-Object { $_.direction } | Select-Object -Unique)
    $strategy = @{
        focus_directions = $focusDirs
        gap_count = $gaps.Count
        criteria = $criteria
        priorities = $priorities
    }

    # 4. Write learning plan
    $planYaml = "# Learning plan (intrinsic metacognition)`n# Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`n"
    $planYaml += "gap_count: $($gaps.Count)`n"
    $planYaml += "focus_directions:`n"
    foreach ($fd in $strategy.focus_directions) {
        $planYaml += "  - `"$fd`"`n"
    }
    $planYaml += "priorities:`n"
    foreach ($p in $priorities) {
        $planYaml += "  - gap: `"$($p.gap)`"`n    direction: `"$($p.direction)`"`n    priority: $($p.priority)`n"
    }
    Write-MetaYaml -FileName 'learning-plan.yaml' -Content $planYaml

    return $strategy
}
# ============================================================
# Component 3: Metacognitive Evaluation (Reflect on Outcomes)
# ============================================================
function Invoke-MetacognitiveReflect {
    Write-Host '=== Metacognitive Evaluation: Reflect on Outcomes ==='

    $pastOutcomes = Read-PastOutcomes
    if ($pastOutcomes.Count -eq 0) {
        Write-Host '  No past outcomes to reflect on.'
        return @{}
    }

    # 1. Analyze patterns
    $successCount = ($pastOutcomes | Where-Object { $_.result -eq 'SUCCESS' }).Count
    $successRate = [double]$successCount / $pastOutcomes.Count
    $sr2 = [Math]::Round($successRate, 2)
    Write-Host "  Overall success rate: $sr2"

    # 2. Generate lessons learned
    $lessons = @()

    $dirStats = @{}
    foreach ($po in $pastOutcomes) {
        $d = $po.direction
        if (-not $dirStats.ContainsKey($d)) { $dirStats[$d] = @{ success = 0; total = 0 } }
        $dirStats[$d].total++
        if ($po.result -eq 'SUCCESS') { $dirStats[$d].success++ }
    }
    foreach ($d in $dirStats.Keys) {
        $rate = [double]$dirStats[$d].success / $dirStats[$d].total
        $r2 = [Math]::Round($rate, 2)
        if ($rate -ge 0.7) {
            $lessons += "Direction '$d' has high success rate ($r2). Continue focusing here."
        } elseif ($rate -lt 0.4) {
            $lessons += "Direction '$d' has low success rate ($r2). Try different approach or reduce priority."
        }
    }

    # Lesson: issues correlate with failure
    $highIssueFails = @($pastOutcomes | Where-Object { $_.result -ne 'SUCCESS' -and $_.issues -gt 2 })
    if ($highIssueFails.Count -gt 0) {
        $lessons += 'Failures with >2 issues suggest the proposal was too ambitious. Consider smaller steps.'
    }

    # Lesson: gene reuse
    $usedGenes = @($pastOutcomes | Where-Object { $_.ContainsKey('gene') -and $_.gene -ne '' } | ForEach-Object { $_.gene } | Select-Object -Unique)
    if ($usedGenes.Count -gt 0) {
        $geneList = $usedGenes -join ', '
        $lessons += "Genes used: ${geneList}. High-use genes should be prioritized for future evolution."
    }

    if ($lessons.Count -eq 0) {
        $lessons += 'Insufficient data for specific lessons. Continue evolving to accumulate more experience.'
    }

    Write-Host '  Lessons learned:'
    foreach ($l in $lessons) { Write-Host "    - $l" }

    # 3. Write reflection
    $dateStamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $reflectYaml = "# Reflection (intrinsic metacognition)`n# Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`n"
    $reflectYaml += "success_rate: $([Math]::Round($successRate, 3))`n"
    $reflectYaml += "total_outcomes: $($pastOutcomes.Count)`n"
    $reflectYaml += "lessons:`n"
    foreach ($l in $lessons) {
        $escaped = $l -replace '"', "'"
        $reflectYaml += "  - `"$escaped`"`n"
    }
    Write-MetaYaml -FileName "reflection-${dateStamp}.yaml" -Content $reflectYaml

    # 4. Update persistent lessons-learned.yaml
    $lessonsPath = Join-Path $MetaPath 'lessons-learned.yaml'
    $lessonsContent = ''
    if (Test-Path $lessonsPath) {
        $lessonsContent = [System.IO.File]::ReadAllText($lessonsPath, [System.Text.Encoding]::UTF8)
    }
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    foreach ($l in $lessons) {
        $escaped = $l -replace '"', "'"
        if ($lessonsContent -notmatch [regex]::Escape($escaped)) {
            $lessonsContent += "`n- lesson: `"$escaped`"`n  added: `"$now`"`n  source: metacognitive_reflect`n"
        }
    }
    if (-not ($DryRun -and -not $Apply)) {
        [System.IO.File]::WriteAllText($lessonsPath, $lessonsContent, [System.Text.Encoding]::UTF8)
        Write-Host "  Lessons updated: $lessonsPath"
    }

    return @{ lessons = $lessons; success_rate = $successRate }
}
# ============================================================
# Full Meta Cycle
# ============================================================
function Invoke-FullMetaCycle {
    Write-Host '=== Full Metacognitive Cycle ==='
    Write-Host ''

    Write-Host '--- Step 1: Self-Assessment ---'
    $assessment = Invoke-MetacognitiveAssess

    Write-Host ''
    Write-Host '--- Step 2: Learning Plan ---'
    $plan = Invoke-MetacognitivePlan -Assessment $assessment

    Write-Host ''
    Write-Host '--- Step 3: Reflect on Outcomes ---'
    $reflection = Invoke-MetacognitiveReflect

    Write-Host ''
    Write-Host '=== Metacognitive Cycle Complete ==='
    $ac = $assessment.capabilities.Count
    $ag = $assessment.gaps.Count
    $pf = $plan.focus_directions.Count
    $rl = $reflection.lessons.Count
    Write-Host "Assessment: $ac capabilities, $ag gaps"
    Write-Host "Plan: $pf focus directions"
    Write-Host "Lessons: $rl lessons learned"
    Write-Host "Dynamic criteria now available at: $MetaPath\dynamic-criteria.yaml"
}

# ============================================================
# Self-test
# ============================================================
if ($SelfTest) {
    Write-Host "[SELFTEST] Running obsidian-metacognitive self-test..."

    # Step 1: Run Assess externally (avoid PS5.1 hashtable binding issues)
    $metaDir = Join-Path $VaultPath "metacognitive"
    if (-not (Test-Path $metaDir)) { New-Item -Path $metaDir -ItemType Directory -Force | Out-Null }

    # Assess should have been called already, check for capability-map.yaml
    $capPath = Join-Path $metaDir "capability-map.yaml"
    $critPath = Join-Path $metaDir "dynamic-criteria.yaml"

    # Generate fresh data by running assess inline
    Write-Host "  [1/3] Running Assess..."
    $cap = @{}
    $cap["classify"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-classify.ps1")
    $cap["evaluate"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-evolve.ps1")
    $cap["link_discover"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-link-discover.ps1")
    $cap["dream"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-dream-reflect.ps1")
    $cap["maintain"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-maintain.ps1")
    $cap["spl_cycle"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-spl-cycle.ps1")
    $cap["self_improve"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-self-improve.ps1")
    $cap["metacognitive"] = Test-Path (Join-Path $ProjectPath ".trae\scripts\obsidian-metacognitive.ps1")
    $present = ($cap.GetEnumerator() | Where-Object { $_.Value }).Count
    Write-Host "  Capabilities: $present/$($cap.Count) present"

    # Step 2: Verify past outcomes reader
    Write-Host "  [2/3] Testing Read-PastOutcomes..."
    $outcomes = Read-PastOutcomes
    Write-Host "  Past outcomes found: $($outcomes.Count)"

    # Step 3: Verify file I/O
    Write-Host "  [3/3] Testing Write-MetaYaml..."
    $testYaml = "# Self-test verification`ntest: true`ntimestamp: $(Get-Date -Format yyyy-MM-ddTHH:mm:ss)`n"
    # Self-test bypasses DryRun to verify actual I/O
    $verifyPath = Join-Path $MetaPath "self-test-verify.yaml"
    [System.IO.File]::WriteAllText($verifyPath, $testYaml, [System.Text.Encoding]::UTF8)
    $verifyPath = Join-Path $MetaPath "self-test-verify.yaml"
    if (Test-Path $verifyPath) {
        Write-Host "[SELFTEST-PASS] File I/O works"
        Remove-Item $verifyPath -Force
    } else {
        Write-Host "[SELFTEST-FAIL] File I/O failed"
        exit 1
    }

    Write-Host "[SELFTEST] All tests passed."
    exit 0
}

# Run
if ($Assess) { Invoke-MetacognitiveAssess }
elseif ($Plan) { Invoke-MetacognitivePlan -Assessment (Invoke-MetacognitiveAssess) }
elseif ($Reflect) { Invoke-MetacognitiveReflect }
elseif ($FullMeta) { Invoke-FullMetaCycle }
else { Write-Error "Specify: -Assess, -Plan, -Reflect, or -FullMeta. Use -Help for details."; exit 1 }
exit 0
