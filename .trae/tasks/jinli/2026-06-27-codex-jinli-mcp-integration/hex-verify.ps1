# hex-verify.ps1 - Hex dump first bytes of key files to verify encoding
Set-Location "E:\UEGameDevelopment"

Write-Host "=== Hex dump verification of key files ===" -ForegroundColor Yellow

function Get-HexDump {
    param([string]$Path, [int]$Bytes=32)
    if (-not [System.IO.File]::Exists($Path)) {
        Write-Host "  [MISSING] $Path" -ForegroundColor Red
        return
    }
    $data = [System.IO.File]::ReadAllBytes($Path)
    $hex = ($data[0..([Math]::Min($Bytes-1, $data.Length-1))] | ForEach-Object { $_.ToString('X2') }) -join ' '
    $size = $data.Length
    $first3 = if ($data.Length -ge 3) { $data[0..2] | ForEach-Object { $_.ToString('X2') } } else { '' }
    Write-Host "  $Path" -NoNewline
    Write-Host " (size=$size, first3=$first3)"
    Write-Host "    HEX: $hex"
}

Write-Host ""
Write-Host "--- Files reported as 'garbled' in git diff ---"
Get-HexDump "AGENTS.md" 64
Get-HexDump "skills\codex-project-router\SKILL.md" 64
Get-HexDump ".opencode\tasks\README.md" 64
Get-HexDump ".opencode\skills\codex-project-router\SKILL.md" 64

Write-Host ""
Write-Host "--- AGENTS.md full content attempt as UTF-8 ---"
try {
    $content = [System.IO.File]::ReadAllText("AGENTS.md", [System.Text.Encoding]::UTF8)
    Write-Host "  Read OK, length: $($content.Length)" -ForegroundColor Green
    Write-Host "  First 200 chars: $($content.Substring(0, [Math]::Min(200, $content.Length)))"
} catch {
    Write-Host "  Read FAILED as UTF-8: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- .opencode/mcp.json ---"
Get-HexDump ".opencode\mcp.json" 32

Write-Host ""
Write-Host "--- Comparing AGENTS.md in git HEAD vs working tree ---"
$headHash = git rev-parse HEAD:AGENTS.md 2>$null
Write-Host "  HEAD hash for AGENTS.md: $headHash"
$gitHeadBytes = cmd /c "git show HEAD:AGENTS.md" 2>$null | ForEach-Object { $_ }
# Easier: write to temp file via git show
$tmpA = [System.IO.Path]::GetTempFileName()
cmd /c "git show HEAD:AGENTS.md > `"$tmpA`"" | Out-Null
if (Test-Path $tmpA) {
    Get-HexDump $tmpA 32
    Write-Host "  (HEAD version of AGENTS.md, first 32 bytes)"
    Remove-Item $tmpA -ErrorAction SilentlyContinue
}