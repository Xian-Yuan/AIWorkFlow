#requires -Version 5.1
<#
.SYNOPSIS
    Generate or check the Jinli file/workflow route index.

.DESCRIPTION
    -Build  : scan the workspace and write Project/Jinli/services/runtime/routes/route-index.json
    -Check  : rebuild the index in memory and compare digest to the on-disk one
    -Show   : print the route index as a summary

    The route index is the machine-readable source of truth for "where
    does this kind of file belong" and "which process applies to this
    kind of request". New models can read it instead of relying on
    tribal prompt knowledge.

    Exit codes:
      0 success (build or check passed)
      1 check failed (drift, missing, or unreadable index)
      2 invalid arguments

.NOTES
    Part of MIRP: Model-Independent Runtime Protocol
    See: Project/Jinli/services/runtime/route_index.py
#>

[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$Check,
    [switch]$Show,
    [string]$Workspace = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Workspace)) {
    Write-Error "Workspace not found: $Workspace"
    exit 2
}

$Workspace = (Resolve-Path -LiteralPath $Workspace).Path
$venvPy = Join-Path $Workspace ".tools\hermes-worker\hermes-agent\venv\Scripts\python.exe"
if (Test-Path -LiteralPath $venvPy) {
    $python = $venvPy
} else {
    $python = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $python) { $python = (Get-Command python3 -ErrorAction SilentlyContinue).Source }
}
if (-not $python) {
    Write-Error "Python not found in PATH or venv."
    exit 2
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliScript = Join-Path $scriptDir "_route_index_cli.py"

if ($Build) { $action = "build" }
elseif ($Check) { $action = "check" }
elseif ($Show) { $action = "show" }
else {
    Write-Error "Must specify -Build, -Check, or -Show"
    exit 2
}

$out = & $python $cliScript $Workspace $action
$rc = $LASTEXITCODE
if ($out) { Write-Output $out }
exit $rc
