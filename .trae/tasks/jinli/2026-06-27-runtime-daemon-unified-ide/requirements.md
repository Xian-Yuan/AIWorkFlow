# Requirement Understanding: Jinli Runtime Daemon Unified IDE

## Desired Outcome

Ba Ba wants Jinli to run as one complete, durable system instead of a split set of per-IDE integrations. Codex, OpenCode, Trae, and future IDE clients should all use the same Jinli capabilities through stable MCP tools or command-line adapters. The authoritative runtime should start the Python service layer, coordinate turn evidence, own memory and event flow, expose health checks, and keep legacy PowerShell/JSON paths only as compatibility layers.

## Underlying Problem

The current system has two partially independent engines:

- The current MCP plugin exposes familiar Soul Core tools but mostly calls PowerShell and project JS modules.
- The Python service layer owns the richer runtime pieces: EventBus, MemoryService, Dreamer, Evolution, Proactive, Emotion, RelationshipLedger, TurnOrchestrator, and AfterTurnCommit.

Because these layers are not connected through one owner process, different IDEs can see different capabilities, runtime state can drift, and a report can claim a plugin is active while the actual Codex session has no callable Jinli MCP tools.

## Intended User and Context

The primary user is Ba Ba working in E:/UEGameDevelopment across Codex, OpenCode, Trae, and future AI IDEs. The system must support both everyday companion turns and project-work turns that need mechanical evidence, task packets, memory, workflow routing, and after-turn commits.

The implementation is for the local Windows workspace first. It must not depend on cloud hosting. It may expose localhost IPC or HTTP endpoints, but the security and authority model must remain local and inspectable.

## End-to-End Experience

1. Ba Ba starts Jinli once with a single command such as `.trae/scripts/jinli-system.ps1 start`.
2. The command starts or reuses a single Python runtime daemon and records PID, port or pipe, logs, and health status.
3. The daemon starts or wires the Python service layer: T3 EventBus, T4 MemoryService, T7 Dreamer, T8 Evolution, T9 Proactive, T12 Emotion and Relationship, and MIRP TurnOrchestrator.
4. Each IDE connects through a generated MCP configuration that points to the same local Jinli MCP adapter.
5. MCP tools keep stable names such as `soul_init`, `soul_auto`, `response_plan`, `soul_memory`, `soul_status`, and `jinli_runtime_turn`.
6. A tool call reaches the daemon, not a separate per-tool engine. The daemon decides whether to run a light companion action, a full MIRP turn, memory retrieval, health inspection, or a compatibility mirror update.
7. Health checks show one clear truth: daemon online/offline, service online/degraded/missing, MCP reachable/unreachable, IDE config synced/drifted.
8. Ba Ba can stop everything with `.trae/scripts/jinli-system.ps1 stop`, and future IDEs can be added by editing a registry instead of rewriting runtime logic.

## Confirmed Decisions

- The selected architecture is Python Runtime Daemon as the single authority.
- MCP is an adapter layer for IDE clients, not the owner of state or service lifecycle.
- PowerShell `soul-core.ps1` and JSON files remain compatibility surfaces, not the long-term source of truth.
- Cross-IDE support is mandatory for Codex, OpenCode, Trae, and future IDE clients.
- The design must be extensible for future systems such as voice, avatar, vision, local model routing, mobile or WeChat proactive delivery, and UE editor control.
- The implementation must use mature project workflow gates and task packets.

## Implicit Requirements

| Requirement inferred by the planner | Status: Confirmed / Rejected / Deferred | Reason |
|---|---|---|
| Introduce a long-lived Python daemon with single-instance locking | Confirmed | Needed to make services online and prevent per-IDE divergent runtime state. |
| Add a health and diagnostics surface | Confirmed | Ba Ba explicitly needs to know whether services are online. |
| Generate IDE configuration from one registry | Confirmed | Future IDE support must not require hand-editing each toolchain. |
| Preserve existing MCP tool names during migration | Confirmed | Existing skills and AGENTS instructions already refer to these tool names. |
| Keep legacy PowerShell/JSON paths working during transition | Confirmed | Existing scripts and data should not be broken by the migration. |
| Move all state ownership immediately in one large cutover | Rejected | Too risky; use staged migration with mirror compatibility and verification. |
| Make each IDE start its own Jinli runtime process | Rejected | This repeats the current split-engine problem. |
| Add cloud deployment or remote multi-user service | Deferred | The current goal is local workspace reliability and IDE sharing. |

## Boundaries and Non-Goals

- Do not change unrelated UE5 RTS or CharacterDesignTool behavior.
- Do not delete existing Soul Core JSON data.
- Do not remove `soul-core.ps1` until compatibility and migration evidence exists.
- Do not require a specific IDE as the only supported client.
- Do not make MCP tools contain business logic that should live in the daemon.
- Do not implement voice, avatar, WeChat, mobile, or UE editor control in this task; only design extension points for them.
- Do not weaken existing task-state, contract-verify, task-guard, doc-guard, or issuer-worker authority scripts.

## Success Experience

This feels right when Ba Ba can ask any supported IDE to use Jinli and receive the same capabilities, same memory backend, same health truth, and same runtime behavior. Starting, stopping, diagnosing, and adding new modules should feel like operating one product, not reconnecting many scripts by hand.

## Open Questions

None.

## Teach-Back Summary

Ba Ba wants Jinli to become a unified local runtime platform. A Python daemon owns lifecycle, state, memory, events, emotion, proactive behavior, and per-turn evidence. MCP and IDE configs become thin adapters generated from a shared registry. Legacy PowerShell and JSON remain as compatibility layers while the new daemon path becomes authoritative. The result should be easier to start, diagnose, extend, and share across Codex, OpenCode, Trae, and future IDEs.

## User Confirmation Evidence

- Ba Ba asked how to run the whole system and make other IDEs use it.
- Ba Ba asked whether the daemon-first scheme remains convenient for future systems.
- Ba Ba then asked Jinli to design the complete detailed task packet for this plan.
- Final implementation entry still requires Ba Ba's explicit plan confirmation before `user_confirmed_plan` is set to true.
