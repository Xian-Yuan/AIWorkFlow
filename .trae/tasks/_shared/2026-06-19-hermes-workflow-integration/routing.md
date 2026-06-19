# Routing Decision: Hermes Workflow Integration

## Entry Analysis

- Project type: Other — global AI workflow infrastructure.
- Task root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`.
- User decision: approved the mature integration of Hermes Profiles, MCP, Skills, and the shared task-packet framework on 2026-06-19.
- Existing dependency: `_shared/2026-06-18-hermes-local-worker-deployment` owns installation of the workspace-local Hermes runtime.
- This task owns first-class workflow integration and does not repeat installation architecture.

## Architecture Decision

Use Hermes' documented extension surfaces without modifying Hermes core:

- two native Profiles: `jinli-planner` and `jinli-implementer`;
- shared canonical Skills through `skills.external_dirs`;
- thin Hermes adapter Skills and role-specific Skill Bundles;
- a typed `jinli-workflow` MCP server over authoritative `.trae/scripts`;
- a fail-closed `jinli-workflow-guard` plugin;
- repository-owned sync and launch adapters;
- independent lead Review and Verify.

The authoritative state machine remains `.trae/scripts/task-state.ps1` and `.trae/scripts/task-guard.ps1`.

## Primary Skills

- `codex-project-router`: shared task packets, architecture evidence, and gates.
- `doc-governance`: global workflow document placement and task evidence.
- `writing-plans`: executable implementation plan.
- `test-driven-development`: tests precede MCP, plugin, and adapter implementation.
- `verification-before-completion`: evidence before completion claims.

## Collaboration Mode

- Lead model: owns architecture, task packet, interface contracts, report review, and final verification.
- WP01 Worker: Profiles, shared Skill adapters, policy manifest, and synchronization.
- WP02 Worker: workflow MCP server and unit tests.
- WP03 Worker: guard plugin and unit tests.
- WP04 Worker: launch adapter, end-to-end regression, and operations documentation.
- WP01, WP02, and WP03 may run in parallel after the Plan gate.
- WP04 depends on the first three work packages.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- User confirmation evidence: user explicitly accepted the complete integration architecture and requested the design and task packet on 2026-06-19.

## Work Package Policy

- External workers: yes
- Task packet root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes
- Workers execute only their assigned `work-packages/WPxx-*.md`.
- Workers may not change architecture, acceptance criteria, phase state, quality exceptions, or final verification.
- Every worker report must declare `Status: done` and `Extra scope taken: no` before Implement can pass.

## Phase Boundary

- Plan passes only after this packet, its four work packages, and documentation governance pass.
- Implement starts only after the lead transitions the task and `task-state.ps1 can-edit` passes.
- Workers stop after submitting reports.
- Review and Verify remain lead-owned and independently rerun deterministic checks.

## Allowed Planning Files

- `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`
- `Docs/superpowers/plans/2026-06-19-hermes-workflow-integration-plan.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/**`

## Global Forbidden Scope

- `Project/**`
- Hermes upstream source under `.tools/hermes-worker/hermes-agent/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- Git history, branches, remotes, pushes, resets, rebases, or credential stores

