# memory-benchmark.ps1 — Agent Memory Benchmark Engine
# Inspired by: rohitg00/agentmemory
# Measures recall rate, precision, and prevention effectiveness of failure memory system

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("run","query","report")]
    [string]$Action,

    [int]$TopK = 5,

    [string]$Query
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$WorkspaceRoot = "E:\UEGameDevelopment"
$MemoryDir = Join-Path $WorkspaceRoot "Docs\Memory"
$FailuresDir = Join-Path $MemoryDir "failures"
$BenchmarkDir = Join-Path $MemoryDir "benchmark"
$RecallHistory = Join-Path $BenchmarkDir "recall-history.jsonl"

if (-not (Test-Path -LiteralPath $BenchmarkDir)) {
    New-Item -ItemType Directory -Force -Path $BenchmarkDir | Out-Null
}

$ConfigPath = Join-Path $BenchmarkDir "benchmark-config.json"
$DefaultConfig = @{
    top_k = 5
    min_failures_for_benchmark = 10
    rotten_threshold_days = 90
    max_recall_history = 1000
    benchmark_interval_days = 7
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    $DefaultConfig | ConvertTo-Json | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}
$Config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

function Get-Failures {
    $failures = @()
    if (Test-Path -LiteralPath $FailuresDir) {
        $files = Get-ChildItem -LiteralPath $FailuresDir -Filter "*.md" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            $keywords = @()
            if ($content -match 'keywords\s*:\s*(.+)') { $keywords = $Matches[1] -split ',\s*' }
            if ($content -match 'tags\s*:\s*(.+)') { $keywords += $Matches[1] -split ',\s*' }

            $failures += @{
                file = $f.Name
                path = $f.FullName
                keywords = $keywords | Select-Object -Unique
                content_preview = $content.Substring(0, [Math]::Min(500, $content.Length))
                mtime = $f.LastWriteTime
            }
        }
    }
    return $failures
}

function Get-Candidates {
    $candidates = @()
    $candDir = Join-Path $MemoryDir "candidates"
    if (Test-Path -LiteralPath $candDir) {
        $files = Get-ChildItem -LiteralPath $candDir -Filter "*.md" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            $keywords = @()
            if ($content -match 'keywords\s*:\s*(.+)') { $keywords = $Matches[1] -split ',\s*' }
            if ($content -match 'tags\s*:\s*(.+)') { $keywords += $Matches[1] -split ',\s*' }

            $candidates += @{
                file = $f.Name
                keywords = $keywords | Select-Object -Unique
                mtime = $f.LastWriteTime
            }
        }
    }
    return $candidates
}

function Measure-KeywordOverlap {
    param([string[]]$QueryKeywords, [string[]]$EntryKeywords)
    if (-not $QueryKeywords -or $QueryKeywords.Count -eq 0) { return 0.0 }
    if (-not $EntryKeywords -or $EntryKeywords.Count -eq 0) { return 0.0 }
    $matches = 0
    foreach ($qk in $QueryKeywords) {
        foreach ($ek in $EntryKeywords) {
            if ($qk -like "*$ek*" -or $ek -like "*$qk*" -or $qk -eq $ek) {
                $matches++
                break
            }
        }
    }
    return [math]::Round($matches / $QueryKeywords.Count, 2)
}

function Search-Memory {
    param([string[]]$QueryKeywords, [int]$K = 5, [string]$ExcludeFile = "")

    $failures = Get-Failures
    $candidates = Get-Candidates
    $all = @()

    foreach ($f in $failures) {
        if ($ExcludeFile -and $f.file -eq $ExcludeFile) { continue }
        $score = Measure-KeywordOverlap -QueryKeywords $QueryKeywords -EntryKeywords $f.keywords
        $all += @{ entry = $f; score = $score; is_failure = $true }
    }

    foreach ($c in $candidates) {
        if ($ExcludeFile -and $c.file -eq $ExcludeFile) { continue }
        $score = Measure-KeywordOverlap -QueryKeywords $QueryKeywords -EntryKeywords $c.keywords
        $all += @{ entry = $c; score = $score; is_failure = $false }
    }

    return ($all | Sort-Object -Property score -Descending | Select-Object -First $K)
}

function Run-Benchmark {
    $failures = Get-Failures
    if ($failures.Count -lt $Config.min_failures_for_benchmark) {
        Write-Host "[memory-bench] Not enough failures ($($failures.Count)). Need at least $($Config.min_failures_for_benchmark)."
        return
    }

    Write-Host "[memory-bench] Running benchmark on $($failures.Count) failures (top-$TopK)..."
    $recall1 = 0; $recall3 = 0; $recall5 = 0; $total = 0
    $results = @()

    foreach ($f in $failures) {
        $results = Search-Memory -QueryKeywords $f.keywords -K $TopK -ExcludeFile $f.file
        $total++

        $foundRank = -1
        for ($i = 0; $i -lt $results.Count; $i++) {
            if ($results[$i].entry.file -eq $f.file) {
                $foundRank = $i + 1
                break
            }
        }

        if ($foundRank -eq 1) { $recall1++ }
        if ($foundRank -le 3 -and $foundRank -gt 0) { $recall3++ }
        if ($foundRank -le 5 -and $foundRank -gt 0) { $recall5++ }

        # Record to history
        $record = @{
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            failure_file = $f.file
            keywords = $f.keywords
            recall_rank = $foundRank
            recall_1 = ($foundRank -eq 1)
            recall_3 = ($foundRank -le 3 -and $foundRank -gt 0)
            recall_5 = ($foundRank -le 5 -and $foundRank -gt 0)
        }
        ($record | ConvertTo-Json -Compress) | Add-Content -LiteralPath $RecallHistory -Encoding UTF8
    }

    $r1 = [math]::Round($recall1 / $total * 100, 1)
    $r3 = [math]::Round($recall3 / $total * 100, 1)
    $r5 = [math]::Round($recall5 / $total * 100, 1)

    # Generate report
    $reportPath = Join-Path $BenchmarkDir "benchmark-report.md"
    $rottenCount = ($failures | Where-Object { ((Get-Date) - $_.mtime).Days -gt $Config.rotten_threshold_days }).Count
    $candCount = (Get-Candidates).Count

    @"
# Agent Memory Benchmark Report
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Failures indexed**: $($failures.Count)
**Candidates**: $candCount
**Rotten entries (>$($Config.rotten_threshold_days)d)**: $rottenCount

## Results

| Metric | Score | Target |
|--------|-------|--------|
| Recall@1 | $r1% | >70% |
| Recall@3 | $r3% | >85% |
| Recall@5 | $r5% | >90% |

## Health

| Indicator | Status |
|-----------|--------|
$(
    if ($r5 -ge 90) { "| Recall target met | PASS |" } else { "| Recall target not met | FAIL |" }
)
$(
    if ($rottenCount -eq 0) { "| No rotten entries | PASS |" } else { "| $rottenCount rotten entries need cleanup | WARN |" }
)
$(
    if ($candCount -gt 5) { "| $candCount candidates awaiting promotion | WARN |" } else { "| Candidate backlog healthy | PASS |" }
)

## Trend

Recall history entries: $(if (Test-Path $RecallHistory) { (Get-Content $RecallHistory | Measure-Object -Line).Lines } else { 0 })
"@ | Set-Content -LiteralPath $reportPath -Encoding UTF8

    Write-Host "[memory-bench] Report: $reportPath"
    Write-Host "[memory-bench] Recall@1: $r1% | Recall@3: $r3% | Recall@5: $r5%"
}

function Invoke-Query {
    if (-not $Query) {
        Write-Host "[memory-bench] Use -Query to search."
        return
    }
    $keywords = $Query -split '\s+'
    $results = Search-Memory -QueryKeywords $keywords -K $TopK

    Write-Host "=== Memory Search: '$Query' ==="
    foreach ($r in $results) {
        $tag = if ($r.is_failure) { "FAILURE" } else { "CANDIDATE" }
        Write-Host "[$($r.score.ToString('P0'))] [$tag] $($r.entry.file)"
        if ($r.entry.keywords) {
            Write-Host "  Tags: $($r.entry.keywords -join ', ')"
        }
    }

    if ($results.Count -eq 0) {
        Write-Host "No matching memories found."
    }
}

switch ($Action) {
    "run" { Run-Benchmark }
    "query" { Invoke-Query }
    "report" {
        $reportPath = Join-Path $BenchmarkDir "benchmark-report.md"
        if (Test-Path -LiteralPath $reportPath) {
            Get-Content -LiteralPath $reportPath
        } else {
            Write-Host "[memory-bench] No report yet. Run benchmark first."
        }
    }
}
