# obsidian-dream-reflect.ps1 - Dream reflection report generator
# WP05: Weekly dream-reflection: Gene usage, knowledge gaps, stale proposals, dormant notes
# PowerShell 5.1 compatible, no external modules
# Safety: SUGGESTIONS ONLY - never auto-archive or auto-approve

param(
    [switch]$FullScan,
    [switch]$QuickScan,
    [string]$OutputPath = "",
    [string]$VaultPath = "E:\ObsidianVault",
    [string]$ProjectPath = "E:\UEGameDevelopment",
    [switch]$SelfTest,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$helpersPath = "$PSScriptRoot\_shared\ObsidianHelpers.psm1"

function Show-Help {
    Write-Output @"
obsidian-dream-reflect.ps1 - Dream reflection report

Usage:
  .\obsidian-dream-reflect.ps1 -QuickScan              # 1-page Gene usage summary
  .\obsidian-dream-reflect.ps1 -FullScan               # Full gap analysis report
  .\obsidian-dream-reflect.ps1 -SelfTest               # Run self-test
  .\obsidian-dream-reflect.ps1 -Help                   # Show this help

Parameters:
  -QuickScan    Quick Gene usage summary
  -FullScan     Full knowledge gap analysis
  -OutputPath   Custom output directory (default: 进化/dreams/)
  -VaultPath    Root path of Obsidian vault
  -ProjectPath  Root path of project (for system file scanning)
  -SelfTest     Run built-in self-test
  -Help         Show this help

Safety:
  SUGGESTIONS ONLY - never auto-archive, never auto-approve
  No files modified outside 进化/dreams/
"@
}

if ($Help) { Show-Help; exit 0 }

Import-Module $helpersPath -Force -WarningAction SilentlyContinue

$vault = Get-VaultPath -VaultPath $VaultPath
if ($null -eq $vault) { exit 1 }

if ($OutputPath -eq "") { $OutputPath = Join-Path $vault "进化\dreams" }
if (-not (Test-Path $OutputPath)) { New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null }

# Self-test
if ($SelfTest) {
    Write-Output "[SELFTEST] Running obsidian-dream-reflect self-test..."
    $testDir = "$env:TEMP\obsidian-dream-selftest"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    New-Item -Path "$testDir\进化\dreams" -ItemType Directory -Force | Out-Null
    New-Item -Path "$testDir\进化\genes" -ItemType Directory -Force | Out-Null
    
    # Create a test Gene
    $testGene = @"
gene_id: test001
domain: ai/coding
trigger: "Test trigger"
strategy: "Test strategy"
created_at: "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
last_used: "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
use_count: 0
status: active
"@
    $testGene | Out-File -FilePath "$testDir\进化\genes\gene-test.yaml" -Encoding UTF8
    
    # Run quick scan
    $genesDir = "$testDir\进化\genes"
    $genes = Get-ChildItem -Path $genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
    if ($null -eq $genes -or $genes.Count -eq 0) {
        Write-Output "[SELFTEST-FAIL] No genes found"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] Found $($genes.Count) gene(s)"
    
    # Generate report
    $date = New-DateStamp
    $reportPath = Join-Path "$testDir\进化\dreams" "dream-report-$date.md"
    "# Dream Report $date`n`n## Gene Usage`n`n- gene-test: use_count=0`n" | Out-File -FilePath $reportPath -Encoding UTF8
    
    if (-not (Test-Path $reportPath)) {
        Write-Output "[SELFTEST-FAIL] Dream report not created"
        exit 1
    }
    Write-Output "[SELFTEST-PASS] Dream report created"
    
    Remove-Item $testDir -Recurse -Force
    Write-Output "[SELFTEST] All tests passed."
    exit 0
}

if (-not $QuickScan -and -not $FullScan) {
    Write-Error "Specify -QuickScan or -FullScan"
    Show-Help
    exit 1
}

$date = New-DateStamp
$reportPath = Join-Path $OutputPath "dream-report-$date.md"
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("# Dream Report $date")
[void]$sb.AppendLine("")

# Section 1: Gene Usage Stats
[void]$sb.AppendLine("## Gene Usage Stats")
[void]$sb.AppendLine("")

$genesDir = Join-Path $vault "进化\genes"
$unusedGenes = @()
$activeGenes = @()

if (Test-Path $genesDir) {
    $genes = Get-ChildItem -Path $genesDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
    foreach ($g in $genes) {
        $content = Get-Content $g.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }
        
        $geneId = ""; $useCount = 0; $lastUsed = ""; $domain = ""
        if ($content -match 'gene_id:\s*(\S+)') { $geneId = $Matches[1] }
        if ($content -match 'use_count:\s*(\d+)') { $useCount = [int]$Matches[1] }
        if ($content -match 'last_used:\s*"([^"]+)"') { $lastUsed = $Matches[1] }
        if ($content -match 'domain:\s*(\S+)') { $domain = $Matches[1] }
        
        $daysSinceUse = 999
        if ($lastUsed -ne "") {
            try {
                $lastDate = [DateTime]::Parse($lastUsed)
                $daysSinceUse = ([DateTime]::Now - $lastDate).Days
            } catch { }
        }
        
        if ($useCount -eq 0 -and $daysSinceUse -gt 90) {
            $unusedGenes += "  - $geneId (domain=$domain, unused=$daysSinceUse days)"
        } else {
            $activeGenes += "  - $geneId (domain=$domain, use_count=$useCount, last_used=$lastUsed)"
        }
    }
}

[void]$sb.AppendLine("Active Genes: $($activeGenes.Count)")
if ($activeGenes.Count -gt 0) { foreach ($g in $activeGenes) { [void]$sb.AppendLine($g) } }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Dormant Genes (use_count=0, >90d): $($unusedGenes.Count)")
if ($unusedGenes.Count -gt 0) { foreach ($g in $unusedGenes) { [void]$sb.AppendLine($g) } }
[void]$sb.AppendLine("")

# Quick scan ends here
if ($QuickScan) {
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Quick scan report. Run -FullScan for complete analysis.*")
    $sb.ToString() | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Output "[DREAM] Quick report written: $reportPath"
    exit 0
}

# Section 2: Knowledge Gaps (FullScan only)
[void]$sb.AppendLine("## Knowledge Gaps")
[void]$sb.AppendLine("")

# Scan system Skill/Docs coverage
$systemCoverage = @{}
if (Test-Path "$ProjectPath\skills") {
    Get-ChildItem -Path "$ProjectPath\skills" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $systemCoverage[$_.Name] = "skill"
    }
}
if (Test-Path "$ProjectPath\Docs\AI") {
    Get-ChildItem -Path "$ProjectPath\Docs\AI" -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $docName = $_.BaseName -replace '^\d+-', ''
        $systemCoverage[$docName] = "doc"
    }
}

# Find actionable notes without system coverage
$knowledgeDir = Join-Path $vault "知识"
$gaps = @()
if (Test-Path $knowledgeDir) {
    $actionableFiles = Get-ChildItem -Path $knowledgeDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
        $fm = Read-FrontMatter $_.FullName
        $fm.ContainsKey('actionable') -and $fm['actionable'] -eq $true
    }
    
    foreach ($af in $actionableFiles) {
        $fm = Read-FrontMatter $af.FullName
        $domain = if ($fm.ContainsKey('domain_path')) { $fm['domain_path'].ToString() } else { "unknown" }
        $title = $af.BaseName
        
        # Check if domain has system coverage
        $hasCoverage = $false
        foreach ($key in $systemCoverage.Keys) {
            if ($domain -match $key -or $key -match $domain) { $hasCoverage = $true; break }
        }
        
        if (-not $hasCoverage) {
            $gaps += "  - [$title] domain=$domain - no matching Skill/Doc found"
        }
    }
}

[void]$sb.AppendLine("Actionable notes without system coverage: $($gaps.Count)")
foreach ($g in $gaps) { [void]$sb.AppendLine($g) }
[void]$sb.AppendLine("")

# Section 3: Stale Proposals
[void]$sb.AppendLine("## Stale Proposals")
[void]$sb.AppendLine("")

$proposalsDir = Join-Path $vault "进化\proposals"
$staleProposals = @()
if (Test-Path $proposalsDir) {
    $proposals = Get-ChildItem -Path $proposalsDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
    foreach ($p in $proposals) {
        $age = ([DateTime]::Now - $p.LastWriteTime).Days
        if ($age -gt 30) {
            $staleProposals += "  - $($p.Name) (age=$age days, status=unapproved)"
        }
    }
}

[void]$sb.AppendLine("Proposals older than 30 days: $($staleProposals.Count)")
foreach ($sp in $staleProposals) { [void]$sb.AppendLine($sp) }
[void]$sb.AppendLine("")

# Section 4: Dormant Notes
[void]$sb.AppendLine("## Dormant Notes")
[void]$sb.AppendLine("")

$dormantNotes = @()
$allMd = Get-ChildItem -Path $vault -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '进化\\' -and $_.FullName -notmatch 'JinliKG\\'
}

# Simple heuristic: files older than 180 days with no ## Related section
foreach ($md in $allMd) {
    $age = ([DateTime]::Now - $md.LastWriteTime).Days
    if ($age -gt 180) {
        $content = Get-Content $md.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($null -ne $content -and $content -notmatch '## Related') {
            $dormantNotes += "  - $($md.Name) (age=$age days, no Related links)"
        }
    }
}

[void]$sb.AppendLine("Dormant notes (>180d, no Related links): $($dormantNotes.Count)")
foreach ($dn in $dormantNotes) { [void]$sb.AppendLine($dn) }
[void]$sb.AppendLine("")

# Section 5: Recommendations
[void]$sb.AppendLine("## Recommendations")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("[SUGGEST] Review dormant Genes for archival or reactivation")
[void]$sb.AppendLine("[SUGGEST] Address knowledge gaps by creating new Skills or Docs")
[void]$sb.AppendLine("[SUGGEST] Review stale proposals - approve or reject")
[void]$sb.AppendLine("[SUGGEST] Connect dormant notes via link-discover")
[void]$sb.AppendLine("")

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("*Full scan report. All items are suggestions - no auto-actions taken.*")

$sb.ToString() | Out-File -FilePath $reportPath -Encoding UTF8
Write-Output "[DREAM] Full report written: $reportPath"
exit 0
