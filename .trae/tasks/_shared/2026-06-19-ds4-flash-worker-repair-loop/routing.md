# Routing Decision: DS4 Flash Worker Repair Loop

## Entry Analysis

- Project type: Other
- System: Shared multi-agent task packet workflow
- Phase: Plan
- Complexity: High
- User confirmation: approved on 2026-06-19

## Skill Routing

- Primary: `codex-project-router`
- Secondary: `doc-governance`
- Implementation: `test-driven-development`
- Failure diagnosis: `systematic-debugging`
- Completion: `verification-before-completion`

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

This workflow task is implemented by Codex. The feature being built will enforce DS4-specific work packages for future delegated tasks.

## Worker Repair Policy

- Worker profile supported: ds4-flash
- Default lead/verifier: codex
- Fresh context per repair: yes
- Automatic repair package generation: yes
- Maximum attempts per root cause: 3
- Same-context worker self-verification: forbidden
- Only lead may set Review/Verify pass: yes

## Allowed Paths

- `.trae/scripts/`
- `.trae/tasks/_shared/templates/`
- `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop/`
- `Docs/AI/`
- `Docs/superpowers/specs/`
- `Docs/superpowers/plans/`
- `AGENTS.md`

## Forbidden Paths

- `Project/`
- `.codex/config.toml`
- user-level Codex or CC Switch configuration
- credentials, tokens, session databases

