# WP03 Result: Existing Service Adapters And After-Turn Commit

Status: done

## Changed Files

- `Project/Jinli/services/runtime/adapters/base.py`
- `Project/Jinli/services/runtime/adapters/__init__.py`
- `Project/Jinli/services/runtime/adapters/memory_adapter.py`
- `Project/Jinli/services/runtime/adapters/persona_adapter.py`
- `Project/Jinli/services/runtime/adapters/skill_route_adapter.py`
- `Project/Jinli/services/runtime/adapters/task_packet_adapter.py`
- `Project/Jinli/services/runtime/adapters/verifier_lite_adapter.py`
- `Project/Jinli/services/runtime/adapters/event_bus_adapter.py`
- `Project/Jinli/services/runtime/adapters/dreamer_adapter.py`
- `Project/Jinli/services/runtime/adapters/proactive_adapter.py`
- `Project/Jinli/services/runtime/adapters/evolution_adapter.py`
- `Project/Jinli/services/runtime/after_turn_commit.py`
- `Project/Jinli/services/runtime/tests/test_adapters.py`
- `Project/Jinli/services/runtime/tests/test_after_turn_commit.py`

## Commands Run

- `python -m pytest Project\Jinli\services\runtime\tests\ -q`
  - Result: `51 passed in 7.80s`
- `.trae\scripts\jinli-runtime-turn.ps1 -Mode standard -UserInput "memory-start-check" -Task runtime-check -JsonOnly`
  - Result: exit `0`, `gate.passed=true`, `degraded=false`, memory evidence `gathered`

## Acceptance Criteria Touched

- AC03: Adapters prove per-turn use or declared degradation for memory, persona, skill routing, file routing, workflow routing, and task packets.
- AC07: Task-state initialization defect was verified after lead-owned repair.
- AC09: Runtime tests cover service-exists versus service-used behavior.

## Scope Control

- Extra scope taken: no
- Existing memory/persona/proactive/evolution/nervous internals were not rewritten.
- `MemoryAdapter` now starts and stops `MemoryService` around the recall call when lifecycle methods are available.

## Unresolved Risks

- External service sinks may still degrade when unavailable; this is recorded in `CommitResult.notes` instead of being silently ignored.
