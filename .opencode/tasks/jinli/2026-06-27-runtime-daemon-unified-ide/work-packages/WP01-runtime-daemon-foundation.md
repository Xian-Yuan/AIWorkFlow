# WP01 Runtime Daemon Foundation

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP01-runtime-daemon-foundation
- Owner: unassigned worker
- Phase: implement after lead plan gate approval
- Claim file: `claims/WP01-runtime-daemon-foundation.claim.json`

## Allowed Paths

- `Project/Jinli/services/runtime/**`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/runtime/tests/**`
- `.trae/scripts/jinli-system.ps1`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP01-runtime-daemon-foundation.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP01-runtime-daemon-foundation.md`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/.task.yaml`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/routing.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/execution-prompt.md`
- `C:/Users/87372/.codex/**`
- `C:/Users/87372/plugins/jinli-soul-core/**`
- `.opencode/**`
- `Project/RTS/**`
- `Project/CharacterDesignTool/**`

## Read First

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `Project/Jinli/docs/03-Architecture/runtime-enforcement-layer.md`
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/jinli_service.py`

## Goal

Create the daemon lifecycle foundation that lets the Jinli Python service layer run as a durable local authority instead of a one-turn script or disconnected background idea.

## Steps

1. Inspect existing runtime and daemon code before editing.
2. Add or refine a single-instance daemon entrypoint with PID, endpoint, lock, log, and stale-lock recovery behavior.
3. Expose lifecycle operations needed by local callers: start, stop, status, and doctor.
4. Add `.trae/scripts/jinli-system.ps1` as the user-facing lifecycle wrapper.
5. Keep daemon state files under an explicit runtime directory and avoid deleting existing Soul Core JSON files.
6. Add focused tests for clean start, duplicate start, status response, stop, and stale lock recovery.

## Done Definition

- `jinli-system.ps1 status` can distinguish offline, starting, online, degraded, and failed states.
- Duplicate start does not create a second daemon instance.
- Stop is graceful when possible and reports the final state.
- Stale lock recovery is tested.
- No legacy JSON state is removed or overwritten by daemon lifecycle code.

## Required Verification

- `python -m pytest Project/Jinli/services/runtime/tests/ -v`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 status`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 doctor`

## Return Report

- Path: `reports/WP01-runtime-daemon-foundation.md`
- Include changed files, commands run, command results, known risks, and any follow-up needed from the lead.
