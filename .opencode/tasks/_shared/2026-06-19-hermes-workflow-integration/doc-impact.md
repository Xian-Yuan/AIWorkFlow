# Documentation Impact: Hermes Workflow Integration

## Project Document Scope

- Project: _shared
- System: AI Workflow / Hermes First-Class Integration
- Owner: architecture

## Global Workflow Changes

- Planned: `.trae/hermes/**`
- Planned: `skills/hermes-project-router/**`
- Planned: `skills/hermes-jinli-planner/**`
- Planned: `skills/hermes-jinli-implementer/**`
- Planned: `skills/hermes-jinli-verifier/**`
- Planned: `.trae/scripts/sync-hermes-workflow.ps1`
- Planned: `.trae/scripts/invoke-hermes-agent.ps1`
- Planned: `.trae/scripts/test-hermes-skill-compatibility.ps1`
- Planned: `.trae/scripts/test-hermes-workflow-integration.ps1`
- Generated runtime state: `.tools/hermes-worker/**`

## No Code Changes

Reason: This task changes global AI workflow infrastructure only. It does not modify files under `Project/<ProjectName>/`.

## Documentation Updates

- `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`
- `Docs/superpowers/plans/2026-06-19-hermes-workflow-integration-plan.md`
- `Docs/AI/39-Hermes-Workflow-Integration.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/routing.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/analysis.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/tasks.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/doc-impact.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/work-packages/*.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/verification-report.md`

## Docs Tree Updates

- Not applicable: this is global AI workflow infrastructure and does not alter a project-specific `Docs/` tree.
- `Docs/AI/README.md` should index `39-Hermes-Workflow-Integration.md` during implementation.

## Documentation Governance Decision

- Formal design lives under `Docs/superpowers/specs/`.
- Executable implementation plan lives under `Docs/superpowers/plans/`.
- Runtime truth lives in this task packet.
- Durable operating guidance will live in `Docs/AI/39-Hermes-Workflow-Integration.md`.
- Secrets, memories, sessions, and generated runtime state are not documentation and remain under ignored `.tools/hermes-worker`.
