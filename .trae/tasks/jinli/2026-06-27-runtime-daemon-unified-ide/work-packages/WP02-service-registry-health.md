# WP02 Service Registry And Health

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP02-service-registry-health
- Owner: unassigned worker
- Phase: implement after WP01 daemon foundation is available
- Claim file: `claims/WP02-service-registry-health.claim.json`

## Allowed Paths

- `Project/Jinli/services/runtime/**`
- `Project/Jinli/services/evolution/**`
- `Project/Jinli/services/memory/**`
- `Project/Jinli/services/nervous/**`
- `Project/Jinli/services/persona/**`
- `Project/Jinli/services/proactive/**`
- `Project/Jinli/services/knowledge/**`
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/runtime/tests/**`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP02-service-registry-health.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP02-service-registry-health.md`

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
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/runtime/**`
- `Project/Jinli/services/memory/**`
- `Project/Jinli/services/persona/**`
- `Project/Jinli/services/proactive/**`
- `Project/Jinli/services/evolution/**`

## Goal

Create a runtime service registry that makes EventBus, memory, dreamer, evolution, proactive, emotion, relationship, turn orchestration, and compatibility mirror services visible through one health model.

## Steps

1. Inspect existing service constructors, async lifecycle hooks, and current test patterns.
2. Define a service descriptor with id, required flag, dependencies, lifecycle hooks, capabilities, status, degraded reason, and last error fields.
3. Register services in dependency order.
4. Make startup resilient: optional service failure degrades the daemon, required service failure blocks readiness.
5. Add health aggregation for daemon status and per-service status.
6. Add tests for online, degraded, offline, optional failure, required failure, and dependency ordering.

## Done Definition

- The daemon can produce a complete service registry snapshot.
- Required and optional services are treated differently.
- Degraded state includes a clear reason and does not pretend full health.
- Service health output is suitable for MCP status and IDE doctor commands.
- Existing service APIs remain usable by their current direct tests.

## Required Verification

- `python -m pytest Project/Jinli/services/runtime/tests/ -v`
- `python -m pytest Project/Jinli/services/tests/ -v`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 doctor`

## Return Report

- Path: `reports/WP02-service-registry-health.md`
- Include registry shape, changed files, verification output, and any services that could not be fully wired.
