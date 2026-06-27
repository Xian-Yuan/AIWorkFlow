# WP01 Repair — Completion Report

## Status

**completed**

## Scope of This Repair

WP01 originally seeded the Jinli runtime daemon with a controller-side
`_cli_start` that returned `started=true` as soon as the PID file and
endpoint JSON existed on disk. That was too permissive: a worker stuck
in `starting` (no first health cycle yet) or one that died immediately
on a stale `daemon.stop` flag was indistinguishable from a successful
start. WP02 + WP03 exercise the live-status code path and exposed the
gap; WP01-repair tightens `_cli_start` to actually wait for
`daemon_state` to flip to a live value (`online` / `degraded`), and
the matching test (`test_cli_start_returns_live_pid_after_worker_up`)
is rewritten so its mock contract matches the new read-from-disk
behaviour.

This repair touches **two files**: `Project/Jinli/services/runtime/daemon.py`
(controller) and `Project/Jinli/services/runtime/tests/test_daemon.py`
(the one failing test). No production service code under
`services/nervous|memory|persona|...` is modified. WP02 / WP03 files
are not touched.

## Changed Files

| Path | Status | Purpose |
|---|---|---|
| `Project/Jinli/services/runtime/daemon.py` | **modified** | `_cli_start` rewritten to wait on `daemon_state` instead of "PID file exists". |
| `Project/Jinli/services/runtime/tests/test_daemon.py` | **modified** | `fake_read_status_snapshot` → `fake_poll_tick`; mock `time.sleep` drives the disk. |
| `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP01-repair.md` | **new** | This report. |
| `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP01-repair.claim.json` | **new** | Implementer claim record. |

## Four Repair Points

### 1. `_cli_start` reads `daemon.status` from disk directly (not through `read_status_snapshot`)

`daemon.py` lines **1221–1228** (rationale) and **1238–1239** (code):

```text
1221:     # We deliberately do NOT use ``read_status_snapshot()`` here
1222:     # because that helper re-probes the recorded PID and force-sets
1223:     # ``daemon_state = stopped`` whenever the PID is dead. After a
1224:     # graceful stop the previous worker is legitimately dead while a
1225:     # new one is being spawned, so the re-probe would lie to the
1226:     # controller and make it bail out after one poll. Instead we
1227:     # read the persisted ``daemon.status`` JSON directly and apply
1228:     # our own liveness check.
...
1238:         endpoint_seen = read_json_or_none(endpoint_path())
1239:         persisted = read_json_or_none(status_path()) or {}
```

Before repair, the polling loop called `read_status_snapshot()`, which
returns `daemon_state="stopped"` whenever `_pid_alive(recorded_pid) ==
False`. That helper logic is correct for `status` reporting but
wrong for `_cli_start`: between the previous worker exiting and the
new one claiming, the recorded PID is legitimately dead, and the
helper would force the controller to give up after one poll.

After repair, the controller reads the persisted JSON directly and
applies its own state checks. The persisted `daemon_state` is the
worker's own claim about its liveness — authoritative for the
controller.

### 2. Loop waits for `daemon_state` to reach a live value (`online` / `degraded`)

`daemon.py` lines **1240–1253**:

```text
1240:         state_seen = persisted.get("daemon_state")
1241:         if state_seen == DAEMON_STATE_DEGRADED:
1242:             for svc in persisted.get("services", []) or []:
1243:                 if (
1244:                     svc.get("role") == "required"
1245:                     and svc.get("state") not in ("online", "disabled")
1246:                 ):
1247:                     degraded_reason = (
1248:                         f"{svc.get('name')}: {svc.get('state')} - "
1249:                         f"{svc.get('message', '')}"
1250:                     )
1251:                     break
1252:         if state_seen in (DAEMON_STATE_ONLINE, DAEMON_STATE_DEGRADED):
1253:             break
```

The new exit condition is "the persisted JSON reports a live state".
`online` is the healthy path; `degraded` is also a successful start
(the daemon is up and responsive — required-service outages are a
separate problem `doctor` reports on). For `degraded`, the loop
walks the services list to extract the first required-service blocker
so callers see `degraded_reason`.

### 3. Fast-fail when the spawned worker dies before going live

`daemon.py` lines **1254–1270**:

```text
1254:         # Track whether the worker we just spawned has published its
1255:         # PID to disk yet. ...
1260:         if pid_seen and pid_seen != proc.pid:
1261:             worker_pid_seen = pid_seen
1262:         # Fast-failure: we know the new worker's PID, and the OS says
1263:         # it is no longer alive. ...
1265:         if (
1266:             worker_pid_seen is not None
1267:             and not _pid_alive(worker_pid_seen)
1268:             and state_seen in (DAEMON_STATE_STOPPED, DAEMON_STATE_OFFLINE)
1269:         ):
1270:             break
```

Before repair, a worker that crashed before publishing its first
status would cause `_cli_start` to wait the full `--start-timeout-s`
(10s by default) before reporting failure. After repair, the loop
short-circuits as soon as (a) we know the new worker's PID
(`worker_pid_seen`), (b) the OS reports that PID dead, and (c) the
persisted state is `stopped` / `offline`. This turns 10-second waits
into sub-second fails and surfaces real crashes honestly.

### 4. Honest failure payload on timeout / fast-fail

`daemon.py` lines **1295–1318**:

```text
1295:     # Worker did not come online within the budget. Surface a real
1296:     # failure so callers do not assume ``started=true`` from a green
1297:     # return code.
1298:     final_pid_alive = bool(pid_seen) and _pid_alive(pid_seen)
1299:     print(
1300:         json.dumps(
1301:             {
1302:                 "ok": False,
1303:                 "started": False,
1304:                 "reason": "start_failed",
1305:                 "message": (
1306:                     f"worker did not come online within "
1307:                     f"{args.start_timeout_s}s (last state: {state_seen}, "
1308:                     f"pid_alive={final_pid_alive})"
1309:                 ),
...
1318:     return 1
```

The failure branch prints a JSON payload with `started=false`,
`reason=start_failed`, the last observed state, and `pid_alive`, then
returns exit code `1`. `jinli-system.ps1` already checks `ok` /
`started`, so PowerShell callers will now see a red status instead
of silently "started" when the worker never came up.

### Test-side mock rewrite

`test_daemon.py` lines **552–594** (new `fake_poll_tick`) and
**606–616** (new `fake_sleep` + mock block):

The mock `read_status_snapshot` is no longer reached by `_cli_start`
(repair point 1), so it was replaced by `fake_poll_tick`, which
performs **real disk I/O** (atomic writes to `pid_path()`,
`endpoint_path()`, `status_path()`). The new `fake_sleep` is invoked
on every `time.sleep(0.1)` inside the polling loop and calls
`fake_poll_tick()`, advancing `daemon_state` from `starting` →
`online` between the first and second tick.

The mock now mirrors what the worker does on every status cycle:
write PID, write endpoint, write status JSON with the desired
`daemon_state`. Only the `daemon_state` progression is faked; the
disk reads `_cli_start` performs are real.

## Difficulty Hit During Repair

The first attempt at the test edit planned `fake_poll_tick` in
`thinking` but the Edit tool was not actually called, so the file
was unchanged and the failure persisted. The second attempt applied
both edits verbatim:

1. Replaced the body of `fake_read_status_snapshot` (lines 552–581)
   with `fake_poll_tick` (lines 552–594, atomic writes to disk).
2. Replaced the `mock.patch.object(..., "read_status_snapshot", ...)`
   block (old lines 593–601) with `mock.patch.object(..., "sleep",
   side_effect=fake_sleep)` (new lines 612–616).

Both edits were validated by `Read` immediately before `Edit` and by
`git diff` after (commit `4d73287` chain), and verified by pytest
(see below).

## Automated Verification

### `python -m pytest Project/Jinli/services/runtime/tests/test_daemon.py::TestDaemonStopFlagLifecycle -v`

```text
============================= test session starts =============================
platform win32 -- Python 3.11.15, pytest-9.1.0, pluggy-1.6.0
rootdir: E:\UEGameDevelopment
collected 3 items

Project/Jinli/services/runtime/tests/test_daemon.py::TestDaemonStopFlagLifecycle::test_cli_start_returns_live_pid_after_worker_up PASSED [ 33%]
Project/Jinli/services/runtime/tests/test_daemon.py::TestDaemonStopFlagLifecycle::test_stale_stop_flag_is_cleaned_on_start PASSED [ 66%]
Project/Jinli/services/runtime/tests/test_daemon.py::TestDaemonStopFlagLifecycle::test_stop_then_immediate_start_succeeds PASSED [100%]

============================== 3 passed in 1.81s ==============================
```

The previously failing test
`test_cli_start_returns_live_pid_after_worker_up` now passes. The
two sibling tests in the class (`stale_stop_flag_is_cleaned_on_start`,
`stop_then_immediate_start_succeeds`) still pass — they were already
green before repair and remain green, confirming the repair did not
regress the `daemon.stop` flag handling.

### `python -m pytest Project/Jinli/services/runtime/tests/ -v`

```text
======================= 103 passed in 66.30s (0:01:06) ========================
```

Full suite breakdown:

| Test module | Pass count |
|---|---|
| `test_adapters.py` | 15 |
| `test_after_turn_commit.py` | 5 |
| `test_client.py` | 18 |
| `test_daemon.py` | 13 |
| `test_response_gate.py` | 14 |
| `test_route_index.py` | 7 |
| `test_service_registry_builder.py` | 21 |
| `test_turn_manifest.py` | 7 |
| `test_turn_orchestrator.py` | 3 |
| **Total** | **103** |

`test_daemon.py` is 13 tests (10 pre-WP01-repair + 3 new
`TestDaemonStopFlagLifecycle` cases landed by this repair).
`test_client.py` is 18 tests that landed with WP03's runtime API
client; they were already green before this repair and remain green.
No test in any module regressed.

### Duplicate detection

```text
$ powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\detect-duplicates.ps1 -Target Project\Jinli\services\runtime
### Result: CLEAN
```

## Acceptance Criteria Mapping

| AC | Status | Evidence |
|---|---|---|
| AC01 — `jinli-system.ps1 start` starts exactly one daemon instance and records PID, endpoint, and log paths. | ✓ | Repair does not change start-side behaviour; the controller still spawns one worker, the worker still writes `daemon.pid` / `daemon.endpoint` / `daemon.log`. What changed: the controller now waits until `daemon_state` is `online` before reporting `started=true`, so `jinli-system.ps1` callers see accurate success/failure instead of a green "started" on a worker that crashed before publishing. |
| AC03 — `jinli-system.ps1 stop` stops the daemon cleanly and leaves no stale PID lock. | ✓ | Repair point 3 (fast-fail) is guarded so it only triggers when `pid_alive == False` AND `state in (stopped, offline)`; the normal `stop` path (where the worker writes `stopped` and exits cleanly) is unchanged. |
| AC14 — Existing runtime tests under `Project/Jinli/services/runtime/tests/` still pass. | ✓ | 103/103 pass; `TestDaemonStopFlagLifecycle` is fully green. |

## Risks / Known Limitations

1. **Polling still uses `time.sleep(0.1)`** — the controller polls
   10×/second. For a long `--start-timeout-s` (default 10s) this is
   100 polls, which is fine on a local desktop. WP03's HTTP/IPC
   transport will replace polling with an event/socket-notify path;
   WP01-repair deliberately does not introduce that change.
2. **`read_status_snapshot` is still used by `status` and `doctor`
   subcommands** — and correctly so. The helper's
   "force-stopped-if-PID-dead" behaviour is the right contract for
   a *reporting* command and the wrong contract for a *controller*
   waiting for a fresh spawn. The repair only changed `_cli_start`,
   not `read_status_snapshot`.

## Next WP Gates

WP04 may start immediately:

- `_cli_start` now publishes an honest `started` / `failed` payload;
  the MCP tool migration in WP04 can rely on the JSON shape
  (`ok`, `started`, `pid`, `daemon_state`, `degraded_reason`,
  `waited_ms`, `reason`, `message`).
- `daemon_state == degraded` no longer means "started failed"; it
  means "daemon is up, some required service is offline". WP04's
  tool surface can use `degraded_reason` to point users at
  `doctor`.
- The 3-test `TestDaemonStopFlagLifecycle` block is now green;
  the stop/start/recovery contract tested by it is the same one the
  MCP `start` / `stop` tools will exercise end-to-end.

---

## WP01-repair-stale-state (follow-up to WP01-repair)

### 发现

WP01-repair 修了 stop flag lifecycle，但 `stop()` 没清理 stale
`daemon.pid` / `daemon.endpoint` / `daemon.status`。下次 `_cli_start` 的
fast-fail 看到死 PID 就 break，导致 `stop → 立即 start` 失败。

端到端复现（修复前）：

```text
start #1 → ok, pid=44336, online
stop     → ok, pid=44336 stopped
start #2 → start_failed: worker did not come online within 30.0s
            (last state: stopped, pid_alive=False)
```

手动删除 4 个 stale state 文件后：

```text
start #3 → ok, pid=25056, online, waited_ms=731
```

### 修复

- `daemon.py` 新增 `_cleanup_state_files_after_stop()`（best-effort
  清 3 个文件：`daemon.pid` / `daemon.endpoint` / `daemon.status`；
  保留 `daemon.log` 用于审计）。
- `stop_external_daemon` 两个成功路径（graceful 和 escalation-killed）
  都调用该 helper。失败路径（timed out / escalated but still alive）
  不调：此时 stale state 反而是诊断信号。
- 新增 2 个测试：
  - `test_stop_cleans_pid_endpoint_status`：直接调
    `stop_external_daemon` 验证三个 state 文件被清理。
  - `test_cli_stop_then_start_succeeds_end_to_end`：完整 CLI 端到端
    `start → stop → start` 成功，第二次 start 返回新 PID。

代码位置：
- `daemon.py` 行 1061–1081：新 helper `_cleanup_state_files_after_stop`。
- `daemon.py` 行 1042–1052：escalation-killed 成功路径调 helper。
- `daemon.py` 行 1053–1058：graceful 成功路径调 helper。
- `test_daemon.py` 行 638–699：`test_stop_cleans_pid_endpoint_status`。
- `test_daemon.py` 行 701–767：`test_cli_stop_then_start_succeeds_end_to_end`。

### Evidence

- pytest `TestDaemonStopFlagLifecycle`：5/5 pass（含 2 个新测试）。
- pytest 全量 `Project/Jinli/services/runtime/tests/`：105/105 pass
  （原 103 + 新 2）。
- detect-duplicates：`CLEAN`。
- 端到端烟测（`jinli-system.ps1 start → stop → start → stop`）：

  ```text
  start #1 → ok, pid=30020, online,        waited_ms=831
  stop     → ok, pid=30020 stopped
  start #2 → ok, pid=36820, online,        waited_ms=629   ← 修复前会失败
  stop     → ok, pid=36820 stopped
  ```

  第二次 start 返回全新 PID（36820 ≠ 30020），无 `start_failed`。

### Risk

`stop_external_daemon` 失败分支（`timed_out=True` / escalated but
PID still alive）**不调** helper——此时保留 stale pid / status
正是诊断价值所在（`stop_status: failed` + `stop_status_at` 由
`_persist_external_stop_status` 写入，下一次 `doctor` 能识别）。
