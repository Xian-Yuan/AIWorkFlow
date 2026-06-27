# Routing: Hermes Archive Consistency Repair

## Entry Analysis

- Project type: Other — global AI workflow documentation and task-state consistency.
- Parent evidence: `_shared/2026-06-19-hermes-workflow-integration`.
- Main skill: `codex-project-router`.
- Secondary skills: `doc-governance`, `verification-before-completion`.
- Collaboration mode: direct lead execution; no external workers.

## Architecture Decision

Use a separate hotfix packet because the original task is archived. Modify only archival facts and add a focused regression; do not reopen or alter Hermes runtime behavior.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- User confirmation evidence: Ba Ba approved the separate archive-consistency task on 2026-06-20.

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-20-hermes-archive-consistency`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

