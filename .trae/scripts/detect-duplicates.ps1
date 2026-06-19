<#
.SYNOPSIS
    Detect duplicate code blocks using jscpd (primary) or PowerShell fallback.
.DESCRIPTION
    Scans source files for duplicate code blocks. Uses jscpd for AST-level
    detection when available, with a PowerShell sliding-window fallback.
.PARAMETER Path
    Root directory to scan (default: Source/).
.PARAMETER Threshold
    Minimum number of identical lines to flag (default: 10).
.PARAMETER Format
    Output format: "markdown", "text", or "json" (default: "markdown").
.PARAMETER CI
    CI mode: exit with non-zero code if L1 duplicates found.
.PARAMETER ForcePowerShell
    Skip jscpd and use built-in PowerShell engine.
.EXAMPLE
    .\detect-duplicates.ps1 -Path "Source/" -Threshold 10
.EXAMPLE
    .\detect-duplicates.ps1 -Path "Source/" -Threshold 6 -CI
.NOTES
    Part of the anti-duplication skill suite.
    See: skills/anti-duplication/SKILL.md
#>

param(
    [string]$Path = "Source/",
    [int]$Threshold = 10,
    [ValidateSet("markdown", "text", "json")]
    [string]$Format = "markdown",
    [switch]$CI,
    [switch]$ForcePowerShell
)

$ErrorActionPreference = "Stop"
$script:StartTime = Get-Date
$script:NodeDir = "C:/Users/87372/AppData/Local/OpenAI/Codex/runtimes/cua_node/a89897d3d9baa117/bin"

# ===== Helpers =====

function Get-ShortPath {
    param([string]$FullPath)
    $clean = $FullPath -replace '^\\\\\?\\', ''
    $cwd = (Get-Location).Path
    if ($clean.StartsWith($cwd, [StringComparison]::OrdinalIgnoreCase)) {
        $rel = $clean.Substring($cwd.Length)
        return $rel.TrimStart("\", "/")
    }
    return $clean
}

function Run-Jscpd {
    param([string]$ScanPath, [int]$Threshold)

    $tempOutput = Join-Path $env:TEMP "jscpd-output"
    Remove-Item $tempOutput -Recurse -Force -ErrorAction SilentlyContinue

    $jscpdCmd = Join-Path $script:NodeDir "jscpd.cmd"
    if (-not (Test-Path $jscpdCmd)) {
        $jscpdCmd = Join-Path $script:NodeDir "jscpd"
    }
    if (-not (Test-Path $jscpdCmd)) { return $null }

    try {
        $env:Path = "$($script:NodeDir);$env:Path"
        $cmdArgs = @($ScanPath, "-l", $Threshold, "-r", "json", "-o", $tempOutput, "--silent")
        $configPath = Join-Path (Get-Location) ".jscpd.json"
        if (Test-Path $configPath) { $cmdArgs += @("-c", $configPath) }
        $allArgs = $cmdArgs -join " "

        $proc = Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c", "`"`"$jscpdCmd`" $allArgs`"" `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput "$env:TEMP\jscpd-stdout.txt" `
            -RedirectStandardError "$env:TEMP\jscpd-stderr.txt"

        $reportFile = Join-Path $tempOutput "jscpd-report.json"
        if (Test-Path $reportFile) {
            $raw = Get-Content $reportFile -Raw
            $report = $raw | ConvertFrom-Json
            Remove-Item $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
            return $report
        }
    }
    catch { Write-Verbose "jscpd error: $_" }
    return $null
}

# ===== PowerShell fallback engine =====

function Find-DuplicatesPS {
    param([string]$ScanPath, [int]$Threshold)

    $files = Get-ChildItem -LiteralPath $ScanPath -Recurse -Include "*.h","*.cpp","*.ts","*.js","*.py","*.cs" -ErrorAction SilentlyContinue
    if (-not $files) { return @() }

    $lineDB = @{}
    foreach ($f in $files) {
        $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        for ($i = 0; $i -le $lines.Count - $Threshold; $i++) {
            $chunk = ($lines[$i..($i + $Threshold - 1)] | ForEach-Object { $_.Trim() }) -join "`n"
            if ($chunk.Trim().Length -lt $Threshold * 3) { continue }
            $hash = [BitConverter]::ToString(
                [Security.Cryptography.SHA256]::Create().ComputeHash(
                    [Text.Encoding]::UTF8.GetBytes($chunk)
                )
            )
            if (-not $lineDB.ContainsKey($hash)) { $lineDB[$hash] = @() }
            $short = Get-ShortPath $f.FullName
            $lineDB[$hash] += @{ file = $short; start = $i + 1; end = $i + $Threshold; lines = $Threshold }
        }
    }

    $result = @()
    foreach ($kv in $lineDB.GetEnumerator()) {
        if ($kv.Value.Count -gt 1) {
            $result += @{ occurrences = $kv.Value; lineCount = $Threshold; hash = $kv.Key.Substring(0,12) }
        }
    }
    return ($result | Sort-Object { $_.lineCount } -Descending)
}

# ===== Report Formatting =====

function Format-JscpdReport {
    param($Report, [string]$ScanPath, [int]$FilesScanned)

    $dups = @($Report.duplicates)
    if ($dups.Count -eq 0) {
        switch ($Format) {
            "markdown" { Write-Host "### Result: CLEAN`nNo duplicate code blocks found above threshold." }
            "text" { Write-Host "CLEAN - No duplicates found." }
            "json" { (@{ status="clean"; threshold=$Threshold; duplicates=@() } | ConvertTo-Json) }
        }
        return @{ L1 = 0; L2 = 0 }
    }

    $l1 = 0; $l2 = 0
    $scope = if (Test-Path $ScanPath) { (Resolve-Path $ScanPath).Path } else { $ScanPath }

    switch ($Format) {
        "markdown" {
            Write-Host "## Duplication Report"
            Write-Host ""
            Write-Host "**Scan Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            Write-Host "**Scope:** $scope"
            Write-Host "**Threshold:** >= $Threshold lines"
            Write-Host "**Engine:** jscpd 5.x"
            if ($Report.statistics) {
                Write-Host "**Sources:** $($Report.statistics.total.sources) files, $($Report.statistics.total.lines) lines"
            }
            Write-Host "**Clones Found:** $($dups.Count)"
            Write-Host ""
            Write-Host "| # | Lines | File A | File B |"
            Write-Host "|---|:-----:|--------|--------|"

            $idx = 1
            foreach ($d in $dups) {
                $lines = if ($d.fragment -and $d.fragment.lines) { $d.fragment.lines }
                         elseif ($d.lines) { $d.lines }
                         elseif ($d.firstFile.end -and $d.firstFile.start) { $d.firstFile.end - $d.firstFile.start + 1 }
                         else { $Threshold }
                $level = if ($lines -ge 20) { "L2"; $l2++ } else { "L1"; $l1++ }

                $fa = Get-ShortPath $d.firstFile.name
                $sa = Get-ShortPath $d.secondFile.name
                $aStart = if ($d.firstFile.start) { ":$($d.firstFile.start)" } else { "" }
                $bStart = if ($d.secondFile.start) { ":$($d.secondFile.start)" } else { "" }
                $locA = "$fa$aStart"; $locB = "$sa$bStart"

                Write-Host "| $idx | $lines | $locA | $locB |"
                $idx++
            }

            Write-Host ""
            Write-Host "### Summary"
            Write-Host "- **L1:** $l1 | **L2:** $l2"
            if ($l1 -gt 0) {
                Write-Host ""
                Write-Host "### Actions"
                Write-Host "1. L1 (exact duplicates): extract to shared function/method"
                Write-Host "2. L2 (structural duplicates): evaluate template/base-class abstraction"
            }
        }

        "text" {
            Write-Host "=== Duplication Report ==="
            Write-Host "Scope: $scope | Threshold: $Threshold | Clones: $($dups.Count)"
            Write-Host ""
            $idx = 1
            foreach ($d in $dups) {
                $lines = if ($d.fragment -and $d.fragment.lines) { $d.fragment.lines }
                         elseif ($d.lines) { $d.lines }
                         elseif ($d.firstFile.end) { $d.firstFile.end - $d.firstFile.start + 1 }
                         else { $Threshold }
                $level = if ($lines -ge 20) { "L2"; $l2++ } else { "L1"; $l1++ }
                $fa = Get-ShortPath $d.firstFile.name
                $sa = Get-ShortPath $d.secondFile.name
                Write-Host "[$idx] $level $lines lines: $fa <-> $sa"
                $idx++
            }
            Write-Host "`nL1=$l1 L2=$l2"
        }

        "json" {
            $output = @{
                scanTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
                scope = $scope
                threshold = $Threshold
                engine = "jscpd"
                totalClones = $dups.Count
                l1 = 0; l2 = 0
                clones = @()
            }
            foreach ($d in $dups) {
                $lines = if ($d.fragment -and $d.fragment.lines) { $d.fragment.lines }
                         elseif ($d.lines) { $d.lines }
                         elseif ($d.firstFile.end) { $d.firstFile.end - $d.firstFile.start + 1 }
                         else { $Threshold }
                $level = if ($lines -ge 20) { "L2"; $output.l2++ } else { "L1"; $output.l1++ }
                $output.clones += @{
                    level = $level
                    lines = $lines
                    fileA = Get-ShortPath $d.firstFile.name
                    fileB = Get-ShortPath $d.secondFile.name
                }
            }
            $output | ConvertTo-Json -Depth 3
        }
    }

    $elapsed = ((Get-Date) - $script:StartTime).TotalSeconds
    Write-Host "`n*Scan completed in $([Math]::Round($elapsed, 1))s*"
    return @{ L1 = $l1; L2 = $l2 }
}

function Format-PSReport {
    param($Duplicates, [int]$FilesScanned)

    if ($Duplicates.Count -eq 0) {
        Write-Host "### Result: CLEAN"
        return @{ L1 = 0; L2 = 0 }
    }

    $l1 = 0; $l2 = 0
    switch ($Format) {
        "markdown" {
            Write-Host "## Duplication Report (PowerShell)"
            Write-Host ""
            Write-Host "**Files Scanned:** $FilesScanned"
            Write-Host "**Duplicates:** $($Duplicates.Count)"
            Write-Host ""
            Write-Host "| # | Lines | Occurrences |"
            Write-Host "|---|:-----:|-------------|"
            $idx = 1
            foreach ($d in $Duplicates) {
                $level = if ($d.lineCount -ge 20) { "L2"; $l2++ } else { "L1"; $l1++ }
                $files = ($d.occurrences | ForEach-Object { "$($_.file):$($_.start)-$($_.end)" }) -join ", "
                Write-Host "| $idx | $level $($d.lineCount) | $files |"
                $idx++
            }
            Write-Host ""
            Write-Host "**L1:** $l1 | **L2:** $l2"
        }
        "text" {
            Write-Host "=== Duplication Report (PowerShell) ==="
            foreach ($d in $Duplicates) {
                $level = if ($d.lineCount -ge 20) { "L2"; $l2++ } else { "L1"; $l1++ }
                Write-Host "[$level] $($d.lineCount) lines:"
                foreach ($o in $d.occurrences) { Write-Host "  $($o.file):$($o.start)-$($o.end)" }
            }
        }
        "json" {
            $output = @{ engine = "powershell"; threshold = $Threshold; l1 = 0; l2 = 0; clones = @() }
            foreach ($d in $Duplicates) {
                $level = if ($d.lineCount -ge 20) { "L2"; $output.l2++ } else { "L1"; $output.l1++ }
                $output.clones += @{ level = $level; lines = $d.lineCount; occurrences = $d.occurrences }
            }
            $output | ConvertTo-Json -Depth 3
        }
    }
    return @{ L1 = $l1; L2 = $l2 }
}

# ===== Main =====

function Main {
    $scanPath = if (Test-Path $Path) { (Resolve-Path $Path).Path } else { $Path }

    if (-not $ForcePowerShell) {
        $jscpdReport = Run-Jscpd -ScanPath $scanPath -Threshold $Threshold
        if ($jscpdReport) {
            $summary = Format-JscpdReport -Report $jscpdReport -ScanPath $scanPath
            if ($CI -and $summary.L1 -gt 0) { Write-Warning "CI: $($summary.L1) L1 duplicate(s) found"; exit 1 }
            exit 0
        }
        Write-Verbose "jscpd not available, falling back to PowerShell engine"
    }

    $psDups = Find-DuplicatesPS -ScanPath $scanPath -Threshold $Threshold
    $summary = Format-PSReport -Duplicates $psDups -FilesScanned 0
    if ($CI -and $summary.L1 -gt 0) { Write-Warning "CI: $($summary.L1) L1 duplicate(s) found"; exit 1 }
    exit 0
}

if ($MyInvocation.InvocationName -ne ".") { Main }
