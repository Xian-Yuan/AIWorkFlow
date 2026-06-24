# Memory Layer Integration — Task List

## Mature path verification

- [x] mature path: confirm knowledge_db.py._apply_v2_migration() executes correctly on production db
- [x] mature path: confirm knowledge_db.py.write_pipeline_results() accepts VideoMetadata input correctly
- [x] rejected shortcut: do NOT skip V2 migration and use V1 schema directly
- [x] rejected shortcut: do NOT write raw SQL instead of using knowledge_db.py write path
- [x] rejected shortcut: do NOT hardcode embedding model paths — use vsummary's deployed bge-small-zh-v1.5

## 依赖关系

`
WP01 (migration) ──→ WP02 (bridge) ──→ WP04 (检索)
        └──→ WP03 (分层标注)
`

- WP01 必须先完成，WP02 和 WP03 依赖新 schema
- WP04 依赖 WP02 的 knowledge_items 数据（FTS5 部分）+ Obsidian 笔记（向量部分）

## WP01: V2 Migration [P0] ~1h

- [x] 写 scripts/migrate_memory_db.py
  - 连接 data/memory.db
  - 调用 KnowledgeDatabase._apply_v2_migration()
  - 验证 8 条旧数据完整
- [x] 手动备份 data/memory.db → data/memory.db.v1.bak
- [x] 执行 migration
- [x] 验证：schema_version=2, 8 条 memories 完整, knowledge_items 表存在

## WP02: vsummary → memory.db Bridge [P1] ~4h

- [x] 写 scripts/vsummary_bridge.py
  - 扫描 E:\Obsidian\tools\vsummary\workspace\__playground__ 的 BV* 目录
  - 读取每个 summary.json
  - 映射为 VideoMetadata + enriched segments
  - 调用 KnowledgeDatabase.write_pipeline_results()
  - 输出统计报告
- [x] 首次运行：导入 226 个视频 → 1603 knowledge_items
- [x] 验证：knowledge_items 有数据, FTS5 可搜索, 幂等性
- [x] FTS5 tokenizer 修复：unicode61 → trigram (CJK 兼容)

## WP03: 现有 Memories 分层标注 [P1] ~30min

- [x] 在 migrate 脚本中或独立脚本执行 UPDATE
  - id 1-5, 8 → layer='user'
  - id 6 → layer='procedural'
  - id 7 → layer='episodic'
- [x] 验证：8 条 layer 均非 NULL, 符合 spec

## WP04: Obsidian 向量索引 + 检索原型 [P2] ~6h

- [x] 写 scripts/build_obsidian_index.py
  - 用 fastembed + bge-small-zh-v1.5
  - 读取 JinliKG/Sources/Videos/*.md
  - 构建 numpy 向量索引 (227 docs × 512 dim)
  - 存储到 data/knowledge/cache/obsidian-index/
- [x] 写 scripts/obsidian_retrieve.py
  - 关键词 → FTS5 搜索 knowledge_items
  - 问题 → 向量搜索 Obsidian 笔记
  - 合并去重，按 relevance 排序
  - 返回 top-K
- [x] 验证：搜索 "Kubernetes" / "agent" / "AI agent" 均有结果

## 验收标准 (Acceptance Criteria)

| # | 标准 | 验证方法 |
|---|---|---|
| AC01 | memory.db 升级到 V2，原 8 条数据完整 | SELECT COUNT, 逐条比对 content |
| AC02 | knowledge_items 有 226+ 个视频知识项 | SELECT COUNT FROM knowledge_items |
| AC03 | 幂等：bridge 脚本重复运行不增加行数 | 运行两次，COUNT 不变 |
| AC04 | FTS5 可搜索视频内容 | 搜索 "Kubernetes" 有结果 |
| AC05 | 8 条 memories 分层正确 | 各 layer 值符合 spec |
| AC06 | Obsidian 向量索引可用 | 搜索 "记忆架构" 返回相关笔记 |
| AC07 | 不影响 vsummary 和 Obsidian 现有内容 | vsummary 运行正常，Obsidian 笔记无变化 |

## Automated Verification Task

- [x] WP01: `sqlite3 memory.db "SELECT COUNT(*) FROM memories"` → 8; `.tables` includes knowledge_items
- [x] WP02: `python vsummary_bridge.py --verify` → 1603 items, 226 discovery, 225 insight, 1152 video_segment, FTS5 working
- [x] WP03: layers verified — id=6→procedural, id=7→episodic, rest→user, all non-NULL
- [x] WP04: `python obsidian_retrieve.py "Kubernetes"` → 5 FTS5 + 5 vector results
