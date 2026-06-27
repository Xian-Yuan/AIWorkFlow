# 47 — Jinli Runtime Enforcement Layer (MIRP)

**Status:** implemented (2026-06-26)
**Owners:** opencode (implementer), Ba Ba (verifier)
**Scope:** `Project/Jinli/services/runtime/**`, `.trae/scripts/jinli-*.ps1`

## Purpose

Define the Model-Independent Runtime Protocol (MIRP) — the per-turn
evidence-gathering layer that forces every meaningful Jinli work turn
through a complete participation loop:

1. **Adapters** call existing services (memory, persona, skill routing,
   file route lookup, workflow route lookup, …) and produce structured
   evidence records.
2. **ResponseGate** validates the manifest against the mode's required
   evidence set and rejects self-attestation.
3. **AfterTurnCommit** writes approved signals (memory candidate, event,
   dream, proactive, evolution) through narrow sink contracts.

A turn that fails the gate does not write success signals. A service
that wasn't called this turn produces no evidence — existence is not
usage.

## Architecture

```text
                    ┌─────────────────────┐
                    │  User turn / input  │
                    └─────────┬───────────┘
                              │
                              ▼
            ┌──────────────────────────────────┐
            │  TurnOrchestrator.run(...)        │
            │  builds TurnManifest + mode       │
            └─────────┬────────────────────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   MemoryAdapter  PersonaAdapter  SkillRouteAdapter
   FileRouteAdapter  WorkflowRouteAdapter  TaskPacketAdapter
       │              │              │
       └──────────────┴──────────────┘
                      │  EvidenceRecord[]
                      ▼
            ┌──────────────────────────────────┐
            │  ResponseGate.validate(manifest) │
            └─────────┬────────────────────────┘
                      │  GateResult(passed, violations)
            ┌─────────┴────────────┐
            ▼                      ▼
        passed=true            passed=false
            │                      │
            ▼                      ▼
   AfterTurnCommit.commit()    manifest.degraded = true
   memory / event / dream      commit skipped (no lies)
   proactive / evolution       MEMORY candidate raised
            │
            ▼
      JSON manifest + gate
      (printed by jinli-runtime-turn.ps1)
```

## Mode Table

| Mode | Required evidence | Degradation allowed | Use case |
|------|-------------------|---------------------|----------|
| LITE | none (soul_persona + memory_lite optional) | n/a | small talk, casual chat |
| STANDARD | memory, skill_route, file_route, workflow_route, verifier_lite | yes (declared) | technical Q&A, advice |
| STRICT | + task_packet, multi_agent, response_gate, after_turn_commit | limited | project work, code changes |
| CRITICAL | + authority, explicit_approval | no (must be GATHERED) | irreversible actions, archives |

## Public API

```python
from Project.Jinli.services.runtime import (
    TurnMode, TurnManifest, TurnOrchestrator, ResponseGate,
    AfterTurnCommit, EvidenceStatus, EvidenceRecord,
)
from Project.Jinli.services.runtime.adapters import AdapterContext
from Project.Jinli.services.runtime.adapters.memory_adapter import MemoryAdapter
# ... other adapters
```

## Scripts

| Script | Purpose |
|--------|---------|
| `.trae/scripts/jinli-route-index.ps1` | Build/Check/Show the file + workflow route index |
| `.trae/scripts/jinli-runtime-turn.ps1` | Run one Jinli turn through MIRP; prints manifest JSON; exit 0 (pass), 2 (gate fail), 3 (degraded pass) |

## Spec Scenarios

See `Project/Jinli/Docs/03-Architecture/runtime-enforcement-layer.md` for the
full scenario-to-test mapping. 11 scenarios, 12 acceptance criteria,
44 unit tests passing.

## Operational Rules

- **Never** modify `task-state.ps1`, `contract-verify.ps1`,
  `task-guard.ps1`, or `task-packet-seal.ps1`. These are project edit
  authority and outside MIRP's scope.
- **Never** write runtime data outside `Project/Jinli/services/runtime/`
  or the per-task `.trae/tasks/<name>/` packet directories.
- **Always** declare degraded evidence when a sink or service is
  unavailable. Silent fallback is a violation.

## Failure Modes

1. **MemoryService not started** → memory adapter records
   `DEGRADED` with explicit reason; gate may allow degraded in
   Standard but blocks Strict/Critical.
2. **Route index drift** → `jinli-route-index.ps1 -Check` returns
   `ok: false`; rebuild with `-Build`.
3. **Adapter raises** → orchestrator catches and records
   `DEGRADED { degradation_reason: "{ExceptionClass}: {msg}"}`.
4. **Sink unavailable** → `CommitResult.notes` records the
   declared drop; no silent loss.

## Future Hardening

- Issuer-worker signing path for Strict/Critical evidence.
- Cross-model stress harness (Claude / Codex / GPT / DeepSeek running
  the same manifest inputs).
- JS expression-orchestrator → Python bridge wiring (Spec Scenario 9).