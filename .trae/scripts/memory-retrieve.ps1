param(
    [Parameter(Mandatory = $true)][ValidateSet("plan", "implement")][string]$Phase,
    [Parameter(Mandatory = $true)][ValidateSet("ue5", "web", "other")][string]$ProjectType,
    [Parameter(Mandatory = $true)][ValidateSet("router", "implement")][string]$Scope,
    [Parameter(Mandatory = $true)][string]$Module,
    [string[]]$Tags = @(),
    [int]$Limit = 1,
    [bool]$UseMem0 = $false,
    [string]$TaskName = "",
    [switch]$Semantic
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$IndexPath = Join-Path $RepoRoot "Docs\Memory\indexes\memory-index.md"

function Get-IndexRows {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $rows = @()
    foreach ($line in (Get-Content $Path -Encoding UTF8)) {
        if (-not $line.StartsWith("| memory-")) {
            continue
        }

        $parts = @($line.Trim("|") -split "\|" | ForEach-Object { $_.Trim() })
        if ($parts.Count -lt 8) {
            continue
        }

        $rows += [pscustomobject]@{
            Id       = $parts[0]
            Title    = $parts[1]
            Phase    = $parts[2]
            Module   = $parts[3]
            Severity = $parts[4]
            Scope    = $parts[5]
            Tags     = $parts[6]
            File     = $parts[7]
        }
    }

    return $rows
}

function Get-MemorySections {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $badPattern = [regex]::Match($content, '## Bad Pattern\s*(?<body>[\s\S]*?)\s*## Correct Rule').Groups['body'].Value.Trim()
    $correctRule = [regex]::Match($content, '## Correct Rule\s*(?<body>[\s\S]*?)\s*## Retrieval Hint').Groups['body'].Value.Trim()
    $verification = [regex]::Match($content, '## Verification\s*(?<body>[\s\S]*)$').Groups['body'].Value.Trim()

    return [pscustomobject]@{
        BadPattern  = ($badPattern -replace '\r?\n', ' ')
        CorrectRule = ($correctRule -replace '\r?\n', ' ')
        Verification = ($verification -replace '\r?\n', ' ')
    }
}

function Score-Row {
    param(
        $Row,
        [string]$WantedPhase,
        [string]$WantedModule,
        [string[]]$WantedTags,
        [string]$WantedScope
    )

    $score = 0
    if ($Row.Phase -eq $WantedPhase) {
        $score += 4
    }
    if ($Row.Module -eq $WantedModule) {
        $score += 3
    }
    if ($Row.Scope -match [regex]::Escape($WantedScope)) {
        $score += 2
    }

    foreach ($tag in $WantedTags) {
        if (-not [string]::IsNullOrWhiteSpace($tag) -and $Row.Tags -match [regex]::Escape($tag)) {
            $score += 1
        }
    }

    return $score
}

function Test-RowRelevance {
    param(
        $Row,
        [string]$WantedModule,
        [string[]]$WantedTags
    )

    if ($Row.Module -eq $WantedModule) {
        return $true
    }

    foreach ($tag in $WantedTags) {
        if (-not [string]::IsNullOrWhiteSpace($tag) -and $Row.Tags -match [regex]::Escape($tag)) {
            return $true
        }
    }

    return $false
}

function Resolve-MemoryPath {
    param(
        [string]$BaseDirectory,
        [string]$RelativePath
    )

    $normalized = $RelativePath -replace '/', '\'
    return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $normalized))
}

function Read-Mem0Health {
    $healthScript = Join-Path $PSScriptRoot "mem0-healthcheck.ps1"
    if (-not (Test-Path $healthScript)) {
        return $null
    }

    $raw = & $healthScript
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Search-Mem0 {
    param(
        $Health,
        [string]$WantedScope,
        [string]$WantedModule,
        [string[]]$WantedTags,
        [int]$WantedLimit
    )

    if (-not $Health -or $Health.status -ne "available" -or $WantedLimit -le 0) {
        return @()
    }

    $queryTerms = @($WantedModule) + $WantedTags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $payload = @{
        query = ($queryTerms -join " ")
        limit = $WantedLimit
        filters = @{
            project = "UEGameDevelopment"
            scope = @($WantedScope)
        }
    } | ConvertTo-Json -Depth 6

    try {
        $result = Invoke-RestMethod -Uri ($Health.endpoint.TrimEnd("/") + "/memories/search") -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 2
        return @($result.results)
    } catch {
        return @()
    }
}

$rows = Get-IndexRows -Path $IndexPath | ForEach-Object {
    $row = $_
    $score = Score-Row -Row $row -WantedPhase $Phase -WantedModule $Module -WantedTags $Tags -WantedScope $Scope
    $isRelevant = Test-RowRelevance -Row $row -WantedModule $Module -WantedTags $Tags
    if ($score -gt 0 -and $isRelevant) {
        [pscustomobject]@{
            Row = $row
            Score = $score
        }
    }
} | Sort-Object -Property @(
    @{ Expression = { $_.Score }; Descending = $true },
    @{ Expression = { $_.Row.Severity }; Descending = $true }
)

$selected = @($rows | Select-Object -First ([Math]::Max($Limit, 0)))
if ($selected.Count -eq 0) {
    return ""
}

$items = foreach ($entry in $selected) {
    $resolvedPath = Resolve-MemoryPath -BaseDirectory (Split-Path $IndexPath -Parent) -RelativePath $entry.Row.File
    if (-not (Test-Path $resolvedPath)) {
        continue
    }

    $sections = Get-MemorySections -FilePath $resolvedPath
    [pscustomobject]@{
        Title = $entry.Row.Title
        BadPattern = $sections.BadPattern
        CorrectRule = $sections.CorrectRule
        Verification = $sections.Verification
    }
}

if (@($items).Count -eq 0) {
    $items = @()
}

$health = if ($UseMem0) { Read-Mem0Health } else { $null }
$minimumLocalItems = if ($Scope -eq "router") { [Math]::Min([Math]::Max($Limit, 0), 2) } else { [Math]::Min([Math]::Max($Limit, 0), 1) }
$needsMem0 = ($UseMem0 -and @($items).Count -lt $minimumLocalItems)

if ($needsMem0) {
    $mem0Items = Search-Mem0 -Health $health -WantedScope $Scope -WantedModule $Module -WantedTags $Tags -WantedLimit ($Limit - @($items).Count)
    foreach ($hit in $mem0Items) {
        $metadata = $hit.metadata
        $items += [pscustomobject]@{
            Title = $hit.memory
            BadPattern = $metadata.bad_pattern
            CorrectRule = $metadata.correct_rule
            Verification = $metadata.verification
        }
    }
}

if (@($items).Count -eq 0) {
    return ""
}

# Semantic search via ruflo (silent fallback if unavailable — ruflo requires internet for ONNX model loading)
if ($Semantic) {
    $indexScript = Join-Path $PSScriptRoot "ruflo-index-memories.ps1"
    if (Test-Path $indexScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $indexScript *> $null
    }

    $queryTerms = @($Module) + $Tags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    try {
        $env:Path = "D:\NodeJS;D:\npm-global;$env:Path"
        $rufloRaw = & cmd /c "ruflo memory search -q `"$queryTerms`" -n $([Math]::Max($Limit, 2)) --timeout 3000 2>&1" 2>$null
        if ($rufloRaw -and $rufloRaw -notmatch "WARN.*No results") {
            # Parse ruflo search results if available (requires ONNX model to be loaded — may be empty offline)
        }
    } catch {
        # ruflo unavailable or model not loaded — silent fallback to keyword-only
    }
}

$header = if ($Scope -eq "router") { "Relevant Failure Memories" } else { "Pre-Edit Failure Reminder" }
$lines = @($header)
$index = 1

foreach ($item in $items) {
    $lines += ("{0}. {1} Rule: {2} Verify: {3}" -f $index, $item.BadPattern, $item.CorrectRule, $item.Verification)
    $index++
}

$lines -join "`n"
