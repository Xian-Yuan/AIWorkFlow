# migrate-docs.ps1 -- Move project docs into taxonomy directories with redirect stubs.
# Usage:
#   migrate-docs.ps1 -Mode plan
#   migrate-docs.ps1 -Mode apply -ProjectName AIRPGWeb -Limit 3
#   migrate-docs.ps1 -Mode apply
#   migrate-docs.ps1 -Mode check

param(
    [ValidateSet("plan", "apply", "check")]
    [string]$Mode = "plan",

    [string]$ProjectName,

    [int]$Limit = 0,

    [switch]$NoRedirect
)

$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ProjectRoot = Join-Path $WorkspaceRoot "Project"
$MigrationLog = Join-Path $WorkspaceRoot "Docs\AI\document-migration-log.md"
$DocsTreeScript = Join-Path $PSScriptRoot "update-docs-tree.ps1"
$Today = Get-Date -Format "yyyy-MM-dd"

$DocRoots = @(
    "00-Overview",
    "01-Planning",
    "02-Design",
    "03-Architecture",
    "04-Implementation",
    "05-Testing",
    "06-Operations",
    "07-Decisions",
    "99-Archive"
)

function Write-Red { Write-Host $args[0] -ForegroundColor Red }
function Write-Green { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }

function Convert-ToSlash {
    param([string]$Path)
    return ($Path -replace "\\", "/")
}

function Get-RelativePath {
    param([string]$Base, [string]$Path)
    $baseFull = [System.IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return Convert-ToSlash ($pathFull.Substring($baseFull.Length))
    }
    return Convert-ToSlash $pathFull
}

function Assert-UnderPath {
    param([string]$Base, [string]$Path, [string]$Label)
    $baseFull = [System.IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if (-not $pathFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label path escapes allowed root: $pathFull"
    }
}

function Test-IsRedirectStub {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $head = Get-Content -LiteralPath $Path -TotalCount 5 -ErrorAction SilentlyContinue
    return (($head -join "`n") -match "doc-migration-redirect")
}

function Test-IsClassifiedDoc {
    param([string]$RelativePath)
    if ($RelativePath -eq "DOCS_TREE.md") { return $true }
    $first = ($RelativePath -split "/")[0]
    return ($first -in $DocRoots)
}

function Get-SuggestedTarget {
    param([string]$RelativePath)
    $lower = $RelativePath.ToLowerInvariant()
    $name = Split-Path $RelativePath -Leaf

    if ($lower -match "archive|deprecated|old") { return "99-Archive/Legacy/$name" }
    if ($lower -match "test|qa|review|verify|verification|result|report|fix") { return "05-Testing/General/$name" }
    if ($lower -match "plan|roadmap|target|progress") { return "01-Planning/General/$name" }
    if ($lower -match "design|spec|schema|gameplay|system|data") { return "02-Design/General/$name" }
    if ($lower -match "architecture|api|reference|mcp|module|integration") { return "03-Architecture/General/$name" }
    if ($lower -match "script|build|deploy|encoding|operation|runbook") { return "06-Operations/General/$name" }
    if ($lower -match "decision|adr") { return "07-Decisions/General/$name" }
    if ($lower -match "readme|overview|guide|tutorial|engine") { return "00-Overview/General/$name" }
    return "00-Overview/General/$name"
}

function Get-Projects {
    $projects = @(Get-ChildItem -LiteralPath $ProjectRoot -Directory -ErrorAction Stop | Sort-Object Name)
    if ($ProjectName) {
        $projects = @($projects | Where-Object { $_.Name -eq $ProjectName })
        if ($projects.Count -eq 0) { throw "Project not found: $ProjectName" }
    }
    return $projects
}

function Get-Candidates {
    $rows = @()
    foreach ($project in (Get-Projects)) {
        $docsDir = Join-Path $project.FullName "Docs"
        if (-not (Test-Path $docsDir)) { continue }

        $files = @(Get-ChildItem -LiteralPath $docsDir -Recurse -File -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object FullName)
        foreach ($file in $files) {
            $rel = Get-RelativePath $docsDir $file.FullName
            if ($rel -eq "DOCS_TREE.md") { continue }
            if (Test-IsRedirectStub $file.FullName) { continue }
            if (Test-IsClassifiedDoc $rel) { continue }

            $suggested = Get-SuggestedTarget $rel
            $dest = Join-Path $docsDir ($suggested -replace "/", "\")
            $status = if (Test-Path -LiteralPath $dest) { "collision" } else { "ready" }

            $rows += [pscustomobject]@{
                Project = $project.Name
                Source = $rel
                Target = $suggested
                SourceFull = $file.FullName
                TargetFull = $dest
                Status = $status
            }
        }
    }

    if ($Limit -gt 0) { return @($rows | Select-Object -First $Limit) }
    return $rows
}

function Write-MigrationReport {
    param([object[]]$Rows, [string]$ReportMode)
    $redirectRows = @(Get-RedirectRows)

    $lines = @(
        "# Document Migration Log",
        "",
        "Date: $Today",
        "Mode: $ReportMode",
        "Scope: Project/*/Docs internal migration only",
        "",
        "## Summary",
        "",
        "| Metric | Count |",
        "|---|---:|",
        "| Rows | $($Rows.Count) |",
        "| Ready | $(($Rows | Where-Object { $_.Status -eq 'ready' }).Count) |",
        "| Collision | $(($Rows | Where-Object { $_.Status -eq 'collision' }).Count) |",
        "",
        "## Rows",
        "",
        "| Project | Source | Target | Status |",
        "|---|---|---|---|"
    )

    if ($Rows.Count -eq 0) {
        $lines += "| _None_ | _None_ | _None_ | _None_ |"
    }
    else {
        foreach ($row in $Rows) {
            $lines += "| $($row.Project) | $($row.Source) | $($row.Target) | $($row.Status) |"
        }
    }

    $lines += @(
        "",
        "## Redirect History",
        "",
        "These rows show documents already migrated with old-path stubs.",
        "",
        "| Old Path | New Path |",
        "|---|---|"
    )

    if ($redirectRows.Count -eq 0) {
        $lines += "| _None_ | _None_ |"
    }
    else {
        foreach ($row in $redirectRows) {
            $lines += "| $($row.OldPath) | $($row.NewPath) |"
        }
    }

    $lines += @(
        "",
        "## Notes",
        "",
        "- Redirect stubs preserve old paths when apply mode is used without -NoRedirect.",
        "- Root Docs project mirrors are not migrated in this pass.",
        "- Run update-docs-tree.ps1 after apply to refresh project document trees."
    )

    [System.IO.File]::WriteAllLines($MigrationLog, $lines, [System.Text.UTF8Encoding]::new($false))
}

function Get-RedirectRows {
    $rows = @()
    foreach ($project in (Get-Projects)) {
        $docsDir = Join-Path $project.FullName "Docs"
        if (-not (Test-Path $docsDir)) { continue }
        $files = @(Get-ChildItem -LiteralPath $docsDir -Recurse -File -Filter "*.md" -ErrorAction SilentlyContinue)
        foreach ($file in $files) {
            if (-not (Test-IsRedirectStub $file.FullName)) { continue }
            $content = Get-Content -LiteralPath $file.FullName -Raw
            $old = ""
            $new = ""
            if ($content -match "(?m)^- Old path:\s*(.+)$") { $old = $matches[1].Trim() }
            if ($content -match "(?m)^- New path:\s*(.+)$") { $new = $matches[1].Trim() }
            $rows += [pscustomobject]@{
                Project = $project.Name
                OldPath = $old
                NewPath = $new
            }
        }
    }
    return @($rows | Sort-Object Project, OldPath)
}

function Invoke-Apply {
    param([object[]]$Rows)

    $readyRows = @($Rows | Where-Object { $_.Status -eq "ready" })
    $blockedRows = @($Rows | Where-Object { $_.Status -ne "ready" })
    if ($blockedRows.Count -gt 0) {
        foreach ($row in $blockedRows) {
            Write-Yellow "[skip] $($row.Project): $($row.Source) -> $($row.Target) ($($row.Status))"
        }
    }

    foreach ($row in $readyRows) {
        $projectDir = Join-Path $ProjectRoot $row.Project
        $docsDir = Join-Path $projectDir "Docs"
        Assert-UnderPath $docsDir $row.SourceFull "source"
        Assert-UnderPath $docsDir $row.TargetFull "target"
        if (-not (Test-Path -LiteralPath $row.SourceFull)) { throw "Source missing: $($row.SourceFull)" }
        if (Test-Path -LiteralPath $row.TargetFull) { throw "Target exists: $($row.TargetFull)" }

        $targetDir = Split-Path -Parent $row.TargetFull
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

        Move-Item -LiteralPath $row.SourceFull -Destination $row.TargetFull

        if (-not $NoRedirect) {
            $oldPath = "Project/$($row.Project)/Docs/$($row.Source)"
            $newPath = "Project/$($row.Project)/Docs/$($row.Target)"
            $stub = @(
                "<!-- doc-migration-redirect -->",
                "# Moved Document",
                "",
                "This document moved during the $Today documentation taxonomy migration.",
                "",
                "- Old path: $oldPath",
                "- New path: $newPath",
                "",
                "Use the new path for future references."
            )
            [System.IO.File]::WriteAllLines($row.SourceFull, $stub, [System.Text.UTF8Encoding]::new($false))
        }

        Write-Green "[moved] $($row.Project): $($row.Source) -> $($row.Target)"
    }
}

try {
    $candidates = @(Get-Candidates)

    if ($Mode -eq "check") {
        $collisions = @($candidates | Where-Object { $_.Status -eq "collision" })
        if ($collisions.Count -gt 0) {
            Write-MigrationReport $candidates "check"
            throw "Migration collisions found: $($collisions.Count)"
        }
        Write-MigrationReport $candidates "check"
        Write-Green "[migrate-docs] check passed; candidates=$($candidates.Count)"
        exit 0
    }

    if ($Mode -eq "plan") {
        Write-MigrationReport $candidates "plan"
        Write-Green "[migrate-docs] plan written: $MigrationLog"
        exit 0
    }

    if ($Mode -eq "apply") {
        Write-MigrationReport $candidates "apply-before"
        Invoke-Apply $candidates
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DocsTreeScript -Mode write
        $remaining = @(Get-Candidates)
        Write-MigrationReport $remaining "apply-after"
        if (($remaining | Where-Object { $_.Status -eq "collision" }).Count -gt 0) { exit 1 }
        Write-Green "[migrate-docs] apply complete; remaining=$($remaining.Count)"
        exit 0
    }
}
catch {
    Write-Red "[migrate-docs] $($_.Exception.Message)"
    exit 1
}
