# encoding-scan-v3.ps1 - Read file list via raw byte stream to avoid PowerShell arg mangling
Set-Location "E:\UEGameDevelopment"

Write-Host "[1/3] Collecting .md files..." -ForegroundColor Cyan

# Capture git output via cmd /c to keep -z flag literal
$tmpTracked = [System.IO.Path]::GetTempFileName()
$tmpUntracked = [System.IO.Path]::GetTempFileName()

cmd /c "git ls-files -z *.md > `"$tmpTracked`" 2>nul"
cmd /c "git ls-files --others --exclude-standard -z > `"$tmpUntracked`" 2>nul"

# Read raw bytes and split on NUL
$trackedBytes = [System.IO.File]::ReadAllBytes($tmpTracked)
$untrackedBytes = [System.IO.File]::ReadAllBytes($tmpUntracked)

$tracked = @()
if ($trackedBytes.Length -gt 0) {
    # Decode as UTF-8 (git outputs UTF-8)
    $text = [System.Text.Encoding]::UTF8.GetString($trackedBytes)
    $tracked = $text -split "`0" | Where-Object { $_ -ne "" -and $_ -match '\.md$' }
}
$untracked = @()
if ($untrackedBytes.Length -gt 0) {
    $text = [System.Text.Encoding]::UTF8.GetString($untrackedBytes)
    $untracked = $text -split "`0" | Where-Object { $_ -ne "" -and $_ -match '\.md$' }
}

# Cleanup tmp files
Remove-Item $tmpTracked -ErrorAction SilentlyContinue
Remove-Item $tmpUntracked -ErrorAction SilentlyContinue

$allMd = @($tracked + $untracked) | Select-Object -Unique

Write-Host "    Tracked .md files: $($tracked.Count)" -ForegroundColor Gray
Write-Host "    Untracked .md files: $($untracked.Count)" -ForegroundColor Gray
Write-Host "    Unique .md to check: $($allMd.Count)" -ForegroundColor Gray

# 2. Encoding detection
function Get-FileEncoding {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not [System.IO.File]::Exists($fullPath)) {
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

    $bomType = "None"
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bomType = "UTF-8"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $bomType = "UTF-16LE"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $bomType = "UTF-16BE"
    }

    $utf8Valid = $false
    try {
        $strict = New-Object System.Text.UTF8Encoding($false, $true)
        $null = $strict.GetString($bytes)
        $utf8Valid = $true
    } catch {
        $utf8Valid = $false
    }

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

# 3. Scan
Write-Host "[2/3] Scanning encodings..." -ForegroundColor Cyan
$report = @()
$count = 0
$total = $allMd.Count
foreach ($f in $allMd) {
    $count++
    if ($count % 200 -eq 0) {
        Write-Host "    Progress: $count / $total" -ForegroundColor Gray
    }
    $enc = Get-FileEncoding -Path $f
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
$report | Export-Csv -Path "encoding-report-v3.csv" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== ENCODING REPORT V3 SUMMARY ===" -ForegroundColor Yellow

$utf8Count = ($report | Where-Object { $_.Status -eq "UTF-8" }).Count
$bomCount = ($report | Where-Object { $_.Status -eq "UTF-8-BOM" }).Count
$gbkCount = ($report | Where-Object { $_.Status -eq "GBK" }).Count
$missingCount = ($report | Where-Object { $_.Status -eq "MISSING" }).Count
$unknownCount = ($report | Where-Object { $_.Status -eq "UNKNOWN" }).Count
$emptyCount = ($report | Where-Object { $_.Status -eq "EMPTY" }).Count
$readErrorCount = ($report | Where-Object { $_.Status -eq "READ_ERROR" }).Count

Write-Host "Total .md files:      $total"
Write-Host "  UTF-8 (no BOM):     $utf8Count"
Write-Host "  UTF-8 with BOM:     $bomCount"
Write-Host "  GBK (needs fix):    $gbkCount"
Write-Host "  MISSING (real):     $missingCount"
Write-Host "  EMPTY:              $emptyCount"
Write-Host "  READ_ERROR:         $readErrorCount"
Write-Host "  UNKNOWN:            $unknownCount"

if ($missingCount -gt 0) {
    Write-Host ""
    Write-Host "=== TRULY MISSING FILES (top 30) ===" -ForegroundColor Red
    $report | Where-Object { $_.Status -eq "MISSING" } | Select-Object -First 30 | Format-Table Path -AutoSize
}

if ($gbkCount -gt 0) {
    Write-Host ""
    Write-Host "=== GBK FILES (top 30) ===" -ForegroundColor Magenta
    $report | Where-Object { $_.Status -eq "GBK" } | Select-Object -First 30 | Format-Table Path, Size -AutoSize
}

if ($bomCount -gt 0) {
    Write-Host ""
    Write-Host "=== UTF-8-BOM FILES (first 30 of $bomCount) ===" -ForegroundColor Yellow
    $report | Where-Object { $_.Status -eq "UTF-8-BOM" } | Select-Object -First 30 | Format-Table Path, Size -AutoSize
}

Write-Host ""
Write-Host "Report saved to: encoding-report-v3.csv"