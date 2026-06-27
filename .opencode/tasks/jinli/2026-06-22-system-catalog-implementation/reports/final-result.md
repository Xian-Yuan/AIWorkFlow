# System Catalog — 系统/项目/技能路径注册表

**任务**: system-catalog-implementation
**执行者**: MiniMax M3 (Mavis)
**日期**: 2026-06-23
**状态**: ✅ done

---

## 🎯 目标

建立**自动维护**的系统/项目/技能路径注册表，让所有常用软件（Hermes、Codex、OpenCode、CC Switch、vsummary 等）的位置和配置文件可被快速发现、查询、验证。

## 📁 新增/修改文件

| 文件 | 状态 | 行数 | 用途 |
|------|------|------|------|
| `services/knowledge/system_catalog.py` | 新建 | 270 | 核心 catalog 系统（CRUD、查询、验证） |
| `services/knowledge/scan_systems.py` | 新建 | 410 | 自动扫描器：检测 Hermes/Codex/Ollama 等 15+ 工具 + 74 个 skills |
| `services/knowledge/sync_catalog_to_memory.py` | 新建 | 130 | 同步到 memory.db（L3 semantic 记忆） |
| `services/knowledge/export_catalog_to_obsidian.py` | 新建 | 165 | 导出到 Obsidian `Sources/Systems/*.md` |
| `services/knowledge/catalog.py` | 新建 | 175 | CLI 入口（find/path/list/verify/scan/sync） |
| `test_catalog.py` | 新建 | 138 | 单元测试 |

**总计**: ~1288 行新代码

## 🏗️ 架构

```
┌─────────────────────────────────────────┐
│           scan_systems.py                │
│   (自动检测 15+ 工具 + 递归 skills)      │
└─────────────┬───────────────────────────┘
              │ 检测
              ▼
┌─────────────────────────────────────────┐
│       system_catalog.py                  │
│   (SystemCatalog + CatalogEntity)       │
│   - add/get/update/remove                │
│   - query(keyword, type, tag)           │
│   - verify (检查所有路径存在)            │
│   - save/load (JSON 持久化)              │
└─────┬──────────────────┬─────────────────┘
      │                  │
      ▼                  ▼
┌──────────┐      ┌──────────────────┐
│ memory.db│      │ Obsidian Sources  │
│ (L3 sem) │      │ /Systems/*.md    │
│ 87 条    │      │ + _index.md       │
└──────────┘      └──────────────────┘
      ▲                  ▲
      │                  │
      └────────┬─────────┘
               │
       ┌──────────────────┐
       │   catalog.py     │
       │   (CLI 入口)      │
       └──────────────────┘
```

## 📊 当前数据

| 类型 | 数量 | 说明 |
|------|------|------|
| **system** | 7 | Hermes Agent, Codex CLI, CC Switch, Claude Server Commander, Obsidian Vault, Trae IDE, vsummary Tool |
| **service** | 2 | Ollama, vsummary API (port 8001) |
| **project** | 4 | Project Jinli, Obsidian Vault (JinliKG), UE Game Development, UEGD Tools |
| **skill** | 74 | 全部从 `E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\skills` 递归扫描 |
| **总计** | **87** | — |

## 🛠️ 已识别的工具

- **Hermes Agent** — `E:\UEGameDevelopment\.tools\hermes-worker`
  - Skills 目录、所有 SKILL.md 自动识别
- **Codex CLI** — `C:\Users\87372\.codex`
- **CC Switch** — `C:\Users\87372\.cc-switch`
- **Claude Server Commander** — `C:\Users\87372\.claude-server-commander`
- **Obsidian Vault** — `E:\ObsidianVault` (JinliKG 子 vault)
- **Ollama** — `C:\Users\87372\AppData\Local\Programs\Ollama`
- **Trae IDE** — `E:\UEGameDevelopment\.trae`
- **vsummary Tool** — `E:\Obsidian\tools\vsummary`
- **Project Jinli** — `E:\UEGameDevelopment\Project\Jinli`

## 🎯 使用方法

### CLI 命令

```bash
# 关键字搜索
python -m knowledge.catalog find hermes
# 输出：找到 2 个匹配（hermes_agent, skill_hermes-*）

# 查特定实体的所有路径
python -m knowledge.catalog path hermes_agent
# 输出：完整路径 + 配置文件 + 描述

# 按类型/标签列出
python -m knowledge.catalog list --type system
python -m knowledge.catalog list --tag skill

# 验证所有路径是否还存在
python -m knowledge.catalog verify
# 警告：缺失路径列表

# 重新扫描（检测新增/消失的软件）
python -m knowledge.catalog scan

# 全量同步到 memory.db + Obsidian
python -m knowledge.catalog sync
```

### Python API

```python
from knowledge.system_catalog import SystemCatalog, EntityType

catalog = SystemCatalog()

# 查 hermes 所有路径
hermes = catalog.get("hermes_agent")
print(hermes.all_paths)
# ['E:\\UEGameDevelopment\\.tools\\hermes-worker',
#  'E:\\UEGameDevelopment\\.tools\\hermes-worker\\skills']

# 关键字搜索
results = catalog.query("agent")
# 返回 EntityType.SYSTEM + EntityType.AGENT 所有含 'agent' 的

# 按 tag 查
ai_skills = [e for e in catalog.entities.values()
             if "ai" in e.tags and e.type == EntityType.SKILL]
```

## 💾 集成到 memory.db

87 个 catalog 实体已作为 `type=system_path` 的记忆存入 memory.db，可通过 FTS5 全文搜索检索：

```sql
SELECT id, content FROM memories WHERE type = 'system_path' AND content MATCH 'hermes';
```

每条记忆格式：
```
系统/项目: Hermes Agent
类型: system
描述: Hermes Agent — 主要使用的 AI Agent 平台
路径:
  - E:\UEGameDevelopment\.tools\hermes-worker (dir)
  - E:\UEGameDevelopment\.tools\hermes-worker\skills (dir)
配置:
  - E:\UEGameDevelopment\.tools\hermes-worker\config.yaml (config)
标签: agent, ai, main, hermes
别名: hermes, Hermes
```

## 📁 Obsidian 集成

每个实体一个 markdown 文件：

- `Sources/Systems/Hermes-Agent.md`
- `Sources/Systems/Project-Jinli.md`
- `Sources/Systems/skill-plan.md`
- ...
- `Sources/Systems/_index.md`（索引）

每个文件包含：
- frontmatter（kg_id, type, aliases, tags, last_seen）
- 类型/描述引用
- ✅ 路径（带存在性检查）
- 配置/端点
- 关联（内部链接）
- Notes 用户笔记区

## 🧪 测试

```
Catalog 单元测试
  ✅ add/get
  ✅ query 'hermes': 2 个
  ✅ query 'ai': 2 个
  ✅ query 'hermes' type=skill: 1 个
  ✅ query tag=skill: 1 个
  ✅ 持久化
  ✅ get_paths: 2 个
  ✅ get_path 含子串: /etc/tool/config.yaml
🎉 全部测试通过

602 passed in 3.79s（知识运行时回归测试全过）
```

## 🛡️ 设计原则

1. **单一数据源**: `data/knowledge/system_catalog.json`
2. **三写一致**: catalog.json + memory.db + Obsidian 同步更新
3. **幂等**: 多次运行不会产生重复记忆
4. **可扩展**: 新增软件只需在 `scan_systems.py::DETECTORS` 加一项
5. **可验证**: `catalog verify` 检查所有路径
6. **路径存在性追踪**: 不存在的路径在导出时标记 ❌

## 🔄 自动化建议

可创建 cron job 定期重跑：
```bash
# 每天早上 8 点自动扫描 + 同步
0 8 * * * cd /e/UEGameDevelopment/Project/Jinli && PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" /e/Obsidian/tools/vsummary/.venv/Scripts/python.exe -u services/knowledge/catalog.py scan
0 8 * * * cd /e/UEGameDevelopment/Project/Jinli && PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" /e/Obsidian/tools/vsummary/.venv/Scripts/python.exe -u services/knowledge/catalog.py sync
```

## ⚠️ 已知遗留

- **opencode** 未检测到（路径不存在或特征文件不匹配）
- **marvis** 未检测到（同上）
- 可手动在 `scan_systems.py::DETECTORS` 添加新工具

---

**Status: done** ✅
**Extra scope taken: no** ✅
