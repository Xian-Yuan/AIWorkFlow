# Analysis: Jinli Runtime Daemon Unified IDE

## Architecture Context

### System boundaries

This task concerns the Jinli runtime infrastructure inside E:/UEGameDevelopment. It creates one local runtime owner and connects IDE clients to it through stable adapters.

In scope:

- Python service runtime ownership and lifecycle
- Local daemon process management
- MCP adapter calls
- IDE configuration synchronization
- Health and diagnostics
- Compatibility with existing Soul Core PowerShell and JSON data
- Documentation and verification

Out of scope:

- New companion product features such as voice, avatar, mobile, WeChat, or UE editor control
- Remote deployment
- Deleting or rewriting unrelated project systems

### Dependency map

Current split path:

```text
Codex/OpenCode/Trae
  -> jinli-soul-core MCP Server
  -> soul-cli.mjs
  -> soul-core.ps1
  -> JSON state and legacy memory files

Project/Jinli Python services
  -> JinliService
  -> EventBus, MemoryService, ObsidianSync, AutoRouter, EvolutionService
  -> optional JinliDaemon scheduled work
  -> runtime TurnOrchestrator and AfterTurnCommit
```

Selected target path:

```text
Codex/OpenCode/Trae/Future IDE
  -> generated IDE MCP config
  -> Jinli MCP Adapter
  -> Jinli Runtime Daemon IPC or local HTTP
  -> TurnOrchestrator plus service facade
  -> T3/T4/T7/T8/T9/T12 services
  -> SQLite, event log, persona config, compatibility mirror
```

### Data and state ownership

Long-term authority:

- Conversation and turn evidence: Python runtime manifest and event sinks
- Semantic memory: T4 MemoryService SQLite/FTS5
- Event propagation: T3 EventBus
- Background reflection: T7 DreamerService
- Evolution proposals and approved growth: T8 EvolutionService and existing growth approval rules
- Proactive signals: T9 ProactiveEngine
- Emotion and relationship state: T12 EmotionEngine and RelationshipLedger

Compatibility ownership:

- `Project/Jinli/data/soul-state.json` remains available as a mirror or import source.
- `Project/Jinli/scripts/soul-core.ps1` remains a CLI compatibility adapter during migration.
- MCP tool names remain stable, but their implementation delegates to the daemon.

### Integration points

- Python daemon: new or extended module under `Project/Jinli/services/runtime/daemon` or `Project/Jinli/services/runtime_daemon.py`.
- Local client: shared Python or Node client for MCP and PowerShell scripts.
- MCP adapter: `C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs` and `mcp/lib/**`.
- Start/stop/doctor scripts: `.trae/scripts/jinli-system.ps1`, plus focused helpers if needed.
- IDE registry and sync: `.trae/scripts/jinli-ide-sync.ps1` and a JSON/YAML registry under `.trae/config` or `Project/Jinli/config`.
- Existing MIRP script: `.trae/scripts/jinli-runtime-turn.ps1`.
- Capability validation: `.trae/scripts/validate-codex-capabilities.ps1`.

## Mature Solution Evidence

### Project-local evidence

- `Project/Jinli/services/jinli_service.py` already starts EventBus, Embedder, MemoryService, ObsidianSync, AutoRouter, SelfAssessor, and EvolutionService.
- `Project/Jinli/services/jinli_daemon.py` already defines scheduled background work and health checks.
- `Project/Jinli/services/runtime/` already provides TurnManifest, TurnOrchestrator, ResponseGate, AfterTurnCommit, route index, and adapters.
- `.trae/scripts/jinli-runtime-turn.ps1` already runs one MIRP turn from PowerShell.
- `C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs` already exposes the expected MCP tool names.
- `.opencode/mcp.json` and `opencode.json` already show IDE-side local MCP registration patterns.
- `.codex/capability-baseline.json` already declares `jinli-soul-core@personal` as required, while current inspection shows it is not enabled in the active Codex config.

### Official/framework evidence

- MCP servers are designed as adapters that expose tool contracts over a transport. Keeping MCP as a thin adapter preserves this boundary.
- Windows local process management is best handled with PID files, single-instance locks, explicit start/stop/status commands, log files, and health endpoints.
- SQLite/FTS5 is already the selected local durable memory backend in the project.
- The project's MIRP design states that service existence is not enough; usage must be evidenced per turn through adapters.

### External mature references

- No new external runtime dependency is required for the first implementation. The mature approach is to reuse the existing local Python service layer, Node MCP SDK, SQLite/FTS5, and PowerShell operational scripts.
- If HTTP is used for daemon IPC, use the Python standard library or the smallest existing project-approved dependency. Avoid introducing a web framework unless the implementation clearly needs it.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| A. Python Runtime Daemon as authority, MCP as adapter | Existing `JinliService`, `JinliDaemon`, MIRP runtime | One service owner, extensible, multi-IDE friendly, health-checkable | Requires adapter migration and startup scripts | Selected |
| B. Keep Node MCP as authority and call Python as needed | Existing MCP plugin | Minimal change to IDE tool surface | Leaves lifecycle and Python services secondary; repeats split ownership | Rejected |
| C. Keep PowerShell Soul Core as authority and mirror into Python | Existing `soul-core.ps1` | Preserves legacy behavior | Blocks full T3/T4/T7/T8/T9/T12 integration; JSON remains bottleneck | Rejected |
| D. Per-IDE runtime adapters with separate startup | Existing Codex/OpenCode configs | Easy for one IDE at a time | Causes drift and multiple runtime owners | Rejected |
| E. Cloud-hosted runtime service | Future possible architecture | Cross-device potential | Unneeded for local workspace, adds secrets/network surface | Deferred |

### Rejected shortcuts

- Do not only add `[mcp_servers.jinli_soul_core]` back to Codex config. That fixes one symptom but not the split-engine architecture.
- Do not create a second small MCP server that wraps `jinli-runtime-turn.ps1` while leaving the existing MCP plugin untouched.
- Do not let every IDE launch its own Python daemon.
- Do not make PowerShell scripts write directly to Python service data stores without a daemon-owned API.
- Do not skip health checks and rely on process names.
- Do not mark the task complete just because `soul_check` passes; the full runtime path must be verified.

### Selected mature path

Implement a staged daemon-first runtime architecture:

1. Introduce a single local Python runtime daemon with start/stop/status/doctor behavior.
2. Create a local API or IPC facade for the daemon.
3. Wire core services through a lifecycle registry with health reports.
4. Migrate MCP handlers to call the daemon while preserving tool names.
5. Add IDE config generation and drift detection.
6. Keep legacy PowerShell/JSON as compatibility and mirror surfaces until parity is proven.
7. Verify across direct CLI, daemon health, MCP calls, and multiple IDE config surfaces.

## Service Architecture

### Daemon responsibilities

- Enforce single runtime owner with PID and lock files.
- Start and stop service modules in dependency order.
- Expose health for each module.
- Provide a stable local API for MCP and scripts.
- Route per-turn work through MIRP where required.
- Queue or declare degraded background services instead of silently ignoring failures.
- Own compatibility mirror updates.

### Service registry shape

Each service entry should declare:

- `id`
- `name`
- `start_order`
- `required`
- `dependencies`
- `start()`
- `stop()`
- `health()`
- `capabilities`
- `degraded_reason`

Initial services:

- `event_bus`
- `memory`
- `dreamer`
- `evolution`
- `proactive`
- `persona_emotion`
- `relationship`
- `turn_orchestrator`
- `legacy_mirror`

### Runtime API surface

Minimum daemon API:

- `GET /health`
- `GET /status`
- `POST /turn`
- `POST /soul/init`
- `POST /soul/auto`
- `POST /soul/turn`
- `POST /soul/end`
- `POST /memory/search`
- `POST /learn`
- `POST /evolve`
- `POST /discover`
- `POST /mirror/sync`

If named pipes are chosen instead of HTTP, the same operation names and payloads must remain.

### MCP compatibility surface

MCP tool names must remain stable:

- `soul_init`
- `soul_auto`
- `soul_turn`
- `soul_end`
- `soul_emotion`
- `soul_status`
- `soul_memory`
- `soul_learn`
- `soul_evolve`
- `soul_discover`
- `soul_check`
- `response_plan`
- `vision_start`
- `vision_stop`
- `vision_status`
- `growth_approve`
- `growth_rollback`
- `jinli_runtime_turn`

### IDE registry

Registry file should declare:

- IDE id
- config path
- MCP registration format
- enabled tool namespace
- sync strategy
- drift detection command
- rollback path

Initial IDEs:

- Codex desktop
- OpenCode
- Trae
- Future generic MCP client

## Acceptance Criteria

- AC01: `jinli-system.ps1 start` starts exactly one daemon instance and records PID, endpoint, and log paths.
- AC02: `jinli-system.ps1 status` reports daemon state and per-service health for EventBus, MemoryService, Dreamer, Evolution, Proactive, Emotion, Relationship, TurnOrchestrator, and MCP adapter.
- AC03: `jinli-system.ps1 stop` stops the daemon cleanly and leaves no stale PID lock.
- AC04: A direct daemon call can run a standard runtime turn through TurnOrchestrator and returns a manifest with evidence records.
- AC05: The existing MCP tool names remain available and call the daemon path instead of directly owning service logic.
- AC06: `soul_status`, `soul_memory`, and `response_plan` use daemon-owned state or declared compatibility mirrors.
- AC07: Codex, OpenCode, and Trae config generation is driven by one registry and produces or validates consistent MCP settings.
- AC08: Codex capability inspection no longer reports `jinli-soul-core@personal` as available but not installed/enabled after sync.
- AC09: Legacy PowerShell `soul-core.ps1 check` still works or explicitly reports daemon compatibility mode.
- AC10: JSON compatibility files are preserved and not deleted.
- AC11: Service degradation is visible in health output and runtime manifests; no silent fallback is accepted.
- AC12: Automated tests cover daemon lifecycle, service registry health, daemon client, MCP adapter, IDE sync, and legacy compatibility.
- AC13: Documentation explains the single-authority runtime contract, extension process for new systems, and IDE onboarding.
- AC14: Existing runtime tests under `Project/Jinli/services/runtime/tests/` still pass.
- AC15: The selected mature path is implemented without reintroducing the rejected split-engine shortcuts.

## Automated Verification Plan

- Command: `python -m pytest Project/Jinli/services/runtime/tests/ -v`
- Expected: all existing MIRP tests pass.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 start`
- Expected: exit 0, daemon PID and endpoint recorded.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 status -Json`
- Expected: JSON reports daemon running and service health states.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 doctor`
- Expected: no blocking failures; any degraded optional service is explicitly named.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-runtime-turn.ps1 -Mode standard -UserInput "health test" -Task chat -JsonOnly`
- Expected: returns manifest JSON with gate result and memory/persona/route evidence.

- Command: `node C:\Users\87372\plugins\jinli-soul-core\mcp\server.mjs` launched through an MCP smoke client or project smoke script.
- Expected: list-tools includes the legacy tool set and new daemon-backed runtime tool.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect`
- Expected: `jinli-soul-core@personal` is installed/enabled/runtime callable after IDE sync.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-ide-sync.ps1 check -Ide all`
- Expected: Codex, OpenCode, Trae, and generic MCP config surfaces are in sync or report concrete repair steps.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project\Jinli\scripts\soul-core.ps1 -Command check`
- Expected: compatibility path remains healthy or reports daemon-backed compatibility status.

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-27-runtime-daemon-unified-ide plan`
- Expected: passes after Ba Ba confirms the plan and `user_confirmed_plan` is set to true.

## Risk Assessment

- Highest risk: configuration drift in Codex desktop plugin activation. Mitigation: registry-driven sync plus capability inspection.
- Medium risk: daemon introduces a long-running process that can stale-lock. Mitigation: PID validation, health probe, and `doctor` repair guidance.
- Medium risk: T7/T9/T12 services may not be fully wired into `JinliService.start()`. Mitigation: lifecycle registry allows service-specific degraded states and incremental wiring.
- Medium risk: compatibility mirror can create state confusion. Mitigation: one-way mirror policy and explicit authority labels in health output.
- Low risk: existing MCP tool names can remain stable because handlers already exist.

## Implementation Sequence

1. Build daemon and service registry.
2. Add operational scripts and health diagnostics.
3. Add daemon client for Python, Node, and PowerShell callers.
4. Migrate MCP handlers one group at a time.
5. Add IDE registry and sync check.
6. Add compatibility mirror policy.
7. Update docs and run full verification.
