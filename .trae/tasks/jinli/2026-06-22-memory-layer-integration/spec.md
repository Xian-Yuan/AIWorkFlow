# Memory Layer Integration — Specification

## 目标

将 Jinli 的五层记忆架构从"设计完整、数据断裂"变为"数据落地、检索可用"。

## 约束

1. **只读 vsummary 产出**：不修改 vsummary 代码、配置、workspace 结构
2. **只读 Obsidian 笔记**：不修改 ObsidianVault/JinliKG 中 Ba Ba 写的任何内容
3. **不丢数据**：V2 migration 必须保留现有 8 条 memories 完整
4. **幂等**：bridge 脚本可重复运行，不产生重复 knowledge_items
5. **不阻塞 Ba Ba 的上游工作**：vsummary 自动下载归档管线与本任务完全独立

## 产出物

### WP01: V2 Migration

**输入**：Project/Jinli/data/memory.db (V1, 8 条)
**输出**：同一 db 升级到 V2 schema

GIVEN memory.db 是 V1 schema (schema_version=0)
WHEN 执行 V2 migration
THEN:
- memories 表新增 9 列：layer, tags, source, source_uri, source_timestamp, related_ids, confidence, exported_to_obsidian, graph_status
- knowledge_items 表被创建（空）
- memory_schema_version 表被创建，version=2
- 原 8 条 memories 数据完整，新列有合理默认值（layer='user', tags='[]', source='conversation', confidence=0.80, graph_status='pending'）
- FTS5 索引 memories_fts 继续工作

**实现**：直接调用 KnowledgeDatabase._apply_v2_migration()，或写一个独立脚本 scripts/migrate_memory_db.py。

**验证**：
- migration 后 SELECT COUNT(*) FROM memories = 8
- 8 条记录的 content 与 migration 前完全一致
- SELECT * FROM memories WHERE layer IS NULL 返回 0 行
- knowledge_items 表存在且为空
- FTS5 搜索 "金璃" 返回 id=1

### WP02: vsummary → memory.db Bridge

**输入**：E:\Obsidian\tools\vsummary\workspace\__playground__\{BV*\}\summary.json
**输出**：memory.db knowledge_items 表写入记录

**summary.json schema**（实际格式，非理论）：
`json
{
  "title": "BV117Eq6cEbM",
  "one_sentence_summary": "一句话总结",
  "core_problem": "核心问题",
  "chapters": [
    {
      "id": "chapter-1",
      "title": "章节标题",
      "start_seconds": 0.0,
      "end_seconds": 120.0,
      "summary": "章节摘要",
      "key_points": ["要点1", "要点2"]
    }
  ],
  "key_takeaways": ["核心收获1", "核心收获2"]
}
`

**映射规则**：

| summary.json 字段 | knowledge_items 字段 | 说明 |
|---|---|---|
| BV ID | item_id = kg-video-{BV_ID} | 视频级知识项 |
| title | title | |
| one_sentence_summary | content | item_type=discovery, layer=episodic |
| chapters[i] | item_id = kg-seg-{BV_ID}-{i:04d} | 段级知识项 |
| chapters[i].summary | content | item_type=ideo_segment, layer=episodic |
| chapters[i].key_points | entities | JSON list |
| key_takeaways | 合并为一条 | item_id=kg-summary-{BV_ID}, item_type=insight, layer=semantic |

**默认值**：
- confidence: 0.75（视频总结的默认置信度）
- importance: 6
- platform: "bilibili"
- source_uri: https://www.bilibili.com/video/{BV_ID}
- graph_status: "pending"
- provenance: {"video_id": "{BV_ID}", "source": "vsummary_bridge"}

**幂等策略**：INSERT OR REPLACE，基于 item_id 去重。同一 BV ID 重复运行只更新不重复。

**实现**：写 scripts/vsummary_bridge.py，流程：
1. 扫描 vsummary workspace 的所有 BV* 目录
2. 读取 summary.json
3. 构造 VideoMetadata + enriched segments（适配 contracts.py 的 dataclass）
4. 调用 KnowledgeDatabase.write_pipeline_results()
5. 输出统计：新增/更新/跳过 的 item 数

**验证**：
- 运行后 knowledge_items COUNT > 0
- 每个 BV ID 至少有 1 条 discovery + N 条 video_segment + 1 条 insight
- 重复运行后 COUNT 不变（幂等）
- FTS5 搜索 "Kubernetes" 返回 BV117Eq6cEbM 相关项
- FTS5 搜索 "agent协作" 返回 BV11KjN6aE37 相关项

### WP03: 现有 Memories 分层标注

**输入**：memory.db 中 8 条 V1 memories
**输出**：8 条 memories 的 layer 字段标注为合理值

**标注规则**：

| id | 当前 type | 标注 layer | 理由 |
|---|---|---|---|
| 1 | relationship | user | 父女关系是核心身份记忆 |
| 2 | relationship | user | 核心关系 |
| 3 | habit | user | 用户习惯 |
| 4 | relationship | user | 核心关系 |
| 5 | preference | user | 用户偏好 |
| 6 | habit | procedural | 工作流习惯 → L4 |
| 7 | technical_disagreement | episodic | 一次性事件 → L2 |
| 8 | relationship | user | 核心关系 |

**实现**：在 migrate_memory_db.py 中完成，migration 后立即执行。

**验证**：每条 memory 的 layer 不为 NULL，且符合上表。

### WP04: Obsidian 向量索引 + 对话检索原型

**输入**：E:\ObsidianVault\JinliKG\Sources\Videos\*.md（~220 个视频笔记）
**输出**：
1. 向量索引文件（用 bge-small-zh-v1.5 embedding）
2. scripts/obsidian_retrieve.py 检索脚本

**检索流程**：
1. 用户提问 → 提取关键词
2. FTS5 搜索 memory.db knowledge_items（已有）
3. 向量搜索 Obsidian 笔记（新增）
4. 合并去重，按 forgetting_score 排序
5. 返回 top-K 结果，格式：来源: {title} ({timestamp}) | {摘要}

**实现约束**：
- embedding 模型用 vsummary 已部署的 ge-small-zh-v1.5（在 E:\Obsidian\tools\vsummary\data\models\fastembed\fast-bge-small-zh-v1.5）
- 索引存储在 Project/Jinli/data/knowledge/cache/obsidian-index/
- 只索引 JinliKG 目录，不索引整个 ObsidianVault
- 索引构建是离线的，不影响 Obsidian 运行

**验证**：
- 索引文件存在且大小 > 0
- 搜索 "记忆架构" 返回相关视频笔记
- 搜索 "token优化" 返回相关视频笔记
- 搜索 "agent框架" 返回相关视频笔记
- 搜索结果包含 video title + timestamp + 摘要

## 不做的事

- 不修改 vsummary 代码或配置
- 不修改 ObsidianVault 中 Ba Ba 写的内容
- 不实现 soul_init/soul_discover/soul_end 生命周期集成（那是 Phase 3）
- 不实现 Mem0 语义增强（那是第二阶段）
- 不实现 visual model keyframe 分析
- 不实现 graph JSON 导出
- 不修改 Hermes memory store
