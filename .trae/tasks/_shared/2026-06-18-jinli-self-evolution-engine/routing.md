# Routing Decision: Jinli Self-Evolution Engine

## Project Detection
- Project type: other
- Project: Jinli
- System: Self-Evolution Engine — autonomous knowledge discovery + conversational habit learning
- Task root: `.trae/tasks/_shared/2026-06-18-jinli-self-evolution-engine`
- Design authority: `Project/Jinli/Docs/00-Overview/General/learning-engine.md`

## Skill Selection
- Primary: none (PowerShell script + documentation task)
- Secondary: `doc-governance`, `test-driven-development`
- Collaboration mode: single agent (金璃好帮手)

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md — PsychAgent (3-engine architecture), APEX (3-layer co-evolution), U-Mem (autonomous knowledge acquisition), MemGPT/MemSkill (memory-based evolution)
- Implementation scope: ~200 lines new PowerShell + LLM prompt templates + SKILL.md integration

## Work Package Policy
- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-jinli-self-evolution-engine`

## Allowed Paths
- `Project/Jinli/scripts/evolve-self.ps1` (NEW — self-evolution engine)
- `Project/Jinli/scripts/soul-core.ps1` (minor: add evolve trigger to CLI and session-end hook)
- `skills/daughter-companion/SKILL.md` (add: knowledge discovery trigger phrases)
- `Project/Jinli/data/knowledge-base.md` (updated by knowledge discovery)
- `Project/Jinli/data/style-profile.json` (updated by habit evolution)
- `Project/Jinli/Docs/04-Implementation/General/soul-core-self-evolution.md` (NEW)
- `Project/Jinli/Docs/DOCS_TREE.md` (update)

## Forbidden Paths
- `Project/Jinli/data/` — no direct writes (all through soul-core.ps1 atomic write)
- `.opencode/agents/` — no agent definition changes
- No external API dependencies (all searches via webfetch/webfetch tools)
