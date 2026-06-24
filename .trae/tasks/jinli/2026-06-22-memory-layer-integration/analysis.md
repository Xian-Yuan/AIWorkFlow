# Memory Layer Integration — 接通记忆系统的三层断裂

## Mature Solution Evidence

### Project-local evidence
- **knowledge_db.py**: V2 schema migration 代码已在 Project/Jinli/services/knowledge/knowledge_db.py 中完备实现（`_apply_v2_migration()` + `write_pipeline_results()` + FTS5），verified via code inspection.
- **contracts.py**: VideoMetadata, MemoryLayer, KnowledgeItem 等 dataclass 已在 Project/Jinli/services/knowledge/contracts.py 中定义并经过 soul-core-phase2.5 spec review.
- **V1 memory.db**: 8 条 production 数据已在 Project/Jinli/data/memory.db 中，作为 migration 的 source-of-truth.

### Official/framework evidence
- SQLite FTS5: 官方内置全文搜索引擎，UE5/Web 项目均使用，成熟度极高。
- fastembed + bge-small-zh-v1.5: 已通过 vsummary pipeline 在 production 环境运行 226 个视频的 embedding，成熟度已验证。

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| 重写 knowledge_db.py | 完全可控 | 浪费已有完备代码 | ❌ Rejected |
| 直接用 Hermes memory store | 已有 infrastructure | 语义不对齐，不满足五层架构 | ❌ Rejected |
| 接通知 knowledge_db.py pipe edge | 零新代码 core 逻辑，成熟度最高 | 需写 bridge adapter | ✅ Selected |

### Rejected shortcuts
- ❌ 跳过 V2 migration，直接在 V1 schema 写入 → 无 layer/tags 列，后续检索不可用
- ❌ 只做 FTS5 不做向量索引 → 丢失语义检索能力，不能满足 Obsidian 笔记检索需求
- ❌ 手动一条条插数据 → 226 个视频无法手工维护，必须自动化

### Selected mature path
1. knowledge_db.py（已有成熟 V2 schema + write_pipeline_results）作为唯一写入门
2. vsummary_bridge.py 作为薄适配层，只做字段映射 + 调用
3. bge-small-zh-v1.5（已在 vsummary 验证 226 次 embedding）作为唯一 embedding 后端

## Architecture Context

### System boundaries
- Owns: Project/Jinli/data/memory.db（V1→V2 升级）、Project/Jinli/scripts/（新增 4 个脚本）、Project/Jinli/data/knowledge/cache/obsidian-index/（新增索引目录）
- Reads only: E:\Obsidian\tools\vsummary\workspace\（vsummary 产出）、E:\ObsidianVault\JinliKG\Sources\Videos\（视频笔记）
- Does not own: vsummary 代码/配置、ObsidianVault 内容、Hermes memory store

### Dependency map
```
memory.db (V1) ──→ V2 migration ──→ knowledge_items table
                                        ↓
vsummary summary.json ──→ bridge ──────→ knowledge_items (226 video entries)
                                        ↓
ObsidianVault/JinliKG ──→ vector index ──→ obsidian_retrieve.py
                                        ↓
                              unified retrieval (FTS5 + vector)
```

### Data and state ownership
- memory.db: Jinli 独占，migration 保留全部 8 条旧数据
- vsummary workspace: 只读，不修改任何产出物
- ObsidianVault: 只读，Ba Ba 的内容完全不受影响
- Vector index: 离线构建，不影响 Obsidian 运行

### Integration points
- KnowledgeDatabase.write_pipeline_results() 是唯一写入点（bridge 调用）
- KnowledgeDatabase._apply_v2_migration() 是唯一 schema 变更点（migration 调用）
- fastembed + bge-small-zh-v1.5 是唯一 embedding 入口（index builder 调用）

## Acceptance Criteria

详见 spec.md 和 tasks.md 的验收标准章节。核心验收点：

| # | 标准 | 验证方法 |
|---|---|---|
| AC01 | memory.db 升级到 V2，原 8 条数据完整 | SELECT COUNT, 逐条比对 content |
| AC02 | knowledge_items 有 226+ 个视频知识项 | SELECT COUNT FROM knowledge_items |
| AC03 | 幂等：bridge 脚本重复运行不增加行数 | 运行两次，COUNT 不变 |
| AC04 | FTS5 可搜索视频内容 | 搜索 "Kubernetes" 有结果 |
| AC05 | 8 条 memories 分层正确 | 各 layer 值符合 spec |
| AC06 | Obsidian 向量索引可用 | 搜索 "记忆架构" 返回相关笔记 |
| AC07 | 不影响 vsummary 和 Obsidian 现有内容 | vsummary 运行正常，Obsidian 笔记无变化 |

## Automated Verification Plan

1. **WP01 验证（SQL）**: `sqlite3 memory.db "SELECT COUNT(*) FROM memories"` → expect 8; `"SELECT COUNT(*) FROM memories WHERE layer IS NULL"` → expect 0; `".tables"` → must include knowledge_items
2. **WP02 验证（Python）**: `python vsummary_bridge.py --verify` 检查 knowledge_items COUNT > 0 且幂等
3. **WP03 验证（SQL）**: `sqlite3 memory.db "SELECT id, layer FROM memories ORDER BY id"` → 比对 spec 表
4. **WP04 验证（Python）**: `python obsidian_retrieve.py "记忆架构"` → 返回非空结果

## 问题诊断

五层记忆架构有完整设计（spec 搂23）和完整代码（knowledge_db.py），但 memory.db 仍是 V1 schema，226 个 vsummary 视频总结从未写入 knowledge_items，Obsidian 笔记无法被对话检索。

### 当前状态

| 组件 | 状态 | 问题 |
|------|------|------|
| memory.db | V1 schema, 8 条 memories | 无 layer/tags/source 列，无 knowledge_items 表 |
| knowledge_db.py | V2 代码完整 | _apply_v2_migration() 从未在 production db 上运行 |
| vsummary workspace | 226 个视频有 summary.json | 无 bridge 脚本写入 memory.db |
| ObsidianVault/JinliKG | ~220 个视频笔记 | 无向量索引，无对话检索能力 |

### 三层断裂

1. **V1→V2 migration 未执行**：production db 停留在 schema_version=0
2. **vsummary → memory.db 管线不存在**：write_pipeline_results() 定义了但从未被调用
3. **Obsidian → 对话检索不存在**：soul_init_retrieve 只有设计没有运行时

### 与其他任务的边界

Ba Ba 正在完善 vsummary 自动下载+归档 Obsidian 的上游管线。本任务只读取 vsummary 的产出物（summary.json），不修改 vsummary 任何代码。两条管线完全独立。
