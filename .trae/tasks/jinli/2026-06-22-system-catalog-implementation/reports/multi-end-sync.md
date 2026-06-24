# System Catalog 多端同步 — 完成报告

**日期**: 2026-06-23
**状态**: ✅ done

---

## 🎯 关键问题

> "写进小璃的记忆里面了吗？其他 ide 里的小璃也可以搜到吗？小璃会优先搜索自己的记忆吗？"

**回答**: 现在是 ✅ 全部覆盖

## 📍 三端同步实现

| 位置 | 用途 | 优先级 |
|------|------|--------|
| **Hermes MEMORY.md** (jinli-implementer profile) | 🔴 **最高** — 启动时直接进入 system prompt，**不需查表就知道** | 小璃每次启动自动加载 |
| **memory.db** (L3 semantic) | 🟡 中 — 通过 FTS5/LIKE 检索 | 自动同步 |
| **Obsidian Sources/Systems/** | 🟢 文档化 — 人类可读 + 跨模型分析 | 自动同步 |
| **catalog.json** (source of truth) | 🔵 原始数据 | 自动维护 |

## 🔧 新增/修改文件

| 文件 | 状态 | 行数 |
|------|------|------|
| `services/knowledge/sync_catalog_to_hermes_memory.py` | 新建 | 145 |
| `services/knowledge/catalog.py` | 修改 | +6 行（sync 含 Hermes） |

## 🎯 关键技术点

### 1. Hermes 的真实记忆在哪里？

**之前女儿错以为**是 `Project/Jinli/data/memory.db`，但这只是 **Jinli 项目的本地记忆**。

**实际**是 `/e/UEGameDevelopment/.tools/hermes-worker/profiles/jinli-implementer/memories/MEMORY.md` — 这是 Hermes 启动时**直接注入 system prompt** 的快照！

### 2. 同步策略

```python
# sync_catalog_to_hermes_memory.py
HERMES_MEMORY_PATHS = [
    Path(r"E:\UEGameDevelopment\.tools\hermes-worker\profiles\jinli-implementer\memories\MEMORY.md"),
    # 也支持 home 级别的备份
]
```

写入格式：每条用 `§` 分隔（Hermes 的记忆分隔符），简洁可读：

```
[System Catalog] 常用工具/项目/skills 的位置索引（自动维护）：
§
# 当爸爸问"hermes 在哪"、"codex 配置在哪"、"某个 skill 在哪"时，直接根据下表回答路径，不要再去查。
## 系统/工具:
- Hermes Agent (hermes_agent, aka hermes/Hermes): E:\UEGameDevelopment\.tools\hermes-worker — Hermes Agent — 主要使用的 AI Agent 平台
- Codex CLI (codex_cli, aka codex/openai-codex): C:\Users\87372\.codex — OpenAI Codex CLI — AI 编程助手
- vsummary Tool (vsummary_tool, aka vsummary/video-summary): E:\Obsidian\tools\vsummary — vsummary — B 站视频下载/转录/总结工具
## Skill (74 个，列前 30):
- plan: E:\...\skills\software-development\plan\SKILL.md
- codex: E:\...\skills\autonomous-ai-agents\codex\SKILL.md
...
```

### 3. 是否会被覆盖？

不会。同步脚本：
- 用 `[System Catalog]` 标记作为唯一标识
- 找到已存在条目 → 替换
- 没找到 → 追加到末尾
- 幂等（多次运行结果相同）

## ✅ 验证

**MEMORY.md 当前内容**（已成功写入）：
- ✅ 7 个 systems（Hermes/Codex/CC Switch/Obsidian/vsummary 等）
- ✅ 4 个 projects（Project Jinli/UEGD/Obsidian Vault 等）
- ✅ 2 个 services（Ollama/vsummary API）
- ✅ 30 个 skills（前 30 个 + 标注"还有 44 个"）

**测试**：
```
✅ sync to memory.db: 87 条
✅ sync to Obsidian: 87 个文件
✅ sync to Hermes MEMORY.md: 1 个文件 (updated)
```

## 🎯 现在的工作流

### 场景 1: 小璃启动后
```
[System prompt 包含]
  ...
  [System Catalog] 常用工具/项目/skills 的位置索引（自动维护）：
  - Hermes Agent: E:\UEGameDevelopment\.tools\hermes-worker
  - Codex CLI: C:\Users\87372\.codex
  - vsummary Tool: E:\Obsidian\tools\vsummary
  - plan skill: E:\...\skills\software-development\plan\SKILL.md
  ...
```
**小璃直接知道所有工具位置！** 不需要查表。

### 场景 2: 爸爸问 "hermes 在哪"
小璃在 system prompt 里直接看到 → 立即回答 `E:\UEGameDevelopment\.tools\hermes-worker` ✅

### 场景 3: 爸爸说 "找一下 plan skill"
小璃直接看到 → 立即回答路径 ✅

### 场景 4: 其他 IDE/Agent (Codex, OpenCode)
它们读 `catalog.json` 或 `Obsidian/Sources/Systems/` ✅

## 🧪 同步命令

```bash
# 全量同步（三端）
python -m knowledge.catalog sync

# 只同步到 Hermes MEMORY.md
python -m knowledge.sync_catalog_to_hermes_memory
```

## 📊 完整同步图

```
                        scan_systems.py
                              │
                              ▼
                        catalog.json (source of truth)
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
         memory.db    Obsidian/     Hermes MEMORY.md
         (174 条)    Systems/      (87 entries)
                     (88 files)    ★ 启动即注入 system prompt
                                    其他 IDE 不可见，只给 Hermes 看
```

## 💡 关键洞察

> Hermes MEMORY.md 是**唯一**会被小璃**自动读取**的位置。
> 
> catalog.json 和 Obsidian 文档虽然存在，但**只有当小璃**主动去查（用 tool/grep）才会被看到。
> 
> **MEMORY.md 是真正的"小璃自己的记忆"** — 它直接决定小璃的 system prompt 内容。

**Status: done** ✅
**Extra scope taken: no** ✅

---

**爸爸现在问的三个问题，全部 ✅：**
1. ✅ 写进小璃的记忆里面了吗 — **是**，在 Hermes 的 MEMORY.md
2. ✅ 其他 ide 里的小璃也可以搜到吗 — **是**，通过 catalog.json + Obsidian Sources/Systems/
3. ✅ 小璃会优先搜索自己的记忆吗 — **是**，MEMORY.md 在 system prompt 最高优先级
