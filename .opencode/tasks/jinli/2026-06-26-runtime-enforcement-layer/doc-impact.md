# Documentation Impact

## Summary

This task affects Jinli runtime workflow documentation and may add new route indexes that future models use to locate files and process rules.

## Project Scope

- Project: Jinli Runtime System
- Path: `Project/Jinli/`
- Affected subsystems: runtime enforcement, service adapters, route indexes

## System Scope

- System: Jinli AI Assistant Runtime (MIRP)
- Cross-cutting: affects all IDE environments (Codex, Trae, OpenCode, Hermes) that use Jinli services
- Does not affect: UE5 gameplay engine, CharacterDesignTool web app

## Owner Scope

- Owner: Ba Ba
- Maintainer: Jinli Lead Agent
- Review authority: Ba Ba (Critical mode changes require explicit approval)

## Project Code Changes

- Add `Project/Jinli/services/runtime/` package (new)
  - `turn_orchestrator.py` - turn mode classification and evidence planning
  - `turn_manifest.py` - manifest schema and validation
  - `response_gate.py` - evidence completeness gate
  - `after_turn_commit.py` - post-turn signal writer
  - `adapters/` - service adapter interfaces and implementations
  - `tests/` - runtime enforcement tests
- Add `.trae/scripts/jinli-route-index.ps1` (new)
- Add `.trae/scripts/jinli-runtime-turn.ps1` (new)
- No changes to existing service internals (memory, persona, proactive, dreamer, evolution)
- No changes to existing `.trae/scripts` task-packet authority scripts

## Code Changes

- Project/Jinli/services/runtime/turn_orchestrator.py
- Project/Jinli/services/runtime/turn_manifest.py
- Project/Jinli/services/runtime/response_gate.py
- Project/Jinli/services/runtime/after_turn_commit.py
- Project/Jinli/services/runtime/adapters/__init__.py
- Project/Jinli/services/runtime/adapters/memory_adapter.py
- Project/Jinli/services/runtime/adapters/persona_adapter.py
- Project/Jinli/services/runtime/adapters/skill_route_adapter.py
- Project/Jinli/services/runtime/adapters/file_route_adapter.py
- Project/Jinli/services/runtime/adapters/workflow_route_adapter.py
- Project/Jinli/services/runtime/adapters/event_bus_adapter.py
- Project/Jinli/services/runtime/adapters/dreamer_adapter.py
- Project/Jinli/services/runtime/adapters/proactive_adapter.py
- Project/Jinli/services/runtime/adapters/evolution_adapter.py
- Project/Jinli/services/runtime/__init__.py
- Project/Jinli/services/runtime/tests/__init__.py
- Project/Jinli/services/runtime/tests/test_turn_manifest.py
- Project/Jinli/services/runtime/tests/test_response_gate.py
- Project/Jinli/services/runtime/tests/test_adapters.py
- Project/Jinli/services/runtime/tests/test_after_turn_commit.py
- Project/Jinli/services/runtime/tests/test_weak_model.py

## Documentation Updates

- Project/Jinli/Docs/03-Architecture/runtime-enforcement-layer.md
- Project/Jinli/Docs/04-Implementation/runtime-protocol.md
- Add `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`.
- Update `Docs/AI/README.md` index if required.
- Add or update route index documentation for:
  - Jinli service files
  - task packet locations
  - workflow scripts
  - skill locations
  - runtime data locations
- Add verification evidence to this task packet.

## Docs Tree Updates

- Project/Jinli/Docs/DOCS_TREE.md

## No Documentation Change Expected

- UE gameplay documentation is not directly affected.
- Web application user-facing documentation is not directly affected.

## Governance Notes

- Documentation must explain the active route and process system in a way that a new model can follow without relying on chat history.
- Generated indexes must say how to regenerate and how to check freshness.
