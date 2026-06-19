param(
    [switch]$DryRun,
    [switch]$Execute,
    [switch]$Force  # Skip expiry date check
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$stubDirs = @(
    (Join-Path $root "Docs\airpgweb"),
    (Join-Path $root "Docs\characterdesigntool")
)

$expiryDate = Get-Date "2026-09-17"
$now = Get-Date
$stubs = @()
$totalDeleted = 0

foreach ($dir in $stubDirs) {
    if (-not (Test-Path $dir)) { continue }
    $files = Get-ChildItem -LiteralPath $dir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '<!-- doc-migration-redirect -->') {
            $created = $file.LastWriteTime
            $stubs += [pscustomobject]@{
                Path = $file.FullName
                Created = $created
                Expired = ($Force -or ($now -gt $expiryDate))
            }
        }
    }
}

Write-Host "=== Redirect Stub Report ==="
Write-Host "Total stubs found: $($stubs.Count)"
Write-Host "Expiry date: $($expiryDate.ToString('yyyy-MM-dd'))"
Write-Host "Expired: $(($stubs | Where-Object { $_.Expired }).Count)"
Write-Host "Not expired: $(($stubs | Where-Object { -not $_.Expired }).Count)"
Write-Host ""

if ($DryRun) {
    Write-Host "--- DRY RUN (no files deleted) ---"
    foreach ($s in $stubs) {
        $marker = if ($s.Expired) { "[EXPIRED]" } else { "[ACTIVE]" }
        $relPath = $s.Path.Replace($root, ".").Replace("\", "/")
        Write-Host "  $marker $relPath (created: $($s.Created.ToString('yyyy-MM-dd')))"
    }
    Write-Host ""
    if ($stubs.Count -eq 0) {
        Write-Host "No redirect stubs found."
    }
    elseif (($stubs | Where-Object { -not $_.Expired }).Count -gt 0) {
        Write-Host "Stubs not yet expired. Re-run with --execute after $($expiryDate.ToString('yyyy-MM-dd'))."
    }
    else {
        Write-Host "All stubs expired. Run with --execute to delete."
    }
    exit 0
}

if ($Execute) {
    if (-not $Force -and $now -lt $expiryDate) {
        Write-Host "STOP: Expiry date ($($expiryDate.ToString('yyyy-MM-dd'))) has not been reached."
        Write-Host "Current date: $($now.ToString('yyyy-MM-dd'))"
        Write-Host "Use --dry-run to preview. Use --execute after expiry."
        exit 1
    }
    Write-Host "--- EXECUTING DELETION ---"
    foreach ($s in $stubs) {
        if ($s.Expired) {
            Remove-Item -LiteralPath $s.Path -Force
            Write-Host "  DELETED: $($s.Path.Replace($root, '.'))"
            $totalDeleted++
        }
    }

    # Clean up empty directories
    foreach ($dir in $stubDirs) {
        if (Test-Path $dir) {
            $emptyDirs = Get-ChildItem -LiteralPath $dir -Directory -Recurse -ErrorAction SilentlyContinue |
                         Where-Object { (Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue).Count -eq 0 }
            foreach ($d in $emptyDirs) {
                Remove-Item -LiteralPath $d.FullName -Recurse -Force
                Write-Host "  REMOVED empty dir: $($d.FullName.Replace($root, '.'))"
            }
        }
    }

    Write-Host ""
    Write-Host "Deleted $totalDeleted stubs."
    exit 0
}

Write-Host "No mode specified. Use --dry-run or --execute."
exit 1
