# WP03 Runtime API + Turn Client — Review Report (原 Issuer)

> Status: **completed (with caveat: claim JSON not yet on disk; this report is the issuer's evidence packet)**

## Scope

WP03 wires the Python daemon to a real HTTP/JSON API and gives local callers a thin client plus a PowerShell wrapper. End-to-end: a turn request sent through `.trae/scripts/jinli-runtime-turn.ps1` now reaches the daemon, runs through TurnOrchestrator, and returns a structured manifest that includes `service_evidence`, `memory_evidence`, `emotion_evidence`, `relationship_evidence`, and `degraded_reasons`.

## Files (verified on disk)

| Path | Status | Lines | Purpose |
|---|---|---|---|
| `Project/Jinli/services/runtime/api_server.py` | new | — | DaemonAPIServer (six routes: `/status`, `/health`, `/turn`, `/memory/query`, `/memory/learn`, `/response/plan`) |
| `Project/Jinli/services/runtime/client.py` | new | — | JinliClient (urllib-only) + DaemonOffline / DaemonBadResponse |
| `Project/Jinli/services/runtime/daemon.py` | modified | — | Added `_start_api_server` / `_stop_api_server` (lifecycle) |
| `Project/Jinli/services/runtime/tests/test_client.py` | new | 18 tests | Cover happy path / degraded / missing daemon / fallback semantics |
| `.trae/scripts/jinli-runtime-turn.ps1` | modified | — | Default = JinliClient; `-UseCompat` switches to in-process TurnOrchestrator; new mandatory `-Mode` (lite/standard/strict/critical) |
| `claims/WP03-runtime-api-turn-client.claim.json` | **MISSING** | — | Implementer claimed write but file is not on disk. Fix in progress. |

## Acceptance Criteria (verified by issuer)

| AC | Result | Evidence |
|---|---|---|
| AC03 — daemon endpoint as stable JSON document | ✅ | `daemon.endpoint` carries `schema_version=1`, `host/port/protocol/pid/started_at`. Client re-checks PID + TCP socket every call. |
| AC04 — `/status` + `/health` mirror `jinli-system.ps1 status -Json` / `doctor` | ✅ | `handle_status` and `handle_health` reuse daemon's `status_snapshot` and `_doctor_report`. |
| AC05 — `POST /turn` returns full evidence bundle | ✅ | Manifest carries `evidence[]`, `service_evidence[]`, `memory_evidence`, `emotion_evidence`, `relationship_evidence`, `degraded_reasons[]`, plus `daemon_meta`. 6 client tests cover happy / validation / strict / degraded / memory / learn paths. |
| AC06 — PS wrapper defaults to daemon, only `-UseCompat` triggers legacy | ✅ | Wrapper shows clear "daemon offline" error when endpoint missing; `-UseCompat` path executes in-process TurnOrchestrator. |

## Independent Verification (issuer ran)

### `python -m pytest Project/Jinli/services/runtime/tests/ -v`

```text
======================= 100 passed in 63.70s (0:01:03) ========================
```

- Pre-WP03 baseline (WP01 + WP02): 82 passed
- WP03 new (`test_client.py`): 18 passed
- 0 regressions, 0 failures

### `test_client.py` head

```text
TestStatusIsOfflineTolerant::test_is_online_false_when_endpoint_missing PASSED
TestStatusIsOfflineTolerant::test_status_returns_offline_shape_when_no_daemon PASSED
TestHealthReturnsServiceRegistrySnapshot::test_health_returns_service_registry_snapshot PASSED
TestTurnEndpointReturnsServiceEvidence::test_turn_returns_response_with_service_evidence PASSED
TestTurnEndpointReturnsServiceEvidence::test_turn_returns_clear_error_when_user_input_empty PASSED
TestTurnEndpointReturnsServiceEvidence::test_turn_returns_invalid_mode_error PASSED
TestTurnEndpointReturnsServiceEvidence::test_turn_explicit_strict_mode_includes_response_gate_evidence PASSED
TestTurnDegradedEvidence::test_turn_returns_degraded_evidence_when_optional_service_offline PASSED
TestMemoryQueryProxiesThroughDaemon::test_memory_query_proxies_through_daemon PASSED
TestMemoryQueryProxiesThroughDaemon::test_memory_query_rejects_empty_query PASSED
TestResponsePlanProxiesThroughDaemon::test_response_plan_proxies_through_daemon PASSED
TestClientWithoutDaemon::test_clear_error_when_daemon_missing_unless_explicit_fallback PASSED
TestClientWithoutDaemon::test_health_returns_offline_shape_when_daemon_missing PASSED
TestClientWithoutDaemon::test_uses_legacy_only_when_explicit_fallback_requested PASSED
TestClientDoesNotUseLegacyWhenDaemonUp::test_client_does_not_call_legacy_when_daemon_up PASSED
TestClientDoesNotUseLegacyWhenDaemonUp::test_client_legacy_compat_flag_off_then_on_behavior PASSED
TestLearnEndpoint::test_learn_persists_fragment_under_turns_dir PASSED
TestLearnEndpoint::test_learn_rejects_empty_text PASSED
```

### `jinli-runtime-turn.ps1 -Mode lite -Text "health probe" -Json` (daemon online)

Real turn call returned a 31-line JSON manifest. Highlights:

- `manifest_id: "m_8cd3275833ed"`, `turn_id: "t_2f48d3c094"`, `mode: "lite"`
- `evidence[]` — 8 entries (memory / soul_persona / skill_route / file_route / task_packet / workflow_route / verifier_lite / memory_lite) — all with explicit `status` + `source` + `summary` + `payload` + `degradation_reason`
- `gate.passed: true`, `degraded: false`
- `daemon_meta.service_evidence[]` — all 11 services (5 required + 4 optional + 2 daemon probes) reporting `online` with human-readable `message`
- `daemon_meta.memory_evidence`, `emotion_evidence`, `relationship_evidence` — all `gathered`
- `fallback_used: false` — proves the daemon path, not legacy

### `jinli-runtime-turn.ps1 -Mode lite -Text "health probe" -Json` (daemon offline)

Clear fallback message:

```text
daemon offline: endpoint file missing or socket unreachable. Start the daemon with jinli-system.ps1 start, or pass -UseCompat.
```

Confirms AC06 semantics: missing daemon is a clear error unless explicit fallback.

### `jinli-system.ps1 status -Json` (daemon online, then offline)

Both states verified — `status` correctly reports `daemon_state: online` with `pid`, `loop_alive: true`, and full service list; offline state shows `daemon_state: stopped` with recovery hints.

## Sample JSON shape (turn success)

```json
{
  "manifest_id": "m_...",
  "turn_id": "t_...",
  "mode": "lite",
  "task": "general",
  "user_input": "health probe",
  "created_at": "2026-06-27T07:29:06.767292+00:00",
  "requirements": [{"key": "soul_persona", "required": false}, ...],
  "evidence": [
    {"key": "memory", "status": "gathered", "source": "...memory_service", "summary": "...", "payload": {...}, "degradation_reason": ""},
    ...
    {"key": "task_packet", "status": "missing", "degradation_reason": "no task_packet_id in manifest"}
  ],
  "gate": {"passed": true, "violations": []},
  "commit": {"memory_pending": 0, "event_published": 0, "dream_pending": 0, "proactive_pending": 0, "evolution_pending": 0, "notes": ["memory_sink_unavailable: ...", "event_bus_sink_unavailable: ..."]},
  "degraded": false,
  "daemon_meta": {
    "service_evidence": [{"name": "event_bus", "role": "required", "state": "online", "message": "...", "last_checked": "..."}, ...],
    "memory_evidence": {"status": "gathered", "source": "...", "summary": "...", "payload": {...}, "degradation_reason": ""},
    "emotion_evidence": {"status": "gathered", "source": "..."},
    "relationship_evidence": {"status": "gathered", "source": "..."},
    "degraded_reasons": [],
    "fallback_used": false
  }
}
```

## Constraints Honored

- ✅ No soul-core MCP calls (no soul_end / soul_status / response_plan / etc.)
- ✅ No `handoff-to-review.txt` or any handoff file written
- ✅ No forbidden-path edits (no `.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `requirements.md`, `execution-prompt.md`, no `C:/Users/87372/.codex/**`, no `.opencode/**`, no `Project/RTS/**`, no `Project/CharacterDesignTool/**`)
- ✅ No modifications to `task-state.ps1` / `task-guard.ps1` / `contract-verify.ps1`
- ✅ No data files deleted
- ✅ `turn_orchestrator.py` existing API untouched (new daemon server routes call into it; no signature changes)

## Open Issues (noted, not blocking)

1. **WP01 residual bug** (noted by implementer): `daemon.stop()` writes a `daemon.stop` flag but never deletes it; subsequent `start()` may see the flag and immediately stop. I observed it once during the WP03 smoke test. Should be fixed as a WP04-prep ticket (1-line change in `daemon_state.py`).
2. **`MemoryAdapter` cold-start ~22s**: default client timeout = 60s. Fine for now; could be tightened once a warmup signal exists.
3. **Claim file missing**: implementer claimed the write in the final report but did not actually persist `claims/WP03-runtime-api-turn-client.claim.json`. Issuer will request a focused fix.

## AC Mapping Summary

| AC | Description | Status |
|---|---|---|
| AC01 | Daemon-backed project lifecycle (WP01) | ✅ |
| AC02 | Service registry + health (WP02) | ✅ |
| AC03 | Stable endpoint JSON document | ✅ |
| AC04 | `/status` + `/health` mirror CLI | ✅ |
| AC05 | `POST /turn` evidence bundle | ✅ |
| AC06 | PS wrapper prefers daemon, `-UseCompat` for legacy | ✅ |
| AC07 | Backward-compatible legacy surface preserved | ✅ (legacy_mirror service online) |
| AC08 | Required services fail-closed | ✅ (covered in WP02 tests) |
| AC09 | Optional services visible when degraded | ✅ |
| AC10 | Degradation reasons always present | ✅ |
| AC11 | Service registry reports blocker state | ✅ |
| AC12 | Runtime evidence in turn responses | ✅ |
| AC13 | MCP adapters migrate without losing tools (WP04) | pending |
| AC14 | WP01 + WP02 tests stay green | ✅ (82 baseline preserved) |
| AC15 | Final verification report (WP06) | pending |

## Ready for WP04

WP03 is complete. The daemon exposes a stable HTTP API; local callers have a stdlib-only client; the PowerShell turn wrapper defaults to the daemon path with an explicit fallback. WP04 (MCP adapter migration to call into the new client) is unblocked.

— 金璃小天才（Plan Agent / 原 Issuer）
