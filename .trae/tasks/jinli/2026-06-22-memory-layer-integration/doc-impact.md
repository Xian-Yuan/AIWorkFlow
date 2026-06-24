# Memory Layer Integration — Documentation Impact

## Project Document Scope

- Project: Jinli
- System: memory (knowledge_db.py + contracts.py)
- Owner: jinli-infra

## Code Changes

- `Project/Jinli/scripts/migrate_memory_db.py` — 新增: V2 migration + 分层标注
- `Project/Jinli/scripts/vsummary_bridge.py` — 新增: vsummary → memory.db 数据桥
- `Project/Jinli/scripts/build_obsidian_index.py` — 新增: Obsidian 向量索引构建
- `Project/Jinli/scripts/obsidian_retrieve.py` — 新增: Obsidian + memory.db 统一检索
- `Project/Jinli/data/knowledge/cache/obsidian-index/` — 新增: 向量索引存储目录
- `Project/Jinli/data/memory.db` — 修改: V1→V2 schema migration（保留数据）

## No Code Changes

Reason: 不改动 vsummary 代码/配置、不改动 ObsidianVault 笔记、不改动 Hermes memory store、不改动 Project/RTS 和 Project/CharacterDesignTool 的任何产品代码。本任务只读取 vsummary 产出物和 Obsidian 笔记，不影响上游管线。

## Documentation Updates

- Project/Jinli/Docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md
- Project/Jinli/Docs/06-Operations/knowledge-layer-runtime.md
- Docs/Memory/README.md

## Docs Tree Updates

- Project/Jinli/Docs/DOCS_TREE.md

## Other Documentation Changes

- Project/Jinli/data/knowledge/README.md — 需要更新目录说明，新增 cache/obsidian-index/ 说明
