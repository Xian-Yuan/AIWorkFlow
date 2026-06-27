# verify-missing.ps1 - Verify which "MISSING" files are truly missing vs encoding issue
Set-Location "E:\UEGameDevelopment"

Write-Host "=== Verifying MISSING files ===" -ForegroundColor Yellow

# Read encoding report
$report = Import-Csv "encoding-report.csv"
$missing = $report | Where-Object { $_.Status -eq "MISSING" }
Write-Host "Total MISSING: $($missing.Count)" -ForegroundColor Red

Write-Host ""
Write-Host "Sample missing paths (first 30):"
$missing | Select-Object -First 30 | ForEach-Object { Write-Host "  $($_.Path)" -ForegroundColor Red }

Write-Host ""
Write-Host "=== Directory check ==="
$firstMissing = $missing[0].Path
$dir = Split-Path $firstMissing -Parent
Write-Host "First missing file dir: $dir"
if (Test-Path $dir) {
    Write-Host "  Directory EXISTS" -ForegroundColor Green
    Get-ChildItem $dir -ErrorAction SilentlyContinue | Select-Object -First 5 | Format-Table Name, Length
} else {
    Write-Host "  Directory MISSING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Trying git status on missing files ==="
$missing[0].Path | Out-File -Encoding utf8 tmp_check.txt
git status --short $missing[0].Path 2>&1 | Out-Host
$missing[0].Path | Out-File -Encoding utf8 tmp_check2.txt
git log --oneline -5 -- $missing[0].Path 2>&1 | Out-Host

Write-Host ""
Write-Host "=== Try git ls-files with --full-name ==="
git ls-files --full-name | Select-String '02-\u5b57\u7b26\u7f16\u7801' | Select-Object -First 3 | Out-Host

Write-Host ""
Write-Host "=== Sample ls of tracked file ==="
$realPath = '.opencode/skills/xg-uecpp-course/knowledge/ch10/02-字符编码与TCHAR系统.md'
Write-Host "Testing: $realPath"
Write-Host "Test-Path: $(Test-Path $realPath)"
if (Test-Path $realPath) {
    $info = Get-Item $realPath
    Write-Host "  Exists, size=$($info.Length)"
    $bytes = [System.IO.File]::ReadAllBytes($realPath)
    Write-Host "  First 4 bytes: $($bytes[0..3] | ForEach-Object { $_.ToString('X2') })"
}

Write-Host ""
Write-Host "=== Checking git index directly ==="
$relPath = '.opencode/skills/xg-uecpp-course/knowledge/ch10/02-字符编码与TCHAR系统.md'
Write-Host "git cat-file -s :$relPath"
git cat-file -s ":$relPath" 2>&1 | Out-Host
Write-Host "git ls-files | grep:"
git ls-files | Select-String '02-' | Select-Object -First 3 | Out-Host