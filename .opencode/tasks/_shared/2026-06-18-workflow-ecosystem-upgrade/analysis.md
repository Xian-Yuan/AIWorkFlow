# Analysis: AI Workflow Ecosystem Upgrade

## Background

The ecosystem survey (`Docs/AI/research/2026-06-AI-Agent-Ecosystem-Survey.md`) evaluated 15+ GitHub projects and 3 architecture trends against the current AI workflow. Four integrations were identified as high-value:

| Priority | Project | Value | Feasibility |
|----------|---------|-------|-------------|
| P0 | spec-kit checklist philosophy | Upgrade spec-template.md with requirement-quality checks | Zero-risk (template-only) |
| P0 | Agent-Reach multi-platform search | Upgrade Plan phase search from single to multi-platform | Blocked by GitHub network |
| P1 | mattpocock handoff pattern | Upgrade handoff templates with structured context | Zero-risk (template-only) |
| P1 | Graphify code knowledge graph | Accelerate large-codebase understanding in Plan phase | Needs UE5 macro validation first |

## Decision: 3 Modules, 1 Deferred

**Selected for this task:**
- M1: spec-template.md Quality Checklist (P0, zero-risk)
- M2: Plan Agent multi-platform search strategy (P0, doc upgrade even without Agent-Reach installed)
- M3: Handoff template Context Snapshot (P1, zero-risk)

**Deferred:**
- M4 (Agent-Reach install): Documented only — blocked by GitHub network access. Integration path documented in `Docs/AI/37-Agent-Reach-Integration.md` for future activation.
- Graphify: P1 validation needed on UE5 C++ macros before integration decision.

## Architecture Constraints

1. **No new dependencies**: All changes are template/documentation edits. No npm/pip packages added.
2. **Backward compatible**: Existing tasks created with old templates continue to work. New templates are additive.
3. **Skill consistency**: Plan Agent SKILL.md changes must not break existing Step 1e behavior — multi-platform is an enhancement, not a replacement.
4. **spec-kit philosophy, not spec-kit code**: We borrow the "Unit Tests for Requirements" concept, not the CLI tool. No `pip install specify` needed.

## Mature Solution Evidence

### M1: Quality Checklist
- **External reference**: github/spec-kit (90k+ stars) — `/checklist` command with "Unit Tests for English" philosophy
- **Key insight**: Checklist items test requirement quality (completeness, clarity, consistency), NOT implementation behavior
- **Why not install spec-kit CLI**: Our task packet system (spec.md + tasks.md + .task.yaml) already covers the SDD workflow. Adding another CLI would create dual-source-of-truth conflict.

### M2: Multi-Platform Search
- **External reference**: Agent-Reach (32.5k stars) — 162 tests, 13 channels, 32 end-to-end tests
- **Key insight**: Plan phase research benefits from cross-platform signals (GitHub for code, Reddit/HN for community validation, X for trend awareness)
- **Why not enforce Agent-Reach**: Network restriction blocks pip install from GitHub. Strategy: document the integration path, implement what we can with existing tools (websearch for Reddit/HN, GitHub code search), make Agent-Reach a "when available" enhancement.

### M3: Handoff Context Snapshot
- **External reference**: mattpocock/skills (68k stars) — `/handoff` command with structured context transfer
- **Key insight**: "What the next agent needs to know in 60 seconds" — active decisions, open questions, known constraints, file change summary
- **Integration**: Extends existing `Docs/AI/09-Agent-Handoff-Templates.md` without breaking current format.

## Rejected Shortcuts

| Shortcut | Why Rejected |
|----------|-------------|
| Install spec-kit CLI directly | Would create dual-source-of-truth with our task packet system |
| Skip Agent-Reach entirely | Valuable capability; document for future activation rather than discard |
| Copy mattpocock templates verbatim | Different agent architecture (they use slash commands, we use skill loading) |
| Add Graphify now without validation | tree-sitter UE5 macro support unverified; risk of misleading architecture graphs |

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Quality Checklist items become checkbox theater | Medium | Low | Template guidance emphasizes "test requirements, not implementation" |
| Multi-platform search instructions confuse AI | Low | Medium | Clear fallback hierarchy: GitHub → web → Agent-Reach |
| Handoff Context Snapshot duplicates existing sections | Low | Low | Design review before merge; integrate with existing structure |
| Agent-Reach doc becomes stale | Low | Low | Mark as "blocked" with clear activation condition |
