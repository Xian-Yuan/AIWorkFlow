param(
    [switch]$Force  # Re-index even if already indexed
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$memoryRoot = Join-Path $root "Docs\Memory"
$indexPath = Join-Path $memoryRoot "indexes\memory-index.md"

# Check ruflo availability
$rufloPath = "D:\npm-global\ruflo.cmd"
if (-not (Test-Path $rufloPath)) {
    Write-Host "[WARN] ruflo not found at $rufloPath — skipping indexing"
    exit 0
}

$env:Path = "D:\NodeJS;D:\npm-global;$env:Path"

# Read memory index
if (-not (Test-Path $indexPath)) {
    Write-Host "[WARN] No memory index at $indexPath"
    exit 0
}

$rows = @()
foreach ($line in (Get-Content $indexPath -Encoding UTF8)) {
    if (-not $line.StartsWith("| memory-")) { continue }
    $parts = @($line.Trim("|") -split "\|" | ForEach-Object { $_.Trim() })
    if ($parts.Count -lt 8) { continue }
    $rows += [pscustomobject]@{
        ID    = $parts[0]
        Title = $parts[1]
        Phase = $parts[2]
        Module = $parts[3]
        Severity = $parts[4]
        Scope = $parts[5]
        Tags = $parts[6]
        File = $parts[7].Replace("./../", "")
    }
}

# Check if already indexed
$existing = & cmd /c "ruflo memory list 2>&1" 2>$null
$alreadyIndexed = ($existing -join " ") -match [regex]::Escape("memory-")

if ($alreadyIndexed -and -not $Force) {
    Write-Host "[INFO] Memories already indexed. Use -Force to re-index."
    Write-Host "Existing entries:"
    Write-Host $existing
    exit 0
}

# Index each memory
$indexed = 0
foreach ($row in $rows) {
    $memFile = Join-Path $memoryRoot $row.File
    if (-not (Test-Path $memFile)) {
        Write-Host "[SKIP] File not found: $($row.File)"
        continue
    }

    $content = Get-Content $memFile -Raw -Encoding UTF8

    # Extract sections
    $badPattern = if ($content -match '## Bad Pattern\s*\n([\s\S]*?)(?=\n## |\Z)') { $matches[1].Trim() } else { "" }
    $correctRule = if ($content -match '## Correct Rule\s*\n([\s\S]*?)(?=\n## |\Z)') { $matches[1].Trim() } else { "" }
    $verification = if ($content -match '## Verification\s*\n([\s\S]*?)(?=\n## |\Z)') { $matches[1].Trim() } else { "" }

    $value = "$($row.Title). Rule: $correctRule. Verify: $verification"
    $tags = $row.Tags -replace '\s*,\s*', ',' -replace ' ', '-'

    $result = & cmd /c "ruflo memory store -k $($row.ID) --value `"$value`" --tags `"$tags`" --vector --upsert 2>&1"
    Write-Host "[INDEXED] $($row.ID): $($row.Title)"
    $indexed++
}

if ($indexed -gt 0) {
    Write-Host ""
    Write-Host "[DONE] Indexed $indexed failure memories into ruflo."
} else {
    Write-Host "[DONE] No new memories to index."
}
