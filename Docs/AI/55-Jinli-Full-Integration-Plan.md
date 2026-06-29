# 55 -- Jinli Full Architecture Integration Plan

> Date: 2026-06-29
> Trigger: Ba Ba asked to design the full integration plan
> Supersedes: 53 (emotion/relationship consolidation, already executed)
> References: 54 (redundancy audit)

---

## 0. Current State Summary

### What's already done (53)
- Emotion: soul-core.ps1 = single truth, T12 @deprecated, /system/vitality renamed
- Relationship: soul-state.json = single truth, T12 @deprecated
- MCP soulEmotionHandler: reads soul-state.json directly
- MCP soulMemoryHandler: fixed P0 undefined functions
- Daemon: required=3 (event_bus, memory, turn_orchestrator), optional=6

### What remains (from 54 audit)
| # | Issue | Priority |
|---|-------|----------|
| A | Event storage dual track (events.jsonl vs events.db) | P3 |
| B | Memory storage dual track (memory.db vs semantic.db) | P3 |
| C | _research 122K lines dead code | P2 |
| D | Knowledge dual-layer CLI entry | P2 |
| E | Zombie services (proactive, vision, skill-scheduler, evolution, bilibili-crawler) | P4 |
| F | Temp directory garbage (113 dirs) | P4 |

---

## 1. Integration Architecture: The Unified Data Layer

### 1.1 Design Principle: One Write, Many Read, Always Tagged

Every data type has exactly ONE writer. Multiple readers are allowed but must annotate their source via a _source field. This eliminates the current confusion where two systems write the same conceptual data independently.

### 1.2 Unified Data Map

After full integration, Jinli's data layer looks like this:

`
                    WRITE LAYER (single writer per data type)
                    ========================================

  soul-core.ps1 ──► soul-state.json        (emotion + relationship + bienao + cross-session)
  EventBus (T3) ──► events.db              (ALL events: emotion, session, proactive, memory ops)
  MemoryService ──► semantic.db            (semantic memories: L0-L3, vector embeddings)
  KnowledgeDB ───► memory.db              (knowledge graph: FTS5, knowledge_items, video segments)
  persona.json ──► (read-only config)      (character definition, style mapping)


                    READ LAYER (multiple readers, always tagged)
                    ==========================================

  MCP Plugin ─────► soul-state.json        (_source: soul_state_json)
                  ► semantic.db via daemon (_source: daemon)
                  ► memory.db via PS       (_source: powershell_fallback)

  Daemon ──────────► soul-state.json       (legacy_mirror, read-only)
                  ► events.db              (replay, proactive triggers)

  Scripts ─────────► memory.db             (knowledge_db.py, obsidian_retrieve.py)
                  ► soul-state.json        (soul-core.ps1)
`

---

## 2. Integration Work Packages

### WP-A: Event Stream Unification [P3, Large]

**Goal**: All events flow through EventBus (T3). events.jsonl becomes read-only.

**Current state**:
- soul-core.ps1 appends to data/events.jsonl (emotion triggers, session lifecycle)
- EventBus persists to data/events.db (proactive, memory ops)
- Two streams are invisible to each other

**Design**:

1. **Add EventBus bridge to soul-core.ps1**
   - After writing to events.jsonl, also POST to daemon POST /events/publish
   - New T3 topics: emotion.trigger.fired, session.started, session.ended
   - This makes emotion events queryable via EventBus replay

2. **Add daemon endpoint POST /events/publish**
   - Accepts a single event or batch
   - Publishes to EventBus, which persists to events.db
   - Returns {ok: true, event_id: "..."}

3. **Migrate events.jsonl history into events.db**
   - One-time script: parse events.jsonl, publish each event to EventBus
   - After migration, events.jsonl becomes append-only backup (not query source)

4. **Update MCP Plugin**
   - soulEmotionHandler / soulStatusHandler can query EventBus for recent emotion events
   - soulCheckHandler reports events.db health (already does via event_bus service)

**Migration path**: events.jsonl stays writable during transition. After migration script runs, soul-core.ps1 stops appending to events.jsonl and only posts to EventBus.

**Risk**: Low. EventBus is already REQUIRED and online. Adding a POST endpoint is additive.

---

### WP-B: Memory Query Unification [P3, Large]

**Goal**: A single query entry searches both memory stores. No data migration needed -- the two stores serve different purposes.

**Current state**:
- memory.db: knowledge graph data (1729 knowledge_items: video segments, discoveries, insights) + 269 memories (system paths, relationships, habits)
- semantic.db: semantic memories (957 items: supplementary research, AI model info, framework comparisons)
- MCP soul_memory only queries semantic.db (via daemon)
- scripts/ only query memory.db (via knowledge_db.py)

**Design insight**: These are NOT duplicates. They are two different memory modalities:

| Store | Modality | Content | Query method | Writer |
|-------|----------|---------|--------------|--------|
| memory.db | Knowledge Graph | Structured knowledge (video segments, discoveries, FTS5) | FTS5 full-text search | knowledge service |
| semantic.db | Semantic Memory | Unstructured semantic memories (research notes, decisions) | Vector similarity + keyword | MemoryService |

**Design**:

1. **Add unified query to daemon: POST /memory/unified-query**
   - Accepts {query, limit, sources: ["semantic", "knowledge"]}
   - Queries semantic.db via MemoryService (vector + keyword)
   - Queries memory.db via KnowledgeDB (FTS5)
   - Merges and deduplicates results by similarity
   - Returns ranked list with _source tag on each item

2. **Update MCP soulMemoryHandler**
   - Primary: POST /memory/unified-query (searches both stores)
   - Fallback: PowerShell memory command (searches memory.db only)

3. **No data migration**
   - memory.db stays as knowledge graph store
   - semantic.db stays as semantic memory store
   - The unification is at the QUERY layer, not the STORAGE layer

**Risk**: Low. No data moves. Only adds a new query endpoint.

---

### WP-C: _research Archive [P2, Medium]

**Goal**: Remove 122K lines of dead code from the active codebase.

**Design**:

1. Move services/_research/ to Project/Jinli/_archived/research/
2. Create services/_research/README.md pointing to the new location
3. Add .gitignore pattern for _archived/
4. Verify no import breaks (already confirmed: 0 production imports)

**Risk**: Very low. No code references _research.

---

### WP-D: Knowledge CLI Consolidation [P2, Small]

**Goal**: Single entry point for knowledge operations.

**Current state**:
- scripts/knowledge-tools.ps1 wraps obra CLI (Obsidian knowledge graph)
- scripts/knowledge-runtime.ps1 wraps Python knowledge service

**Design**:

1. Create scripts/knowledge.ps1 as unified entry:
   `
   knowledge.ps1 obra <command>   # delegates to knowledge-tools.ps1
   knowledge.ps1 runtime <command> # delegates to knowledge-runtime.ps1
   knowledge.ps1 search <query>   # default: searches both backends
   knowledge.ps1 health           # checks both backends
   `

2. Keep old scripts as internal implementation details (not user-facing)

**Risk**: Very low. Old scripts still work, new script is additive.

---

### WP-E: Zombie Service Activation Plan [P4, Deferred]

These services have complete code but are dormant. Not redundant -- they are future capabilities. Activation order:

| Priority | Service | Depends on | Activation trigger |
|----------|---------|------------|-------------------|
| 1 | proactive | EventBus + Memory | Ba Ba wants 小璃 to initiate conversations |
| 2 | evolution | EventBus + Memory | Ba Ba wants 小璃 to self-improve habits |
| 3 | vision | Memory | Ba Ba wants 小璃 to see and understand images |
| 4 | skill-scheduler | Knowledge | Ba Ba wants automatic skill discovery |
| 5 | bilibili-crawler | Knowledge | Ba Ba wants video ingestion |

**Design**: Add each to daemon service_registry as OPTIONAL when its dependencies are met. No code changes needed -- just registration.

---

### WP-F: Temp Directory Cleanup [P4, Trivial]

113 jinli_evo_test_* dirs owned by daemon process. Fix:

1. Add cleanup to daemon shutdown sequence: texit.register(lambda: shutil.rmtree(tmpdir))
2. Or: change evolution service to use 	empfile.TemporaryDirectory instead of persistent dirs
3. Manual: run Remove-Item from admin PowerShell

---

## 3. Execution Sequence

`
Phase 1 (Now)     ──► WP-C: Archive _research        [15 min, zero risk]
Phase 2 (Now)     ──► WP-D: Knowledge CLI merge       [30 min, zero risk]
Phase 3 (Next)    ──► WP-B: Memory query unification   [2-3 hrs, low risk]
Phase 4 (Next)    ──► WP-A: Event stream unification    [3-4 hrs, low risk]
Phase 5 (When needed) ──► WP-E: Service activation    [varies, per service]
Phase 6 (Admin)   ──► WP-F: Temp cleanup              [5 min, trivial]
`

Phases 1-2 can execute immediately with no risk. Phases 3-4 require daemon endpoint additions and MCP Plugin changes. Phases 5-6 are deferred.

---

## 4. Post-Integration Architecture

### 4.1 Service Map (after WP-C + WP-D)

`
services/
  nervous/       (T3 EventBus)     REQUIRED  -- the event spine
  memory/        (T4 MemoryService) REQUIRED  -- semantic memories
  runtime/       (daemon + API)    REQUIRED  -- the process host
  knowledge/     (KG runtime)      active    -- knowledge graph
  ai-video-creator/                active    -- video processing
  persona/       (T12, deprecated) OPTIONAL  -- kept for tests only
  proactive/     (T9, dormant)     OPTIONAL  -- future: proactive conversations
  evolution/     (T8, dormant)     OPTIONAL  -- future: habit evolution
  vision/        (T7, dormant)     unreg     -- future: visual understanding
  skill-scheduler/                 unreg     -- future: skill discovery
  bilibili-crawler/                unreg     -- future: video ingestion
  _research/     → _archived/      removed   -- DONE: moved to _archived/research/, stub with README
`

### 4.2 Data Map (after WP-A + WP-B)

`
data/
  soul-state.json    ◄── soul-core.ps1 writes, all read    [2.7 KB]
  events.db          ◄── EventBus writes (unified)          [~1 MB]
  memory.db          ◄── knowledge service writes           [10.4 MB]
  events.jsonl       ◄── (read-only after WP-A migration)  [0.46 MB]

services/memory/data/
  semantic.db        ◄── MemoryService writes               [14.5 MB]
  procedural.db      ◄── MemoryService writes               [0.04 MB]
`

### 4.3 Query Flow (after WP-B)

`
User asks: "小璃，GAS怎么用？"
  │
  ├─ MCP soul_memory(query="GAS怎么用")
  │    │
  │    ├─ daemon POST /memory/unified-query
  │    │    ├─ semantic.db vector search → [AI framework memories]
  │    │    ├─ memory.db FTS5 search → [video segments about GAS]
  │    │    └─ merge + rank + tag _source
  │    │
  │    └─ fallback: PowerShell memory command → memory.db only
  │
  └─ Combined result: video segments + research notes + framework docs
`

---

## 5. Risk Matrix

| Work Package | Data Loss Risk | Downtime Risk | Reversibility | Test Coverage |
|-------------|----------------|---------------|---------------|---------------|
| WP-A (Events) | None (additive) | None | Full (events.jsonl still works) | EventBus has tests |
| WP-B (Memory) | None (no data moves) | None | Full (old endpoints stay) | MemoryService has tests |
| WP-C (Archive) | None | None | Full (move back) | N/A |
| WP-D (CLI) | None | None | Full (old scripts stay) | Manual |
| WP-E (Activate) | None | None | Full (unregister) | Per-service tests |
| WP-F (Cleanup) | None | None | Irreversible | N/A |

---

*This plan is designed by 小璃 for Ba Ba's approval. Phases 1-2 can execute immediately.*
