[CmdletBinding()]
param(
    [ValidateSet(
        'Inspect', 'Apply', 'StopScans', 'Watch',
        'DisablePush', 'EnablePush', 'Classify'
    )]
    [string]$Mode = 'Inspect',
    [int]$WatchSeconds = 900,
    [int]$PollSeconds = 2,
    [int]$MinimumProcessAgeSeconds = 3,
    [string]$CommandLine,
    [switch]$ConfirmEnablePush,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gitDir = Join-Path $repoRoot '.git'
$pushBackupPath = Join-Path $gitDir 'workspace-git-guard-push-urls.json'
$logPath = Join-Path $repoRoot '.tmp\workspace-git-guard.log'
$pushDisabledValue = 'DISABLED_BY_WORKSPACE_POLICY'

function Invoke-Git {
    $gitArguments = @($args)
    $output = & git -C $repoRoot @gitArguments 2>&1
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
}

function Write-GuardLog {
    param([string]$Message)
    $logDirectory = Split-Path -Parent $logPath
    if (-not (Test-Path -LiteralPath $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value (
        '{0} {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffK'), $Message
    )
}

function Get-ProcessSnapshot {
    $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    $byId = @{}
    foreach ($process in $processes) {
        $byId[[int]$process.ProcessId] = $process
    }
    [pscustomobject]@{ Processes = $processes; ById = $byId }
}

function Test-AiAncestor {
    param([object]$Process, [hashtable]$ById)
    $current = $Process
    for ($depth = 0; $depth -lt 8 -and $current; $depth++) {
        if ($current.Name -match '^(Codex|OpenCode|Trae)(\.exe)?$') {
            return $true
        }
        $parentId = [int]$current.ParentProcessId
        if (-not $ById.ContainsKey($parentId)) {
            break
        }
        $current = $ById[$parentId]
    }
    return $false
}

function Test-ScanCommandLine {
    param([string]$Value)

    if (-not $Value) {
        return $false
    }

    $hasAddCommand = $Value -match '(?i)(?:^|\s)add(?:\s|$)'
    $hasAddScope = $Value -match '(?i)(?:^|\s)(?:-A|--all|--)(?:\s|$)'
    $hasStatusCommand = $Value -match '(?i)(?:^|\s)status(?:\s|$)'
    $hasCheckIgnoreCommand = $Value -match '(?i)(?:^|\s)check-ignore(?:\s|$)'
    $hasProtectedCommand = $Value -match (
        '(?i)(?:^|\s)(?:push|commit|fetch|pull|clone|merge|rebase)(?:\s|$)'
    )

    return (
        (($hasAddCommand -and $hasAddScope) -or
            $hasStatusCommand -or
            $hasCheckIgnoreCommand) -and
        -not $hasProtectedCommand
    )
}

function Stop-AiGitScans {
    $snapshot = Get-ProcessSnapshot
    $now = Get-Date
    $stopped = [System.Collections.Generic.List[object]]::new()

    foreach ($process in $snapshot.Processes) {
        if ($process.Name -ne 'git.exe' -or -not $process.CommandLine) {
            continue
        }

        $command = [string]$process.CommandLine
        if (-not (Test-ScanCommandLine $command)) {
            continue
        }
        if (-not (Test-AiAncestor -Process $process -ById $snapshot.ById)) {
            continue
        }

        $runtimeSeconds = $MinimumProcessAgeSeconds
        try {
            $created = [Management.ManagementDateTimeConverter]::ToDateTime($process.CreationDate)
            $runtimeSeconds = ($now - $created).TotalSeconds
        } catch {}
        if ($runtimeSeconds -lt $MinimumProcessAgeSeconds) {
            continue
        }

        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        $entry = [pscustomobject]@{
            ProcessId       = [int]$process.ProcessId
            ParentProcessId = [int]$process.ParentProcessId
            CommandLine     = $command
        }
        $stopped.Add($entry)
        Write-GuardLog "Stopped AI Git scan PID=$($process.ProcessId): $command"
    }
    return @($stopped)
}

function Get-RemoteState {
    $remotesResult = Invoke-Git remote
    if ($remotesResult.ExitCode -ne 0) {
        return @()
    }

    $states = foreach ($remote in $remotesResult.Output) {
        $remoteName = ([string]$remote).Trim()
        if (-not $remoteName) { continue }
        $fetch = Invoke-Git remote get-url $remoteName
        $push = Invoke-Git remote get-url --push $remoteName
        $pushUrl = ($push.Output -join '').Trim()
        [pscustomobject]@{
            Name     = $remoteName
            FetchUrl = ($fetch.Output -join '').Trim()
            PushUrl  = $pushUrl
            Disabled = ($pushUrl -eq $pushDisabledValue)
        }
    }
    return @($states)
}

function Disable-GitPush {
    $remoteStates = @(Get-RemoteState)
    if ($remoteStates.Count -eq 0) {
        return @()
    }

    $backup = [ordered]@{
        saved_at = (Get-Date -Format 'o')
        remotes = @(
            $remoteStates | ForEach-Object {
                [ordered]@{
                    name = $_.Name
                    fetch_url = $_.FetchUrl
                    push_url = if ($_.Disabled) { $_.FetchUrl } else { $_.PushUrl }
                }
            }
        )
    }
    $backup | ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $pushBackupPath -Encoding UTF8

    foreach ($remote in $remoteStates) {
        $result = Invoke-Git remote set-url --push $remote.Name $pushDisabledValue
        if ($result.ExitCode -ne 0) {
            throw "Failed to disable push for '$($remote.Name)': $($result.Output -join ' ')"
        }
    }
    return @(Get-RemoteState)
}

function Enable-GitPush {
    if (-not $ConfirmEnablePush) {
        throw 'EnablePush requires -ConfirmEnablePush.'
    }
    if (-not (Test-Path -LiteralPath $pushBackupPath)) {
        throw "Push URL backup not found: $pushBackupPath"
    }

    $backup = Get-Content -LiteralPath $pushBackupPath -Raw | ConvertFrom-Json
    foreach ($remote in $backup.remotes) {
        $result = Invoke-Git remote set-url --push $remote.name $remote.push_url
        if ($result.ExitCode -ne 0) {
            throw "Failed to restore push for '$($remote.name)': $($result.Output -join ' ')"
        }
    }
    return @(Get-RemoteState)
}

function Install-LocalExcludeDefense {
    $excludePath = Join-Path $gitDir 'info\exclude'
    $beginMarker = '# BEGIN WORKSPACE_GIT_GUARD'
    $endMarker = '# END WORKSPACE_GIT_GUARD'
    $block = @'
# BEGIN WORKSPACE_GIT_GUARD
/.agents/
/.claude/
/.claude-flow/
/.codex/
/.codex-shared/
/.codex-shared-profile/
/.pytest_cache/
/.qoder/
/.superpowers/
/.swarm/
/.temp/
/.tmp/
/.tmp_pip/
/.tools/
/.venv/
/ModelConverter/
/OpenCode/
/Plugins/
/Project/
/Scripts/
/Temp/
/Tools/
/node_modules/
/nul
/秋叶comfyui整合包/
# END WORKSPACE_GIT_GUARD
'@

    $existing = if (Test-Path -LiteralPath $excludePath) {
        Get-Content -LiteralPath $excludePath -Raw
    } else { '' }
    $pattern = '(?ms)^' + [regex]::Escape($beginMarker) + '.*?^' +
        [regex]::Escape($endMarker) + '\r?\n?'
    $clean = [regex]::Replace($existing, $pattern, '').TrimEnd()
    $content = if ($clean) { "$clean`r`n$block" } else { $block }
    Set-Content -LiteralPath $excludePath -Value $content -Encoding UTF8
}

function Apply-GitPolicy {
    $settings = [ordered]@{
        'core.autocrlf'       = 'false'
        'core.fscache'        = 'true'
        'core.longpaths'      = 'true'
        'core.preloadindex'   = 'true'
        'core.untrackedCache' = 'true'
        'feature.manyFiles'   = 'true'
    }
    foreach ($entry in $settings.GetEnumerator()) {
        $result = Invoke-Git config --local $entry.Key $entry.Value
        if ($result.ExitCode -ne 0) {
            throw "Failed to set $($entry.Key): $($result.Output -join ' ')"
        }
    }
    Install-LocalExcludeDefense
    [pscustomobject]@{
        GitSettings = $settings
        Remotes = @(Disable-GitPush)
    }
}

function Get-Inspection {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $status = Invoke-Git status --porcelain=v1 --untracked-files=all
    $timer.Stop()
    $autocrlf = Invoke-Git config --local --get core.autocrlf
    $remotes = @(Get-RemoteState)

    [pscustomobject]@{
        Repository = $repoRoot
        StatusExitCode = $status.ExitCode
        StatusSeconds = [math]::Round($timer.Elapsed.TotalSeconds, 3)
        UntrackedFiles = @(
            $status.Output | Where-Object { ([string]$_).StartsWith('?? ') }
        ).Count
        TrackedChanges = @(
            $status.Output | Where-Object { -not ([string]$_).StartsWith('?? ') }
        ).Count
        CoreAutoCrlf = ($autocrlf.Output -join '').Trim()
        Remotes = $remotes
        PushDisabled = @($remotes | Where-Object { -not $_.Disabled }).Count -eq 0
        GuardLog = $logPath
    }
}

switch ($Mode) {
    'Inspect' { $result = Get-Inspection }
    'Apply' { $result = Apply-GitPolicy }
    'StopScans' {
        $stopped = @(Stop-AiGitScans)
        $result = [pscustomobject]@{ StoppedCount = $stopped.Count; Processes = $stopped }
    }
    'Watch' {
        $deadline = (Get-Date).AddSeconds($WatchSeconds)
        $totalStopped = 0
        Write-GuardLog "Watch started for $WatchSeconds seconds."
        while ((Get-Date) -lt $deadline) {
            $totalStopped += @(Stop-AiGitScans).Count
            Start-Sleep -Seconds $PollSeconds
        }
        Write-GuardLog "Watch ended. Total stopped: $totalStopped."
        $result = [pscustomobject]@{
            WatchedSeconds = $WatchSeconds
            TotalStopped = $totalStopped
        }
    }
    'DisablePush' { $result = Disable-GitPush }
    'EnablePush' { $result = Enable-GitPush }
    'Classify' {
        $result = [pscustomobject]@{
            CommandLine = $CommandLine
            IsScan = (Test-ScanCommandLine $CommandLine)
        }
    }
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    $result | Format-List
}
