# 54 -- Jinli Full System Redundancy Audit

> Date: 2026-06-29
> Trigger: Ba Ba asked about other system redundancies
> Scope: Project/Jinli/ all 13 services + scripts/ + data/ + MCP Plugin

---

## 1. Redundancy Registry

### 1.1 Emotion System Triple Redundancy [RESOLVED, see 53]

| System | Verdict | Action |
|--------|---------|--------|
| soul-core.ps1 (8-dim) | Single source of truth | Kept |
| T12 EmotionEngine (4-dim) | Zombie, never ticked | @deprecated, OPTIONAL |
| runtime_emotion.py | Endpoint semantics confused | Renamed /system/vitality |

### 1.2 Relationship System Dual Redundancy [RESOLVED, see 53]

| System | Verdict | Action |
|--------|---------|--------|
| soul-state.json trait_params | Single source of truth | Kept |
| T12 RelationshipLedger | Zombie, never ticked | @deprecated, OPTIONAL |

### 1.3 Event Storage Dual Redundancy [UNRESOLVED]

Two event systems persist independently, different formats, different content, overlapping concept:

| Storage | Format | Writer | Content | Size |
|---------|--------|--------|---------|------|
| data/events.jsonl | JSONL | soul-core.ps1 | Emotion triggers, session start/end | 0.46 MB, 1449 lines |
| data/events.db | SQLite | services/nervous/event_bus.py | Proactive messages, memory ops | 0.45 MB, 899 rows |

Problem: Two event streams don't know about each other. soul-core.ps1 emotion triggers are NOT in EventBus; EventBus proactive messages are NOT in events.jsonl. Consumers must check both sources for a complete event history.

Recommendation: soul-core.ps1 should publish emotion triggers via EventBus (T3 topic emotion.trigger.fired), unified into events.db. events.jsonl demoted to read-only historical snapshot.

### 1.4 Memory Storage Dual Redundancy [UNRESOLVED]

Two memory systems with independent databases and query interfaces:

| Storage | Format | Writer | Content | Size |
|---------|--------|--------|---------|------|
| data/memory.db | SQLite+FTS5 | scripts/ (knowledge_db.py) | 269 memories + 1729 knowledge_items (video segments, discoveries, insights) | 10.42 MB |
| services/memory/data/semantic.db | SQLite | services/memory/memory_service.py | 957 memories (supplementary research, test records) | 14.47 MB |

Problem:
- MCP soul_memory tool goes through daemon -> MemoryService -> semantic.db
- scripts/ (obsidian_retrieve.py, knowledge_db.py) read memory.db directly
- Two databases have different data, different schemas, different query paths
- Consumer must know which database to query

Recommendation: Long-term merge into single memory store. Short-term: memory.db knowledge_items are knowledge graph data, semantic.db memories are semantic memories -- conceptually different and can coexist, but need a unified query entry (MCP tool should search both).

### 1.5 Event Index Dual Redundancy [UNRESOLVED]

| Storage | Rows | Path |
|---------|------|------|
| services/memory/data/events_index.db | 10 | memory/data/ |
| services/memory/events_index.db | 109 | memory/ |

Problem: Two identically-named databases in different paths, different content, no code references either. Orphaned files.

Recommendation: **Done 2026-06-29.** Deleted services/memory/events_index.db and data/memory.db.v1.bak.

### 1.6 MCP Plugin Memory Fallback Missing [BUG]

soulMemoryHandler calls _powerShellMemoryRecall(query, limit) when daemon is unreachable, but this function is UNDEFINED. When daemon is offline, soul_memory tool will throw a ReferenceError.

Recommendation: **Fixed 2026-06-29.** Replaced all 3 undefined functions with working implementations: daemon POST /memory/query primary, PowerShell soul-core.ps1 memory command fallback.

### 1.7 _research Service: 122K Lines Dead Code [UNRESOLVED]

| Metric | Value |
|--------|-------|
| Python files | 555 |
| Code lines | 122,157 |
| JSON files | 339 |
| YAML files | 21 |
| Imported by production code | 0 |

Problem: services/_research/ contains mem0 integration and various experimental code. No production code imports it. 122K lines is the largest chunk of the project.

Recommendation: Move to Project/Jinli/_archived/research/ or a separate repo. Keep _research/ directory with only a README pointing to the new location.

### 1.8 Knowledge Dual-Layer Entry [Design Redundancy, Not Bug]

| Layer | Location | Role |
|-------|----------|------|
| CLI wrapper | scripts/knowledge-tools.ps1 | Wraps obra CLI (Obsidian KG) |
| CLI wrapper | scripts/knowledge-runtime.ps1 | Wraps Python knowledge service |
| Python service | services/knowledge/ | Knowledge graph runtime implementation |

Verdict: Not redundant -- scripts/ are CLI entries, services/ is implementation. But two PS1 scripts wrap different backends (obra vs Python) which may confuse consumers.

Recommendation: Merge into single knowledge.ps1 with subcommands to select backend.

---

## 2. Non-Redundant But Notable

### 2.1 Zombie Services (code exists but never runs)

| Service | Lines | Last Update | Status |
|---------|-------|-------------|--------|
| proactive | 10K | 06-25 | Complete framework, never started by daemon |
| vision | 2.3K | 06-25 | Complete framework, never started by daemon |
| skill-scheduler | 2.4K | 06-25 | Complete framework, never started by daemon |
| evolution | 5.4K | 06-25 | Complete framework, never started by daemon |
| bilibili-crawler | 574 | 06-25 | Single file, never started by daemon |

These services have complete code and tests, but daemon service_registry doesn't register them (except evolution and proactive as OPTIONAL). They're not redundant -- they're dormant capabilities.

### 2.2 Temp Directory Garbage [Requires Admin]

113 jinli_evo_test_* directories created by daemon's evolution service, owned by daemon process. Codex cannot delete.

---

## 3. Storage Inventory

| Storage | Size | Purpose | Active |
|---------|------|---------|--------|
| data/memory.db | 10.42 MB | Knowledge graph + FTS5 | Active (scripts/) |
| services/memory/data/semantic.db | 14.47 MB | Semantic memories | Active (daemon) |
| data/events.db | 0.45 MB | EventBus persistence | Active (daemon) |
| data/events.jsonl | 0.46 MB | soul-core event log | Active (soul-core.ps1) |
| data/soul-state.json | 2.7 KB | Soul state (single truth) | Active |
| services/memory/events_index.db | 0.63 MB | Event index | Orphan |
| services/memory/data/events_index.db | 0.11 MB | Event index | Orphan |
| data/memory.db.v1.bak | 0.03 MB | Old backup | Deletable |
| **Total** | **~26 MB** | | |

---

## 4. Priority Fixes

| # | Issue | Risk | Effort | Priority |
|---|-------|------|--------|----------|
| 1 | MCP soul_memory fallback function undefined | ~~High~~ **Fixed** | ~~Small~~ Done | ~~P0~~ Done |
| 2 | events_index.db orphan files | Low | Trivial | P1 |
| 3 | memory.db.v1.bak old backup | Low | Trivial | P1 |
| 4 | _research 122K lines dead code | Medium (discovery cost) | Medium | P2 |
| 5 | Event storage unification (events.jsonl -> EventBus) | Medium | Large | P3 |
| 6 | Memory storage unified query entry | Medium | Large | P3 |

---

*This document is a complete record of Jinli's system redundancy audit. P0 items should be fixed immediately.*
