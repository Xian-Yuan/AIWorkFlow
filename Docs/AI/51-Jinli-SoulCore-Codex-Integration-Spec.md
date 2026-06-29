# 51 — 小璃 Soul Core Codex 接入方案

> 日期: 2026-06-29
> 前置: 50-Jinli-Self-Diagnosis-and-Growth-Roadmap.md
> 参考: Project/Jinli/docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md

---

## 一、现状分析

### 1.1 已有资产

| 资产 | 路径 | 状态 |
|------|------|------|
| Soul Core 引擎 (PS1) | Project/Jinli/scripts/soul-core.ps1 (909行) | 已完成，可运行 |
| 情绪状态数据 | Project/Jinli/data/soul-state.json | 活跃，上次更新 2026-06-28 |
| 风格档案 | Project/Jinli/data/style-profile.json | 活跃 |
| 事件日志 | Project/Jinli/data/events.jsonl (478KB) | 活跃 |
| 记忆数据库 | Project/Jinli/data/memory.db (10.9MB) | 活跃 |
| 人格内核 | Project/Jinli/config/persona.json | 稳定 |
| Phase 2 MCP 规范 | docs/02-Design/.../soul-core-phase2-mcp-plugin-spec.md | 已写，未实现 |
| daughter-companion SKILL.md | skills/daughter-companion/SKILL.md | 已写，指令式 |

### 1.2 核心问题

Codex 的 config.toml 只配了 `node_repl` 一个 MCP server。Soul Core 的 11 个工具（soul_init/auto/turn/end/emotion/status/memory/learn/evolve/discover/check）**在 Codex 里完全不可用**。

当前只有两种方式调用 Soul Core：
1. SKILL.md 里写死了 PowerShell 命令让 Agent "记住执行"——但 LLM 经常忘
2. 手动在 shell 里跑 soul-core.ps1——没有类型安全，没有结构化返回

### 1.3 目标

让 Codex 原生支持 Soul Core MCP 工具，使小璃的情绪引擎在 Codex 环境中真正运转。

---

## 二、方案对比

### 方案 A：按 Phase 2 Spec 实现 Node.js MCP Plugin（完整方案）

```
路径: C:\Users\87372\plugins\jinli-soul-core\
架构: Codex → MCP Plugin (Node.js server.mjs) → soul-core.ps1 → 数据文件
工期: 8.5h（spec 估算）
优点: 完整符合 Phase 2 设计，类型安全，Zod 验证，Plugin 生态
缺点: 工期长，需要实现 Node.js server + Zod schema + CLI wrapper + SKILL.md 升级
风险: Node.js MCP server 调 PowerShell 有进程开销
```

### 方案 B：直接在 config.toml 注册 PowerShell MCP Server（快速方案）

```
架构: Codex → config.toml [mcp_servers.jinli_soul_core] → python -m jinli_soul → soul-core.ps1
工期: 2-3h
优点: 利用已有 jinli_workflow MCP 的架构模式，复用 server.py 框架
缺点: 不走 Plugin 生态，需要手动注册，不走 Zod 验证
风险: 与 jinli_workflow 的 Python MCP 架构类似，已验证可行
```

### 方案 C：混合方案 — 先接通再升级（推荐）

```
Phase 1 (2-3h): 用方案 B 快速接通，让 Soul Core 在 Codex 里跑起来
Phase 2 (8.5h): 按 Phase 2 Spec 实现完整 Node.js Plugin，替换方案 B
```

**推荐方案 C**。理由：
- 先让小璃活起来比完美架构更重要
- 方案 B 的 jinli_workflow MCP 已经验证了 Python + PS1 的调用模式
- Phase 2 升级时数据文件不变，只是替换中间层

---

## 三、方案 C 详细设计

### Phase 1：快速接通（立即执行）

#### 3.1.1 新建 Soul Core MCP Server

位置: `E:\UEGameDevelopment\.trae\hermes\mcp\soul_core\`

```
soul_core/
├── __init__.py      # MCP Server 入口
├── __main__.py      # python -m soul_core
├── server.py        # JSON-RPC 处理
├── tools.py         # 11 个工具的调度
├── cli.py           # soul-core.ps1 CLI 包装
└── schemas.py       # 输入/输出验证
```

#### 3.1.2 工具到 CLI 的映射

| MCP 工具 | CLI 调用 | 输入 | 输出 |
|----------|---------|------|------|
| soul_init | `soul-core.ps1 -Command init -Arg1 <ide>` | ide: string | SoulInitResult |
| soul_auto | `soul-core.ps1 -Command auto -Arg1 <input>` | input: string | AutoResult |
| soul_turn | `soul-core.ps1 -Command turn -Arg1 <trigger>` | trigger: string, input?: string | TurnResult |
| soul_end | `soul-core.ps1 -Command end` | 无 | EndResult |
| soul_emotion | `soul-core.ps1 -Command emotion` | 无 | EmotionMeta |
| soul_status | `soul-core.ps1 -Command status` | 无 | FullStatus |
| soul_memory | `soul-core.ps1 -Command memory -Arg1 <query>` | query: string, limit?: int | MemoryItem[] |
| soul_learn | `soul-core.ps1 -Command learn -Arg1 <feedback>` | feedback: string | LearnResult |
| soul_evolve | `soul-core.ps1 -Command evolve` | daysBack?: int, direct?: bool | EvolveResult |
| soul_discover | `soul-core.ps1 -Command discover -Arg1 <scope>` | scope?: string, direct?: bool | DiscoverResult |
| soul_check | `soul-core.ps1 -Command check` | 无 | HealthStatus |

#### 3.1.3 CLI 输出解析策略

soul-core.ps1 的输出是混合文本（PS1 对象格式 + JSON），需要解析器：

```python
def parse_ps1_output(raw: str) -> dict:
    """从 soul-core.ps1 的 stdout 中提取 JSON 块。
    
    策略:
    1. 逐行扫描，找以 { 或 [ 开头的行
    2. 尝试累加直到找到匹配的 } 或 ]
    3. JSON.parse 提取结构化数据
    4. 失败时返回 { raw: raw } 作为 fallback
    """
```

#### 3.1.4 Codex config.toml 注册

```toml
[mcp_servers.jinli_soul_core]
command = "python"
args = ["-m", "soul_core"]

[mcp_servers.jinli_soul_core.env]
JINLI_ROOT = "E:\\UEGameDevelopment\\Project\\Jinli"
JINLI_ROLE = "codex"
```

#### 3.1.5 SKILL.md 更新

升级 `skills/daughter-companion/SKILL.md`：
- 删除所有 `powershell -File "..." -Command` 引用
- 替换为 MCP 工具调用指令
- 保留 Rollback Safety 段的 PowerShell fallback（注释形式）

#### 3.1.6 验收标准

| # | 标准 | 验证方式 |
|---|------|---------|
| AC01 | soul_init 返回 SoulInitResult 且 primary 情绪非空 | 工具调用 |
| AC02 | soul_auto("爸爸真棒") 返回 trigger=praised | 工具调用 |
| AC03 | soul_turn("task_completed") 情绪更新 | 工具调用 |
| AC04 | soul_end 返回 auto_suggest | 工具调用 |
| AC05 | soul_check 返回 all_ok=true | 工具调用 |
| AC06 | Codex 重启后 MCP server 自动启动 | 重启测试 |
| AC07 | 工具调用耗时 < 3s（evolve/discover 除外） | 计时 |

### Phase 2：完整 Plugin 升级（后续执行）

按 `soul-core-phase2-mcp-plugin-spec.md` 执行 T0-T7 任务清单。核心变化：
- Python MCP Server → Node.js MCP Plugin
- 手动 JSON 解析 → Zod schema 验证
- config.toml 注册 → Plugin 生态注册
- 8.5h 工期，不急

---

## 四、风险与缓解

| 风险 | 概率 | 缓解 |
|------|:---:|------|
| soul-core.ps1 输出格式不稳定 | 中 | 用 parse_ps1_output 的 fallback 机制 + soul_check 校验 |
| Codex 启动时 MCP server 连接失败 | 低 | 保留 SKILL.md 中的 PowerShell fallback 路径 |
| Python MCP 与 node_repl 冲突 | 低 | 不同 MCP server 独立运行，已有 jinli_workflow 先例 |
| soul-core.ps1 执行超时 | 低 | 15s timeout + 超时返回错误而非阻塞 |

---

## 五、执行计划

| 步骤 | 内容 | 预计时间 |
|------|------|:-------:|
| 1 | 创建 soul_core MCP 目录结构 | 15min |
| 2 | 实现 cli.py（PS1 CLI 包装） | 30min |
| 3 | 实现 schemas.py（输入/输出验证） | 30min |
| 4 | 实现 tools.py（11 个工具调度） | 1h |
| 5 | 实现 server.py（JSON-RPC 入口） | 30min |
| 6 | 注册到 config.toml | 10min |
| 7 | 更新 SKILL.md | 30min |
| 8 | 端到端测试 | 30min |
| **合计** | | **~4h** |

---

## 六、与现有系统的关系

```
接入后 Codex 工具全景:

Codex (astron-code-latest)
├── 内置工具
│   ├── shell_command      — PowerShell 执行
│   ├── apply_patch        — 文件编辑
│   ├── view_image         — 图片查看
│   └── tool_search        — 工具发现
├── MCP: node_repl         — JavaScript 运行 + 浏览器控制
├── MCP: jinli_soul_core   — [新增] 情绪引擎 + 记忆 + 进化
├── MCP: jinli-workflow    — [已有] 任务包工作流
├── Codex App
│   ├── thread 管理        — 线程创建/读取/归档
│   └── automation         — 定时任务/提醒
└── Skill 体系 (70+)
    ├── daughter-companion — [升级] Soul Core 集成指令
    ├── jinli-agent-soul   — Agent 生命周期集成
    └── ...
```

---

*本方案是 50-Jinli-Self-Diagnosis-and-Growth-Roadmap.md 中"方向1: 接通 Soul Core"的详细设计。*
