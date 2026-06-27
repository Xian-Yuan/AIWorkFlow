# jinli-runtime-turn.ps1
# One-turn wrapper around the Jinli Runtime Daemon (WP03) or, in -UseCompat
# mode, a direct in-process TurnOrchestrator invocation.
#
# Usage (daemon mode — default):
#   jinli-runtime-turn.ps1 -Text "hello" -Mode standard
#   jinli-runtime-turn.ps1 -Text "do work" -Mode strict -TaskPacketId "jinli/2026-06-26-x"
#   jinli-runtime-turn.ps1 -Text "do work" -Mode strict -SubAgentReportsPath ".../subagents.json"
#
# Usage (compat mode — explicit opt-in, in-process):
#   jinli-runtime-turn.ps1 -Text "hello" -Mode standard -UseCompat
#
# Exit codes:
#   0  - gate passed; result JSON printed to stdout
#   2  - gate failed; failure JSON printed to stdout
#   3  - degraded but passed; result JSON printed with degraded=true
#   1  - runtime/setup error
#   4  - daemon offline and -UseCompat not set (in daemon mode)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet("lite","standard","strict","critical")][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Text,
    [string]$Task = "general",
    [string]$TaskPacketId,
    [string]$SubAgentReportsPath,
    [string]$Workspace = (Get-Location).Path,
    [string]$Python,
    [int]$TimeoutSeconds = 60,
    [switch]$UseCompat,
    [switch]$JsonOnly
)

$ErrorActionPreference = "Stop"

# Resolve Python interpreter: explicit -Python, then known venv locations.
if (-not $Python) {
    $candidates = @(
        "$PSScriptRoot\..\..\..\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe",
        (Join-Path (Get-Location) ".tools\hermes-worker/hermes-agent/venv/Scripts/python.exe"),
        "python.exe"
    )
    foreach ($c in $candidates) {
        if ($c -eq "python.exe") {
            $resolved = (Get-Command python.exe -ErrorAction SilentlyContinue)
            if ($resolved) { $Python = $resolved.Source; break }
        } elseif (Test-Path $c) { $Python = (Resolve-Path $c).Path; break }
    }
}

if (-not $Python -or -not (Test-Path $Python)) {
    Write-Error "Python interpreter not found. Set -Python or install the venv."
    exit 1
}

# ---------------------------------------------------------------------------
# Mode selection: daemon client (default) vs in-process compat (-UseCompat)
# ---------------------------------------------------------------------------

if ($UseCompat) {
    $mode_label = "compat"
} else {
    $mode_label = "daemon"
}

# ---------------------------------------------------------------------------
# Daemon client driver (default)
# ---------------------------------------------------------------------------

$tmp = Join-Path $env:TEMP "jinli-runtime-turn-$PID.py"
$statusPath = "$tmp.status.json"

# The driver invokes Project.Jinli.services.runtime.client.JinliClient,
# prints the parsed JSON to stdout, and writes a tiny status blob to
# $statusPath so the PS script can pick the right exit code.
$daemonDriver = @"
import json
import sys
import os
from pathlib import Path

# Force UTF-8 stdout for Windows consoles.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

from Project.Jinli.services.runtime.client import JinliClient, DaemonOffline, DaemonBadResponse

text = r"$Text"
task = r"$Task"
mode = r"$Mode".lower()
task_packet_id = r"$TaskPacketId" or None
timeout_s = $TimeoutSeconds
sub_agent_reports_path = r"$SubAgentReportsPath"

extra = {}
if sub_agent_reports_path:
    try:
        raw = json.loads(Path(sub_agent_reports_path).read_text(encoding="utf-8"))
        if isinstance(raw, dict):
            raw = [raw]
        extra["sub_agent_reports"] = raw
    except Exception as exc:
        sys.stderr.write(f"failed to read sub_agent_reports: {type(exc).__name__}: {exc}\n")
        sys.exit(11)

client = JinliClient(timeout_s=float(timeout_s))
try:
    if not client.is_online():
        sys.stderr.write(
            "daemon offline: endpoint file missing or socket unreachable. "
            "Start the daemon with jinli-system.ps1 start, or pass -UseCompat.\n"
        )
        sys.exit(4)
    result = client.turn(
        text,
        mode=mode,
        task=task,
        task_packet_id=task_packet_id,
        **(extra or {}),
    )
except DaemonOffline as exc:
    sys.stderr.write(f"daemon offline: {exc}\n")
    sys.exit(4)
except DaemonBadResponse as exc:
    sys.stderr.write(f"daemon returned bad response: {exc}\n")
    sys.exit(1)
except Exception as exc:
    sys.stderr.write(f"client error: {type(exc).__name__}: {exc}\n")
    sys.exit(1)

if not isinstance(result, dict):
    sys.stderr.write("client returned non-dict result\n")
    sys.exit(1)

# Adapt daemon response to the same shape the compat driver produces,
# so the PS script downstream stays simple.
manifest = dict(result.get("manifest") or {})
if not manifest:
    manifest = {
        "manifest_id": (result.get("response") or {}).get("manifest_id"),
        "turn_id": (result.get("response") or {}).get("turn_id"),
        "mode": (result.get("response") or {}).get("mode"),
        "task": (result.get("response") or {}).get("task"),
        "evidence": result.get("evidence", []),
        "degraded": bool((result.get("response") or {}).get("degraded")),
    }
manifest["daemon_meta"] = {
    "service_evidence": result.get("service_evidence", []),
    "memory_evidence": result.get("memory_evidence"),
    "emotion_evidence": result.get("emotion_evidence"),
    "relationship_evidence": result.get("relationship_evidence"),
    "degraded_reasons": result.get("degraded_reasons", []),
    "fallback_used": bool(result.get("fallback_used", False)),
}
manifest["gate"] = {
    "passed": (result.get("response") or {}).get("passed"),
    "violations": (result.get("response") or {}).get("violations", []),
}
resp = result.get("response") or {}
status = {
    "passed": bool(resp.get("passed")),
    "degraded": bool(resp.get("degraded")),
    "mode": resp.get("mode"),
    "violations": resp.get("violations", []),
    "daemon_offline": False,
    "fallback_used": bool(result.get("fallback_used", False)),
}
Path(r"$statusPath").write_text(json.dumps(status, ensure_ascii=False), encoding="utf-8")
print(json.dumps(manifest, ensure_ascii=False))
"@

# ---------------------------------------------------------------------------
# Compat driver (-UseCompat): in-process TurnOrchestrator, no daemon
# ---------------------------------------------------------------------------

$compatDriver = @"
import json
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

from Project.Jinli.services.runtime import TurnMode, TurnOrchestrator
from Project.Jinli.services.runtime.turn_manifest import SubAgentReport
from Project.Jinli.services.runtime.adapters import AdapterContext
from Project.Jinli.services.runtime.adapters.memory_adapter import MemoryAdapter
from Project.Jinli.services.runtime.adapters.persona_adapter import PersonaAdapter
from Project.Jinli.services.runtime.adapters.skill_route_adapter import SkillRouteAdapter
from Project.Jinli.services.runtime.adapters.file_route_adapter import FileRouteAdapter
from Project.Jinli.services.runtime.adapters.task_packet_adapter import TaskPacketAdapter
from Project.Jinli.services.runtime.adapters.workflow_route_adapter import WorkflowRouteAdapter
from Project.Jinli.services.runtime.adapters.verifier_lite_adapter import VerifierLiteAdapter

mode_map = {"lite": TurnMode.LITE, "standard": TurnMode.STANDARD,
            "strict": TurnMode.STRICT, "critical": TurnMode.CRITICAL}

ctx = AdapterContext(workspace=Path(r"$Workspace").resolve(), config={})
adapters = {
    "memory": MemoryAdapter(context=ctx).gather,
    "persona": PersonaAdapter(context=ctx).gather,
    "skill_route": SkillRouteAdapter(context=ctx).gather,
    "file_route": FileRouteAdapter(context=ctx).gather,
    "workflow_route": WorkflowRouteAdapter(context=ctx).gather,
    "task_packet": TaskPacketAdapter(context=ctx).gather,
    "verifier_lite": VerifierLiteAdapter(context=ctx).gather,
}

orc = TurnOrchestrator(adapters=adapters)
sub_agent_reports = []
sub_agent_reports_path = r"$SubAgentReportsPath"
if sub_agent_reports_path:
    raw = json.loads(Path(sub_agent_reports_path).read_text(encoding="utf-8"))
    if isinstance(raw, dict):
        raw = [raw]
    sub_agent_reports = [SubAgentReport(**item) for item in raw]

res = orc.run(
    user_input=r"$Text",
    task=r"$Task",
    mode=mode_map[r"$Mode".lower()],
    task_packet_id=r"$TaskPacketId" or None,
    sub_agent_reports=sub_agent_reports or None,
)

manifest = res.manifest.to_dict()
manifest["gate"] = {"passed": res.passed, "violations": res.violations}
manifest["daemon_meta"] = {
    "service_evidence": [],
    "memory_evidence": None,
    "emotion_evidence": None,
    "relationship_evidence": None,
    "degraded_reasons": [
        {"service": "daemon", "state": "offline", "reason": "compat mode: in-process fallback (no daemon)"}
    ],
    "fallback_used": True,
}
status = {
    "passed": res.passed,
    "degraded": bool(manifest.get("degraded")),
    "mode": manifest.get("mode"),
    "violations": res.violations,
    "daemon_offline": True,
    "fallback_used": True,
}
Path(r"$statusPath").write_text(json.dumps(status, ensure_ascii=False), encoding="utf-8")
print(json.dumps(manifest, ensure_ascii=False))
"@

$driver = if ($UseCompat) { $compatDriver } else { $daemonDriver }

Set-Content -LiteralPath $tmp -Value $driver -Encoding UTF8

try {
    $env:PYTHONPATH = $Workspace + [IO.Path]::PathSeparator + $env:PYTHONPATH
    $proc = Start-Process -FilePath $Python -ArgumentList @($tmp) -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "$tmp.out" -RedirectStandardError "$tmp.err"
    $stdout = Get-Content -LiteralPath "$tmp.out" -Raw -ErrorAction SilentlyContinue
    $stderr = Get-Content -LiteralPath "$tmp.err" -Raw -ErrorAction SilentlyContinue

    if ($proc.ExitCode -ne 0) {
        if ($stderr) { Write-Host $stderr -ForegroundColor Red }
        # 4 = daemon offline, 11 = sub_agent_reports read error.
        exit $proc.ExitCode
    }
    if (-not $stdout) {
        Write-Host "no output produced" -ForegroundColor Red
        exit 1
    }
    $statusJson = Get-Content -LiteralPath $statusPath -Raw -ErrorAction SilentlyContinue
    if (-not $statusJson) {
        Write-Host "status file missing" -ForegroundColor Red
        exit 1
    }
    $status = $statusJson | ConvertFrom-Json -ErrorAction Stop
    if (-not $JsonOnly) {
        $tag = if ($UseCompat) { "[mode=compat" } else { "[mode=daemon" }
        $tag += " gate.passed=$($status.passed) degraded=$($status.degraded) mode=$($status.mode)]"
        Write-Host $tag -ForegroundColor Cyan
        if ($status.daemon_offline) {
            Write-Host "note: daemon was offline; ran in -UseCompat mode (in-process fallback)" -ForegroundColor Yellow
        }
        if (-not $status.passed) {
            Write-Host "violations:" -ForegroundColor Yellow
            $status.violations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        }
    }
    Write-Output $stdout
    if (-not $status.passed) { exit 2 }
    if ($status.degraded) { exit 3 }
    exit 0
}
finally {
    Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $statusPath -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "$tmp.out" -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "$tmp.err" -ErrorAction SilentlyContinue
}
