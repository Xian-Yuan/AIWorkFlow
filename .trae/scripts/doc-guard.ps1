# doc-guard.ps1 -- Documentation governance gate
# Usage:
#   doc-guard.ps1 init-project <ProjectName>
#   doc-guard.ps1 check-project <ProjectName>
#   doc-guard.ps1 check-task <task-name> -Stage plan|implement|review|verify

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("init-project", "check-project", "check-task", "print-impact-template", "print-tree-template")]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$Target,

    [ValidateSet("plan", "implement", "review", "verify")]
    [string]$Stage = "implement"
)

$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskRoots = @(
    (Join-Path $WorkspaceRoot ".trae\tasks"),
    (Join-Path $WorkspaceRoot ".opencode\tasks"),
    (Join-Path $WorkspaceRoot ".codex\tasks")
)
$AllowedDocRoots = @(
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

function Normalize-DocPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    $value = $Path.Trim()
    $value = $value -replace "^`"", ""
    $value = $value -replace "`"$", ""
    $value = $value -replace "^'", ""
    $value = $value -replace "'$", ""
    $value = $value -replace "^``", ""
    $value = $value -replace "``$", ""
    $value = $value -replace "\\", "/"
    return $value.Trim()
}

function Resolve-WorkspacePath {
    param([string]$Path)
    $normalized = Normalize-DocPath $Path
    return Join-Path $WorkspaceRoot ($normalized -replace "/", "\")
}

function Add-Failure {
    param([string]$Message)
    Write-Red "  [FAIL] $Message"
    $script:Blocked = $true
}

function Add-Pass {
    param([string]$Message)
    Write-Green "  [PASS] $Message"
}

function Add-Warn {
    param([string]$Message)
    Write-Yellow "  [WARN] $Message"
}

function Get-SectionBody {
    param([string]$Content, [string]$SectionName)
    $escaped = [regex]::Escape($SectionName)
    $match = [regex]::Match($Content, "(?ms)^##\s+$escaped\s*\r?\n(?<body>.*?)(?=^##\s+|\z)")
    if (-not $match.Success) { return "" }
    return $match.Groups["body"].Value
}

function Get-SectionItems {
    param([string]$Content, [string]$SectionName)
    $body = Get-SectionBody $Content $SectionName
    $items = @()
    foreach ($line in ($body -split "\r?\n")) {
        if ($line -match "^\s*-\s+(?:\[[ xX]\]\s*)?(?<item>.+?)\s*$") {
            $item = Normalize-DocPath $matches["item"]
            if ($item -and $item -notin @("None", "none", "N/A", "n/a", "null", "<none>")) {
                $items += $item
            }
        }
    }
    return $items
}

function Get-ScopeField {
    param([string]$Content, [string]$Field)
    $escaped = [regex]::Escape($Field)
    $match = [regex]::Match($Content, "(?mi)^\s*-\s*$escaped\s*:\s*(?<value>.+?)\s*$")
    if (-not $match.Success) { return "" }
    return $match.Groups["value"].Value.Trim()
}

function Test-ConcreteValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value -match "<.*>") { return $false }
    if ($Value -match "^(TODO|TBD|None|null|N/A)$") { return $false }
    return $true
}

function Get-ProjectFromPath {
    param([string]$Path)
    $normalized = Normalize-DocPath $Path
    if ($normalized -match "^Project/([^/]+)/") { return $matches[1] }
    return $null
}

function Test-DocPathCategory {
    param([string]$Project, [string]$Path)
    $normalized = Normalize-DocPath $Path
    $prefix = "Project/$Project/Docs/"
    if (-not $normalized.StartsWith($prefix)) { return $false }
    $relative = $normalized.Substring($prefix.Length)
    if ($relative -eq "DOCS_TREE.md") { return $true }
    $first = ($relative -split "/")[0]
    return ($first -in $AllowedDocRoots)
}

function Resolve-TaskPath {
    param([string]$TaskName)
    if (-not $TaskName) { Write-Red "ERROR: task name required"; exit 1 }

    if ($TaskName -match "^(.+?)/(.+)$") {
        foreach ($root in $TaskRoots) {
            $dir = Join-Path $root ($TaskName -replace "/", "\")
            if (Test-Path $dir) { return $dir }
        }
    }

    foreach ($root in $TaskRoots) {
        $direct = Join-Path $root $TaskName
        if (Test-Path $direct) { return $direct }

        foreach ($projectDir in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            $dir = Join-Path $projectDir.FullName $TaskName
            if (Test-Path $dir) { return $dir }
        }
    }

    Write-Red "ERROR: Task not found: $TaskName"
    exit 1
}

function Initialize-ProjectDocs {
    param([string]$ProjectName)
    if (-not $ProjectName) { Write-Red "ERROR: project name required"; exit 1 }

    $projectDir = Join-Path $WorkspaceRoot "Project\$ProjectName"
    if (-not (Test-Path $projectDir)) {
        Write-Red "ERROR: project not found: Project/$ProjectName"
        exit 1
    }

    $docsDir = Join-Path $projectDir "Docs"
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
    foreach ($root in $AllowedDocRoots) {
        New-Item -ItemType Directory -Path (Join-Path $docsDir $root) -Force | Out-Null
    }

    $treePath = Join-Path $docsDir "DOCS_TREE.md"
    if (-not (Test-Path $treePath)) {
        $templatePath = Join-Path $PSScriptRoot "doc-tree-template.md"
        $today = Get-Date -Format "yyyy-MM-dd"
        $content = Get-Content -LiteralPath $templatePath -Raw
        $content = $content -replace "<ProjectName>", $ProjectName
        $content = $content -replace "<YYYY-MM-DD>", $today
        Set-Content -LiteralPath $treePath -Value $content
        Write-Green "[doc-guard] Created Project/$ProjectName/Docs/DOCS_TREE.md"
    }
    else {
        Write-Green "[doc-guard] Docs tree already exists: Project/$ProjectName/Docs/DOCS_TREE.md"
    }
}

function Test-ProjectDocs {
    param([string]$ProjectName)
    $script:Blocked = $false
    Write-Host "=== Doc Guard: project $ProjectName ==="
    $projectDir = Join-Path $WorkspaceRoot "Project\$ProjectName"
    $docsDir = Join-Path $projectDir "Docs"
    $treePath = Join-Path $docsDir "DOCS_TREE.md"

    if (Test-Path $projectDir) { Add-Pass "project exists: Project/$ProjectName" }
    else { Add-Failure "project missing: Project/$ProjectName" }

    if (Test-Path $docsDir) { Add-Pass "Docs directory exists" }
    else { Add-Failure "Docs directory missing" }

    if (Test-Path $treePath) { Add-Pass "DOCS_TREE.md exists" }
    else { Add-Failure "DOCS_TREE.md missing" }

    if ($Blocked) { exit 1 }
    exit 0
}

function Test-TaskDocumentation {
    param([string]$TaskName, [string]$StageName)

    $script:Blocked = $false
    $taskDir = Resolve-TaskPath $TaskName
    $impactPath = Join-Path $taskDir "doc-impact.md"

    Write-Host "=== Doc Guard: task $TaskName ($StageName) ==="

    if (-not (Test-Path $impactPath)) {
        Add-Failure "doc-impact.md missing at $impactPath"
        Write-Yellow "  Run: .trae/scripts/doc-guard.ps1 print-impact-template"
        exit 1
    }

    $content = Get-Content -LiteralPath $impactPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Add-Failure "doc-impact.md is empty"
        exit 1
    }
    Add-Pass "doc-impact.md exists"

    foreach ($field in @("Project", "System", "Owner")) {
        $value = Get-ScopeField $content $field
        if (Test-ConcreteValue $value) { Add-Pass "$field scope is set: $value" }
        else { Add-Failure "$field scope is missing or placeholder" }
    }

    $codeChanges = Get-SectionItems $content "Code Changes"
    $docUpdates = Get-SectionItems $content "Documentation Updates"
    $treeUpdates = Get-SectionItems $content "Docs Tree Updates"
    $noCodeBody = Get-SectionBody $content "No Code Changes"
    $hasNoCodeReason = $noCodeBody -match "(?mi)^\s*Reason\s*:\s*\S+"

    $projectCodeChanges = @($codeChanges | Where-Object {
        $_ -match "^Project/" -and $_ -notmatch "^Project/[^/]+/Docs/"
    })

    if ($projectCodeChanges.Count -eq 0) {
        if ($hasNoCodeReason) {
            Add-Pass "no project code changes declared with reason"
        }
        else {
            Add-Failure "no project code changes listed and no No Code Changes reason"
        }
    }

    $projects = @($projectCodeChanges | ForEach-Object { Get-ProjectFromPath $_ } | Where-Object { $_ } | Select-Object -Unique)

    foreach ($project in $projects) {
        $projectDocsDir = Resolve-WorkspacePath "Project/$project/Docs"
        $projectTreePath = Resolve-WorkspacePath "Project/$project/Docs/DOCS_TREE.md"
        if (Test-Path $projectDocsDir) { Add-Pass "project Docs exists: Project/$project/Docs" }
        else { Add-Failure "project Docs missing: Project/$project/Docs" }

        if (Test-Path $projectTreePath) { Add-Pass "project DOCS_TREE exists: Project/$project/Docs/DOCS_TREE.md" }
        else { Add-Failure "project DOCS_TREE missing: Project/$project/Docs/DOCS_TREE.md" }

        $sameProjectDocs = @($docUpdates | Where-Object { $_ -match "^Project/$([regex]::Escape($project))/Docs/" })
        if ($sameProjectDocs.Count -gt 0) {
            Add-Pass "documentation update listed for Project/$project"
        }
        else {
            Add-Failure "code changed in Project/$project but no same-project Docs update listed"
        }

        foreach ($docPath in $sameProjectDocs) {
            if (Test-DocPathCategory $project $docPath) {
                Add-Pass "classified doc path: $docPath"
            }
            else {
                Add-Failure "doc path violates classification: $docPath"
            }
        }

        $sameProjectTree = @($treeUpdates | Where-Object { $_ -eq "Project/$project/Docs/DOCS_TREE.md" })
        if ($sameProjectTree.Count -gt 0) {
            Add-Pass "DOCS_TREE update listed for Project/$project"
        }
        else {
            Add-Failure "code changed in Project/$project but DOCS_TREE update not listed"
        }

        $wrongProjectDocs = @($docUpdates | Where-Object {
            ($_ -match "^Project/") -and ($_ -notmatch "^Project/$([regex]::Escape($project))/Docs/")
        })
        foreach ($wrong in $wrongProjectDocs) {
            Add-Failure "cross-project doc update cannot satisfy Project/$project code change: $wrong"
        }
    }

    if ($Blocked) {
        Write-Red "BLOCKED - documentation governance failed"
        exit 1
    }

    Write-Green "DOCUMENTATION GOVERNANCE PASSED"
    exit 0
}

switch ($Command) {
    "init-project" {
        Initialize-ProjectDocs $Target
        exit 0
    }
    "check-project" {
        Test-ProjectDocs $Target
    }
    "check-task" {
        Test-TaskDocumentation $Target $Stage
    }
    "print-impact-template" {
        Get-Content -LiteralPath (Join-Path $PSScriptRoot "doc-impact-template.md")
        exit 0
    }
    "print-tree-template" {
        Get-Content -LiteralPath (Join-Path $PSScriptRoot "doc-tree-template.md")
        exit 0
    }
}
