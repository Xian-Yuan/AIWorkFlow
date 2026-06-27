# WP03 Runtime API Turn Client

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP03-runtime-api-turn-client
- Owner: unassigned worker
- Phase: implement after WP01 and WP02 provide daemon and registry contracts
- Claim file: `claims/WP03-runtime-api-turn-client.claim.json`

## Allowed Paths

- `Project/Jinli/services/runtime/**`
- `Project/Jinli/runtime/**`
- `Project/Jinli/scripts/**`
- `Project/Jinli/tests/**`
- `.trae/scripts/jinli-runtime-turn.ps1`
- `.trae/scripts/jinli-system.ps1`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP03-runtime-api-turn-client.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP03-runtime-api-turn-client.md`

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

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md`
- `Project/Jinli/runtime/**`
- `Project/Jinli/services/runtime/**`
- `.trae/scripts/jinli-runtime-turn.ps1`

## Goal

Route one standard conversation turn through the durable daemon and return a manifest that proves which services participated and which ones degraded.

## Steps

1. Inspect the current one-turn runtime command and TurnOrchestrator integration.
2. Define a small local runtime API for status, health, turn, memory query, learn, and response planning.
3. Implement Python client code for local callers.
4. Update PowerShell turn wrapper so it prefers daemon-backed calls and reports fallback status only when fallback is intentionally used.
5. Ensure turn output includes response payload plus service evidence, memory evidence, emotion or relationship evidence when available, and degraded reasons when not available.
6. Add tests for successful turn, degraded turn, and missing daemon behavior.

## Done Definition

- A local command can send a turn to the daemon and receive structured JSON.
- Turn requests pass through the runtime orchestration layer, not direct JSON-only emotion or memory files.
- Missing optional services are visible as degraded evidence.
- Missing required daemon is a clear error unless an explicit compatibility fallback was requested.

## Required Verification

- `python -m pytest Project/Jinli/services/runtime/tests/ -v`
- `python -m pytest Project/Jinli/tests/ -v`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-runtime-turn.ps1 -Text "health probe" -Json`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 doctor`

## Return Report

- Path: `reports/WP03-runtime-api-turn-client.md`
- Include API summary, sample JSON shape, changed files, command output, and unresolved runtime contract questions.
