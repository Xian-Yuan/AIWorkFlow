# Tasks: Jinli Runtime Daemon Unified IDE

## T0 Plan Gate

- [ ] T0.1: Ba Ba confirms the selected mature path and quality level.
- [ ] T0.2: Set `.task.yaml` `user_confirmed_plan: true` after explicit confirmation.
- [ ] T0.3: Run `contract-verify.ps1 jinli/2026-06-27-runtime-daemon-unified-ide init -Apply`.
- [ ] T0.4: Run `contract-verify.ps1 jinli/2026-06-27-runtime-daemon-unified-ide verify -Strict`.
- [ ] T0.5: Run `task-guard.ps1 jinli/2026-06-27-runtime-daemon-unified-ide plan`.

## T1 Runtime Daemon Foundation

- [ ] T1.1: Implement a single-instance Python runtime daemon with PID, endpoint, log, and lock handling. Scenario: S01.
- [ ] T1.2: Add `.trae/scripts/jinli-system.ps1 start|stop|status|doctor`. Scenario: S01, S02, S07.
- [ ] T1.3: Add daemon lifecycle tests for start, duplicate start, status, stop, and stale lock recovery. Scenario: S01.

## T2 Service Registry And Health

- [ ] T2.1: Implement service registry with dependency order, start, stop, health, capabilities, and degraded reason fields. Scenario: S02.
- [ ] T2.2: Register EventBus, MemoryService, Dreamer, Evolution, Proactive, Emotion, Relationship, TurnOrchestrator, and legacy mirror services. Scenario: S02.
- [ ] T2.3: Add service health tests for online, degraded, offline, optional, and required service states. Scenario: S02, S07.

## T3 Runtime API And Turn Orchestration

- [ ] T3.1: Implement daemon client API for local Python, PowerShell, and Node callers. Scenario: S03.
- [ ] T3.2: Add turn endpoint or IPC operation that routes standard turns through TurnOrchestrator. Scenario: S03.
- [ ] T3.3: Add manifest and gate evidence tests for successful, degraded, and missing-service turns. Scenario: S03, S07.

## T4 MCP Adapter Migration

- [ ] T4.1: Add daemon-backed handlers for `soul_init`, `soul_auto`, `soul_status`, `soul_memory`, and `response_plan`. Scenario: S04.
- [ ] T4.2: Preserve existing MCP tool names and schemas. Scenario: S04.
- [ ] T4.3: Keep PowerShell fallback for emergency compatibility only, with explicit degraded/fallback status. Scenario: S06, S07.
- [ ] T4.4: Add MCP smoke tests or local smoke script for list-tools and representative calls. Scenario: S04.

## T5 IDE Registry And Sync

- [ ] T5.1: Design and implement a shared IDE registry for Codex, OpenCode, Trae, and generic MCP clients. Scenario: S05.
- [ ] T5.2: Add `.trae/scripts/jinli-ide-sync.ps1 check|apply|doctor -Ide all`. Scenario: S05.
- [ ] T5.3: Ensure Codex capability inspection detects `jinli-soul-core@personal` installed/enabled/runtime callable after sync. Scenario: S05.
- [ ] T5.4: Add rollback/backup behavior for generated IDE config changes. Scenario: S05.

## T6 Legacy Compatibility And Mirror Policy

- [ ] T6.1: Define source-of-truth labels for daemon state, SQLite memory, event logs, JSON compatibility files, and PowerShell CLI. Scenario: S06.
- [ ] T6.2: Preserve `soul-core.ps1 check` compatibility or make it report daemon compatibility mode. Scenario: S06.
- [ ] T6.3: Add compatibility tests proving JSON files are preserved and not deleted. Scenario: S06.

## T7 Documentation

- [ ] T7.1: Update `Project/Jinli/docs/03-Architecture/runtime-enforcement-layer.md` or add a sibling architecture doc for daemon authority. Scenario: S08.
- [ ] T7.2: Update `Project/Jinli/docs/04-Implementation/runtime-protocol.md` with daemon API, lifecycle, and MCP adapter rules. Scenario: S08.
- [ ] T7.3: Add operations runbook for start, stop, status, doctor, IDE sync, and recovery. Scenario: S08.
- [ ] T7.4: Update `Project/Jinli/Docs/DOCS_TREE.md` if the project docs tree exists and doc paths require indexing. Scenario: S08.
- [ ] T7.5: Update `AGENTS.md` or a referenced AI workflow doc only if the runtime contract changes agent entry behavior. Scenario: S08.

## T8 Verification

- [ ] T8.1: Run `python -m pytest Project/Jinli/services/runtime/tests/ -v`. Scenario: S09.
- [ ] T8.2: Run daemon lifecycle verification commands and record outputs. Scenario: S01, S02.
- [ ] T8.3: Run runtime turn command and record manifest evidence. Scenario: S03.
- [ ] T8.4: Run MCP smoke tests and record tool evidence. Scenario: S04.
- [ ] T8.5: Run IDE sync check and Codex capability inspection. Scenario: S05.
- [ ] T8.6: Run legacy `soul-core.ps1 -Command check`. Scenario: S06.
- [ ] T8.7: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T8.8: Run automated verification and record command output in verification-report.md.
- [ ] T8.9: Map implementation result to Acceptance Criteria in verification-report.md.

## Dependency Order

T0 -> T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> T7 -> T8

T4 may start after T3. T5 may start after the daemon endpoint contract is stable. T7 should be updated throughout implementation and finalized before T8.
