# Routing Decision: Jinli Runtime Enforcement Layer

## Task Identity

- Task: `2026-06-26-runtime-enforcement-layer`
- Project: `jinli`
- Project type: `other`
- System: Jinli runtime, workflow enforcement, file routing, multi-agent coordination
- Runtime task root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer`

## Requirement Discovery Gate

- Change profile: deep-discovery
- Plain-language summary confirmed: yes
- Confirmed summary: Build a runtime enforcement layer that forces non-trivial Jinli work through memory, skill routing, multi-agent evidence, response gating, after-turn commit, file routing, and workflow route maintenance.
- Unresolved high-impact questions: none
- No unresolved high-impact questions before Plan.
- Implementation still requires Ba Ba's explicit plan confirmation because the change affects workflow authority and future model behavior.

## Main Skill And Supporting Skills

- Main skill: `codex-project-router`
- Supporting skills:
  - `smart-requirements`
  - `jinli-agent-soul`
  - `failure-memory`
  - `memory-keeper`
  - `dispatching-parallel-agents`
  - `systematic-debugging`

## Collaboration Mode

- Required pattern: orchestrator-workers plus independent verifier.
- Lead/Issuer: Codex/Jinli lead model.
- Workers: bounded work packages only.
- Verifier: independent context, cannot be the worker that implemented the code.
- Authority rule: workers cannot mutate task packet, review, verify, repair, or archive state.

## Quality Gate

- Default quality level: Mature production-grade.
- MVP/prototype requested by user: no.
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes.
- User confirmation must include quality level: yes.
- Quality exception: none.

## Work Package Policy

- External workers: yes
- Task packet root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes

## Runtime Mode Policy

The enforcement layer must support four modes:

| Mode | Use Case | Required Evidence |
|---|---|---|
| Lite | casual or tiny factual answer | soul/persona sync, optional memory-lite |
| Standard | technical advice, design, analysis | memory, skill route, file/process route, verifier-lite |
| Strict | project work, automation, memory, workflow changes | full multi-agent, task packet, manifest, response gate, after-turn commit |
| Critical | authority, safety, persona, memory schema, archive | Strict plus explicit Ba Ba approval and signed/issuer authority where available |

## Stop Conditions

- Stop if task-state, contract, or task-guard scripts fail in a way that prevents safe progress.
- Stop before Implement until Ba Ba confirms the mature plan.
- Stop if a required runtime component cannot be used and no declared degradation path exists.
- Stop if a worker package would need to edit outside its allowed paths.
- Stop if route indexes cannot be verified as current.
