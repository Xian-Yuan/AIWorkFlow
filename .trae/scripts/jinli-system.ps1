# jinli-system.ps1
# Jinli runtime daemon lifecycle wrapper.
#
# Subcommands:
#   start    Start the daemon. If a live daemon is already running,
#            reports the existing PID/endpoint without starting a new
#            process.
#   stop     Gracefully stop the running daemon. Polls the PID until
#            it exits; escalates to TerminateProcess on timeout.
#   status   Print a human-readable daemon status. Add -Json for JSON.
#   doctor   Print human-readable diagnostics. Add -Json for JSON.
#            Exit code 2 if there are blocking issues.
#
# Exit codes (controller mode):
#   0  - success / daemon already running (start) / healthy (doctor)
#   1  - runtime/setup error
#   2  - gate failed (doctor only) / already running conflict (_run)
#
# Usage examples:
#   jinli-system.ps1 start
#   jinli-system.ps1 status -Json | Out-File state.json
#   jinli-system.ps1 doctor
#   jinli-system.ps1 stop
#
# The script locates the Python interpreter the same way as
# jinli-runtime-turn.ps1 (explicit -Python, known venvs, then PATH).

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("start","stop","status","doctor")]
    [string]$Subcommand,

    [int]$Port = 0,
    [double]$HealthIntervalS = 5.0,
    # WP01-repair: controller-side start now polls until the worker
    # reports a live ``daemon_state`` (online/degraded) instead of
    # bailing as soon as the PID/endpoint files exist. The previous
    # 5s default was too tight for that contract; 30s is a generous
    # ceiling that still fails fast on real outages.
    [double]$StartTimeoutS = 30.0,
    [double]$StopTimeoutS = 5.0,
    [switch]$Json,
    [string]$Python,
    [string]$Workspace = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# --- Resolve Python ---------------------------------------------------------
if (-not $Python) {
    $candidates = @(
        "$PSScriptRoot\..\..\..\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe",
        (Join-Path (Get-Location) ".tools\hermes-worker\hermes-agent\venv\Scripts\python.exe"),
        "python.exe"
    )
    foreach ($c in $candidates) {
        if ($c -eq "python.exe") {
            $resolved = Get-Command python.exe -ErrorAction SilentlyContinue
            if ($resolved) { $Python = $resolved.Source; break }
        } elseif (Test-Path $c) { $Python = (Resolve-Path $c).Path; break }
    }
}

if (-not $Python -or -not (Test-Path $Python)) {
    if ($Json) {
        Write-Output (ConvertTo-Json -Compress @{ ok = $false; error = "python_not_found" })
    } else {
        Write-Error "Python interpreter not found. Set -Python or install the venv."
    }
    exit 1
}

# --- Build daemon subcommand args ------------------------------------------
$daemonArgs = @("-m", "Project.Jinli.services.runtime.daemon", $Subcommand.ToLower())
switch ($Subcommand.ToLower()) {
    "start" {
        $daemonArgs += @("--start-timeout-s", $StartTimeoutS.ToString())
        if ($Port) { $daemonArgs += @("--port", $Port.ToString()) }
        $daemonArgs += @("--health-interval-s", $HealthIntervalS.ToString())
    }
    "stop" {
        $daemonArgs += @("--stop-timeout-s", $StopTimeoutS.ToString())
    }
    "status" {
        if ($Json) { $daemonArgs += "--json" }
    }
    "doctor" {
        if ($Json) { $daemonArgs += "--json" }
    }
}

# --- Run daemon subcommand -------------------------------------------------
$env:PYTHONPATH = $Workspace + [IO.Path]::PathSeparator + $env:PYTHONPATH
$stdoutFile = "$env:TEMP\jinli-system-$PID.out"
$stderrFile = "$env:TEMP\jinli-system-$PID.err"

# Use the call operator with redirection rather than Start-Process so
# that ``start`` (which spawns its own detached worker) returns
# promptly. Start-Process -Wait on a process that itself spawns and
# detaches can hang on certain Windows versions.
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Python
# Quote each argument so paths with spaces survive the round-trip.
$psi.Arguments = ($daemonArgs | ForEach-Object {
    if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
}) -join ' '
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.RedirectStandardInput  = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WorkingDirectory = $Workspace

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
[void]$proc.Start()
$stdoutTask = $proc.StandardOutput.ReadToEndAsync()
$stderrTask = $proc.StandardError.ReadToEndAsync()
$proc.StandardInput.Close()
[void]$proc.WaitForExit(30000)  # 30s hard ceiling on the controller call
$procExitCode = $proc.ExitCode
$proc.Dispose()
$stdout = $stdoutTask.Result
$stderr = $stderrTask.Result

# Cleanup temp files (none used anymore, but keep hook for future).
Remove-Item -LiteralPath $stdoutFile -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $stderrFile -ErrorAction SilentlyContinue

if ($procExitCode -ne 0 -and -not $stdout) {
    if ($Json) {
        Write-Output (ConvertTo-Json -Compress @{ ok = $false; exit_code = $procExitCode; stderr = $stderr })
    } else {
        if ($stderr) { Write-Host $stderr -ForegroundColor Red }
        else { Write-Host "daemon subcommand failed with exit code $procExitCode" -ForegroundColor Red }
    }
    exit 1
}

if ($stdout) {
    Write-Output $stdout.TrimEnd()
}

# Status / doctor: forward exit code (doctor returns 2 on blockers).
exit $procExitCode