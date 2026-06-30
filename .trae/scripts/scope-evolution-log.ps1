# scope-evolution-log.ps1 -- Evolution Audit Trail for Jinli (AGP-inspired)
#
# Sixth layer of the Scope Recall pattern: store -> recall -> close -> fuse -> index -> audit
#
# Inspired by Autogenesis/AGP protocol (gene f13795a4):
#   - RSPL Resource Layer: register all evolution resources (genes, proposals, scripts)
#   - SPL Update Layer: version-managed updates with rollback capability
#   - Systematically record changes, evaluate effects, safely rollback
#   - Prevent self-evolution from becoming an untraceable black box
#
# Usage:
#   .\scope-evolution-log.ps1 -Init
#   .\scope-evolution-log.ps1 -Record -GeneId e7f6845e -Direction "more-intelligent" -ProposalId 47834661 -Result committed -ScriptName scope-index.ps1
#   .\scope-evolution-log.ps1 -History
#   .\scope-evolution-log.ps1 -History -GeneId e7f6845e
#   .\scope-evolution-log.ps1 -Rollback -EvolutionId <id>
#   .\scope-evolution-log.ps1 -GeneStats
#   .\scope-evolution-log.ps1 -ResourceIndex
#   .\scope-evolution-log.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.

param(
    [switch]$Init,
    [switch]$Record,
    [switch]$History,
    [switch]$Rollback,
    [switch]$GeneStats,
    [switch]$ResourceIndex,
    [switch]$SelfTest,
    [switch]$Apply,

    [string]$GeneId = "",
    [string]$Direction = "",
    [string]$ProposalId = "",
    [ValidateSet("committed", "rolled-back", "failed", "in-progress")]
    [string]$Result = "",
    [string]$ScriptName = "",
    [string]$CommitHash = "",
    [string]$Notes = "",
    [string]$EvolutionId = "",
    [int]$Limit = 50,
    [string]$DbPath = ""
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$scriptVersion = 1

if (-not $DbPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-evolution-log.json"
}

# --- JSON I/O ---
function Read-EvoLog {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ entries = @(); meta = @{ created_at = ""; version = $scriptVersion }; resources = @{} }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $entriesArray = @()
        if ($parsed.entries -ne $null) {
            foreach ($e in $parsed.entries) {
                $ht = @{
                    id = $e.id
                    gene_id = $e.gene_id
                    direction = $e.direction
                    proposal_id = $e.proposal_id
                    result = $e.result
                    script_name = $e.script_name
                    commit_hash = $e.commit_hash
                    notes = $e.notes
                    rolled_back_from = $e.rolled_back_from
                    created_at = $e.created_at
                }
                $entriesArray += $ht
            }
        }
        # Parse resources
        $resourcesHt = @{}
        if ($parsed.resources -ne $null) {
            $resProps = $parsed.resources | Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue
            if ($resProps) {
                foreach ($rp in $resProps) {
                    $resourcesHt[$rp.Name] = $parsed.resources.($rp.Name)
                }
            }
        }
        $metaHt = @{
            created_at = $parsed.meta.created_at
            version = [int]$parsed.meta.version
        }
        return @{ entries = $entriesArray; meta = $metaHt; resources = $resourcesHt }
    } catch {
        return @{ entries = @(); meta = @{ created_at = ""; version = $scriptVersion }; resources = @{} }
    }
}

function Write-EvoLog {
    param([string]$Path, $Data)

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $json = ($Data | ConvertTo-Json -Depth 10)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}
# --- Core Operations ---

function Initialize-EvoLog {
    param([string]$Path)

    $data = @{
        entries = @()
        meta = @{
            created_at = (Get-Date).ToString("o")
            version = $scriptVersion
        }
        resources = @{}
    }
    Write-EvoLog -Path $Path -Data $data
    Write-Host "[INIT] Evolution audit log initialized at: $Path"
}

function Invoke-Record {
    param(
        [string]$Path,
        [string]$GeneIdVal,
        [string]$DirectionVal,
        [string]$ProposalIdVal,
        [string]$ResultVal,
        [string]$ScriptNameVal,
        [string]$CommitHashVal,
        [string]$NotesVal
    )

    $data = Read-EvoLog -Path $Path

    # Generate evolution ID: evo-<short-hash>
    $seed = "${GeneIdVal}-${ProposalIdVal}-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $evoId = "evo-" + $seed.GetHashCode().ToString("x8")

    $entry = @{
        id = $evoId
        gene_id = $GeneIdVal
        direction = $DirectionVal
        proposal_id = $ProposalIdVal
        result = $ResultVal
        script_name = $ScriptNameVal
        commit_hash = $CommitHashVal
        notes = $NotesVal
        rolled_back_from = ""
        created_at = (Get-Date).ToString("o")
    }

    # Prepend (newest first)
    $data.entries = @($entry) + $data.entries

    # Update resource index (AGP RSPL layer)
    if ($ScriptNameVal -and -not $data.resources.ContainsKey($ScriptNameVal)) {
        $data.resources[$ScriptNameVal] = @{
            created_by = $evoId
            gene_id = $GeneIdVal
            version = 1
            status = "active"
        }
    } elseif ($ScriptNameVal -and $data.resources.ContainsKey($ScriptNameVal)) {
        $existing = $data.resources[$ScriptNameVal]
        $newVer = [int]$existing.version + 1
        # Replace with new hashtable (avoids PSCustomObject property issues in PS5.1)
        $data.resources[$ScriptNameVal] = @{
            created_by = $existing.created_by
            gene_id = $GeneIdVal
            version = $newVer
            status = "active"
            updated_by = $evoId
        }
    }

    Write-EvoLog -Path $Path -Data $data
    Write-Host "[RECORD] Evolution logged: $evoId gene=$GeneIdVal result=$ResultVal script=$ScriptNameVal"
    return $entry
}

function Show-History {
    param(
        [string]$Path,
        [string]$GeneIdVal,
        [int]$LimitVal
    )

    $data = Read-EvoLog -Path $Path
    if ($data.entries.Count -eq 0) {
        Write-Host "[HISTORY] No evolution entries found."
        return
    }

    $filtered = @()
    foreach ($e in $data.entries) {
        if ($GeneIdVal -and $e.gene_id -ne $GeneIdVal) { continue }
        $filtered += $e
    }

    if ($filtered.Count -eq 0) {
        Write-Host "[HISTORY] No entries matching gene=$GeneIdVal"
        return
    }

    # Apply limit
    if ($filtered.Count -gt $LimitVal) {
        $filtered = $filtered[0..($LimitVal - 1)]
    }

    Write-Host "=== Evolution Audit Trail ==="
    Write-Host "  Total entries: $($data.entries.Count)"
    if ($GeneIdVal) { Write-Host "  Filtered by gene: $GeneIdVal ($($filtered.Count) entries)" }
    Write-Host ""

    foreach ($e in $filtered) {
        $rollbackMark = if ($e.rolled_back_from) { " [ROLLED-BACK]" } else { "" }
        Write-Host ("  [{0}] {1} -> {2} | gene={3} | dir={4} | script={5} | result={6}{7}" -f `
            $e.id, $e.created_at.Substring(0, [Math]::Min(19, $e.created_at.Length)), `
            $e.proposal_id, $e.gene_id, $e.direction, $e.script_name, $e.result, $rollbackMark)
        if ($e.commit_hash) { Write-Host "    commit: $($e.commit_hash)" }
        if ($e.notes) { Write-Host "    notes: $($e.notes)" }
    }
}

function Invoke-Rollback {
    param(
        [string]$Path,
        [string]$EvoIdVal
    )

    $data = Read-EvoLog -Path $Path
    $targetEntry = $null
    foreach ($e in $data.entries) {
        if ($e.id -eq $EvoIdVal) { $targetEntry = $e; break }
    }

    if (-not $targetEntry) {
        Write-Host "[ROLLBACK] Evolution $EvoIdVal not found."
        return
    }

    if ($targetEntry.result -eq "rolled-back") {
        Write-Host "[ROLLBACK] Evolution $EvoIdVal is already rolled back."
        return
    }

    # Create rollback entry
    $rollbackEntry = @{
        id = "evo-" + ("rollback-$EvoIdVal-$(Get-Date -Format 'yyyyMMddHHmmss')").GetHashCode().ToString("x8")
        gene_id = $targetEntry.gene_id
        direction = $targetEntry.direction
        proposal_id = $targetEntry.proposal_id
        result = "rolled-back"
        script_name = $targetEntry.script_name
        commit_hash = ""
        notes = "Rollback of $EvoIdVal"
        rolled_back_from = $EvoIdVal
        created_at = (Get-Date).ToString("o")
    }

    # Mark original as rolled-back
    foreach ($e in $data.entries) {
        if ($e.id -eq $EvoIdVal) {
            $e.result = "rolled-back"
            break
        }
    }

    # Update resource index
    if ($targetEntry.script_name -and $data.resources.ContainsKey($targetEntry.script_name)) {
        $oldRes = $data.resources[$targetEntry.script_name]
        $data.resources[$targetEntry.script_name] = @{
            created_by = $oldRes.created_by
            gene_id = $oldRes.gene_id
            version = [int]$oldRes.version
            status = "rolled-back"
            rolled_back_by = $rollbackEntry.id
        }
    }

    # Prepend rollback entry
    $data.entries = @($rollbackEntry) + $data.entries

    Write-EvoLog -Path $Path -Data $data
    Write-Host "[ROLLBACK] Marked $EvoIdVal as rolled-back. Rollback entry: $($rollbackEntry.id)"

    if ($Apply -and $targetEntry.commit_hash) {
        Write-Host "[ROLLBACK] To undo the commit, run: git revert $($targetEntry.commit_hash)"
    } else {
        Write-Host "[ROLLBACK] Use -Apply for git revert guidance."
    }

    return $rollbackEntry
}
function Show-GeneStats {
    param([string]$Path)

    $data = Read-EvoLog -Path $Path
    if ($data.entries.Count -eq 0) {
        Write-Host "[GENE-STATS] No evolution entries found."
        return
    }

    # Per-gene breakdown
    $geneStats = @{}
    foreach ($e in $data.entries) {
        $gid = $e.gene_id
        if (-not $geneStats.ContainsKey($gid)) {
            $geneStats[$gid] = @{ total = 0; committed = 0; rolled_back = 0; failed = 0; in_progress = 0; scripts = @{} }
        }
        $geneStats[$gid].total++
        $resultKey = $e.result -replace '-', '_'
        if ($geneStats[$gid].ContainsKey($resultKey)) { $geneStats[$gid][$resultKey]++ }
        if ($e.script_name) {
            if (-not $geneStats[$gid].scripts.ContainsKey($e.script_name)) {
                $geneStats[$gid].scripts[$e.script_name] = 0
            }
            $geneStats[$gid].scripts[$e.script_name]++
        }
    }

    Write-Host "=== Gene Statistics ==="
    Write-Host "  Total evolutions: $($data.entries.Count)"
    Write-Host ""

    foreach ($key in ($geneStats.Keys | Sort-Object)) {
        $gs = $geneStats[$key]
        Write-Host "  Gene: $key"
        Write-Host "    Total: $($gs.total) | Committed: $($gs.committed) | Rolled-back: $($gs.rolled_back) | Failed: $($gs.failed) | In-progress: $($gs.in_progress)"
        if ($gs.script -and $gs.script -is [System.Collections.IDictionary]) {
            foreach ($sn in $gs.script.Keys) {
                Write-Host "    Script: $sn ($($gs.script[$sn]) evolutions)"
            }
        }
    }

    # Success rate
    $totalCommitted = 0
    $totalRollbacks = 0
    foreach ($gs in $geneStats.Values) { $totalCommitted += $gs.committed; $totalRollbacks += $gs.rolled_back }
    $totalAttempted = $totalCommitted + $totalRollbacks
    if ($totalAttempted -gt 0) {
        $rate = [Math]::Round(($totalCommitted / $totalAttempted) * 100, 1)
        Write-Host "`n  Overall success rate: $rate% ($totalCommitted/$totalAttempted)"
    }
}

function Show-ResourceIndex {
    param([string]$Path)

    $data = Read-EvoLog -Path $Path
    if ($data.resources.Count -eq 0) {
        Write-Host "[RESOURCES] No resources registered."
        return
    }

    Write-Host "=== Resource Index (AGP RSPL Layer) ==="
    $resProps = $data.resources | Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue
    if ($resProps) {
        foreach ($rp in $resProps) {
            $res = $data.resources.($rp.Name)
            Write-Host "  $($rp.Name): v$($res.version) status=$($res.status) gene=$($res.gene_id)"
        }
    } elseif ($data.resources -is [System.Collections.IDictionary]) {
        foreach ($key in $data.resources.Keys) {
            $res = $data.resources[$key]
            Write-Host "  ${key}: v$($res.version) status=$($res.status) gene=$($res.gene_id)"
        }
    }
}
function Invoke-SelfTest {
    $testDir = Join-Path $env:TEMP "scope-evo-log-selftest-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    $testPath = Join-Path $testDir "scope-evolution-log.json"
    $script:passCount = 0
    $script:failCount = 0

    function Assert-Test {
        param([bool]$Condition, [string]$Name)
        if ($Condition) { $script:passCount++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
        else { $script:failCount++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
    }

    try {
        Write-Host "=== scope-evolution-log.ps1 SelfTest ==="

        # Test 1: Init
        Write-Host "`n--- Test 1: Initialize ---"
        Initialize-EvoLog -Path $testPath
        Assert-Test -Condition (Test-Path -LiteralPath $testPath) -Name "Init creates file"
        $initData = Read-EvoLog -Path $testPath
        Assert-Test -Condition ($initData.entries.Count -eq 0) -Name "Init has empty entries"

        # Test 2: Record an evolution
        Write-Host "`n--- Test 2: Record ---"
        $entry1 = Invoke-Record -Path $testPath -GeneIdVal "gene-001" -DirectionVal "more-intelligent" -ProposalIdVal "prop-001" -ResultVal "committed" -ScriptNameVal "scope-store.ps1" -CommitHashVal "abc1234" -NotesVal "First evolution"
        Assert-Test -Condition ($entry1.id -match "^evo-") -Name "Record generates evo- ID"
        Assert-Test -Condition ($entry1.gene_id -eq "gene-001") -Name "Record stores gene_id"
        Assert-Test -Condition ($entry1.result -eq "committed") -Name "Record stores result"

        # Test 3: Record another evolution
        Write-Host "`n--- Test 3: Multiple Records ---"
        $entry2 = Invoke-Record -Path $testPath -GeneIdVal "gene-001" -DirectionVal "more-intelligent" -ProposalIdVal "prop-002" -ResultVal "committed" -ScriptNameVal "scope-bridge.ps1" -CommitHashVal "def5678" -NotesVal "Second evolution"
        $data2 = Read-EvoLog -Path $testPath
        Assert-Test -Condition ($data2.entries.Count -eq 2) -Name "Two entries recorded"
        Assert-Test -Condition ($data2.entries[0].id -eq $entry2.id) -Name "Newest entry is first (LIFO)"

        # Test 4: Resource index updated
        Write-Host "`n--- Test 4: Resource Index ---"
        Assert-Test -Condition ($data2.resources.ContainsKey("scope-store.ps1")) -Name "scope-store registered in resources"
        Assert-Test -Condition ($data2.resources.ContainsKey("scope-bridge.ps1")) -Name "scope-bridge registered in resources"
        Assert-Test -Condition ([int]$data2.resources["scope-store.ps1"].version -eq 1) -Name "scope-store version is 1"

        # Test 5: Record same script again (version increment)
        Write-Host "`n--- Test 5: Version Increment ---"
        $null = Invoke-Record -Path $testPath -GeneIdVal "gene-001" -DirectionVal "more-intelligent" -ProposalIdVal "prop-003" -ResultVal "committed" -ScriptNameVal "scope-store.ps1" -CommitHashVal "ghi9012" -NotesVal "Updated scope-store"
        $data3 = Read-EvoLog -Path $testPath
        Assert-Test -Condition ([int]$data3.resources["scope-store.ps1"].version -eq 2) -Name "scope-store version incremented to 2"

        # Test 6: Rollback an evolution
        Write-Host "`n--- Test 6: Rollback ---"
        $rbEntry = Invoke-Rollback -Path $testPath -EvoIdVal $entry2.id
        Assert-Test -Condition ($rbEntry.result -eq "rolled-back") -Name "Rollback entry has rolled-back result"
        Assert-Test -Condition ($rbEntry.rolled_back_from -eq $entry2.id) -Name "Rollback references original ID"
        $data4 = Read-EvoLog -Path $testPath
        # Find the original entry and verify it's marked
        $origMarked = $false
        foreach ($e in $data4.entries) {
            if ($e.id -eq $entry2.id -and $e.result -eq "rolled-back") { $origMarked = $true; break }
        }
        Assert-Test -Condition $origMarked -Name "Original entry marked as rolled-back"

        # Test 7: Resource status updated on rollback
        Write-Host "`n--- Test 7: Rollback Resource Update ---"
        Assert-Test -Condition ($data4.resources["scope-bridge.ps1"].status -eq "rolled-back") -Name "scope-bridge marked rolled-back"

        # Test 8: History display
        Write-Host "`n--- Test 8: History ---"
        Show-History -Path $testPath -LimitVal 10
        Assert-Test -Condition $true -Name "History display completes"

        # Test 9: GeneStats
        Write-Host "`n--- Test 9: GeneStats ---"
        Show-GeneStats -Path $testPath
        Assert-Test -Condition $true -Name "GeneStats display completes"

        # Test 10: ResourceIndex display
        Write-Host "`n--- Test 10: ResourceIndex ---"
        Show-ResourceIndex -Path $testPath
        Assert-Test -Condition $true -Name "ResourceIndex display completes"

    } finally {
        if (Test-Path -LiteralPath $testDir) { Remove-Item -LiteralPath $testDir -Recurse -Force }
    }

    Write-Host "`n=== SelfTest Results: $($script:passCount) passed, $($script:failCount) failed ==="
    if ($script:failCount -gt 0) { exit 1 }
}

# --- Parameter Routing ---
if ($SelfTest) { Invoke-SelfTest; exit 0 }
if ($Init) { Initialize-EvoLog -Path $DbPath; exit 0 }
if ($Record) { Invoke-Record -Path $DbPath -GeneIdVal $GeneId -DirectionVal $Direction -ProposalIdVal $ProposalId -ResultVal $Result -ScriptNameVal $ScriptName -CommitHashVal $CommitHash -NotesVal $Notes; exit 0 }
if ($History) { Show-History -Path $DbPath -GeneIdVal $GeneId -LimitVal $Limit; exit 0 }
if ($Rollback) { Invoke-Rollback -Path $DbPath -EvoIdVal $EvolutionId; exit 0 }
if ($GeneStats) { Show-GeneStats -Path $DbPath; exit 0 }
if ($ResourceIndex) { Show-ResourceIndex -Path $DbPath; exit 0 }

Write-Host "Usage: scope-evolution-log.ps1 [-Init | -Record | -History | -Rollback | -GeneStats | -ResourceIndex | -SelfTest]"