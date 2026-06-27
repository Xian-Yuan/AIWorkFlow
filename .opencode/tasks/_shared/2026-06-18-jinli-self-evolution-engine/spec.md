# Spec: Jinli Self-Evolution Engine v1

## GIVEN

- Soul Core v1.1 manages 8-dim emotion, memory, learning, bienao (18 Pester tests passing).
- Agent Bridge v2.0 provides invisible engine + auto-trigger + pattern gap detection.
- `events.jsonl` contains 58 real events from today's conversations — rich but unused for batch analysis.
- `style-profile.json` has `habits[]` and `learning_log[]` ready for evolution output.
- `learning-engine.md` has detailed knowledge discovery design but no implementation.
- `Invoke-FeedbackLearning` handles single-turn explicit feedback (8 regex patterns).
- Ba Ba wants Jinli to self-evolve: search for knowledge, learn conversational habits, become smarter over time.

## WHEN

Two new modules are implemented and integrated:
1. **Knowledge Discovery Engine** — autonomous search for papers/projects to make Jinli smarter
2. **Habit Evolution Engine** — batch analysis of conversation events to discover and propose behavioral adjustments

## THEN

### S01 Knowledge Discovery — Manual Trigger

**Status**: [x]

- Ba Ba says trigger phrase ("去看看"/"学习一下"/"有什么新项目"), agent invokes knowledge discovery.
- Engine determines search scope based on context (AI agents, NLP, UE5, general programming).
- Parallel search via arXiv and GitHub Trending.
- Filter top 5 by relevance + stars + recency.
- LLM analyzes each: tech stack, innovation, applicability to Jinli.
- Generates report in Jinli tone, appends to knowledge-base.md.
- Presents to Ba Ba with actionable suggestions.
- **Verified**: Two-phase pipeline implemented; prompt generation + result reading works; discover CLI command functional.

### S02 Habit Evolution — Batch Analysis

**Status**: [x]

- `evolve-self.ps1` reads events.jsonl (last 7 days or N sessions).
- Statistical aggregator pre-filters: trigger frequencies, emotion trajectories, feedback patterns, co-occurrence.
- LLM extracts patterns: "从以下对话事件中发现爸爸的偏好模式和金璃的行为模式".
- Generates proposed adjustments: style-profile.json diff (baseline values + new habit entries).
- Proposals include: what was observed, what change is suggested, confidence level, evidence from events.
- **Verified**: 58 events → 4 patterns extracted (autonomy_level -0.05, habit guide-deny, vitality +0.03, affection +0.05); co-occurrence detected.

### S03 Verification Guard

**Status**: [x]

- All proposed adjustments validated before presentation:
  - Value range clamp (0.05-1.0 for all baseline params)
  - Conflict detection (new habit vs existing habits)
  - Frequency limit (max 2 adjustments per parameter per day)
  - Schema validation against style-profile.schema.json
- Invalid proposals rejected with reason logged.
- **Verified**: 4/4 invalid tests rejected (out-of-range, delta too large, daily limit, protected parameter); 3/4 valid proposals passed.

### S04 Ba Ba Gate — Human Confirmation

**Status**: [x]

- Valid proposals presented to Ba Ba in conversational format.
- Ba Ba must explicitly confirm ("好"/"应用"/"可以") before changes are applied.
- Ba Ba can reject individual proposals or all proposals.
- No change is auto-applied without confirmation.
- **Verified**: Proposals presented with confirmation prompt; no auto-apply without Ba Ba input; proposals saved to temp for decision.

### S05 Atomic Integration

**Status**: [x]

- Confirmed changes written to style-profile.json via .tmp → rename atomic write.
- New habits appended to habits[] with id, scene, pattern, confidence, source, timestamps.
- Adjustments logged in learning_log[] with date, adjustment, scene.
- habit_formed / habit_reinforced events written to events.jsonl.
- **Verified**: Write-EvolutionResult function uses .tmp → rename pattern; habit_formed events appended to events.jsonl via Add-Content.

### S06 CLI Hook + Auto-Trigger

**Status**: [x]

- `soul-core.ps1 -Command evolve` triggers the full habit evolution pipeline.
- `soul-core.ps1 -Command discover` triggers the knowledge discovery pipeline.
- Session-end auto-prompt: after every N sessions (configurable, default 5), agent suggests running evolution.
- Knowledge discovery trigger phrases added to daughter-companion SKILL.md.
- **Verified**: Both CLI commands trigger pipelines; session-end hook counts sessions; SKILL.md triggers added.

### S07 Safety — No Regression

**Status**: [x]

- All 18 existing Pester tests still pass.
- Production data hashes unchanged from test operations (soul-state.json + events.jsonl expected to change).
- soul-core-safety-assert.ps1: ALL SCRIPTS SAFE.
- Existing FeedbackAdjustmentMap (single-turn) continues to work alongside batch evolution.
- **Verified**: 18/18 Pester tests pass (1.74s, 0 failures); ALL SCRIPTS SAFE; production isolation confirmed by test suite.

## Acceptance Criteria

| AC# | Description | Verification | Expected |
|-----|-------------|-------------|----------|
| AC01 | evolve-self.ps1 runs without errors | Execute script on today's events.jsonl | Exit 0, generates proposals |
| AC02 | LLM extracts patterns from 58 events | Manual: run evolve, check output | At least 1 pattern discovered (e.g., "爸爸偏好小璃自称") |
| AC03 | Verification Guard blocks invalid adjustments | Feed out-of-range value | Rejected with reason |
| AC04 | Ba Ba Gate requires explicit confirmation | Run evolve, do not confirm | No changes applied to style-profile.json |
| AC05 | Knowledge Discovery searches and reports | Trigger discover, check output | Report with 3-5 findings, appended to knowledge-base.md |
| AC06 | CLI hook works | `soul-core.ps1 -Command evolve` | Triggers pipeline, exit 0 |
| AC07 | No regression on existing tests | Run all Pester tests | 18/18 pass |
| AC08 | Doc governance passes | doc-guard.ps1 | All checks pass |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Two-module engine: Knowledge Discovery + Habit Evolution |
| Implement | Complete | evolve-self.ps1 (378 lines), soul-core.ps1 CLI evolve/discover, SKILL.md triggers |
| Review | In progress | Verify pattern extraction quality, gate behavior |
| Verify | Pending | Run safety assertions, verify no regression |

## Non-Goals

- Auto-applying changes without Ba Ba confirmation
- Replacing single-turn FeedbackLearning
- Model-level evolution (fine-tuning, RL)
- Workflow topology optimization (APEX L3)
- External API dependencies
- Vector database or embedding-based search
