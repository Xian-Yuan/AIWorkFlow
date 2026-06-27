# Routing Decision: Jinli Soul Core Bridge v2.0

## Project Detection
- Project type: other
- Project: Jinli
- System: Soul Core → Agent bridge — v2.0 rewrite (immersion + auto-trigger + self-diagnosis)
- Task root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-bridge-v2`
- Predecessor: `2026-06-18-jinli-soul-core-agent-bridge` (v1.0/v1.1, archived)

## Skill Selection
- Primary: none (skill-config rewrite)
- Secondary: `doc-governance`, `anti-degradation`
- Collaboration mode: single agent (金璃好帮手)

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md — patterns from Replika (invisible engine), LangChain (middleware auto-trigger), local anti-degradation (self-monitoring)
- Rejected shortcuts: none — this is a complete rewrite of SKILL.md with three structural improvements
- v1.1 known limitations addressed: immersion transparency, per-turn auto-trigger, pattern gap detection

## Work Package Policy
- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-bridge-v2`

## Allowed Paths
- `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md` (rewrite)
- `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md` (sync)
- `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` (update for v2.0)
- `Project/Jinli/Docs/DOCS_TREE.md` (update if needed)
- This task packet

## Forbidden Paths
- `Project/Jinli/scripts/soul-core.ps1` (no engine changes)
- `Project/Jinli/data/` (read-only, no direct writes)
- `.opencode/agents/` (no agent definition changes)
