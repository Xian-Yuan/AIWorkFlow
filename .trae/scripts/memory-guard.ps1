# memory-guard.ps1 -- T6 Memory Gate PowerShell wrapper (spec sec.H.5)
#
# Calls Python memory_guard.py to check:
#   1. Does the current task have a memory decision recorded?
#   2. Is --skip-memory-check set?
#   3. Is task duration < 5 min?
# Returns: PASS / FAIL / SKIP
#
# Usage:
#   .\memory-guard.ps1 -TaskName "T-fix-x" -DurationMinutes 12 -HadNewDecision -LeadMemoryWritten
#   .\memory-guard.ps1 -TaskName "T-light" -DurationMinutes 3            # -> SKIP
#   .\memory-guard.ps1 -TaskName "T-skip" -DurationMinutes 30 -SkipMemoryCheck  # -> SKIP
#   .\memory-guard.ps1 -TaskName "T-x" -DurationMinutes 60 -HadFailure   # -> FAIL (exit 1)
#   # From a pre-built GuardInputs JSON (used by task-state.ps1 memory-gate subcommand)
#   .\memory-guard.ps1 -InputJson '{"task_name":"T-x",...}' -DecisionPath ".\memory-decision.json"
#   # Or from a JSON file
#   .\memory-guard.ps1 -InputJsonPath ".\gate-input.json" -DecisionPath ".\memory-decision.json"
#
# Design:
# - Dual-written to .trae/scripts/ + .opencode/scripts/ (shared implementation)
# - Patches task-state.ps1 (adds Memory Gate sub-phase; see spec sec.C.3)
# - Invokes Python via -m services.memory.keeper.memory_guard (workdir must be on sys.path)
# - Exit codes: PASS=0 / SKIP=0 / FAIL=1 / internal-error=2

[CmdletBinding()]
param(
    [string]$TaskName = "",
    [int]$DurationMinutes = 0,

    # Trigger condition flags
    [switch]$HadFailure,
    [switch]$HadNewDecision,
    [switch]$HadSuccessPattern,
    [switch]$BabaExplicitRemember,

    # Pass condition flags
    [switch]$LeadMemoryWritten,
    [switch]$LeadNoMemoryConfirmed,

    # Exemption
    [switch]$SkipMemoryCheck,

    # Optional: task text sample (used to detect "remember" as fallback)
    [string]$RawTextSample = "",

    # Output format
    [switch]$Json,

    # Working directory (default: current)
    [string]$Workdir = ".",

    # Pass GuardInputs JSON directly (mutually exclusive with -InputJsonPath)
    [string]$InputJson = "",

    # Read GuardInputs JSON from file (used by task-state.ps1 memory-gate subcommand)
    [string]$InputJsonPath = "",

    # Save the decision result to a JSON file (used by task-state.ps1:
    # .trae/tasks/<task>/memory-decision.json)
    [string]$DecisionPath = ""
)

$ErrorActionPreference = "Stop"

# Colors
function Write-ColorLine { param([string]$Text, [string]$Color)
    Write-Host $Text -ForegroundColor $Color
}

# Build GuardInputs JSON: -InputJson > -InputJsonPath > assemble from flags
if ($InputJson -and $InputJsonPath) {
    Write-ColorLine "ERROR: -InputJson and -InputJsonPath are mutually exclusive" "Red"
    exit 2
}
if ($InputJsonPath) {
    if (-not (Test-Path -LiteralPath $InputJsonPath)) {
        Write-ColorLine "ERROR: InputJsonPath not found: $InputJsonPath" "Red"
        exit 2
    }
    $inputs = (Get-Content -LiteralPath $InputJsonPath -Raw).Trim()
} elseif ($InputJson) {
    $inputs = $InputJson.Trim()
} else {
    # Build GuardInputs JSON from flags
    $inputs = @{
        task_name = $TaskName
        duration_minutes = $DurationMinutes
        had_failure = [bool]$HadFailure
        had_new_decision = [bool]$HadNewDecision
        had_success_pattern = [bool]$HadSuccessPattern
        baba_explicit_remember = [bool]$BabaExplicitRemember
        lead_memory_written = [bool]$LeadMemoryWritten
        lead_no_memory_confirmed = [bool]$LeadNoMemoryConfirmed
        skip_flag = [bool]$SkipMemoryCheck
        raw_text_sample = $RawTextSample
    } | ConvertTo-Json -Compress -Depth 5
}

# Resolve workdir to absolute path
$absWorkdir = (Resolve-Path -LiteralPath $Workdir -ErrorAction SilentlyContinue)
if (-not $absWorkdir) {
    Write-ColorLine "ERROR: Workdir not found: $Workdir" "Red"
    exit 2
}

# Find the project root that contains the `services` package.
# Search order: <workdir>/Project/Jinli, <workdir>, parents up to 4 levels.
function Find-ServicesRoot {
    param([string]$StartPath)
    $candidates = @(
        (Join-Path $StartPath "Project\Jinli"),
        (Join-Path $StartPath "Project\jinli"),
        $StartPath
    )
    foreach ($c in $candidates) {
        $svcPath = Join-Path $c "services"
        if (Test-Path -LiteralPath $svcPath) { return $c }
    }
    # Walk up parents
    $parent = Split-Path -Parent $StartPath
    for ($i = 0; $i -lt 4 -and $parent; $i++) {
        $svcPath = Join-Path $parent "Project\Jinli\services"
        if (Test-Path -LiteralPath $svcPath) { return (Join-Path $parent "Project\Jinli") }
        $svcPath2 = Join-Path $parent "services"
        if (Test-Path -LiteralPath $svcPath2) { return $parent }
        $parent = Split-Path -Parent $parent
    }
    return $null
}

$servicesRoot = Find-ServicesRoot $absWorkdir.Path
if (-not $servicesRoot) {
    Write-ColorLine "ERROR: Cannot locate 'services' package. Tried under: $absWorkdir" "Red"
    exit 2
}

# Build PYTHONPATH so the `services.memory.keeper` module is importable
$env:PYTHONPATH = $servicesRoot
# Suppress the runpy RuntimeWarning ("module found in sys.modules after import
# of package") which fires when __init__.py re-exports the entry module.
# This is benign noise; gate behavior is unaffected.
$env:PYTHONWARNINGS = "ignore::RuntimeWarning"

# CRITICAL: PowerShell 5.1 strips embedded double-quote characters when passing
# strings as native-command arguments. To preserve the JSON exactly, write it
# to a temp file and pass --input-json-path-file (or use --input-json-path).
# The Python CLI reads from --input-json-path if --input-json is empty.
$tempInputFile = Join-Path $env:TEMP "memory-guard-input-$PID.json"
try {
    # Use [System.IO.File]::WriteAllText to write UTF-8 WITHOUT BOM (utf8Bom=False)
    # Set-Content -Encoding UTF8 adds BOM which trips up Python's json parser in
    # some configurations. Use [IO.File]::WriteAllText with explicit UTF8 (no BOM).
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tempInputFile, $inputs, $utf8NoBom)
} catch {
    Write-ColorLine "ERROR: failed to write temp input file: $_" "Red"
    exit 2
}
if ($env:JINLI_GATE_DEBUG) {
    Write-ColorLine "[DEBUG] temp input file: $tempInputFile" "Yellow"
    Write-ColorLine "[DEBUG] content: $inputs" "Yellow"
}

# Invoke Python with the services root on sys.path
$pythonArgs = @("-m", "services.memory.keeper.memory_guard", "--input-json-path", $tempInputFile)
if ($Json) { $pythonArgs += "--json" }

$stdout = ""
$stderr = ""
$exitCode = 0

# Temporarily relax ErrorAction so python's non-zero exit codes (e.g. FAIL=1)
# do not raise a terminating PowerShell error.
$prevErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $output = & python @pythonArgs 2>&1
    $exitCode = $LASTEXITCODE
    $stdout = ($output | Out-String).Trim()
}
catch {
    Write-ColorLine "ERROR: failed to invoke python: $_" "Red"
    $exitCode = 2
}
finally {
    $ErrorActionPreference = $prevErrorAction
    # Clean up temp file (skip if JINLI_GATE_DEBUG for inspection)
    if (-not $env:JINLI_GATE_DEBUG) {
        if (Test-Path -LiteralPath $tempInputFile) {
            Remove-Item -LiteralPath $tempInputFile -Force -ErrorAction SilentlyContinue
        }
    }
    # Restore PYTHONPATH / PYTHONWARNINGS to pre-call values
    if ($env:PYTHONPATH -eq $servicesRoot) { Remove-Item Env:PYTHONPATH -ErrorAction SilentlyContinue }
    if ($env:PYTHONWARNINGS -eq "ignore::RuntimeWarning") { Remove-Item Env:PYTHONWARNINGS -ErrorAction SilentlyContinue }
}

# Output
Write-Host $stdout

# If -DecisionPath specified, persist the decision result to a JSON file
if ($DecisionPath) {
    $decision = @{
        task_name = $TaskName
        exit_code = $exitCode
        decision = if ($exitCode -eq 0) { "PASS_OR_SKIP" } else { "FAIL" }
        rendered_report = $stdout
        captured_at = (Get-Date -Format "o")
    }
    try {
        $dir = Split-Path -Parent $DecisionPath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $decision | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $DecisionPath -Encoding UTF8
    } catch {
        Write-ColorLine "WARN: failed to write decision to $DecisionPath : $_" "Yellow"
    }
}

# Exit codes:
#  0 = PASS or SKIP (gate passes, does not block)
#  1 = FAIL (gate blocks)
#  2 = internal error
if ($exitCode -ne 0) {
    if ($exitCode -eq 1) {
        Write-ColorLine "" "Red"
        Write-ColorLine "BLOCKED: Memory Gate FAIL -- task has memorable content but no Lead approval" "Red"
        Write-ColorLine "  Fix: call Lead.approve() to write L2/L3 memory; or pass -SkipMemoryCheck flag" "Yellow"
        Write-ColorLine "  Fix: pass -LeadNoMemoryConfirmed (Lead confirms no memory needed this time)" "Yellow"
        exit 1
    }
    Write-ColorLine "ERROR: memory-guard exited with code $exitCode" "Red"
    exit 2
}

# PASS / SKIP both return 0
Write-ColorLine "" "Green"
Write-ColorLine "OK: Memory Gate passed (exit 0)" "Green"
exit 0
