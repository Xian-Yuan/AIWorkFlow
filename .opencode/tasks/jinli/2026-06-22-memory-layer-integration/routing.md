# Memory Layer Integration — Routing Decision

## 项目识别

- 项目: Jinli (Project/Jinli)
- 类型: Web 应用 (Python + SQLite)
- 阶段: Implement (代码已存在，需要接通)

## 技术栈

- 语言: Python 3
- 数据库: SQLite (memory.db)
- 依赖: knowledge_db.py, contracts.py (已存在)
- 外部: vsummary workspace (只读), ObsidianVault (只读)
- Embedding: fastembed + bge-small-zh-v1.5 (vsummary 已部署)

## 关键路径

| 文件 | 角色 |
|---|---|
| Project/Jinli/services/knowledge/knowledge_db.py | 核心数据库类，V2 migration + write_pipeline_results() |
| Project/Jinli/services/knowledge/contracts.py | 数据类型定义 (VideoMetadata, MemoryLayer, etc.) |
| Project/Jinli/data/memory.db | Production 数据库 (V1, 需升级) |
| E:\Obsidian\tools\vsummary\workspace\__playground__\ | vsummary 产出目录 (只读) |
| E:\ObsidianVault\JinliKG\Sources\Videos\ | Obsidian 视频笔记 (只读) |

## 不需要修改的文件

- vsummary 任何代码/配置
- ObsidianVault 任何笔记
- Hermes memory store
- .trae/tasks 其他任务包

## Quality Gate

- MVP/prototype requested by user: no
- 任务性质: 基础设施接线，将已有成熟组件（knowledge_db.py + contracts.py）接入数据管线
- 成熟路径: knowledge_db.py 的 V2 schema + write_pipeline_results() 是唯一 trusted write path
- 风险控制: WP01 先备份 memory.db，所有写入幂等

## Work Package Policy

- External workers: no
- 所有 WP 由同一 Jinli agent 串行执行（WP01 → WP02/WP03 → WP04）
- WP 按 spec.md 定义的工作包划分，每个 WP 有独立验证点
