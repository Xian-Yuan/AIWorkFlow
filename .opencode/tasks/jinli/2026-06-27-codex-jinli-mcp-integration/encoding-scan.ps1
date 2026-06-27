# encoding-scan.ps1 - Detect encoding of all working-tree .md files
# Output: encoding-report.csv (path, current_encoding, has_bom, is_valid_utf8, can_decode_as_gbk, size)

Set-Location "E:\UEGameDevelopment"

# 1. Collect all .md files (tracked + untracked)
Write-Host "[1/3] Collecting .md files..." -ForegroundColor Cyan

# tracked .md
$tracked = @()
git ls-files '*.md' 2>$null | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '\.md$') { $tracked += $line }
}

# untracked .md
$untracked = @()
git ls-files --others --exclude-standard 2>$null | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '\.md$') { $untracked += $line }
}

$allMd = @($tracked + $untracked) | Select-Object -Unique

Write-Host "    Tracked .md files: $($tracked.Count)" -ForegroundColor Gray
Write-Host "    Untracked .md files: $($untracked.Count)" -ForegroundColor Gray
Write-Host "    Unique .md to check: $($allMd.Count)" -ForegroundColor Gray

# 2. Encoding detection function
function Get-FileEncoding {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @{ Status="MISSING"; Bom="None"; Utf8Valid=$false; GbkDecoded=$false; Size=0 }
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
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
foreach ($f in $allMd) {
    $count++
    if ($count % 200 -eq 0) {
        Write-Host "    Progress: $count / $total" -ForegroundColor Gray
    }
    $enc = Get-FileEncoding -Path $f
    $isGood = ($enc.Status -eq "UTF-8" -or $enc.Status -eq "UTF-8-BOM" -or $enc.Status -eq "EMPTY")
    if (-not $isGood) { $badCount++ }
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
$report | Export-Csv -Path "encoding-report.csv" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== ENCODING REPORT SUMMARY ===" -ForegroundColor Yellow
Write-Host "Total .md files: $total"
Write-Host "Non-UTF-8 files: $badCount"
Write-Host ""
Write-Host "Breakdown by status:"
$report | Group-Object Status | Select-Object Count, Name | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host ""
Write-Host "Non-UTF-8 files (showing up to 80):"
$report | Where-Object { $_.Status -ne "UTF-8" -and $_.Status -ne "UTF-8-BOM" -and $_.Status -ne "EMPTY" } |
    Select-Object -First 80 |
    Format-Table Path, Status, Size -AutoSize

Write-Host ""
Write-Host "Report saved to: encoding-report.csv"