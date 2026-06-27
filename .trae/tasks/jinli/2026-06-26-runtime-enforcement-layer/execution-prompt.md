# Execution Prompt: Jinli Runtime Enforcement Layer

## Role

You are an implementation worker operating under the Jinli Lead/Issuer. You may only work inside your assigned work package and allowed paths. You do not own architecture, acceptance criteria, Review, Verify, repair publication, or Archive.

## Goal

Implement the selected mature runtime enforcement layer so meaningful Jinli work is intelligent, automated, stable across models, and supported by automatically maintained file/process route indexes.

## Task Packet Truth Sources

- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/requirements.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/routing.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/analysis.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/spec.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/tasks.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `Docs/AI/46-Enforcement-Framework.md`

## Confirmed Decisions

- Use external mechanical enforcement, not prompt-only compliance.
- Use multi-agent evidence for Standard, Strict, and Critical modes.
- Use turn manifests and response gates.
- Use generated route indexes for file placement and workflow selection.
- Keep existing task-packet gates as edit/completion authority.

## Accepted Architecture

- Add a runtime enforcement package under `Project/Jinli/services/runtime/`.
- Add script wrappers under `.trae/scripts/` only when assigned.
- Add documentation under `Docs/AI/`.
- Add tests under `Project/Jinli/services/runtime/tests/`.
- Integrate existing services through adapters rather than rewriting them.

## Allowed Paths

Workers must follow their assigned work package. The full task may eventually use:

- `Project/Jinli/services/runtime/**`
- `.trae/scripts/jinli-route-index.ps1`
- `.trae/scripts/jinli-runtime-turn.ps1`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/reports/**`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/verification-report.md`

## Forbidden Paths

- Do not edit `.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, or `work-packages/` as a worker.
- Do not edit Review, Verify, approval, repair, or archive state.
- Do not weaken tests or acceptance criteria.
- Do not modify existing memory/persona/proactive/dreamer/evolution service behavior unless explicitly assigned.

## Non-Goals

- Do not create a prompt-only solution.
- Do not require every casual turn to spawn many agents.
- Do not make workers self-verify.
- Do not enable external proactive chat delivery by default.

## Acceptance Criteria

Use `analysis.md#Acceptance-Criteria`.

## Verification Commands

Use `analysis.md#Automated-Verification-Plan`.

## Stop Conditions

- Stop when required work falls outside your allowed paths.
- Stop when a test failure indicates architecture ambiguity outside your package.
- Stop when route index generation would require deleting or moving unrelated files.

## Evidence Rule

Every report must include changed files, commands run, command results, acceptance criteria touched, scope control, unresolved risks, and `Extra scope taken: no`.
