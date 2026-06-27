# Analysis: Jinli Runtime Enforcement Layer

## Architecture Context

### System boundaries

- In scope:
  - per-turn runtime enforcement
  - multi-agent orchestration contract
  - response gate and turn manifest
  - after-turn commit hooks
  - file route and workflow route indexes
  - script-level validation for those artifacts
  - integration adapters for existing Jinli services
- Out of scope:
  - replacing `.trae/scripts` task-packet authority
  - changing worker authority ownership rules
  - enabling external chat delivery by default
  - letting persona/emotion override factual or workflow gates

### Dependency map

- Current workflow truth:
  - `AGENTS.md`
  - `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
  - `Docs/AI/29-Mature-Solution-First-Workflow.md`
  - `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
  - `Docs/AI/45-Conversational-Requirements-Discovery-Workflow.md`
  - `Docs/AI/46-Enforcement-Framework.md`
  - `skills/codex-project-router/SKILL.md`
- Current mechanical gates:
  - `.trae/scripts/task-state.ps1`
  - `.trae/scripts/task-guard.ps1`
  - `.trae/scripts/contract-verify.ps1`
  - `.trae/scripts/memory-guard.ps1`
  - `.trae/scripts/worker-submit.ps1`
  - `.trae/scripts/issuer-*.ps1`
- Existing Jinli services to integrate:
  - `Project/Jinli/services/nervous/`
  - `Project/Jinli/services/memory/`
  - `Project/Jinli/services/memory/keeper/`
  - `Project/Jinli/services/memory/dreamer/`
  - `Project/Jinli/services/evolution/`
  - `Project/Jinli/services/proactive/p1/`
  - `Project/Jinli/services/persona/`
  - `Project/Jinli/services/ai-video-creator/`

### Data and state ownership

- Task packets remain owned by `.trae/tasks/<project>/<task>/`.
- Runtime turn evidence should be append-only under a Jinli runtime data directory.
- File route index should be generated from declared route rules plus repository scan evidence.
- Workflow route index should be generated from active workflow docs, skills, and scripts.
- Memory writes must continue through approved memory gate paths, not direct worker writes.
- Persona and relationship state remain owned by the persona service.

### Integration points

- Pre-answer:
  - soul/persona adapter
  - memory adapter
  - skill router adapter
  - file route adapter
  - workflow route adapter
  - sub-agent dispatch adapter
- Draft validation:
  - response gate
  - manifest validator
  - evidence completeness check
- Post-answer:
  - memory candidate writer
  - event bus publisher
  - dreamer enqueue
  - proactive enqueue
  - evolution candidate enqueue
- Project work:
  - task-state
  - contract-verify
  - task-guard
  - work-package reports
  - issuer-worker authority scripts

## Mature Solution Evidence

### Project-local evidence

- `Docs/AI/46-Enforcement-Framework.md` already identifies that model self-discipline is not enough and defines Layer 1/2/3 enforcement.
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` already defines Lead/Worker/Reviewer split, work packages, worker reports, and authority separation.
- `Docs/AI/41-Issuer-Worker-Authority-Separation.md` already defines that workers cannot approve their own work.
- Sub-agent runtime audit found partial service wiring in `Project/Jinli/services/jinli_service.py`: it starts EventBus, MemoryService, and EvolutionService, but does not expose a per-turn `process_turn(...)` path that drives all Jinli modules.
- Sub-agent runtime audit found `Project/Jinli/services/jinli_daemon.py` runs background dreamer/evolution jobs, but daemon scheduling is not the same as per-turn conversation enforcement.
- Sub-agent runtime audit found `Project/Jinli/runtime/expression-orchestrator.mjs` produces response planning but does not call the Python service runtime, T3 EventBus, memory, persona, proactive, dreamer, or evolution adapters.
- `Project/Jinli/services/memory/keeper/final-result.md` proves memory gate exists but is opt-in through `JINLI_MEMORY_GATE_INPUT`.
- `Project/Jinli/services/memory/dreamer/final-result.md` proves dreamer exists but still needs import/start integration.
- `Project/Jinli/services/proactive/p1/final-result.md` proves proactive output writes `.codex/proactive_messages.json`, but needs a reader/orchestrator.
- `Project/Jinli/services/persona/final-result.md` proves persona/emotion service exists but must be wired into a runtime turn.
- `task-state.ps1 init` currently fails for new task names unless the directory exists first. This is a stability defect and must be fixed.
- Sub-agent gate audit confirmed existing scripts can strongly govern task packets, but cannot yet govern ordinary chat turns without a new runtime manifest/gate.
- Sub-agent gate audit confirmed `contract-verify.ps1` is a thin contract layer and its current verification-report section check is weaker than `task-guard.ps1`.
- Sub-agent gate audit confirmed issuer-worker evidence exists through `task-packet-seal.ps1`, `worker-capability.ps1`, `worker-submit.ps1`, `issuer-review.ps1`, and `issuer-archive.ps1`, but those authority artifacts are not yet first-class per-turn runtime evidence.
- Sub-agent gate audit found one legacy/test violation in `jinli/test-memory-gate`: phase entered implement while user confirmation/router-loaded fields were missing.

### Official/framework evidence

- Mature agent architectures use orchestrator-workers and evaluator-optimizer patterns for complex tasks.
- Robust agent systems need hooks or external validators when instructions must be enforced across models.
- Prompt-only compliance is not sufficient for stable cross-model behavior.

### External mature references

- Claude Code subagents pattern: delegate noisy or specialized work into isolated contexts and integrate evidence.
- Claude Code hooks pattern: enforce lifecycle checks outside the model.
- Anthropic agent patterns: route, chain, parallelize, orchestrate workers, and evaluate outputs when task complexity warrants it.
- GitHub Spec Kit style requirement gates: treat ambiguity and quality checks as first-class artifacts.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Prompt-only rules | Current skills/AGENTS | Cheap and easy | Models skip steps; no proof | Rejected |
| Task-packet-only enforcement | Current `.trae/scripts` | Strong for project edits | Does not govern every meaningful response | Rejected as incomplete |
| Per-turn runtime manifest plus response gate | New layer over existing systems | Proves what ran this turn; model-independent | Needs new adapter and tests | Selected |
| Full platform hook only | Future Codex/OpenCode hooks | Strongest enforcement | Not available everywhere now | Deferred, keep adapter points |

### Rejected shortcuts

- "Just update AGENTS.md": rejected because natural-language rules are already being skipped.
- "Always spawn many agents": rejected because casual/light turns need a fast path.
- "Let the lead agent self-report checks": rejected because self-attestation is not evidence.
- "Wire only memory": rejected because the user asked for the whole system.
- "Manual file placement docs only": rejected because file route indexes must be automatically maintained.

### Selected mature path

Build a model-independent runtime enforcement layer, named MIRP: Model-Independent Runtime Protocol:

1. `TurnOrchestrator` builds a required evidence plan based on mode.
2. Service adapters gather memory, persona, skill, file route, workflow route, and task-packet context.
3. Multi-agent worker outputs are normalized into structured evidence reports.
4. `TurnManifest` records what actually ran.
5. `ResponseGate` blocks or repairs missing evidence before output.
6. `AfterTurnCommit` writes memory/event/dream/proactive/evolution signals.
7. `FileRouteIndex` and `WorkflowRouteIndex` are generated and checked by scripts.
8. Existing task-packet gates remain the authority for edits and completion.

## Acceptance Criteria

- AC01: A turn manifest schema exists and records mode, required evidence, gathered evidence, sub-agent reports, gate result, and after-turn commit result.
- AC02: Standard/Strict/Critical modes cannot produce a final answer when required evidence is missing.
- AC03: Runtime adapters prove actual use or declared degradation for memory, persona, skill routing, file routing, workflow routing, and task packets.
- AC04: Multi-agent evidence is normalized so lead, worker, verifier, and after-turn roles cannot be confused.
- AC05: Worker packages are bounded and forbid workers from mutating task state, acceptance criteria, review, verify, repair, or archive files.
- AC06: File route and workflow route indexes are generated or checked automatically.
- AC07: New task initialization defect in `task-state.ps1` is fixed or covered by a regression test.
- AC08: Cross-model stability is verified with a deterministic fixture that simulates a weak model skipping steps and confirms the response gate blocks it.
- AC09: Existing workflow regression tests still pass or any failure is documented with root cause and repair package.
- AC10: Documentation explains the runtime flow so another model can enter the project and find file placement and workflow rules.
- AC11: Contract verification is strengthened or supplemented so verify-report checks require all required sections, not an OR match.
- AC12: Issuer-worker packet seal, capability, worker result, issuer approval, and archive evidence can be referenced in runtime manifests for Strict/Critical modes.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\contract-verify.ps1 jinli/2026-06-26-runtime-enforcement-layer verify -Phase plan -Strict`
  - Expected: passes after Ba Ba confirms the mature plan and plan files are complete.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-26-runtime-enforcement-layer plan`
  - Expected: passes before Implement.
- Command: `python -m pytest Project/Jinli/services/runtime/tests/ -q`
  - Expected: runtime enforcement tests pass after implementation.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
  - Expected: existing workflow regression remains green or produces documented repair evidence.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-route-index.ps1 -Check`
  - Expected: file and workflow route indexes are current after implementation.

## Initial Risk Register

- R01: Existing task-state initialization cannot create a new task without a pre-existing directory.
- R02: Current contract-verify project discovery does not include `jinli` unless the task is passed as `project/task`.
- R03: Existing services are tested as components but not wired into one per-turn runtime.
- R04: Proactive output path exists but needs a runtime reader or dispatch bridge.
- R05: Memory gate is opt-in through environment variables, not unconditional per meaningful turn.
- R06: Encoding corruption in several Chinese workflow docs can weaken model comprehension.
- R07: Response quality is not currently mechanically checked.
- R08: File placement and process routing are not yet maintained as generated runtime indexes.
- R09: `JinliService` and `JinliDaemon` are service/background entrypoints, but neither is currently a universal per-turn contract gate.
- R10: JS response planning and Python service runtime are split without a proven bridge.
- R11: `contract-verify.ps1` can pass weak verification-report content because its section regex is not an all-sections check.
- R12: Existing worker Markdown reports are weaker than signed issuer-worker JSON evidence.
- R13: Platform-level hooks are not currently available everywhere, so Layer 2 runtime gates must be usable manually and by wrappers.
