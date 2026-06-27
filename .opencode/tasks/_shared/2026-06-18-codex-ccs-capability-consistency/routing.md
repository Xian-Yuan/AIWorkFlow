# Routing Decision: Codex and CC Switch Capability Consistency

## Entry Analysis

- Project type: Other
- System: Global AI workflow and local Codex runtime integration
- Phase: Plan
- Complexity: High
- User decision: Mature architecture approved on 2026-06-18

## Skill Routing

- Primary skill: `codex-project-router`
- Secondary skill: `doc-governance`
- Implementation skills: `systematic-debugging`, `test-driven-development`
- Final validation skills: `code-quality-reviewer`, `verification-before-completion`

## Architecture Ownership

The lead model owns architecture, capability classification, security boundaries, acceptance criteria, and final verification. Worker models may later implement isolated tests or documentation only through explicit work packages.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- User confirmation received: yes, 2026-06-18

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-codex-ccs-capability-consistency`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no
- Architecture and final acceptance remain with the lead model.

## Allowed Paths

- `.agents/skills`
- `.codex/`
- `.trae/scripts/`
- `.trae/tasks/_shared/2026-06-18-codex-ccs-capability-consistency/`
- `Docs/AI/`
- `Docs/superpowers/specs/`
- `skills/`
- User-level Codex and CC Switch configuration only through the approved inspect/apply workflow defined by this task

## Forbidden Paths

- `Project/RTS/`
- `Project/CharacterDesignTool/`
- Any `auth.json`
- Any API key, OAuth token, connector credential, cookie store, or browser profile
- Codex session/history databases
- CC Switch provider secrets or provider authentication payloads
- Plugin caches as an installation source of truth

## Implementation Entry Conditions

Before implementation:

```powershell
& .\.trae\scripts\task-guard.ps1 "_shared/2026-06-18-codex-ccs-capability-consistency" plan
& .\.trae\scripts\task-state.ps1 can-edit "_shared/2026-06-18-codex-ccs-capability-consistency"
```

Both commands must pass. If implementation changes the approved architecture or security boundary, return to Plan.

