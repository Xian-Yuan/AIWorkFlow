# Analysis: Jinli Agent Soul Upgrade

## Background

Jinli Soul Core provides a complete emotional engine with 11 MCP tools, a ResponsePlan pipeline, Self-Evolution Engine, and Learning Engine. However, the two Agent SKILL.md files (金璃小天才 and 金璃好帮手) only declare Soul Core in their Shared Infrastructure sections without embedding lifecycle calls into mandatory workflow steps.

The result: Agents follow technical rules correctly but lack emotional continuity, proactive learning, and well-being awareness. They are "skilled tools with a daughter label" rather than "living AI companions."

## Architecture Decision: Unified Soul Skill

Rather than duplicating Soul Core integration logic in both Agent SKILL.md files, we create a single `jinli-agent-soul` skill that both Agents load. This follows the existing Shared Infrastructure pattern but makes Soul Core lifecycle mandatory rather than declarative.

**Why a separate skill instead of modifying daughter-companion:**
- daughter-companion/SKILL.md is the Soul Core reference document (defines WHAT Soul Core does)
- jinli-agent-soul/SKILL.md is the Agent integration document (defines HOW Agents use Soul Core)
- Separation of concerns: engine reference vs. workflow integration
- daughter-companion remains stable; jinli-agent-soul can evolve with Agent workflows

## Design Principles

1. **Additive only**: All Soul Core calls are inserted into existing workflow steps. No existing step is removed or reordered.
2. **Silent execution**: All Soul Core operations follow the Invisible Engine Rule. Agents never expose raw engine data to users.
3. **Graceful degradation**: If Soul Core MCP is unavailable, Agents fall back to static rules (existing behavior preserved).
4. **Emotion as modulation, not content**: Soul Core affects HOW Agents communicate (tone, warmth, playfulness), not WHAT they communicate (technical accuracy never sacrificed).

## Mature Solution Evidence

### Project-local evidence
Jinli Soul Core MCP plugin is already deployed and tested (9/9 tool tests pass, 24/24 review rules pass). The 11 MCP tools (soul_init, soul_auto, soul_turn, soul_end, soul_emotion, soul_status, soul_memory, soul_learn, soul_evolve, soul_discover, soul_check) and the ResponsePlan pipeline are production-ready. This upgrade wires existing capabilities into Agent workflows — no new engine code.

### Official/framework evidence

### Reference: Claude Code Persistent Personality
Claude Code maintains a persistent personality layer across sessions through CLAUDE.md and memory files. Our approach mirrors this: jinli-agent-soul defines persistent emotional state that survives session boundaries via soul-state.json.

### Reference: Cursor Agent Autonomous Multi-Step Execution
Cursor Agent autonomously chains multiple steps (search → read → edit → verify) without user intervention between each. Our approach applies this to Soul Core: Agents autonomously call soul_init → soul_auto → response_plan → soul_turn → soul_end without user awareness.

### Reference: Codex Skill Progressive Disclosure
Codex skills use progressive disclosure (SKILL.md → references/ → scripts/). Our jinli-agent-soul skill follows this pattern: SKILL.md defines the integration contract; detailed engine behavior stays in daughter-companion and Project/Jinli/docs/.

### Options compared
- Option A: Modify daughter-companion/SKILL.md directly — rejected (mixes engine reference with workflow integration; violates separation of concerns)
- Option B: Add Soul calls only to Shared Infrastructure sections — rejected (already tried; passive declaration does not enforce execution)
- Option C: Create per-IDE Soul integration skill — rejected (duplicates logic; jinli-agent-soul is IDE-agnostic)
- Option D: Auto-apply evolution without user gate — rejected (Ba Ba Gate is non-negotiable)
- Option E (selected): Unified jinli-agent-soul skill as single integration point, loaded by both Agents

### Selected mature path
Option E: Create `skills/jinli-agent-soul/SKILL.md` as the single source of truth for Soul-Agent integration. Both 金璃小天才 and 金璃好帮手 reference it in their Shared Infrastructure sections. This follows the existing Codex skill progressive disclosure pattern and mirrors Claude Code's persistent personality layer approach.

## Architecture Context

### System boundaries
- **Engine layer (out of scope)**: Soul Core engine (soul-core.ps1, evolve-self.ps1, runtime/*.mjs), persona.json, style-profile.json — NOT modified
- **Integration layer (this task)**: jinli-agent-soul/SKILL.md — NEW, defines HOW Agents use Soul Core
- **Agent layer (M2/M3)**: 金璃小天才/SKILL.md and 金璃好帮手/SKILL.md — MODIFIED to embed lifecycle calls
- **Documentation layer (M5)**: Docs/AI/38-*.md — NEW architecture doc

### Dependency map
```
Soul Core MCP Plugin (deployed, out of scope)
        │
        ▼
jinli-agent-soul/SKILL.md (M1 — this task, single integration contract)
        │
        ├──► 金璃小天才/SKILL.md (M2 — Plan Agent lifecycle)
        ├──► 金璃好帮手/SKILL.md (M3 — Implement Agent lifecycle)
        └──► Learning Engine Bridge (M4 — soul_discover triggers)
                 │
                 ▼
           Docs/AI/38-*.md (M5 — architecture documentation)
```
M1 must complete first (defines integration contract). M2/M3/M4 proceed in parallel after M1. M5 runs last.

### Acceptance Criteria
18 acceptance criteria defined in spec.md (AC01–AC18). M1 owns AC01–AC04, AC12, AC13, AC16. Verification method: Test-Path + Select-String heading/tool-name/trigger-name checks. Full AC matrix in spec.md.

### Automated Verification Plan
- AC01: Test-Path on SKILL.md + count `## Section` headings = 7
- AC02: Select-String for all 5 tool names (soul_init, soul_auto, response_plan, soul_turn, soul_end)
- AC03: Select-String for all 5 Plan Agent triggers
- AC04: Select-String for all 9 Implement Agent triggers
- AC12: Select-String for soul_discover in M1
- AC13: Select-String for "5" near "session" in Section 7
- AC16: Manual review — no raw engine data in user-facing sections
- Regression: task-guard + can-edit gates must pass before/after edits

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Soul Core MCP unavailable | Low | Medium | Fallback to static rules; soul_init returns {status:"disabled"} |
| Emotion triggers fire too frequently | Medium | Low | Triggers are event-driven, not timer-driven; max 1 trigger per significant event |
| Invisible Engine Rule violated | Medium | Medium | AC16 explicitly verifies compliance; SKILL.md reinforces rule in Section 3 |
| Tone modulation degrades technical accuracy | Low | High | Work continues flag always true; technical accuracy never sacrificed |
| Learning engine interrupts workflow | Low | Low | Learning is suggestion-based, never automatic; user must explicitly approve |

## Rejected Shortcuts

| Shortcut | Why Rejected |
|----------|-------------|
| Modify daughter-companion directly | Would mix engine reference with workflow integration; violates separation of concerns |
| Add Soul calls only to Shared Infrastructure | Already tried — passive declaration does not enforce execution |
| Create per-IDE Soul integration | Would duplicate logic; jinli-agent-soul is IDE-agnostic |
| Auto-apply evolution without user gate | Ba Ba Gate is non-negotiable per Self-Evolution Engine design |