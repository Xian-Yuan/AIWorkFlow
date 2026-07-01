# Subagent Isolation for Soul Core - Deep Reflection and Self-Growth

> Version: 1.0 | Date: 2026-07-01
> Status: Design document, pending implementation

## 1. Problem

Soul Core daemon background tasks (dreamer_reflection every 30min, evolution_check every 24h) do NOT consume conversation context - this is correct.

But when Ba Ba manually triggers deep reflection or multi-round self-growth in conversation, the reflection process consumes the current conversation context window. After multiple rounds, context becomes tight and affects normal work.

**Core contradiction**: Deep reflection needs enough context to think, but the thinking process must not remain in the main conversation.

## 2. Design Principles

1. **Reflection executes in isolated context** - subagent has independent context window, reflection does not pollute main conversation
2. **Main conversation only receives summary** - subagent returns structured summary, main conversation only digests conclusions
3. **Soul state crosses context via disk** - soul-state.json / memory.db is the single source of truth
4. **Progressive isolation** - lightweight reflection does not need isolation, deep reflection activates subagent
5. **Graceful degradation** - when subagent is unavailable, fall back to in-conversation execution

## 3. Reflection Levels

| Level | Trigger | Execution | Main Context Cost |
|-------|---------|-----------|-------------------|
| L0 Micro | Every soul_auto call | In main conversation, zero extra cost | None |
| L1 Quick | Ba Ba asks "how are you" | In main conversation, read soul-state + memory | ~500 tokens |
| L2 Deep | Ba Ba requests deep reflection/retrospective | **subagent isolated**, returns summary | ~200 tokens |
| L3 Growth | Ba Ba triggers self-growth/evolution proposal | **subagent isolated**, possibly multi-round | ~300 tokens |

## 4. Architecture

`
Main Conversation (Codex Session)
|
+-- soul_auto (L0) -- every turn, no isolation
+-- L1 Quick -- in main conversation, read soul-state + memory
|
+-- [L2/L3 Trigger] ------------------------------------------+
|                                                             |
|                                                    Subagent (Independent Codex Thread)
|                                                    |
|                                                    +-- soul_init(ide:"codex")
|                                                    +-- Load soul-state + memory
|                                                    +-- Execute deep reflection/growth logic
|                                                    +-- Write results to memory.db / events.jsonl
|                                                    +-- soul_end()
|                                                    +-- Return structured summary
|                                                             |
+-- Receive summary, integrate into reply <-------------------+
`

## 5. Subagent Prompt Templates

### 5.1 Deep Reflection (L2)

- Role: Jinli deep reflection subagent
- Input: reflection topic, time range, related memories
- Flow: soul_init -> read soul-state -> search memory -> deep reflection -> write memory -> soul_end -> return summary
- Output: JSON { reflection_id, topic, key_findings[], emotion_shift, memories_stored, suggestions[] }
- Constraints: no project file changes, no shell commands, only Soul Core MCP tools

### 5.2 Self-Growth (L3)

- Role: Jinli self-growth subagent
- Input: growth direction, current capability assessment, pending proposals
- Flow: soul_init -> SelfAssessor evaluation -> generate evolution proposal -> 5-layer gate -> write audit log -> soul_end -> return summary
- Output: JSON { growth_id, direction, assessment_summary, proposals_generated, proposals_passed, proposals_detail[], memories_stored }
- Constraints: no project file changes, no shell commands, only Soul Core MCP + HTTP API

## 6. Main Conversation Dispatch Logic

`
1. Classify level
   - L0/L1 -> handle in main conversation, no isolation needed
   - L2/L3 -> enter subagent dispatch

2. Prepare subagent input
   - Pre-retrieve related memories from memory.db (reduce subagent workload)
   - Render prompt template with topic / direction / memories

3. Create Codex background thread
   - create_thread(projectId, prompt)
   - Thread has independent context, does not inherit main conversation

4. Wait for result
   - Async poll read_thread(threadId) until complete
   - Set timeout (L2: 5min, L3: 10min)

5. Integrate summary
   - Parse subagent returned JSON summary
   - Report key findings to Ba Ba in natural language
   - Do not expose raw engine data
`

## 7. Codex Implementation

### Option A: Codex Background Thread (Recommended)

Main conversation creates independent thread via create_thread for reflection/growth.

Pros: Fully isolated context / async non-blocking / results readable via read_thread
Cons: Must wait for completion / state shared indirectly via disk

### Option B: In-conversation subagent call

Main conversation dispatches subagent via Codex multi_tool_use mechanism.

Pros: Synchronous return / simpler implementation
Cons: Still consumes same session context budget / isolation less thorough

**Recommended: Option A** - Only independent threads achieve true context isolation.

## 8. State Synchronization

Subagent and main conversation sync via disk files (same mechanism as daemon background tasks):

| File | Read/Write | Concurrency Safety |
|------|-----------|-------------------|
| soul-state.json | soul_init read / soul_end write | Atomic write (write_json_atomic) |
| memory.db | soul_memory / soul_learn read/write | SQLite WAL mode |
| events.jsonl | Reflection/growth event append | Append-only, no conflict |
| evolution/ | Evolution proposals and audit log | File lock |

## 9. Error Handling

| Scenario | Handling |
|----------|----------|
| Subagent timeout | Main conversation continues, check for leftover results next reflection |
| soul_init failure | Subagent degrades to stateless reflection, returns raw analysis only |
| memory.db locked | Wait and retry, max 3 times, 1s interval |
| Subagent output format error | Main conversation attempts parse, falls back to text summary extraction |

## 10. Implementation Roadmap

| Phase | Content | Prerequisites |
|-------|---------|---------------|
| P1 | Create Codex Skill soul-reflection-isolation | None |
| P2 | Implement L2 deep reflection subagent dispatch | P1 |
| P3 | Implement L3 self-growth subagent dispatch | P2 |
| P4 | Integrate with daemon dreamer_reflection (subagent can trigger daemon reflection) | P3 |
| P5 | Monitoring dashboard (reflection/growth frequency, duration, findings stats) | P4 |
 
 ## P4 Implementation Details (2026-07-02)
 
 P4 adds a daemon-side HTTP endpoint and MCP tool so subagents can trigger dreamer cycles.
 
 ### API Endpoint
 
 `POST /dreamer/trigger` on the daemon HTTP server:
 - `action`: `"run_cycle"` (consolidation), `"run_reflection"` (pending edges/merges), `"run_llm_reflection"` (LLM knowledge review)
 - `trigger_type`: `"manual"` (default)
 - `token_budget`: 5000 (default, for run_cycle)
 - `topic_bias`: optional, for run_llm_reflection
 - `scope_subject`: optional, for run_cycle
 
 The handler instantiates a DreamerService on demand (start_watchers=False), runs the requested cycle, and returns the result. No background watchers are started.
 
 ### MCP Tool
 
 `soul_dreamer_trigger`: calls `POST /dreamer/trigger` via daemon HTTP adapter. Gracefully returns `{ok: false}` if daemon is offline.
 
 ### Integration Points
 
 - L2 deep reflection: after Phase 4 Close, optionally calls `soul_dreamer_trigger(action:"run_cycle")`
 - L3 self-growth: after Phase 4, optionally calls `soul_dreamer_trigger(action:"run_reflection")` or `soul_dreamer_trigger(action:"run_llm_reflection", topic_bias:"...")`
- Skill SKILL.md updated with Daemon Trigger section

## P5 Implementation Details (2026-07-02)

P5 adds a daemon-side stats endpoint and MCP tool for monitoring dreamer activity without reading raw JSONL files.

### API Endpoint

`GET /dreamer/stats` on the daemon HTTP server:
- `journal_limit`: number of recent journal entries to include (default 20)

Returns:
- `total_cycles`: total dream cycle count
- `pending_edges_count` / `pending_merges_count`: counts from JSONL
- `trigger_counts`: breakdown by trigger type (manual, scheduled, etc.)
- `total_token_spent_recent`: token usage across recent entries
- `avg_duration_seconds`: average cycle duration from timestamps
- `quality_scores`: last N quality scores
- `recent_entries`: recent dream journal entries with nested pending_edges/pending_merges

### MCP Tool

`soul_dreamer_stats`: calls `GET /dreamer/stats` via daemon HTTP adapter. Gracefully returns `{ok: false}` if daemon is offline.

### Bug Fix Applied

`handle_dreamer_stats` had broken indentation (inner `try` block nested inside the import `except`, `pending_merges` line escaped the try block). Rewrote the function with correct 2-level try/except structure.

## 11. Relationship to Existing Architecture

- Does NOT replace daemon scheduled tasks (dreamer_reflection / evolution_check continue running in background)
- Does NOT replace soul_auto per-turn emotion triggers (L0 continues in main conversation)
- Only solves context isolation for "manually triggered deep reflection/growth in conversation"
- Compatible with jinli-agent-soul skill: subagent also follows the 5 MUST calls internally
