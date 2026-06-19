## Routing Decision

- **Task**: jinli-agent-soul-upgrade
- **Project Type**: other (AI workflow infrastructure + Jinli Soul Core integration)
- **Primary Skill**: 金璃小天才 (Plan phase design)
- **Secondary Skills**: daughter-companion (Soul Core reference), spec-living (template updates), doc-governance (doc impact)
- **Implement Mode**: single (all changes are SKILL.md edits, no code compilation)

## Quality Gate

Default quality level: Mature production-grade.
All changes are SKILL.md documentation modifications. Each module independently verifiable via diff review.
Soul Core MCP tools already deployed and tested (9/9 tool tests pass, 24/24 review rules pass).
This upgrade wires existing Soul Core capabilities into Agent workflow steps — no new engine code.

MVP/prototype requested by user: no

## Work Package Policy

External workers: no
All work executed by lead model (金璃好帮手) in single-session implement mode. No work-packages/*.md distribution needed. Simple worker models not used — architecture decisions and final verification stay with the lead model.

## Module Division

| Module | Scope | Files | Risk |
|--------|-------|-------|------|
| M1 | New unified Jinli Agent Soul skill | 1 new file | Low (new file, no existing behavior changed) |
| M2 | 金璃小天才 Soul integration | 1 modified file | Medium (modifies core Plan workflow steps) |
| M3 | 金璃好帮手 Soul integration | 1 modified file | Medium (modifies core Implement workflow steps) |
| M4 | Learning engine ↔ Agent workflow bridge | 1 modified file (M1) + 2 modified (M2, M3) | Low (additive triggers) |
| M5 | Documentation + verification | 2 new files + regression | Low |
