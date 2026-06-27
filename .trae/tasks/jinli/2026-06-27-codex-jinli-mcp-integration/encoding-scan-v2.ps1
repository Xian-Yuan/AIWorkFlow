# encoding-scan-v2.ps1 - Use [System.IO.File]::Exists() instead of Test-Path for Chinese paths
Set-Location "E:\UEGameDevelopment"

Write-Host "[1/3] Collecting .md files..." -ForegroundColor Cyan

# Use git ls-files with -z for safe path handling
$tracked = @()
git ls-files -z '*.md' 2>$null | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '\.md$') { $tracked += $line }
}

$untracked = @()
git ls-files --others --exclude-standard -z 2>$null | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '\.md$') { $untracked += $line }
}

$allMd = @($tracked + $untracked) | Where-Object { $_ -ne "" } | Select-Object -Unique

Write-Host "    Tracked .md files: $($tracked.Count)" -ForegroundColor Gray
Write-Host "    Untracked .md files: $($untracked.Count)" -ForegroundColor Gray
Write-Host "    Unique .md to check: $($allMd.Count)" -ForegroundColor Gray

# 2. Encoding detection using System.IO.File (bypasses Test-Path Chinese bug)
function Get-FileEncoding {
    param([string]$Path)

    # Use .NET directly to avoid PowerShell path mangling
    $fullPath = [System.IO.Path]::GetFullPath($Path)

    $exists = [System.IO.File]::Exists($fullPath)
    if (-not $exists) {
        return @{ Status="MISSING"; Bom="None"; Utf8Valid=$false; GbkDecoded=$false; Size=0 }
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    } catch {
        return @{ Status="READ_ERROR"; Bom="None"; Utf8Valid=$false; GbkDecoded=$false; Size=0 }
    }

    if ($bytes.Length -eq 0) {
        return @{ Status="EMPTY"; Bom="None"; Utf8Valid=$true; GbkDecoded=$false; Size=0 }
    }

    # BOM detection
    $bomType = "None"
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bomType = "UTF-8"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $bomType = "UTF-16LE"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $bomType = "UTF-16BE"
    }

    # UTF-8 strict decode
    $utf8Valid = $false
    try {
        $strict = New-Object System.Text.UTF8Encoding($false, $true)
        $null = $strict.GetString($bytes)
        $utf8Valid = $true
    } catch {
        $utf8Valid = $false
    }

    # GBK decode attempt
    $gbkOk = $false
    try {
        $gbk = [System.Text.Encoding]::GetEncoding(936)
        $decoded = $gbk.GetString($bytes)
        if ($decoded -match '[\u4e00-\u9fff]') {
            $gbkOk = $true
        }
    } catch {
        $gbkOk = $false
    }

    if ($utf8Valid) {
        if ($bomType -ne "None") { $status = "UTF-8-BOM" } else { $status = "UTF-8" }
    } elseif ($gbkOk) {
        $status = "GBK"
    } else {
        $status = "UNKNOWN"
    }

    return @{
        Status = $status
        Bom = $bomType
        Utf8Valid = $utf8Valid
        GbkDecoded = $gbkOk
        Size = $bytes.Length
    }
}

# 3. Scan each file
Write-Host "[2/3] Scanning encodings..." -ForegroundColor Cyan
$report = @()
$count = 0
$total = $allMd.Count
$badCount = 0
$missingCount = 0
$gbkCount = 0
$bomCount = 0
foreach ($f in $allMd) {
    $count++
    if ($count % 200 -eq 0) {
        Write-Host "    Progress: $count / $total" -ForegroundColor Gray
    }
    $enc = Get-FileEncoding -Path $f
    switch ($enc.Status) {
        "UTF-8"     { }
        "UTF-8-BOM" { $bomCount++ }
        "GBK"       { $gbkCount++; $badCount++ }
        "MISSING"   { $missingCount++; $badCount++ }
        "UNKNOWN"   { $badCount++ }
    }
    $report += [PSCustomObject]@{
        Path = $f
        Status = $enc.Status
        Bom = $enc.Bom
        Utf8Valid = $enc.Utf8Valid
        GbkDecoded = $enc.GbkDecoded
        Size = $enc.Size
    }
}

Write-Host "[3/3] Writing report..." -ForegroundColor Cyan
$report | Export-Csv -Path "encoding-report-v2.csv" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== ENCODING REPORT V2 SUMMARY ===" -ForegroundColor Yellow
Write-Host "Total .md files:    $total"
Write-Host "UTF-8 (no BOM):     $($report | Where-Object { $_.Status -eq "UTF-8" }).Count"
Write-Host "UTF-8 with BOM:     $bomCount"
Write-Host "GBK (needs convert): $gbkCount"
Write-Host "MISSING (real):     $missingCount"
Write-Host "Other/Unknown:      $($report | Where-Object { $_.Status -eq "UNKNOWN" }).Count"
Write-Host ""

if ($missingCount -gt 0) {
    Write-Host "=== TRULY MISSING FILES (top 30) ===" -ForegroundColor Red
    $report | Where-Object { $_.Status -eq "MISSING" } | Select-Object -First 30 | Format-Table Path -AutoSize
}

if ($gbkCount -gt 0) {
    Write-Host "=== GBK FILES (top 30) ===" -ForegroundColor Magenta
    $report | Where-Object { $_.Status -eq "GBK" } | Select-Object -First 30 | Format-Table Path, Size -AutoSize
}

Write-Host ""
Write-Host "Report saved to: encoding-report-v2.csv"