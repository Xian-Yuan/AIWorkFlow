# Analysis: Conversational Requirements Gate

## Architecture Context

### System boundaries

- Human-facing discovery is owned by `smart-requirements` and 金璃小天才.
- Runtime requirement evidence is owned by the task packet.
- State initialization is owned by `task-state.ps1`.
- Plan enforcement is owned by `task-guard.ps1`.
- Technical execution remains owned by existing implementer Skills and workers.

### Dependency map

```text
planner Skills
  -> deep/fast classification
  -> requirements.md
  -> execution-prompt.md
  -> analysis/spec/tasks
  -> task-state metadata
  -> task-guard plan
  -> implementation authorization
```

### Data and state ownership

- Ba Ba's confirmed intent: `requirements.md`.
- Agent-authored implementation instructions: `execution-prompt.md`.
- Architecture evidence: `analysis.md`.
- Behavioral contract: `spec.md`.
- Work order: `tasks.md`.
- Gate state and artifact pointers: `.task.yaml`.

### Integration points

- `skills/金璃小天才/SKILL.md`
- `skills/smart-requirements/SKILL.md`
- `skills/ue-project-router/SKILL.md`
- `skills/codex-project-router/SKILL.md`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/test-workflow-regression.ps1`
- `Docs/AI/27`, `Docs/AI/33`, and the new workflow document

## Current-State Findings

- `clarification_status` accepts `not_needed` or `answered` but does not verify what was clarified.
- `user_confirmed_plan` proves a boolean was set, not what the user understood.
- The current planner caps clarification at five questions, conflicting with iterative discovery.
- There is no required human-readable requirement artifact.
- The task-package prompt template is worker-oriented and does not prove it was generated from confirmed requirements.
- Existing task packets must not be broken by a new schema without migration.

## Mature Solution Evidence

### Project-local evidence

- `skills/smart-requirements/SKILL.md` already requires 5W exploration and implicit-needs analysis but lacks an iterative teach-back contract.
- `skills/金璃小天才/SKILL.md` already owns clarification and task packet generation.
- `.trae/scripts/task-guard.ps1` is the authoritative mechanical gate.
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` already treats packet files as runtime truth.
- `Docs/AI/43-AI-Workflow-Context-Efficiency-Patterns.md` already requires execution prompts for handoff.

### Official/framework evidence

- GitHub Spec Kit's clarify workflow prioritizes high-impact ambiguities, asks focused questions, and writes accepted answers into the specification.
- Requirements engineering favors iterative elicitation, validation, and shared understanding over one-shot collection.
- Existing repository architecture requires soft Skill guidance to be backed by mechanical checks where possible.

### External mature references

| Reference | Relevant pattern | Adoption |
|---|---|---|
| GitHub Spec Kit | ambiguity scan, focused clarification, spec write-back | Adopt |
| LoopEngineering | human intent followed by agent-owned planning/execution loop | Adopt |
| Grill Me | iterative interview before implementation | Adopt |
| Requirements ambiguity research | ambiguous requirements produce divergent implementations | Use as risk evidence |

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Existing boolean clarification | Current workflow | Simple | Easy to game; no shared-understanding artifact | Rejected |
| Fixed questionnaire | Traditional forms | Predictable | Burdens users; irrelevant questions; false completeness | Rejected |
| Iterative discovery + teach-back + artifacts + gate | Combined mature references | Human-friendly, inspectable, enforceable | More files and regression work | Selected |

### Rejected shortcuts

- Do not merely expand the maximum question count.
- Do not add prose to the Skill without a guard.
- Do not make `requirements.md` optional for deep tasks.
- Do not force migration of every legacy packet in this task.
- Do not let the executor derive scope directly from the original chat sentence.

### Selected mature path

Use a versioned schema so all newly initialized packets receive deep/fast classification fields. Require human-readable requirement evidence plus an execution prompt for new packets, preserve legacy compatibility, and update both guidance and regression tests.

## Acceptance Criteria

- AC01: New task initialization includes requirement-gate metadata.
- AC02: A deep version-1 task lacking confirmed requirements is blocked.
- AC03: A fast version-1 task lacking a concrete reason is blocked.
- AC04: Complete deep and fast packets pass.
- AC05: Execution prompt structure is required.
- AC06: Planner Skills encode the confirmed conversational behavior.
- AC07: Legacy packets without the version field retain current gate behavior.
- AC08: Workflow and documentation regressions pass.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
  - Expected: all scenarios pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1`
  - Expected: exit 0.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check`
  - Expected: exit 0.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-21-conversational-requirements-gate verify`
  - Expected: Verify passes after report and checklist completion.

## Residual Risk

- A model can still ask poor questions; mechanical checks guarantee artifacts and flow, while Skill pressure tests address conversation quality.
- Legacy packets are intentionally grandfathered and do not gain the new gate until recreated or migrated.
- No heuristic can perfectly classify change size, so uncertainty explicitly defaults to deep discovery.

