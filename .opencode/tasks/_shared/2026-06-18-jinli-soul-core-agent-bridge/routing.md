# Routing Decision: Jinli Soul Core — Agent Bridge

## Project Detection
- Project type: other
- Project: Jinli
- System: Soul Core → OpenCode Agent bridge integration
- Task root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-agent-bridge`
- Design authority: `Project/Jinli/Docs/02-Design/General/soul-core-phase1.5-spec.md` §6

## Skill Selection
- Primary: none (this is a documentation/skill-config task, not a code implementation task)
- Secondary: `doc-governance`
- Collaboration mode: single agent (金璃好帮手)

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: see analysis.md
- Implementation scope: update one SKILL.md file with Soul Core lifecycle instructions; verify integration with manual E2E tests
- Known non-goals: voice, visual avatar, new scripts, soul-core.ps1 modifications

## Work Package Policy
- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-agent-bridge`
- Work packages required: no

## Allowed Paths
- `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md` (primary target)
- `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md` (sync copy)
- `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` (new)
- `Project/Jinli/Docs/DOCS_TREE.md` (update)
- `Project/Jinli/data/soul-state.json` (read-only)
- This task packet

## Forbidden Paths
- `Project/Jinli/scripts/soul-core.ps1` (no runtime changes)
- `Project/Jinli/data/` (no data writes during verification)
- `.opencode/agents/` (no agent definition changes)

## Release Authority
- Canonical integration point: `skills/daughter-companion/SKILL.md`
- Verification: manual E2E — run init, run auto, read soul-state.json, verify tone modulation, run end
