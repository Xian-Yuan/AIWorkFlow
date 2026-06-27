# Execution Prompt

## Role

Implement Agent for Jinli runtime infrastructure. You execute the approved daemon-first architecture after the lead has passed Plan gates and obtained edit authorization.

## Goal

Build a unified local Jinli runtime system where a Python Runtime Daemon is the single authority for service lifecycle, state, turn orchestration, health, and extension points. MCP servers and IDEs must become adapters that call this daemon instead of owning separate runtime logic.

## Task Packet Truth Sources

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/routing.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/doc-impact.md`
- `Project/Jinli/docs/03-Architecture/runtime-enforcement-layer.md`
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`

## Confirmed Decisions

- Python Runtime Daemon is the selected single authority.
- MCP is an adapter surface for IDE clients.
- Existing MCP tool names must remain stable.
- PowerShell and JSON remain compatibility layers during migration.
- Codex, OpenCode, Trae, and future MCP clients must be supported from one registry.
- Service degradation must be explicit in health output and turn evidence.

## Accepted Architecture

Implement a daemon-first architecture:

```text
IDE client
  -> generated MCP config
  -> Jinli MCP Adapter
  -> daemon client
  -> Python Runtime Daemon
  -> service registry
  -> EventBus, MemoryService, Dreamer, Evolution, Proactive, Emotion, Relationship, TurnOrchestrator
  -> SQLite/event logs/persona config/compatibility mirror
```

The daemon owns service lifecycle and state authority. MCP handlers must preserve their tool contracts while delegating to the daemon client. Compatibility fallback must be visible and testable.

## Allowed Paths

- `Project/Jinli/services/runtime/`
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/memory/`
- `Project/Jinli/services/nervous/`
- `Project/Jinli/services/evolution/`
- `Project/Jinli/services/proactive/`
- `Project/Jinli/services/persona/`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/`
- `.trae/scripts/jinli-system.ps1`
- `.trae/scripts/jinli-ide-sync.ps1`
- `.trae/scripts/validate-codex-capabilities.ps1`
- `.opencode/mcp.json`
- `opencode.json`
- `C:/Users/87372/.codex/config.toml`
- `Project/Jinli/docs/`
- `Project/Jinli/Docs/`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`
- `AGENTS.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/verification-report.md`

## Forbidden Paths

- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/contract-verify.ps1`
- `.trae/scripts/task-packet-seal.ps1`
- Any existing production data deletion path under `Project/Jinli/data/`
- Any Git reset, checkout, force push, or history rewrite operation
- Any credential file or secret-bearing config beyond the exact MCP registration fields required for local tool discovery

## Non-Goals

- Do not implement voice, avatar, WeChat, mobile, local LLM router, or UE editor control.
- Do not remove `soul-core.ps1`.
- Do not delete JSON compatibility files.
- Do not introduce cloud hosting.
- Do not create a per-IDE daemon.
- Do not bypass MIRP evidence rules.

## Acceptance Criteria

- AC01: `jinli-system.ps1 start` starts exactly one daemon instance and records PID, endpoint, and log paths.
- AC02: `jinli-system.ps1 status` reports daemon state and per-service health for EventBus, MemoryService, Dreamer, Evolution, Proactive, Emotion, Relationship, TurnOrchestrator, and MCP adapter.
- AC03: `jinli-system.ps1 stop` stops the daemon cleanly and leaves no stale PID lock.
- AC04: A direct daemon call can run a standard runtime turn through TurnOrchestrator and returns a manifest with evidence records.
- AC05: Existing MCP tool names remain available and call the daemon path.
- AC06: `soul_status`, `soul_memory`, and `response_plan` use daemon-owned state or declared compatibility mirrors.
- AC07: Codex, OpenCode, and Trae config generation is driven by one registry and produces or validates consistent MCP settings.
- AC08: Codex capability inspection no longer reports `jinli-soul-core@personal` as available but not installed/enabled after sync.
- AC09: Legacy `soul-core.ps1 check` still works or explicitly reports daemon compatibility mode.
- AC10: JSON compatibility files are preserved and not deleted.
- AC11: Service degradation is visible in health output and runtime manifests.
- AC12: Automated tests cover daemon lifecycle, service registry health, daemon client, MCP adapter, IDE sync, and legacy compatibility.
- AC13: Documentation explains the single-authority runtime contract, extension process, and IDE onboarding.
- AC14: Existing runtime tests under `Project/Jinli/services/runtime/tests/` still pass.
- AC15: The selected mature path is implemented without reintroducing split-engine shortcuts.

## Verification Commands

Run and record all relevant outputs in `verification-report.md`:

```powershell
python -m pytest Project/Jinli/services/runtime/tests/ -v
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 start
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 status -Json
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 doctor
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-runtime-turn.ps1 -Mode standard -UserInput "health test" -Task chat -JsonOnly
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-ide-sync.ps1 check -Ide all
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect
powershell -NoProfile -ExecutionPolicy Bypass -File Project\Jinli\scripts\soul-core.ps1 -Command check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-27-runtime-daemon-unified-ide verify
```

If any command does not exist yet because it is part of this implementation, create it before claiming the related task is done.

## Stop Conditions

- Stop if Plan gate or can-edit gate has not passed.
- Stop if implementing the mature daemon path becomes impossible without a quality exception.
- Stop if a required service cannot be safely started and no degraded state contract exists.
- Stop before deleting any data file.
- Stop before changing workflow gate scripts.
- Stop if Codex/OpenCode/Trae config changes require secrets or credentials.

## Evidence Rule

Every acceptance criterion must be backed by command output, test output, or file diff evidence. Verbal claims are not enough. Any degraded service or fallback path must be named explicitly in the verification report.
