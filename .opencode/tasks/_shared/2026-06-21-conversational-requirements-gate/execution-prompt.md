# Task Execution Prompt: Conversational Requirements Gate

## Role

Act as the lead workflow engineer. Preserve Ba Ba's confirmed human-facing interaction model while adding mechanical enforcement for future task packets.

## Goal

Implement a versioned requirement-understanding gate so meaningful features cannot enter implementation without confirmed plain-language requirements and an agent-authored execution prompt, while bounded fixes retain a documented fast path.

## Task Packet Truth Sources

Read in order:

1. `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/requirements.md`
2. `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/analysis.md`
3. `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/spec.md`
4. `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/tasks.md`
5. `Docs/superpowers/specs/2026-06-21-conversational-requirements-gate-design.md`
6. `Docs/superpowers/plans/2026-06-21-conversational-requirements-gate-plan.md`

## Confirmed Decisions

- Deep discovery for new systems, meaningful features, redesigns, and ambiguity.
- Fast track only for concrete bounded fixes with no unresolved high-impact requirement.
- Uncertainty defaults to deep discovery.
- One plain-language question per turn; no fixed round count.
- Planner recommends options and permits free-form correction.
- Planner owns technical translation and task-packet prompt writing.
- Ba Ba confirms the plain-language requirement picture and short plan summary.

## Accepted Architecture

- Add versioned requirement metadata to newly initialized task packets.
- Add `requirements.md` and `execution-prompt.md` templates.
- Enforce complete deep or fast evidence in `task-guard.ps1 plan`.
- Keep legacy packets compatible when the version field is absent.
- Update Jinli and router Skills plus authoritative workflow docs.

## Allowed Paths

- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/test-workflow-regression.ps1`
- `.trae/tasks/_shared/templates/`
- `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/`
- `skills/smart-requirements/`
- `skills/金璃小天才/`
- `skills/ue-project-router/`
- `skills/codex-project-router/`
- `Docs/AI/`
- `Docs/superpowers/specs/2026-06-21-conversational-requirements-gate-design.md`
- `Docs/superpowers/plans/2026-06-21-conversational-requirements-gate-plan.md`

## Forbidden Paths

- `Project/`
- Other active task packets
- Existing unrelated user changes
- Git history or remote publication

## Non-Goals

- Do not redesign the full state machine.
- Do not migrate or rewrite all legacy task packets.
- Do not add a generic questionnaire with a fixed number of questions.
- Do not make Ba Ba author technical prompts.

## Acceptance Criteria

- AC01: New tasks are initialized with requirement-gate metadata.
- AC02: Version-1 deep tasks without confirmed requirement evidence are blocked.
- AC03: Version-1 fast tasks without an explicit reason are blocked.
- AC04: Complete deep and fast packets pass the Plan gate.
- AC05: The execution prompt is mandatory and structurally validated.
- AC06: Jinli planning Skills implement the confirmed conversational rules.
- AC07: Legacy packets without the version field remain compatible.
- AC08: Documentation and workflow regressions pass.

## Verification Commands

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
  - Expected: all scenarios pass, including deep/fast requirement-gate cases.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1`
  - Expected: exit 0.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check`
  - Expected: exit 0.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-21-conversational-requirements-gate verify`
  - Expected: pass after evidence is recorded.

## Stop Conditions

Stop and return to Plan if:

- a required change would affect project application code;
- legacy compatibility cannot be preserved;
- the gate cannot distinguish deep and fast packets without ambiguous heuristics;
- existing unrelated user edits would need to be overwritten;
- verification exposes an architectural conflict outside this task.

## Evidence Rule

Do not claim a file exists, a test passed, a task is done, or an acceptance criterion is satisfied without a current-session file read or command result.

