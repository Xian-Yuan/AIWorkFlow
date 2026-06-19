# Living Spec — Jinli Persona, Language, and Vision Foundation

Date: 2026-06-18  
Status: Implement repair in progress; release verification pending  
Scenarios: S01-S09 and S13-S14 verified locally; S10 project supervisor implemented but installed Plugin adapter is pending; S11-S12 await full Python dependency verification

## Progress Summary

| Phase | Module | Status | Scenarios |
|---|---|---|---|
| P1 | Contracts and Stable Persona Kernel | ✅ complete | S01-S03 |
| P2 | Expression Orchestrator | ✅ complete | S04-S07 |
| P3 | Dynamic Soul integration and growth | ✅ complete | S08-S09 |
| P4 | Visual Perception | ⚠️ Project supervisor implemented; Plugin deployment blocked | S10 (partial), S11-S12 (verification pending) |
| P5 | Avatar Presentation and regression | ✅ complete | S13-S14 |

## Decisions

- Stable identity is versioned and runtime read-only.
- Dynamic Soul affects expression but cannot redefine who Jinli is.
- Private summaries are bounded observations held in process memory, not chain-of-thought and not durable memory.
- Visual observation and avatar presentation are separate systems.
- Screen observation is explicit-start, explicit-stop, local-first, redaction-first, and non-resuming.
- Long-term memory and personality growth require explicit approval.

## Behavior Scenarios

### S01 — Load stable persona

**Status**: [x] ✅ 37/37 tests passing

**GIVEN** a valid versioned persona configuration  
**WHEN** the Persona Kernel loads  
**THEN** it returns identity, values, interests, relationship, honesty boundaries, and language fingerprint  
**AND** the returned object is immutable to ordinary runtime callers.

### S02 — Reject protected-field mutation

**Status**: [x] ✅ 37/37 tests passing

**GIVEN** Dynamic Soul or a Plugin tool proposes changing identity, relationship role, or honesty boundaries  
**WHEN** the mutation is evaluated  
**THEN** it is rejected as a protected-field write  
**AND** no persona file is changed.

### S03 — Preserve digital-life honesty

**Status**: [x] ✅ 37/37 tests passing

**GIVEN** Jinli has no active visual or avatar adapter evidence  
**WHEN** a response is planned  
**THEN** she may describe wishes or intentions  
**AND** she does not claim she saw the screen or physically performed an action.

### S04 — Route five conversation scenes

**Status**: [x]

**GIVEN** representative technical, casual, emotional-support, safety, and proactive-alert inputs  
**WHEN** the Expression Orchestrator classifies them  
**THEN** each input maps to exactly one primary scene route  
**AND** optional secondary tags do not replace the primary route.

### S05 — Keep private planning ephemeral

**Status**: [x]

**GIVEN** the orchestrator creates a bounded psychological summary and topic queue  
**WHEN** the session ends or the MCP process resets  
**THEN** those values are cleared  
**AND** they are absent from Soul state, events, logs, screenshots, and memory storage.

### S06 — Limit proactive interruption

**Status**: [x]

**GIVEN** a routine observation, a key error, a major risk, and a clear physical-discomfort signal  
**WHEN** interruption policy is evaluated  
**THEN** routine observations enter the topic queue  
**AND** only the latter three may produce an immediate interruption  
**AND** physical-discomfort wording remains cautious and non-diagnostic.

### S07 — Express unconfirmed actions as intentions

**Status**: [x]

**GIVEN** the response plan requests a smile or head tilt  
**WHEN** no presentation adapter confirms execution  
**THEN** `action_intent.status` is `desired` or `dispatched`  
**AND** the user-facing text does not state that the action already happened.

### S08 — Apply Dynamic Soul without identity drift

**Status**: [x]

**GIVEN** Soul reports low warmth, frustration, or a repaired relationship state  
**WHEN** the response plan is composed  
**THEN** tone directives change within persona policy bounds  
**AND** technical accuracy remains mandatory  
**AND** protected persona fields remain unchanged.

### S09 — Approve and roll back persona growth

**Status**: [x]

**GIVEN** repeated approved evidence suggests a style preference change  
**WHEN** a growth proposal is generated  
**THEN** it records evidence, before/after values, scope, approval state, and rollback ID  
**AND** it changes production configuration only after explicit approval  
**AND** rollback restores the previous version.

### S10 — Start and stop visual perception explicitly

**Status**: [⚠️] Cross-process Python supervisor and no-auto-resume tests pass; installed MCP Plugin still uses the wrong package root

**GIVEN** Visual Perception is stopped  
**WHEN** the user explicitly starts it  
**THEN** all configured displays may be observed  
**AND** status reports active consent and session ID  
**WHEN** the user stops it or the service restarts  
**THEN** capture ends and does not resume automatically.

### S11 — Redact before inference

**Status**: [ ]

**GIVEN** a frame contains configured private regions, password fields, tokens, email addresses, or payment identifiers  
**WHEN** the frame enters the pipeline  
**THEN** redaction runs before Qwen3-VL or OmniParser receives the frame  
**AND** tests can prove the inference adapter receives only the redacted frame.

### S12 — Use event-driven visual inference and short retention

**Status**: [ ]

**GIVEN** consecutive frames are materially unchanged  
**WHEN** change detection runs  
**THEN** no VLM request is made  
**WHEN** a meaningful change occurs  
**THEN** one structured `VisualObservation` is produced  
**AND** frame data and observation data expire by configured TTL  
**AND** long-term memory requires a separate per-item approval.

### S13 — Keep presentation independent

**Status**: [x]

**GIVEN** a valid `action_intent` and no Visual Perception service  
**WHEN** a mock Live2D/3D adapter consumes the intent  
**THEN** it can drive its state machine without any screenshot dependency  
**AND** it returns confirmation or failure through the presentation contract.

### S14 — Preserve existing behavior and isolate tests

**Status**: [x] Node.js available; project module regression tests execute normally

## Verification State

- Node.js project tests: 196/198 pass; the remaining two failures are installed Plugin integration tests.
- Vision supervisor standard-library tests: 4/4 pass; Python bytecode compilation passes.
- Full Python pytest suite: blocked because dependency installation was denied by the current execution environment.
- Workflow regression: 20/20 pass.
- Final verification: pending; task remains in Implement.

## Changelog

| Date | Change |
|---|---|---|
| 2026-06-19 | Repair pass: restored Avatar/Dialogue tests so 89 tests execute; fixed Soul JSON BOM parsing; added cross-process Vision supervisor and live Plugin integration tests; Plugin deployment and full pytest remain blocked |
| 2026-06-18 | T06 complete: avatar-bridge.mjs + 35 tests (presentation state machine, action→animation mapping, S07/S13 semantics) |
| 2026-06-18 | T07 complete: 6 new MCP tools (response_plan, vision_start/stop/status, growth_approve/rollback) + Zod schemas + server registration |
| 2026-06-18 | T08 complete: spec.md updated (11/14 scenarios marked), verification-report.md created, tasks.md checked off |
| 2026-06-18 | T03-T05 (existing prior work): expression-orchestrator.mjs, soul-bridge.mjs with 5 scene routes, interruption policy, private state, tone directives |
| 2026-06-18 | Phase 1 (T01+T02) complete: 7 JSON schemas + Persona Kernel + 37/37 tests pass |
| 2026-06-18 | Initial approved five-module Living Spec published |
