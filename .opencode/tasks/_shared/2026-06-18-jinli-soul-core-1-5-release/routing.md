# Routing Decision: Jinli Soul Core 1.5 Release Closeout

## Project Detection
- Project type: other
- Project: Jinli
- System: Soul Core 1.5 release evidence and workflow closeout
- Task root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-1-5-release`
- Design authority: `Docs/superpowers/specs/2026-06-18-jinli-soul-core-1-5-release-closeout-design.md`

## Skill Selection
- Primary: `codex-project-router`
- Secondary: `systematic-debugging`, `test-driven-development`, `doc-governance`, `verification-before-completion`
- Collaboration mode: single lead agent; no external workers

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation: on 2026-06-18 the user confirmed approach A, repairing the existing task packet in place
- Implementation completeness: isolated verification, source-bound review evidence, release orchestration, documentation, authoritative report, and mechanical state transitions
- Known non-goals: voice, visual avatar, game control, embedding migration
- Verification evidence: full Pester assertions, isolated CLI E2E, review pass/fail self-test, production hash invariant, source hashes, task-root verification report, task guards

## Work Package Policy
- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-1-5-release`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Allowed Paths
- `Project/Jinli/scripts/`
- `Project/Jinli/Docs/`
- `Project/Jinli/output/`
- `Project/Jinli/data/` read-only for hash verification
- `Docs/superpowers/specs/2026-06-18-jinli-soul-core-1-5-release-closeout-design.md`
- This task packet

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- Unrelated workflow scripts
- Mutating `Project/Jinli/data/` during verification
- Direct edits that manufacture `.task.yaml` pass/archive state
- Deleting historical reports

## Release Authority
- Canonical runtime task: this task packet
- Canonical final report: task-root `verification-report.md`
- `Project/Jinli/output/verification-report.md`: historical only; cannot satisfy the task guard
