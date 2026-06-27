# Routing Decision: Workflow Optimization

## Entry Analysis
- **Type:** Other (workflow/governance infrastructure)
- **Phase:** Plan (design complete, awaiting user confirmation)
- **Complexity:** Medium — 27 file operations across 7 modules, no code compilation

## Architecture Decision
- **Implement Mode:** direct (no branching needed for config/docs/scripts changes)
- **Primary Skill:** None — this is workflow infrastructure, not UE5/Web feature work
- **No compilation needed** — all changes are PowerShell scripts, Markdown docs, and directory restructuring

## Scope

Optimize the AI workflow system across 7 modules:

1. **M1: Destroy dual-track** — delete 10 duplicate scripts from `engine/`, keep only unique assets
2. **M2: Disable experimental scripts** — add `_DISABLED.` prefix to `engine/_experimental/test-*.ps1`
3. **M3: Stub expiry policy** — declare 3-month expiry, create cleanup script
4. **M4: Gate enforcement** — embed mandatory gate check block in AGENTS.md
5. **M5: Automated regression** — create task/spec templates with verification steps
6. **M6: Semantic memory** — add `-Semantic` parameter to memory-retrieve.ps1
7. **M7: Codex adapter** — create `.codex/tasks/` junction to `.trae/tasks/`

## References
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` — authoritative workflow declaration
- `Docs/AI/29-Mature-Solution-First-Workflow.md` — mature path requirement
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` — task packet standard
- `Docs/AI/34-AI-Workflow-Current-Audit.md` — current state audit (§A1, §A3, §I3, §I4)
- `.trae/tasks/_shared/pending-checklists/2026-06-17-doc-migration-acceptance-gaps.md` — gap definitions
- `.agents/skills/金璃小天才/SKILL.md` — agent constraint (no incremental minimal plans)

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes (see analysis.md#Rejected-shortcuts)
- User confirmation must include quality level: yes

## Work Package Policy
- This task is self-contained (workflow infrastructure, no project code changes).
- No sub-work-packages needed — all 7 modules are sequential dependencies on the same file set.
- External workers: no (single implementer can handle all changes).
- If delegated: worker must not own architecture decisions; must return evidence per module.
