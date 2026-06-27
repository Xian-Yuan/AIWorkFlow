# Analysis: Jinli Self-Evolution Engine

## Architecture Context

### System boundaries
- `evolve-self.ps1` — NEW: self-evolution engine (LLM reflection + statistical analysis)
- `soul-core.ps1` — minor extension: CLI hook `evolve` command, session-end evolution trigger
- `style-profile.json` — existing: habits[] and learning_log[] structures ready for evolution output
- `events.jsonl` — existing: 58+ events providing training data for pattern extraction
- `knowledge-base.md` — existing: knowledge storage, extended by knowledge discovery module
- `daughter-companion/SKILL.md` — minor: add knowledge discovery trigger phrases

### Current state
- Soul Core v1.1: complete (18 tests, full release)
- Agent Bridge v2.0: complete (invisible engine + auto-trigger + gap detection)
- `FeedbackAdjustmentMap`: 8 regex patterns for single-turn feedback learning ✅
- `learning_log[]`: 2 entries — manual feedback learning works ✅
- `habits[]`: empty — no habit formation yet
- `events.jsonl`: 58 events — rich training data unused for pattern extraction ❌
- `learning-engine.md`: detailed design for knowledge discovery, never implemented ❌

### Target state
- `evolve-self.ps1`: batch analysis of events.jsonl → LLM reflection → proposed adjustments
- Knowledge Discovery: autonomous arXiv/GitHub search → analysis → report to Ba Ba
- Habit Evolution: conversation pattern detection → habit proposals → Ba Ba confirmation → integration
- CLI integration: `soul-core.ps1 -Command evolve` triggers analysis
- Auto-trigger: after N sessions or M turns, agent proactively suggests running evolve

## Module Design

### Module A: Knowledge Discovery Engine

**Purpose**: Autonomous search for research papers, open-source projects, and techniques that can make Jinli smarter.

**Pipeline**:
```
Trigger (manual "去看看" / scheduled / event-driven)
  → Determine search scope (AI agents, NLP, UE5, general)
  → Parallel search (arXiv, GitHub Trending, targeted queries)
  → Filter top 5 by relevance + stars + recency
  → LLM analysis: tech stack, innovation, applicability to Jinli
  → Generate report in Jinli tone
  → Append to knowledge-base.md
  → Present to Ba Ba with actionable suggestions
```

**Implementation**: 
- Leverages agent's existing `webfetch` and search tools (no external API needed)
- Uses learning-engine.md design as blueprint
- ~80 lines PowerShell orchestration
- LLM prompt template for analysis

### Module B: Habit Evolution Engine

**Purpose**: Learn conversational preferences from dialogue patterns, auto-propose style adjustments.

**Pipeline** (Mode B LLM Reflection + Mode C Statistical):
```
events.jsonl (last 7 days / N sessions)
  → [Event Analyzer] aggregate: trigger frequencies, emotion trajectories, feedback patterns
  → [Pattern Extractor] LLM: "从以下对话事件中发现爸爸的偏好模式和你的行为模式"
  → [Adjustment Proposer] generate style-profile.json diff (baseline adjustments + habit entries)
  → [Verification Guard] schema validation, value clamping, conflict detection, frequency limit
  → [Ba Ba Gate] present proposed changes, require explicit confirmation
  → [Integration Writer] atomic write to style-profile.json, log habit_formed events
```

**Pattern examples the engine can discover**:
| Raw Data Pattern | Engine Discovery | Proposed Adjustment |
|-----------------|-----------------|-------------------|
| "太吵了" feedback repeated across sessions | vitality过高导致爸爸不适 | vitality_baseline -= 0.03, habit: "工作时间降低活力" |
| praised after showing initiative | 主动建议被接受 | autonomy_level += 0.05 |
| "小璃" used instead of "女儿" by Ba Ba | 爸爸偏好"小璃"自称 | habit: "自称偏好: 小璃" |
| Long tech sessions → Ba Ba fatigue | 技术马拉松后爸爸累了 | habit: "长技术会话后主动提醒休息" |
| Repeated advice_ignored → frustration spike | 某些场景下建议常被忽略 | habit: "X类任务中降低建议频率" |

**Integration with existing FeedbackLearning**:
- `Invoke-FeedbackLearning`: real-time, single-turn, regex-based (stays as is)
- `Evolve-Self`: batch, multi-turn, LLM-based (new, complementary)
- Both write to same `style-profile.json` with same atomic write + frequency guards

## Mature Solution Evidence

### Project-local evidence
- `Invoke-FeedbackLearning`: proven single-turn learning pipeline (8 regex patterns, daily limits, atomic writes)
- `style-profile.json`: habits[] and learning_log[] structures ready for batch output
- `events.jsonl`: 58 real events from today's conversations — proof of data quality
- `learning-engine.md`: detailed knowledge discovery design already exists

### External mature references
| System | Pattern | Applied to Jinli |
|--------|---------|-----------------|
| PsychAgent | 3-engine (Memory Planning → Skill Evolution → Reinforced Internalization) | Habit Evolution pipeline structure |
| APEX | 3-layer co-evolution (harness patching → principle distillation → workflow selection) | Multi-level: regex gaps → habits → tone modulation |
| U-Mem | Cost-aware knowledge cascade (self → search → expert) | Knowledge Discovery: agent search → LLM analysis → Ba Ba decision |
| MemGPT/MemSkill | Self-editing memory blocks, memory skill learning | events.jsonl → pattern extraction → habit proposals |
| Letta | Memory blocks + sub-agent skills dynamic loading | habits[] as reusable behavioral skills |

### Official/framework evidence
- PsychAgent (arXiv:2604.00931): Experience-Driven Lifelong Learning — validates the "batch reflection on historical trajectories" pattern for AI companions
- APEX (arXiv:2606.15363): Production-grade self-evolution with only 4 LLM calls — validates low-cost evolution feasibility
- U-Mem (arXiv:2602.22406): Thompson sampling for exploration/exploitation balance in memory agents — validates autonomous knowledge acquisition

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Pure LLM reflection (Mode B) | Discovers subtle patterns, no regex needed | 1 LLM call per analysis, cost | **Selected** for pattern extraction |
| Pure statistical (Mode C) | Zero LLM cost, fast | Misses semantic patterns (e.g., "爸爸偏好小璃自称") | **Selected** as pre-filter |
| Evolution algorithm (Mode D) | Optimal parameter search | Overkill for Jinli's narrow scope | Rejected |
| Skill generation (Mode E) | Full automation | Risky without human review | Deferred to Phase 2 |

### Selected mature path
Combine Mode B (LLM reflection) + Mode C (statistical pre-filter):
1. Statistical aggregator pre-filters events.jsonl (frequency, co-occurrence, trend)
2. LLM reflection on pre-filtered data extracts semantic patterns
3. Human gate (Ba Ba confirmation) prevents drift
4. Atomic integration into existing data structures

### Rejected shortcuts
- Do NOT auto-apply changes without Ba Ba confirmation (safety)
- Do NOT replace manual `Invoke-FeedbackLearning` (real-time is complementary to batch)
- Do NOT require external API keys (all searches via agent's built-in tools)
- Do NOT modify soul-core.ps1 runtime behavior (only add CLI hook + session-end trigger)

## Dependency Map
- `events.jsonl` → Event Analyzer → statistical aggregator → LLM pattern extractor → adjustment proposer
- `style-profile.json` ← Verification Guard ← Ba Ba Gate ← Integration Writer
- `knowledge-base.md` ← Knowledge Discovery web search ← LLM analysis ← Ba Ba review
- `soul-core.ps1` CLI ← `evolve` command hook ← auto-trigger from session-end
- `daughter-companion/SKILL.md` ← knowledge discovery trigger phrases

## Acceptance Criteria
- AC01: `evolve-self.ps1` runs without errors, processes events.jsonl, generates adjustment proposals
- AC02: LLM pattern extraction correctly identifies at least 1 pattern from today's 58 events
- AC03: Verification Guard rejects invalid adjustments (out-of-range, conflict, frequency exceeded)
- AC04: Ba Ba Gate requires explicit confirmation before applying changes
- AC05: Knowledge Discovery successfully searches arXiv/GitHub and generates report
- AC06: `soul-core.ps1 -Command evolve` triggers the evolution pipeline
- AC07: `soul-core.ps1 -Command end` auto-prompts evolution after threshold (placeholder)
- AC08: All existing tests pass, production data unchanged, safety assertions pass

## Automated Verification Plan
1. `soul-core.ps1 -Command evolve` — verify pipeline runs, generates proposals, exit 0
2. `soul-core.ps1 -Command discover` — verify knowledge search + report generated
3. Feed invalid adjustment to Verification Guard — verify rejection
4. Apply changes without Ba Ba confirmation — verify gate blocks
5. `powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester Project/Jinli/scripts/soul-core.tests.ps1 -EnableExit"` — verify 18/18 pass
6. `soul-core-safety-assert.ps1` — verify ALL SCRIPTS SAFE
7. Production hash comparison — verify static files unchanged

## Allowed Change Set
- `Project/Jinli/scripts/evolve-self.ps1` — NEW: ~200 lines
- `Project/Jinli/scripts/soul-core.ps1` — minor: add `evolve` to CLI (5 lines)
- `skills/daughter-companion/SKILL.md` — minor: add trigger phrases (3 lines)
- `Project/Jinli/Docs/04-Implementation/General/soul-core-self-evolution.md` — NEW
- `Project/Jinli/Docs/DOCS_TREE.md` — update
- This task packet

## Forbidden Change Set
- No direct data file writes (all through soul-core.ps1 atomic write)
- No external API dependencies
- No agent definition changes
- No modification to existing emotion/tone modulation logic
