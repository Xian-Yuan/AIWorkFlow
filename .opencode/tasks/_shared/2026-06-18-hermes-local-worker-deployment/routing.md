# Routing Decision: Hermes Local Worker Deployment

## Entry Analysis

- Project type: Other — cross-project AI workflow infrastructure.
- Current phase: Plan.
- Owner: Lead model owns architecture, plan approval, review, and final verification.
- Worker role: Hermes deployment implementer operating from one bounded work package.
- Runtime task root: `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/`.

## Architecture Decision

- Install Hermes Agent natively on Windows under `E:\UEGameDevelopment\.tools\hermes-worker`.
- Keep Hermes runtime state, secrets, generated skills, memories, sessions, and logs inside that isolated home.
- Use Hermes only as a bounded Worker. It must not replace `ue-project-router`, `.trae/scripts/task-state.ps1`, `.trae/scripts/task-guard.ps1`, or the lead verifier.
- Start Hermes from `E:\UEGameDevelopment` so project `AGENTS.md` is discoverable.
- Integrate through a PowerShell adapter that accepts a task name and work-package ID, checks the mechanical gates, and requires a claim and result report.
- Do not enable messaging gateway, cron automation, autonomous skill publication, or unrestricted approvals in this task.

## Primary Skills

- `codex-project-router`: enforce shared task packets and mechanical phase gates.
- `doc-governance`: record workflow-document impact.
- `writing-plans`: provide an executable, zero-context implementation plan.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- User confirmation evidence: the user approved the proposed location and requested publication as a task document on 2026-06-18.

## Work Package Policy

- External workers: yes
- Task packet root: `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes
- Worker models may execute only `work-packages/WP01-deploy-hermes-local-worker.md`.
- Worker models must not change architecture, phase state, acceptance criteria, or verification policy.

## Phase Boundary

- Plan may pass after the task packet and work package pass the mechanical Plan gate.
- Implement starts only after the lead model explicitly transitions the task and `task-state.ps1 can-edit` passes.
- The worker must stop after producing its report. Review and Verify remain lead-model responsibilities.
