[CmdletBinding()]
param(
    [int]$MaxUntrackedFiles = 1000,
    [double]$MaxStatusSeconds = 10
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Git {
    $gitArguments = @($args)
    $output = & git -C $repoRoot @gitArguments 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output)
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Test-Ignored {
    param([string]$Path)
    $result = Invoke-Git check-ignore -q -- $Path
    return $result.ExitCode -eq 0
}

$requiredIgnoredPaths = @(
    '.codex-shared-profile/probe',
    '.codex-shared/probe',
    '.codex/probe',
    '.opencode/future-large-local-directory/probe',
    '.tools/probe',
    '.tmp/probe',
    '.trae/future-large-local-directory/probe',
    '.venv/probe',
    'node_modules/probe',
    'Project/probe',
    'Temp/probe',
    'Tools/probe',
    '秋叶comfyui整合包/probe',
    'future-large-local-directory/probe'
)

$requiredVisiblePaths = @(
    '.github/probe.yml',
    '.opencode/agents/probe.md',
    '.opencode/rules/probe.md',
    '.opencode/skills/probe/SKILL.md',
    '.opencode/tasks/probe.md',
    '.trae/rules/probe.md',
    '.trae/scripts/probe.ps1',
    '.trae/skills/probe/SKILL.md',
    '.trae/tasks/probe.md',
    'Docs/AI/probe.md',
    'skills/probe/SKILL.md',
    'AGENTS.md'
)

foreach ($path in $requiredIgnoredPaths) {
    Assert-True (Test-Ignored $path) "Expected ignored path: $path"
}

foreach ($path in $requiredVisiblePaths) {
    Assert-True (-not (Test-Ignored $path)) "Expected repository-visible path: $path"
}

$attributesPath = Join-Path $repoRoot '.gitattributes'
Assert-True (Test-Path -LiteralPath $attributesPath) 'Missing .gitattributes'
if (Test-Path -LiteralPath $attributesPath) {
    $attributes = Get-Content -LiteralPath $attributesPath -Raw
    Assert-True ($attributes -match '(?m)^\*\s+text=auto\s+eol=lf\s*$') 'Missing repository-wide LF policy'
}

$guardPath = Join-Path $repoRoot '.trae\scripts\workspace-git-guard.ps1'
Assert-True (Test-Path -LiteralPath $guardPath) 'Missing workspace-git-guard.ps1'
if (Test-Path -LiteralPath $guardPath) {
    function Get-GuardClassification {
        param([string]$CommandLine)

        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $guardPath `
            -Mode Classify -CommandLine $CommandLine -Json 2>&1
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousPreference
        if ($exitCode -ne 0) {
            return $null
        }
        try {
            return ($output -join "`n") | ConvertFrom-Json
        } catch {
            return $null
        }
    }

    $diffClassification = Get-GuardClassification (
        'git.exe diff --no-ext-diff --name-status -z HEAD'
    )
    Assert-True (
        $null -ne $diffClassification -and -not $diffClassification.IsScan
    ) 'Guard must not classify git diff --name-status as a scan'

    $statusClassification = Get-GuardClassification (
        'git.exe -c core.fsmonitor= status --porcelain=v1 -z --untracked-files=no'
    )
    Assert-True (
        $null -ne $statusClassification -and $statusClassification.IsScan
    ) 'Guard must classify git status as a scan'

    $addClassification = Get-GuardClassification 'git.exe add -A'
    Assert-True (
        $null -ne $addClassification -and $addClassification.IsScan
    ) 'Guard must classify git add -A as a scan'
}

$autocrlf = Invoke-Git config --local --get core.autocrlf
Assert-True (
    $autocrlf.ExitCode -eq 0 -and ($autocrlf.Output -join '').Trim() -eq 'false'
) 'Local core.autocrlf must be false'

$pushUrl = Invoke-Git config --local --get remote.origin.pushurl
Assert-True (
    $pushUrl.ExitCode -eq 0 -and ($pushUrl.Output -join '').Trim() -eq 'DISABLED_BY_WORKSPACE_POLICY'
) 'origin push URL is not disabled'

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$status = Invoke-Git status --porcelain=v1 --untracked-files=all
$stopwatch.Stop()

Assert-True ($status.ExitCode -eq 0) 'git status failed'
$untrackedCount = @(
    $status.Output | Where-Object { ([string]$_).StartsWith('?? ') }
).Count
$trackedChangeCount = @(
    $status.Output | Where-Object { -not ([string]$_).StartsWith('?? ') }
).Count
Assert-True (
    $untrackedCount -le $MaxUntrackedFiles
) "Untracked file count $untrackedCount exceeds limit $MaxUntrackedFiles"
Assert-True (
    $stopwatch.Elapsed.TotalSeconds -le $MaxStatusSeconds
) "git status took $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2))s; limit is ${MaxStatusSeconds}s"

$dryRun = Invoke-Git add --dry-run -A
$dryRunText = $dryRun.Output -join "`n"
Assert-True ($dryRun.ExitCode -eq 0) 'git add --dry-run -A failed'
Assert-True (
    $dryRunText -notmatch 'could not open directory|LF will be replaced by CRLF|fatal: adding files failed'
) 'git add dry-run still emits the original scan failure or line-ending warning'

$inspectOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $guardPath `
    -Mode Inspect -Json
$inspect = ($inspectOutput -join "`n") | ConvertFrom-Json
Assert-True (
    $inspect.UntrackedFiles -eq $untrackedCount
) "Guard reported $($inspect.UntrackedFiles) untracked files; expected $untrackedCount"
Assert-True (
    $inspect.TrackedChanges -eq $trackedChangeCount
) "Guard reported $($inspect.TrackedChanges) tracked changes; expected $trackedChangeCount"

if ($failures.Count -gt 0) {
    Write-Host 'Root Git boundary verification FAILED:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Root Git boundary verification PASSED' -ForegroundColor Green
Write-Host "Untracked files: $untrackedCount"
Write-Host "git status duration: $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2))s"
