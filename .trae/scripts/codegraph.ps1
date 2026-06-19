# codegraph.ps1 — UE5 Code Knowledge Graph Builder
# Inspired by: colbymchenry/codegraph
# Builds dependency graph for UE5 C++ code to reduce agent token consumption

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("build","query","check")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$Project,

    [string]$Output,

    [string]$File,

    [string]$Tag,

    [string]$Dependency,

    [string]$Format = "summary",

    [switch]$Incremental
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$WorkspaceRoot = "E:\UEGameDevelopment"
$ProjectPath = Join-Path $WorkspaceRoot "Project\$Project"
$SourcePath = Join-Path $ProjectPath "Source"
$GraphDir = Join-Path $WorkspaceRoot ".codex-shared\codegraph"

if (-not (Test-Path -LiteralPath $GraphDir)) {
    New-Item -ItemType Directory -Force -Path $GraphDir | Out-Null
}

if (-not $Output) {
    $Output = Join-Path $GraphDir "$($Project.ToLower())-graph.json"
}

function Get-FileHash {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return (Get-FileHash -LiteralPath $Path -Algorithm MD5).Hash
    }
    return "MISSING"
}

function Get-Includes {
    param([string]$FilePath)
    $includes = @()
    if (Test-Path -LiteralPath $FilePath) {
        $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $matches = [regex]::Matches($content, '#include\s+"([^"]+)"')
            foreach ($m in $matches) {
                $includes += $m.Groups[1].Value
            }
        }
    }
    return $includes
}

function Get-ClassDeclarations {
    param([string]$FilePath)
    $classes = @()
    if (Test-Path -LiteralPath $FilePath) {
        $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $classMatches = [regex]::Matches($content, 'class\s+(\w+)\s*[:{]')
            foreach ($m in $classMatches) {
                $classes += $m.Groups[1].Value
            }
            $structMatches = [regex]::Matches($content, 'struct\s+(\w+)\s*[:{]')
            foreach ($m in $structMatches) {
                $classes += $m.Groups[1].Value
            }
        }
    }
    return $classes | Select-Object -Unique
}

function Get-LineCount {
    param([string]$FilePath)
    if (Test-Path -LiteralPath $FilePath) {
        return (Get-Content -LiteralPath $FilePath | Measure-Object -Line).Lines
    }
    return 0
}

function Build-Graph {
    Write-Host "[codegraph] Building graph for $Project..."
    $graph = @{
        project = $Project
        generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        modules = @{}
        cross_module_deps = @{}
        file_stats = @{
            total_files = 0
            total_lines = 0
            largest_file = ""
            largest_lines = 0
        }
    }

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Host "[codegraph] Source path not found: $SourcePath"
        $graph | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Output -Encoding UTF8
        return
    }

    $files = Get-ChildItem -LiteralPath $SourcePath -Recurse -Include "*.cpp","*.h" -ErrorAction SilentlyContinue
    $graph.file_stats.total_files = $files.Count

    # First pass: collect file metadata
    $fileMeta = @{}
    foreach ($f in $files) {
        $relPath = $f.FullName.Replace($ProjectPath, "").TrimStart("\")
        $lines = Get-LineCount $f.FullName
        $graph.file_stats.total_lines += $lines
        if ($lines -gt $graph.file_stats.largest_lines) {
            $graph.file_stats.largest_file = $relPath
            $graph.file_stats.largest_lines = $lines
        }
        $fileMeta[$relPath] = @{
            path = $relPath
            includes = Get-Includes $f.FullName
            classes = Get-ClassDeclarations $f.FullName
            lines = $lines
            hash = Get-FileHash $f.FullName
        }
    }

    # Second pass: build modules and resolve deps
    foreach ($relPath in $fileMeta.Keys) {
        $meta = $fileMeta[$relPath]
        $isHeader = $relPath.EndsWith(".h") -or $relPath.EndsWith(".hpp")

        $deps = @()
        foreach ($inc in $meta.includes) {
            $incPath = $inc -replace '/', '\'
            foreach ($otherPath in $fileMeta.Keys) {
                if ($otherPath.EndsWith($incPath)) {
                    $deps += $otherPath
                    break
                }
            }
            # Also match by just filename
            if ($deps.Count -eq 0 -or $deps[-1] -notmatch [regex]::Escape($incPath.Split('\')[-1])) {
                foreach ($otherPath in $fileMeta.Keys) {
                    if ((Split-Path -Leaf $otherPath) -eq (Split-Path -Leaf $incPath)) {
                        $deps += $otherPath
                        break
                    }
                }
            }
        }

        # Extract tags from GameplayTag references
        $content = Get-Content -LiteralPath (Join-Path $SourcePath $relPath) -Raw -ErrorAction SilentlyContinue
        $tags = @()
        if ($content) {
            $tagMatches = [regex]::Matches($content, 'FGameplayTag\s+\w+')
            if ($tagMatches.Count -gt 0) { $tags += "GAS" }
            if ($content -match 'AbilitySystemComponent') { $tags += "AbilitySystem" }
            if ($content -match 'GameFeatureAction|UGameFeatureData') { $tags += "GameFeature" }
            if ($content -match 'UPawnData|UInputConfig|UAbilitySet') { $tags += "Lyra" }
            if ($content -match 'AIController|StateTree|BehaviorTree|EQS') { $tags += "AI" }
            if ($content -match 'UMG|UserWidget|Slate') { $tags += "UI" }
        }

        $className = if ($meta.classes.Count -gt 0) { $meta.classes[0] } else { [IO.Path]::GetFileNameWithoutExtension($relPath) }

        $graph.modules[$relPath] = @{
            name = $className
            type = if ($isHeader) { "header" } else { "source" }
            dependencies = $deps | Select-Object -Unique
            classes = $meta.classes
            tags = $tags | Select-Object -Unique
            lines = $meta.lines
            hash = $meta.hash
        }
    }

    # Third pass: cross-module dependencies (from Build.cs)
    $buildFile = Get-ChildItem -LiteralPath $SourcePath -Recurse -Filter "*.Build.cs" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($buildFile) {
        $buildContent = Get-Content -LiteralPath $buildFile.FullName -Raw -ErrorAction SilentlyContinue
        $pubDeps = [regex]::Matches($buildContent, 'PublicDependencyModuleNames\.Add\("([^"]+)"\)')
        $privDeps = [regex]::Matches($buildContent, 'PrivateDependencyModuleNames\.Add\("([^"]+)"\)')
        $graph.cross_module_deps.Public = ($pubDeps | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        $graph.cross_module_deps.Private = ($privDeps | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    }

    $graph | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Output -Encoding UTF8
    Write-Host "[codegraph] Graph built: $($graph.modules.Count) modules, $($graph.file_stats.total_lines) lines"
}

function Query-Graph {
    if (-not (Test-Path -LiteralPath $Output)) {
        Write-Host "[codegraph] Graph not found. Run 'build' first."
        return
    }
    $graph = Get-Content -LiteralPath $Output -Raw | ConvertFrom-Json

    if ($File) {
        $match = $graph.modules.PSObject.Properties | Where-Object { $_.Name -like "*$File*" }
        if (-not $match) {
            Write-Host "[codegraph] File not found: $File"
            return
        }
        $mod = $match[0].Value
        switch ($Format) {
            "dependency-tree" {
                Write-Host "=== $($mod.name) ($($mod.lines) lines) ==="
                Write-Host "Dependencies: $($mod.dependencies -join ', ')"
                Write-Host "Tags: $($mod.tags -join ', ')"
            }
            "dependents" {
                $dependents = $graph.modules.PSObject.Properties | Where-Object { $mod.name -in $_.Value.dependencies } | ForEach-Object { $_.Name }
                Write-Host "=== Dependents of $($mod.name) ==="
                Write-Host ($dependents -join "`n")
            }
            default {
                Write-Host "=== $($match[0].Name) ==="
                Write-Host "Name: $($mod.name)"
                Write-Host "Type: $($mod.type)"
                Write-Host "Lines: $($mod.lines)"
                Write-Host "Dependencies: $($mod.dependencies -join ', ')"
                Write-Host "Classes: $($mod.classes -join ', ')"
                Write-Host "Tags: $($mod.tags -join ', ')"
            }
        }
    }
    elseif ($Tag) {
        $matches = $graph.modules.PSObject.Properties | Where-Object { $Tag -in $_.Value.tags }
        Write-Host "=== Modules tagged '$Tag' ($($matches.Count) found) ==="
        foreach ($m in $matches) {
            Write-Host "  $($m.Name) ($($m.Value.lines) lines)"
        }
    }
    elseif ($Dependency) {
        $matches = $graph.modules.PSObject.Properties | Where-Object { $Dependency -in $_.Value.dependencies }
        Write-Host "=== Files depending on '$Dependency' ($($matches.Count) found) ==="
        foreach ($m in $matches) {
            Write-Host "  $($m.Name) ($($m.Value.lines) lines)"
        }
    }
    else {
        Write-Host "=== Project: $($graph.project) ==="
        Write-Host "Modules: $($graph.modules.PSObject.Properties.Count)"
        Write-Host "Total lines: $($graph.file_stats.total_lines)"
        Write-Host "Largest: $($graph.file_stats.largest_file) ($($graph.file_stats.largest_lines) lines)"
        if ($graph.cross_module_deps.Public) {
            Write-Host "Public deps: $($graph.cross_module_deps.Public -join ', ')"
        }
        if ($graph.cross_module_deps.Private) {
            Write-Host "Private deps: $($graph.cross_module_deps.Private -join ', ')"
        }
    }
}

function Check-Staleness {
    if (-not (Test-Path -LiteralPath $Output)) {
        Write-Host "[codegraph] No existing graph. Needs build."
        return @{ stale_count = -1; stale_files = @() }
    }
    $graph = Get-Content -LiteralPath $Output -Raw | ConvertFrom-Json
    $stale = @()
    foreach ($prop in $graph.modules.PSObject.Properties) {
        $filePath = Join-Path $SourcePath $prop.Name
        $currentHash = Get-FileHash $filePath
        if ($currentHash -ne $prop.Value.hash -and $currentHash -ne "MISSING") {
            $stale += $prop.Name
        }
    }
    Write-Host "[codegraph] Stale files: $($stale.Count) / $($graph.modules.PSObject.Properties.Count)"
    return @{ stale_count = $stale.Count; stale_files = $stale }
}

switch ($Action) {
    "build" {
        if ($Incremental -and (Test-Path -LiteralPath $Output)) {
            $staleCheck = Check-Staleness
            if ($staleCheck.stale_count -eq 0) {
                Write-Host "[codegraph] Graph is up to date."
                return
            }
        }
        Build-Graph
    }
    "query" { Query-Graph }
    "check" { Check-Staleness | Out-Null }
}
