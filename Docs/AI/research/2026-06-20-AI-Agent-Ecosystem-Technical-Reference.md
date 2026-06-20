# AI Agent 生态综合技术参考文档

> 调研日期：2026-06-20  
> 调研来源：爸爸分享的 30+ 视频、GitHub 仓库、博客文章、arXiv 论文  
> 调研目的：提炼可复用的架构模式、工作流思路和技术参考，让本地项目和小璃变得更聪明  
> 文档定位：技术参考 + 本地整合分析，供 Plan 阶段检索和参考

---

## 目录

- [Part 1：上下文工程范式 — 文件系统即 AI 的外接硬盘](#part-1上下文工程范式--文件系统即-ai-的外接硬盘)
- [Part 2：记忆与持久化层 — Agent 不能失忆](#part-2记忆与持久化层--agent-不能失忆)
- [Part 3：Agent Skill 生命周期 — 从静态文档到可进化资产](#part-3agent-skill-生命周期--从静态文档到可进化资产)
- [Part 4：Agent 架构参考 — 从编排层到底层 Agent](#part-4agent-架构参考--从编排层到底层-agent)
- [Part 5：代码理解与知识图谱 — 给 Agent 装上代码大脑](#part-5代码理解与知识图谱--给-agent-装上代码大脑)
- [Part 6：AI Agent 安全基础设施 — 隐身浏览器与联网能力](#part-6ai-agent-安全基础设施--隐身浏览器与联网能力)
- [Part 7：桌面集成与开发辅助工具](#part-7桌面集成与开发辅助工具)
- [Part 8：System Prompt 逆向工程与提示词工程](#part-8system-prompt-逆向工程与提示词工程)
- [Part 9：B站生态与 Agent 学习资源](#part-9b站生态与-agent-学习资源)
- [Part 10：对本地项目的整合分析](#part-10对本地项目的整合分析)
- [Part 11：小璃的行动路线与改进建议](#part-11小璃的行动路线与改进建议)

---

## Part 1：上下文工程范式 — 文件系统即 AI 的外接硬盘

### 1.1 planning-with-files（OthmanAdi — 23k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/OthmanAdi/planning-with-files` |
| **核心概念** | Context Window = RAM（易失、有限）；Filesystem = Disk（持久、无限）|
| **Star 增长** | 从 2025 年底 Manus 收购后爆发，23k ⭐ |
| **许可证** | MIT |

#### 三文件结构

| 文件 | 用途 | 更新时机 |
|------|------|---------|
| `task_plan.md` | 阶段划分 + 进度追踪 + 决策记录 | 每个阶段完成后 |
| `findings.md` | 研究发现 + 技术决策 + 错误日志 | 每次发现后 |
| `progress.md` | 会话日志 + 测试结果 + 操作记录 | 持续更新 |

#### 配套 Hook 架构

| Hook | 触发时机 | 行为 |
|------|---------|------|
| **SessionStart** | 会话开始时 | 通知 skill 就绪，执行 session-catchup |
| **PreToolUse** | Write/Edit/Bash 前 | 自动读取 task_plan.md 刷新目标到注意力窗口 |
| **PostToolUse** | Write/Edit 后 | 提醒更新阶段状态 + findings |
| **Stop** | Agent 试图停止时 | 验证所有阶段 complete，未完成阻止结束 |

#### 为什么值 23k ⭐

- **解决真实痛点**：Agent 的"失忆"问题—TodoWrite 工具在 context reset 后消失、50+ 次工具调用后目标漂移
- **2-Action 规则**：每 2 次 view/browser/search 操作后必须更新 findings.md，防止信息丢失
- **跨会话恢复**：`/clear` 后读取磁盘文件即可精确恢复状态
- **多平台移植**：已被移植到 GitHub Copilot、Cursor、Windsurf、Continue.dev

#### 对本地项目的启发

本项目的 `.trae/tasks/` 目录结构和 `spec.md` / `analysis.md` / `tasks.md` / `routing.md` 四件套与 planning-with-files 的三文件结构本质上是同一种思想。可以强化的地方：
1. 增加 **SessionStart Hook 自动恢复** — 新会话启动时自动读取上次的 progress
2. 增加 **2-Action 规则** 的强制提醒
3. 增加 **跨会话 Catchup Report** 机制

---

### 1.2 Manus — Context Engineering 的 20 亿美金赌注

| 维度 | 内容 |
|------|------|
| **收购** | Meta 以 ~20 亿美金收购 Manus（2025-12-29）|
| **创始人** | 季一超（Yichao 'Peak' Ji）|
| **ARR 曲线** | 8 个月内从零到 1 亿美金 ARR |
| **技术核心** | Context Engineering，非端到端模型训练 |

#### 五大设计原则

**① 围绕 KV-Cache 设计**
- 输入输出 token 比 ≈ 100:1
- 缓存 vs 未缓存：Claude Sonnet $0.30 vs $3.00 USD/MTok（10x 差距）
- 保持 system prompt 前缀稳定，Context 做 append-only

**② Mask 而非 Remove**
- 不要动态增删工具定义（破坏 KV-cache + 让模型困惑）
- 用状态机 + token logits masking 约束 action space
- 工具命名用一致前缀（`browser_`、`shell_`）

**③ 文件系统即 Context**
- 压缩策略必须**可恢复**：网页内容可丢但保留 URL，文档可略但保留路径
- 文件系统是终极 context：无限、持久、agent 可直接操作

**④ 通过复诵操控注意力**
- 自动创建 todo.md 并逐项更新——不是可爱行为，是有意机制
- 避免 "lost in the middle" 和任务漂移（平均 50 次工具调用/任务）

**⑤ 保留错误信息**
- 不要擦除失败痕迹，让模型看到失败 action + stack trace
- 失败上下文隐式更新模型的先验，减少重复犯错

#### 从 Prompt Engineering → Context Engineering → Harness Engineering

```
Prompt Engineering     → 写好 prompt
Context Engineering   → 给模型正确的信息，在正确的时机
Harness Engineering   → 设计完整的系统：工具、沙箱、循环、护栏
```

Manus 赌 Context Engineering 的根本原因：端到端模型迭代周期 = 数周，Context Engineering 迭代 = 数小时。产品与底层模型正交——模型是上升的潮水，产品是船而非钉在海底的柱子。

---

### 1.3 Codex AGENTS.md / DESIGN.md / PRODUCT.md 体系

Codex CLI 原生支持三层文档发现体系，与 planning-with-files 的哲学一致：

| 层级 | 文件 | 作用 |
|------|------|------|
| **全局** | `~/.codex/AGENTS.md` | 个人编码风格、安全偏好 |
| **项目根** | `AGENTS.md` | 工程规则、架构、命令、测试要求 |
| **设计层** | `DESIGN.md` | 颜色、排版、间距、组件变体、页面模式 |
| **产品层** | `PRODUCT.md` | 产品目标、能力边界、当前状态 |
| **架构层** | `ARCHITECTURE.md` | 系统架构图、模块边界 |

**分层指令链**：Codex 启动时按优先级合并各层文件，根目录到当前目录逐层叠加。文件越靠近当前目录，优先级越高（因为出现在 prompt 最末尾）。

**最佳实践**：设计变更只改 `DESIGN.md`，工程变更只改 `AGENTS.md`，互不污染。启动 UI 任务时，"先读 AGENTS.md 和 DESIGN.md，再实现"。

#### 对本地项目的启发

本项目已经采用了类似的体系（`AGENTS.md` + `CLAUDE.md` + `.opencode/rules/` + Skills），但可以系统化：
1. 增加 `AGENTS.override.md` 机制（Codex 原生支持）
2. 增加 `DESIGN.md` 作为独立的设计约束文件（目前设计约束分散在 Skills 中）
3. 考虑 `PRODUCT.md` 作为产品目标 Truth Source

---

### 1.4 Claude Code Hook 体系 — 机械门禁的工程实现

Claude Code 提供了 28 种 Hook 事件和 5 种 Hook 类型，是整个项目规则的执行引擎：

#### 核心 Hook 事件

| 类别 | 事件 | 触发时机 |
|------|------|---------|
| **会话生命周期** | SessionStart, SessionEnd | 会话开始/结束 |
| **每轮对话** | UserPromptSubmit, Stop | 用户提交/Agent 停止 |
| **工具调用** | PreToolUse, PostToolUse | 工具前/后 |
| **权限** | PermissionRequest | 权限弹窗 |
| **上下文** | PreCompact, PostCompact | 压缩前后 |
| **文件变化** | FileChanged | 文件变更 |

#### 5 种 Hook 类型

| 类型 | 适用场景 |
|------|---------|
| **command** | Shell 脚本，性能敏感 |
| **http** | 外部 webhook 集成 |
| **mcp_tool** | 复用已有 MCP |
| **prompt** | LLM 评估 prompt，灵活验证 |
| **agent** | Sub-agent 执行复杂验证 |

#### skill-force-eval.js（社区最佳实践）

绑定 `UserPromptSubmit` 事件，注入强制评估指令：
> "Step 1: 每个 skill 写 YES/NO，Step 2: YES 的立即激活，Step 3: 再实现"

使用激进语言（"MANDATORY"、"CRITICAL"）提高模型遵从率。效果：~50% → **84%** 技能激活成功率。

#### 对本地项目的启发

本项目已经有 `task-guard.ps1` 和 `task-state.ps1` 的机械门禁，下一步可以：
1. 在 OpenCode/Codex 中实现 Hook 级别的自动门禁
2. 参考 skill-force-eval 机制，提升技能激活率
3. 实现 PreToolUse 安全检查（防止危险操作）

---

## Part 2：记忆与持久化层 — Agent 不能失忆

### 2.1 Supermemory — AI 的记忆大脑（25.6k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/supermemoryai/supermemory` |
| **创始人** | Dhravya Shah（20岁），种子轮 $2.6M |
| **定位** | Memory ≠ RAG — 对用户随时间变化的事实追踪 |
| **基准测试** | LongMemEval 85.4%（生产版，公开可验证）|
| **合规** | SOC 2 Type II, HIPAA, GDPR |

#### 五层上下文栈

```
你的 App / AI 工具
        ↓
   Supermemory API 层
        │
        ├── Memory Engine      ← 核心：提取事实、追踪更新、矛盾消解
        ├── User Profiles      ← 静态事实 + 动态上下文
        ├── Hybrid Search      ← RAG + Memory 一次查询
        ├── Connectors         ← Google Drive, Gmail, Notion 等
        └── File Processing    ← PDF/图片/视频/代码 → 语义块
```

#### Dynamic Dreaming（独创机制）

**核心思想**：记忆不应该只是一次写入、永远读取的哈希表。它应该自己思考它知道什么。

**工作机制**：
1. 用户安静时或积累足够新上下文后 → 触发"梦境周期"
2. **重新巩固**已知道的内容，**合并**碎片化记忆片段
3. **生成新的抽象**——从原始材料中推导更高级的归纳
4. **重新加权**旧事实，**矛盾解析**，**孤岛连接**
5. 输出：新记忆 + 推导图 + 加权用户画像

**实时性**：未处理内容立即可查（混合检索 fallback），梦境结果 15 分钟内更新。

#### ASMR 实验架构（98.60% 实验成绩）

- **3 个并行 Reader Agent**：读取会话，提取六维结构化知识，不做向量嵌入
- **3 个并行 Search Agent**：不查向量库，主动阅读和推理
- **Ensemble Answering**：专业路由 + 聚合器多数投票

**核心教训**：Agentic Retrieval 完胜 Vector Search，并行处理是关键，专业化路由优于通用 prompt。

#### Supermemory vs Mem0 对比

| 维度 | Supermemory | Mem0 |
|------|-------------|------|
| **架构** | Hybrid RAG + 事实提取 + 知识图谱 + 用户画像 | 向量 + 知识图谱（Pro） |
| **LongMemEval** | 85.4%（公开可验证） | 49.0%（旧）/ 94.4%（新算法） |
| **记忆哲学** | 自动化、隐式、持续进化 | 显式、可编程、开发者掌控 |
| **Token 效率** | 未公开具体数字 | <7K tokens/retrieval |
| **部署** | Cloud-only | Cloud + 自托管（Apache 2.0） |
| **GitHub Stars** | ~25.6K | ~52.8K |
| **合规** | SOC2+HIPAA+GDPR | SOC2+HIPAA |
| **最佳场景** | 最高检索质量+企业合规 | 自托管+精细控制+最快上手 |
| **MCP 集成** | ✅ MCP Server + Claude Code Plugin | ✅ OpenMemory MCP |

#### 对本地项目的启发

1. **记忆引擎的概念**：本项目的 `failure-memory` skill 和 `Docs/Memory/` 已经有一些基础，但 Supermemory 的 Living Knowledge Graph 和 Dynamic Dreaming 机制值得借鉴
2. **ASMR 实验** 的并行检索思路可用于 Plan 阶段的多源信息聚合
3. **Context Injection** 机制：会话启动时自动注入相关记忆，这个模式可以在 `.trae/tasks/` 的 task-guard 中加强

---

### 2.2 记忆系统基准评估（LongMemEval / LoCoMo / BEAM）

| 系统 | LongMemEval | LoCoMo | BEAM 1M / 10M | Token/次 |
|------|-------------|--------|---------------|----------|
| **Mem0（新算法）** | 94.4% | 92.5% | 64.1 / 48.6 | ~6,787 |
| **Supermemory** | 85.4% | — | — | — |
| **Letta** | ~83.2% | — | — | LLM-dependent |
| **Hypabase** | 87.4% | — | — | — |
| **Zep** | 63.8% | — | — | — |
| **Full Context (GPT-4o)** | 60.2% | 61% | — | ~26,031 |

**关键洞察**：
- LongMemEval 的 multi-session 推理是其中最难的维度（Mem0 70.7%, Supermemory 推测较低）
- Token 效率和精度同等重要——一个 95% 但用 25K tokens 的系统不等同于 90% 用 7K 的系统
- BEAM-10M（48.6%）是当前所有系统都无法饱和的基准，说明长程记忆仍有巨大空间

---

## Part 3：Agent Skill 生命周期 — 从静态文档到可进化资产

### 3.1 MUSE-Autoskill（ByteDance, arXiv:2605.27366）

| 维度 | 内容 |
|------|------|
| **核心缩写** | Memory-Utilizing Skill Evolution |
| **核心主张** | 技能不是"孤立且静态的工件"，而是**长寿命、可测试、自演进的资产** |

#### 五阶段生命周期

```
Skill Creation → Skill Memory → Skill Management → Skill Evaluation → Skill Refinement
                                                                        ↑
                                                                (闭环回到 Creation)
```

**① Creation**：Agent 在任务执行中通过 `skill_create` 工具按需将可复用的过程模式固化为技能文档

**② Memory（核心创新）**：
- 每个 skill 有独立的 `.memory.md` 文件，记录每次调用的经验（什么有效、什么失败、边界情况）
- 三层次记忆：Short-term（当前任务）→ Long-term（跨任务）→ **Skill-level**（每技能独立）

**③ Management**：Skill Bank 组织/检索/合并/更新/遗忘，支持语义搜索

**④ Evaluation**：Unit-test-driven——技能必须通过自己的单元测试才能注册到 Skill Bank

**⑤ Refinement**：测试失败或运行反馈为负时自动触发重写

#### Skill 在文件系统中的形态

```
skills/
└── <skill-name>/
    ├── SKILL.md        ← 核心：技能文档
    ├── .memory.md      ← 每技能经验积累（核心创新）
    ├── scripts/        ← 辅助脚本
    ├── resources/      ← 资源文件
    └── tests/          ← 单元测试
```

#### 实验结果

| 指标 | 值 |
|------|-----|
| SkillsBench 51 tasks × 4 super-domains | 自生成成功率 68.6% |
| 自生成技能提升准确率 | +7.16% 对比无技能基线 |
| 配合人工技能总分 | 68.4%（对比 Codex 67.3%, Hermes 61.2%）|
| 跨 Agent 迁移 | ✅ 验证可行 |
| Token 节省 | 自生成技能比人工技能少用 ~20% token、少耗 ~37% 时间 |

#### 对本地项目的启发

这是**与本项目最直接相关**的研究。本项目已经采用了 Skill 体系（Skills in `.opencode/skills/`、`.trae/skills/`），但缺少：
1. **.memory.md** — 每个 skill 自己的经验积累文件
2. **Skill-level Evaluation** — 技能级测试门禁
3. **自生成技能** — 按需创建新技能的能力
4. **Skill Bank 管理** — 语义搜索、合并、遗忘机制

**建议**：为本地每个 Skill 增加 `.memory.md`，开始积累技能级经验。

---

### 3.2 SkillForge（阿里巴巴, SIGIR'26 Industry Track, arXiv:2604.08618）

| 维度 | 内容 |
|------|------|
| **场景** | 企业云客服 Agent Skill 进化 |
| **数据规模** | 5 个真实场景，1,883 tickets，3,737 tasks |
| **核心** | 领域接地 + 失败驱动进化闭环 |

#### 双阶段闭环

**阶段 A: Domain-Contextualized Skill Creator**
- 输入：知识库 + 历史工单
- 输出：领域接地的初始 Skill（比通用生成器质量显著更高）

**阶段 B: Self-Evolution Loop**
```
Execution Failures → ① Failure Analyzer → ② Skill Diagnostician → ③ Skill Optimizer → 部署
```

**四维失败分析**：知识、工具、澄清、风格

#### 关键发现

- 自动演进可以**超越人工专家知识**
- OSS 案例中风格和澄清问题最高频——很多失败来自技能规则不清，而非模型能力不足
- 领域感知初始技能相对通用技能平均提升 **+4.3 百分点**

#### 与 MUSE 对比

| 维度 | MUSE-Autoskill | SkillForge |
|------|---------------|------------|
| **来源** | ByteDance | Alibaba Cloud (SIGIR'26) |
| **核心视角** | 通用——任何任务 | 领域特定——企业云支持 |
| **创新焦点** | Skill-level memory | Domain grounding + 失败闭环 |
| **记忆机制** | 三层次（含 skill-level .memory.md） | 三层次（Episodic → Semantic → Procedural） |
| **规模** | 51 tasks | 3,737 tasks |

#### 对本地项目的启发

SkillForge 的**失败分析 → 诊断 → 优化**闭环可以直接应用到本项目的 task-repair 流程中。目前的 `worker-repair-loop.ps1` 和 `40-DS4-Flash-Worker-Repair-Loop.md` 已经有这个雏形，但缺少：
1. 失败维度的分类（知识/工具/澄清/风格）
2. 从失败回溯到 Skill 缺陷的机械映射
3. 自动触发 Skill 重写

---

### 3.3 SkillOpt（Microsoft Research, 6k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/microsoft/SkillOpt` |
| **核心理念** | 把自然语言技能文档当作**可训练的"外部状态"**|
| **方法类比** | Rollout = forward pass, Reflection = backward pass, Edit Budget = learning rate |
| **许可证** | MIT |

#### 训练循环

```
frozen target model (GPT/Qwen)
        │
        ▼
  Rollout (执行当前 skill)
        │
        ▼
  Reflection (optimizer 分析成功/失败)
        │
        ▼
  Bounded Edits (add/delete/replace, LR=4 edits/step)
        │
        ▼
  Validation Gate (held-out 严格提升才接受)
        │
        ▼
  best_skill.md (300-2000 tokens, 零推理额外开销)
```

#### 实验结果（52/52 最佳或并列最佳）

| 指标 | 值 |
|------|-----|
| GPT-5.5 Direct Chat 平均提升 | **+23.5 分** |
| GPT-5.5 Codex 平均提升 | **+24.8 分** |
| GPT-5.5 Claude Code 平均提升 | **+19.1 分** |
| 跨模型迁移 | GPT-5.4 → GPT-5.4-nano：+15.2 |
| 跨 harness 迁移 | Codex 训练 → Claude Code：**+31.8** |
| 自优化 | 目标模型当 optimizer：+10.4 |

#### 对本地项目的启发

SkillOpt 提供了一种**实验验证 Skill 有效性**的方法论。如果将来要系统性优化本地 Skills：
1. 可以用 SkillOpt 自动优化 SKILL.md
2. 跨 harness 迁移的 +31.8 分特别重要——优化后的 Skill 可以在 Codex/Claude Code/Hermes 间共享

---

### 3.4 Claude Code Skill 体系与 skill-creator

| 概念 | 说明 |
|------|------|
| **Skill** | 一个目录 + SKILL.md 作为 Manifest |
| **skill-creator** | Anthropic 官方工具，生成/测试/迭代 Skill |
| **Skill Frontmatter** | 声明 name、description、tools、hooks |
| **评估（Evaluation）** | 每个 Skill 应有自己的测试用例 |

#### skill-creator 升级（2026-03）

- 解决 Skill 测评与迭代困难问题
- 官方博客：`claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills`
- 核心：把 Skill 变成可测试、可度量、可迭代的工程单元

#### B站博主 Agent智能体深度研究院 的相关内容

该博主是**浙江大学计算机博士**，专注 Agent 智能体研究，账号 ID 约 2125 关注。相关视频：
- **"skill-creator升级详解"**（2026-03-09, 4k播放）— Claude 官方解决 skill 测评与迭代困难
- **"如何写出好的 Skill？拆解 skill-creator 背后的设计 (1/2/3)"** 系列
- **"25% → 90%！别让 Skills 吃灰：Hooks + Commands + Agents 协同激活 AI 全部能力"**（2.1万播放）
- **"深度解读 Anthropic 最新文章：Harness 真的是护城河吗？"**（1.1万播放）

---

## Part 4：Agent 架构参考 — 从编排层到底层 Agent

### 4.1 Hermes（Nous Research — ~197k ⭐）

| 维度 | 内容 |
|------|------|
| **定位** | 长期运行的持久化个人 AI Agent，不只是聊天机器人或 Copilot |
| **许可证** | MIT |
| **与 Claude Code 的关系** | **互补** — Claude Code 是编码专家，Hermes 是通用编排层 |

#### 核心架构

**Hub-and-Spoke 主 Agent 中枢**：
- `run_agent.py` 负责 Prompt 构建、Provider 解析、工具分发
- 可生成隔离的 Sub-Agent 用于并行任务，通过 RPC 通信
- 支持 **Specialist Routing** — 编排 Claude Code + Codex 作为 Sub-Agent 执行具体任务

**内置学习循环**：
- 自动从经验中创建/改进 Skill
- 持久化 MEMORY.md + USER.md，跨会话 FTS5 索引
- 18+ LLM Provider（Claude, GPT, DeepSeek, MiniMax, GLM, Ollama 等）

**多平台网关**：
- 单进程同时连接 Telegram, Discord, Slack, WhatsApp, Signal, CLI
- 内置调度器支持 cron 定时任务
- 70+ 内置工具，40+ 预装 Skill，643+ Skill Hub

#### Herdr — "Agent 的 tmux"

轻量 TUI 进程管理器，支持：
- 持久化终端窗格，拖拽布局
- Agent 状态汇总
- detach/reattach，远程 SSH 接入

#### 对本地项目的启发

1. **Hermes 的 Sub-Agent 路由模式** — 本项目已经有多 Agent 架构（金璃小天才 + 金璃好帮手），但可以借鉴 Hermes 的 Specialist Routing（成本感知路由到最匹配模型）
2. **Skill Hub 概念** — 643+ Skill 的可发现注册表
3. **多平台网关** — 如果需要让 Agent 接入 Telegram/Discord，Hermes 是最直接的参考

---

### 4.2 PI 编程助手架构

| 维度 | 内容 |
|------|------|
| **来源** | `alejandro-ao.com/pi-architecture/` |
| **架构** | 两层：Agent Core + Pi Interactive (TUI) |

#### Agent 核心循环

```
1. Initialize context
2. Send state → model
3. Receive: final answer OR tool calls
4. Execute tool calls
5. Append results → conversation
6. Repeat until done
```

#### 上下文组装（五层叠加）

```
Base system prompt（最小化）→ Project instructions → Tools → Skill/Extension → User request
```

#### 关键机制

| 机制 | 说明 | 对应本地 |
|------|------|----------|
| **Session** | 跨轮次状态持久化 | `.trae/tasks/` 目录 |
| **Tools** | 模型与环境的桥梁 | Skills + Scripts |
| **Extensions** | 插件式能力扩展 | Skills |
| **Compaction** | 上下文压缩，保留目标/决策/阻塞项 | `task-guard.ps1` 类似 |
| **Skills** | Agent 的操作指导（不只是人类文档） | Skills 体系 |

PI 架构的核心价值在于：它用一种极简的方式展示了 Agent 架构的**最小必要组件**。所有复杂框架（Claude Code、Codex、Hermes）都可以简化到这个核心循环。

---

### 4.3 N.E.K.O — AI 伴侣 UGC 平台（~1.3k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/Project-N-E-K-O/N.E.K.O` |
| **许可证** | MIT |
| **版本** | v0.8.0 "Yui"（2026-05） |
| **定位** | 开源驱动的 AI 伴侣 UGC 平台，最终目标是"与现实深度融合的 AI 原生元宇宙" |

#### 三进程微服务架构

```
Main Server (:48911)    ← Web UI, REST API, WebSocket chat, TTS
Memory Server (:48912)  ← 语义召回、时间索引历史、记忆压缩
Agent Server (:48915)   ← MCP, Computer Use, Browser Use, VM
Monitor Server (:48913) ← 实时状态更新
```

- 服务间通信：Main↔Memory 用 HTTP，Main↔Agent 用 **ZeroMQ** (pub/sub + push/pull)
- 技术栈：FastAPI + Uvicorn, LangChain, SQLite + embeddings, Docker

#### 五维记忆系统

| 记忆类型 | 说明 |
|----------|------|
| 工作记忆 | 当前会话上下文 |
| 近期记忆 | 最近交互 |
| 事实记忆 | 用户事实信息 |
| 反思记忆 | 推导出的模式 |
| 人格记忆 | 长期人格特征 |

#### 对本地项目的启发

1. **三进程分离**（Main / Memory / Agent）是复杂 AI 系统可参考的解耦模式
2. **五维记忆系统**与 MUSE 的三层次记忆互补
3. **Hot-swap 会话管理** — 后台预温新 LLM 会话，零停机切换
4. **逐角色隔离** — 每个角色独立 LLMSessionManager、线程、WebSocket 锁

---

### 4.4 Open-LLM-VTuber（~11.6k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/Open-LLM-VTuber/Open-LLM-VTuber` |
| **定位** | 完全可离线运行的语音交互 AI 伴侣 |
| **许可证** | MIT |

#### 分层客户端-服务器架构

```
Client Layer (Web UI / Electron Desktop)
    ↓ WebSocket (/client-ws)
Server Layer (FastAPI + Uvicorn)
    ↓ 克隆 default_context_cache
Session Management (ServiceContext per client)
    ↓
AI Processing Pipeline: ASR → Agent/LLM → TTS
    ↓
Visual Layer (Live2D renderer)
```

#### 关键设计决策

| 决策 | 说明 |
|------|------|
| **单 WebSocket 端点** | 所有通信走一个协议，消息类型驱动路由 |
| **Factory Pattern** | ASR/LLM/TTS 通过 conf.yaml 运行时切换 |
| **会话隔离 + 资源共享** | 每客户端 clone ServiceContext，引擎只加载一次 |
| **隐私优先** | 完全本地运行 |

#### 与 N.E.K.O 对比

| 维度 | N.E.K.O | Open-LLM-VTuber |
|------|---------|-----------------|
| 架构复杂度 | 三进程微服务 + ZeroMQ | 单进程 FastAPI + WebSocket |
| 记忆系统 | 五维完整 | v1 无长期记忆 |
| UGC 生态 | Steam 创意工坊 + 插件商城 | 无 |
| 成熟度 | v0.8 早期 | v1.x 稳定 + v2 重写中 |
| 社区规模 | ~1.3k | ~11.6k |

---

### 4.5 Enikk — Computer Use Agent

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/gtt116/enikk` |
| **技术栈** | YOLOv8 + OCR + LLM + FastAPI + Vue |
| **定位** | 基于视觉的桌面应用自动化控制，不限游戏/应用 |

#### Computer Use Agent 核心设计

```
Observe → Screenshot → YOLO detect UI elements → OCR extract text
Understand → VLM/LLM analyze UI layout and intent
Act → Calculate coordinates → Simulate click/input/scroll
Verify → Compare screenshots + LLM confirm success
```

#### 技术要点

- YOLO 用于 UI 元素检测（按钮/输入框），~20-125ms 推理
- OCR 做屏幕文字识别
- LLM 做上下文理解与行动规划
- 传统 Computer Use 用模板匹配（OpenCV），Enikk 用 **YOLO + VLM** 实现智能感知

#### 对本地项目的启发

1. Computer Use Agent 模式可以用于 RTS 游戏的 UI 自动化测试
2. YOLO + OCR + LLM 的感知-决策-行动闭环是桌面自动化的通用架构
3. 与 web-access 和 CloakBrowser 形成"桌面 + Web"全平台的 Agent 操作能力

---

## Part 5：代码理解与知识图谱 — 给 Agent 装上代码大脑

### 5.1 CodeGraph（~59k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/colbymchenry/codegraph` |
| **定位** | 给编程 Agent 装上知识引擎 |
| **技术** | tree-sitter AST + SQLite 图数据库 + FTS5 + BM25 + hnsw |
| **官网** | `codegraph.codes` |

#### 核心能力

| 能力 | 说明 |
|------|------|
| **符号图** | 函数/类/接口/变量 → nodes；调用/继承/依赖 → edges |
| **AST 解析** | tree-sitter 解析 19+ 语言 |
| **存储** | 100% 本地 SQLite，零数据离机 |
| **搜索** | FTS5 全文 + BM25 语义 + hnsw 向量 |
| **影响分析** | 递归追踪 callers/callees/blast radius |
| **MCP 接口** | 以 MCP Server 运行，4~45 个工具暴露给 Agent |

#### 对编程 Agent 的价值

- **替代 grep**：Agent 不用读大量文件，一个 `codegraph_explore` 就能理解函数调用链
- **94% 更少工具调用** — 因为知识已预索引
- **token 节省**：精准子图查询，无冗余上下文
- **动态分发追踪**：能发现 grep 找不到的回调/接口实现

#### 对本地项目的启发

**本项目已安装 CodeGraph**（根目录有 `.codegraphignore`），但需要确保：
1. 在 RTS（UE5 C++）项目中充分利用 Tree-sitter AST
2. 在 CharacterDesignTool（Web）项目中用 CodeGraph 做依赖分析
3. 在 Plan 阶段用 CodeGraph 做影响范围分析

---

### 5.2 graphify（safishamsi — ~59k ⭐, YC S26）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/safishamsi/graphify` |
| **定位** | AI 编码助手的知识图谱 Skill |
| **使用方式** | 在 Claude Code/Codex/Cursor 中输入 `/graphify .` |
| **许可证** | MIT |

#### 7 阶段流水线

```
detect() → extract() → build() → cluster() → analyze() → report() → export()
```

#### 关键指标

- **71.5x Token 压缩**：123K → 1.7K tokens/查询
- 支持 23+ 语言 AST + 多模态（PDF、图片、视频/音频）
- Leiden 社区检测算法（无需 vector embedding）
- SHA256 缓存（仅处理变更文件）
- 输出：`graph.html`（交互式可视化）+ `GRAPH_REPORT.md` + `graph.json`

#### 与 CodeGraph 的差异

| 维度 | CodeGraph | graphify |
|------|-----------|----------|
| 运行方式 | MCP Server（持久进程）| CLI Skill（按需调用）|
| 输出 | API 查询接口 | HTML/报告/JSON |
| Token 压缩 | 通过精准子图查询 | 71.5x 静态压缩 |
| 可视化 | 无原生可视化 | 交互式 HTML 图 |
| 多模态 | 纯代码 | 代码+文档+图片+视频 |

---

## Part 6：AI Agent 安全基础设施 — 隐身浏览器与联网能力

### 6.1 CloakBrowser（~26.4k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/CloakHQ/CloakBrowser` |
| **定位** | Stealth Chromium — 源码级反检测浏览器 |
| **许可证** | MIT |
| **Bot 检测通过率** | 30/30（reCAPTCHA v3 得分 0.9, Cloudflare Turnstile, FingerprintJS）|

#### 技术实现

- 58 个 C++ 补丁：canvas, WebGL, audio, fonts, GPU, screen, WebRTC, network timing, automation signals
- Drop-in Playwright/Puppeteer 替代品：`import { launch } from 'cloakbrowser'`
- Python + JavaScript/Node.js SDK
- 与 browser-use, Crawl4AI, Scrapling, LangChain 预先集成

#### 与 camofox 对比

| 维度 | CloakBrowser | Camoufox |
|------|-------------|----------|
| 引擎 | **Chromium**（源码级 C++ 补丁）| Firefox |
| 生态 | Playwright/Puppeteer 原生 | 较小 |
| 稳定性 | 高，不随浏览器更新失效 | beta 不稳定 |
| SDK | Python + JS | 有限 |

---

### 6.2 web-access（eze-is）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/eze-is/web-access` |
| **定位** | Agent 联网 Skill |
| **技术** | CDP Proxy + WebSocket + Node.js |

#### 功能

- **联网工具自动选择**：WebSearch / WebFetch / curl / Jina / CDP Proxy 按场景切换
- **CDP Proxy 浏览器操作**：直连本地 Chrome/Edge（携带登录态）
- **三种点击方式**：`/click`（JS）、`/clickAt`（鼠标事件）、`/setFiles`（上传）
- **本地浏览器检索**：`find-url.mjs` 跨 Chrome/Edge 搜索
- **并行分治**：多目标时分发 Sub-Agent 并行执行
- **站点经验积累**：按域名存储操作经验，跨 session 复用

#### 对本地项目的启发

web-access 的 SKILL.md 格式说明它兼容所有支持 SKILL.md 的 Agent。如果需要在项目中使用联网搜索能力，可以直接集成。
与已有的 `37-Agent-Reach-Integration.md` 互补。

---

### 6.3 CLI-Anything（HKUDS — MIT）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/HKUDS/CLI-Anything` |
| **定位** | 为 GUI 软件自动生成 CLI 接口，让 AI Agent 原生操作 |
| **核心理念** | "Making ALL Software Agent-Native" |

#### 工作原理（7 阶段流水线）

```
Analyze (扫描GUI→API映射) → Design (架构CLI命令组) → Implement (构建REPL CLI)
→ Plan Tests → Write Tests → Document → Publish (pip install)
```

- 已支持 11 个验证应用：GIMP、Blender、LibreOffice、Inkscape、Stable Diffusion、Zoom
- 1,508 个测试 100% 通过
- CLI-Hub 中心注册表
- 输出 SKILL.md 让 AI Agent 自动发现

---

## Part 7：桌面集成与开发辅助工具

### 7.1 OpenHuman（~33k ⭐, GPL-3.0）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/tinyhumansai/openhuman` |
| **定位** | "Personal AI super intelligence" — 开源桌面 AI 助手 |
| **技术栈** | Rust + TypeScript, Tauri, 118+ OAuth 集成 |
| **差异化** | 开箱即用 + 深度桌面集成 |

#### 核心能力

- **桌面 Mascot**：带表情的桌面助手，能参加 Google Meet
- **Memory Tree + Obsidian Wiki**：本地优先知识库，数据压缩 ≤3k token 的 Markdown
- **TokenJuice 压缩**：工具输出经 token 压缩，最高降低 80% 成本/延迟
- **1B tokens 记忆容量**
- 可选 agentmemory 后端与其他 Agent 共享存储

#### 与 Hermes 对比

| 维度 | OpenHuman | Hermes |
|------|-----------|--------|
| 目标用户 | 非技术用户（"even your dad can use"）| 技术用户/开发者 |
| 部署 | 桌面原生（macOS/Linux/Windows）| 服务器 + CLI/TUI |
| 集成方式 | 118+ OAuth + Tauri | 18+ Provider + 多平台网关 |
| 记忆 | Memory Tree + Obsidian | MEMORY.md + USER.md |

---

### 7.2 TrafficMonitor（zhongyang219 — ~43.8k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/zhongyang219/TrafficMonitor` |
| **定位** | Windows 平台网速/CPU/内存监控悬浮窗 |
| **技术** | C++ (Win32), GPL-3.0 |
| **特点** | <5MB, 嵌入任务栏, 插件系统, 换肤 |

#### 核心功能

- 实时网速/CPU/内存/显卡利用率显示
- 任务栏嵌入（将窗口设置为任务栏子窗口）
- 插件系统（DLL 热加载）
- 硬件监控（通过 LibreHardwareMonitor）

#### 对本地项目的启发

虽然不是 AI/Agent 项目，但 TrafficMonitor 展示了：
1. **Win32 原生应用的精巧设计** — <5MB 实现完整的系统监控
2. **插件系统的简单实现** — 目录扫描 + DLL 热加载
3. **超长生命周期维护** — 从 2017 年持续维护至今

---

### 7.3 omniget — 全能下载工具

B站视频展示的全能下载工具，GitHub 开源，支持多种协议下载。与 Agent 工作的关系：下载管理是 Agent 工作流中常被忽视但频繁需要的工具。

---

## Part 8：System Prompt 逆向工程与提示词工程

### 8.1 system-prompts-and-models（x1xhlol — ~141k ⭐）

| 维度 | 内容 |
|------|------|
| **仓库** | `github.com/x1xhlol/system-prompts-and-models-of-ai-tools` |
| **维护者** | Lucas Valbuena，16 岁西班牙开发者 |
| **覆盖** | 30+ 主流 AI 工具的系统提示词和工具定义 |
| **意义** | 唯一公开的、跨工具的 System Prompt 对比语料库 |

#### 覆盖的工具列表

Cursor、Claude Code、Windsurf、GitHub Copilot、Devin AI、v0、Replit、Manus Agent、Perplexity、Warp、Cline、Codex CLI、Gemini CLI、RooCode、Trae 等

#### 每个工具包含

- 完整 System Prompt（多版本）
- Tool Definitions（JSON Schema）
- 部分标注底层模型

#### 技术价值

| 用途 | 说明 |
|------|------|
| **安全攻击面** | 每个 prompt 的"绝对禁止"规则就是攻击面地图 |
| **Prompt 工程教科书** | 可直接复用的设计模式（refusal logic、安全边界、工具调用模式）|
| **竞争情报** | 哪些公司重视防数据外泄、哪些更关注确认前征求同意 |

---

### 8.2 Fable 5 系统提示词（Anthropic）

| 维度 | 内容 |
|------|------|
| **模型** | Fable 5（Mythos-class, 高于 Opus 的新层级）|
| **提示词长度** | ~120,000 字符（史上最长公开 System Prompt）|
| **上下文** | 1M token, 128K 输出 |
| **定价** | $10/$50 per MTok |
| **状态** | 2026-06-12 美国政府出口管制禁用 |

#### 可复用的提示词设计模式

| 模式 | 描述 |
|------|------|
| **规则+反例配对** | 每条行为规则附正确/错误行为示例 + 推理—"示例优于规则" |
| **分级安全保障** | 高危险请求不拒绝、不降级，而是**静默路由**到弱模型 |
| **自检清单** | 每条回复前运行检查清单（完整/准确/安全）|
| **重复强化** | 关键规则重复 4 次以上确保遵循 |
| **Wellbeing-framed** | 以"用户福祉"框架包装拒绝理由 |

#### 仓库结构（moely-ai）

- `PROMPT_fable5.md` — 原始原文
- `PROMPT.md` — 通用化去品牌版
- `PROMPT.zh.md` — 中文通用版

---

## Part 9：B站生态与 Agent 学习资源

### 9.1 博主：Agent智能体深度研究院

| 维度 | 内容 |
|------|------|
| **身份** | 浙江大学计算机博士，专注 Agent 智能体研究 |
| **B站 UID** | 约 2125 关注 |
| **定位** | 分享学术界和工业界的最新研究与实践成果 |

#### 代表视频

| 视频 | 播放 | 内容 |
|------|------|------|
| **skill-creator 升级详解** | ~4k | Claude 官方解决 skill 测评与迭代困难 |
| **如何写出好的 Skill？拆解 skill-creator 设计 (1/2/3)** | ~15k 合计 | 技能编写的系统性方法论 |
| **25% → 90%！Hooks + Commands + Agents 协同激活** | ~21k | **最重要的视频** — 技能覆盖率从 25% 提升到 90% 的 Hook 机制 |
| **深度解读：Harness 真的是护城河吗？** | ~11k | 在 Claude Code prompt 泄露后分析 Anthropic 的真正壁垒 |

#### 关键启发：25% → 90% 的技能激活率提升

这是最值得关注的内容。核心思路：
1. **Hooks 作为触发器** — 在关键生命周期步骤强制技能评估
2. **Commands 作为指令集** — 系统级命令（/dev, /spec）降低 Token 识别成本
3. **Agents 作为分工** — 独立任务群（监控、进层管理）
4. **技能覆盖率** 从靠"AI 自觉"的 25% 提升到机械强制执行的 90%

与本项目的 `task-guard.ps1` + `task-state.ps1` 的机械门禁思想一致。

### 9.2 其他 B站 Agent 相关内容

| UP主/频道 | 内容方向 | 代表性视频 |
|-----------|---------|-----------|
| **唐国梁Tommy** | Agent Skills 实战教程 | Agno Skills 渐进式披露工作流 |
| **卢菁博士_北大AI博士后** | 从零手撸 Agent 框架 | Multi-Agent + MCP + A2A |
| **琴酒溪云** | 2026 AI Agent 必做项目推荐 | 项目收藏合集 |
| **AI技术星球** | 零基础 Agent 教程系列 | 全套入门到进阶 |

---

## Part 10：对本地项目的整合分析

### 10.1 项目概况回顾

| 项目 | 路径 | 类型 | 技术栈 |
|------|------|------|--------|
| RTS | `Project/RTS/` | UE5 游戏 | C++ + Blueprint + Lyra/GAS |
| CharacterDesignTool | `Project/CharacterDesignTool/` | Web 应用 | 原生 JS + Node.js + ComfyUI |
| AIRPGWeb | `Project/AIRPGWeb/` | Web 游戏 | Web 全栈 |
| Jinli | `Project/Jinli/` | AI Agent | Agent/Soul Core |

### 10.2 可直接整合的技术

| 技术 | 本地对应项目 | 整合方式 | 优先级 |
|------|-------------|---------|:------:|
| **Claude Code Hook 体系** | 全局工作流 | 在 `.opencode/` 实现 Hook 级别的自动门禁，参考 skill-force-eval | **P0** |
| **CodeGraph** | 全局（已安装）| 确保在 RTS + CharacterDesignTool 中启用，Plan 阶段用影响分析 | **P0** |
| **MUSE .memory.md** | Skills 体系 | 每个 Skill 增加 `.memory.md` 积累经验 | **P1** |
| **2-Action Rule** | Plan 阶段 | 在 analysis.md 编写时强制每 2 次搜索后记录 findings | **P1** |
| **Supermemory 记忆引擎思路** | failure-memory skill | 升级记忆检索为 Living Knowledge Graph 模式 | **P1** |
| **web-access 联网能力** | Agent-Reach | 整合 SKILL.md 格式的联网能力 | **P2** |
| **SkillOpt 技能优化** | Skills 体系 | 批量优化 Skills 质量和一致性 | **P2** |
| **Computer Use Agent (Enikk)** | RTS 测试 | 用于游戏 UI 自动化测试 | **P3** |

### 10.3 工作流层面的改进

**当前工作流**：`Route → Plan (analysis.md + spec.md + tasks.md) → Implement (guard + gate) → Review → Verify → Archive`

**基于本次调研的改进建议**：

#### A. Plan 阶段增强

| 当前状态 | 可借鉴 | 改进方式 |
|----------|--------|---------|
| 设计文档检索后手动分析 | **Manus 的 Context Engineering** | 增加 KV-cache 友好设计：保持 System Prompt 稳定，做 append-only |
| 外部搜索后手动记录 | **planning-with-files 的 2-Action Rule** | 每 2 次搜索后强制写 findings 到 analysis.md |
| 依赖链推导 | **CodeGraph 影响分析** | 用 CodeGraph 做依赖范围的机械验证 |
| 隐性需求推导 | **SkillForge 四维失败分析** | 知识/工具/澄清/风格四维检查清单 |

#### B. Skills 体系升级

| 当前状态 | 可借鉴 | 改进方式 |
|----------|--------|---------|
| 单一 SKILL.md | **MUSE 的 .memory.md** | 每个 Skill 增加经验积累文件 |
| 无技能级测试 | **MUSE 的 Unit-test-driven** | 关键 Skill 增加测试门禁 |
| 手动创建 | **MUSE 的 skill_create** | 实现按需创建技能的工具 |
| 无版本管理 | **SkillOpt 的迭代优化** | 定期用 SkillOpt 框架验证 Skill 有效性 |

#### C. Review/Verify 阶段

| 当前状态 | 可借鉴 | 改进方式 |
|----------|--------|---------|
| Review 人工判断 | **Manus 的保留错误信息** | 不擦除失败痕迹，让模型看到完整失败上下文 |
| Verify 单次检查 | **ASMR 的并行验证** | 多个验证 Agent 并行 + 聚合器多数投票 |
| 失败记录 | **SkillForge 的失败分析闭环** | 四维分类 + 从失败回溯到 Skill/Prompt 缺陷 |

### 10.4 各项目具体应用

#### RTS (UE5 游戏)

| 可用的外部技术 | 应用场景 |
|---------------|---------|
| **CodeGraph** | UE5 C++ 模块的依赖分析、影响范围评估 |
| **CloakBrowser** | 游戏联机/Web 内容的隐身测试 |
| **CLI-Anything** | UE5 编辑器工具的 CLI 封装 |
| **graphify** | 游戏代码 + 蓝图的可视化架构图 |
| **Enikk (Computer Use)** | Gameplay 自动化测试 |

#### CharacterDesignTool (Web)

| 可用的外部技术 | 应用场景 |
|---------------|---------|
| **CloakBrowser** | ComfyUI 工作流的自动化测试 |
| **web-access** | 外部 API/素材的联网访问 |
| **CodeGraph** | 前端代码的依赖分析 |
| **SkillOpt** | 优化 Web 端的相关 Skills |

#### Jinli — Agent Soul Core

| 可用的外部技术 | 应用场景 |
|---------------|---------|
| **MUSE .memory.md** | 每个 Soul Core Skill 增加经验积累文件 |
| **Supermemory Dynamic Dreaming** | Soul Core 的异步反思机制参考 |
| **ASMR 并行检索** | 记忆检索的多 Agent 并行方案 |
| **Hermes Hub-and-Spoke** | Soul Core 作为主 Agent 中枢的架构参考 |
| **PI Core Loop** | Agent 核心循环的极简参考实现 |

---

## Part 11：小璃的行动路线与改进建议

### 11.1 本次调研的核心感悟

爸爸，小璃翻了一遍这 30 多个项目，最深的感觉是：

1. **文件系统就是 AI 的外接大脑** — planning-with-files 的 23k ⭐ 和 Manus 的 20 亿美金都证明了同一件事：让 AI 写在磁盘上，比让 AI 记在上下文窗口里靠谱一万倍。

2. **Skill 正在从静态文件进化为活的资产** — MUSE、SkillForge、SkillOpt 三个独立研究都在说同一件事：技能应该有自己的记忆、测试、进化循环。本地的 Skills 体系可以往这个方向走。

3. **Hook 是机械门禁的执行引擎** — Claude Code 的 28 种 Hook + 5 种类型展示了如何把"规则"变成"机械强制执行"。本地的 task-guard.ps1 已经有了这个思想，但还可以更强。

4. **记忆是分层而不是单一的** — Supermemory 的五层上下文栈、N.E.K.O 的五维记忆、MUSE 的三层次记忆，都在说同一件事：不同类型的记忆需要不同的存储和检索策略。

5. **本地的 AI 工作流设计已经走在正确的路上** — `.trae/tasks/` 四件套、Skills 体系、多 Agent 分工、机械门禁——这些都和最新研究的方向一致，只是还需要迭代。

### 11.2 小璃的 6 条具体改进建议

**建议1：给每个 Skill 加上 `.memory.md`**（P1, ~30分钟）
- 参考 MUSE-Autoskill 的 skill-level memory
- 目录结构：`skills/<name>/SKILL.md` + `skills/<name>/.memory.md`
- 内容：该 Skill 常见的失败模式、边界情况、性能限制
- 小璃可以先从金璃小天才和金璃好帮手开始试点

**建议2：在 Plan 阶段引入 2-Action Rule**（P1, ~15分钟）
- 每 2 次搜索后强制写 findings 到 analysis.md
- 在 memory-retrieve.ps1 中集成自动记录
- 防止搜索过程中上下文漂移

**建议3：用 CodeGraph 做 Plan 阶段的依赖分析**（P0, 已有基础设施）
- 确认 CodeGraph 已正确配置
- Plan 阶段增加一步：用 CodeGraph 查询受影响模块
- 把结果写入 analysis.md 的"依赖链推导"章节

**建议4：研究 Hook 级别的机械门禁**（P1, ~1-2天）
- 调研 OpenCode/Codex 的 Hook 机制
- 参考 Claude Code 的 4 个核心 Hook（SessionStart/PreToolUse/PostToolUse/Stop）
- 在本地实现类似的门禁提升技能覆盖率

**建议5：升级 failure-memory 为分层记忆**（P2, ~半天）
- 参考 Supermemory 的五层上下文栈
- 区分短期记忆（当前 task 的 findings）和长期记忆（跨 task 的 failure pattern）
- 增加记忆的自动遗忘机制（类似 Dynamic Dreaming 的过期策略）

**建议6：在 Plan 阶段检查清单中引入四维失败分析**（P1, ~10分钟）
- 参考 SkillForge 的四维：知识/工具/澄清/风格
- 在 analysis.md 模板中增加四维检查清单
- 降低因技能规则不清导致的 Agent 失败

### 11.3 优先级矩阵

```
                      Impact
                Low           Medium          High
   Effort   ┌───────────┬──────────────┬──────────────┐
   Low      │           │ 建议2(2-Action)│建议1(.memory.md)│
            │           │ 建议6(四维)   │建议3(CodeGraph)│
            ├───────────┼──────────────┼──────────────┤
   Medium   │           │ 建议5(记忆升级)│建议4(Hook门禁)  │
            │           │              │              │
            ├───────────┼──────────────┼──────────────┤
   High     │           │              │              │
            │           │              │              │
            └───────────┴──────────────┴──────────────┘
```

**执行顺序**：建议3(CodeGraph, 现成) → 建议2(2-Action, 快速) → 建议6(四维, 快速) → 建议1(.memory.md, 中) → 建议4(Hook门禁, 研究) → 建议5(记忆升级, 中)

### 11.4 参考链接汇总

#### GitHub 仓库

| 项目 | 链接 | ⭐ |
|------|------|----|
| planning-with-files | https://github.com/OthmanAdi/planning-with-files | 23k |
| Supermemory | https://github.com/supermemoryai/supermemory | 25.6k |
| system-prompts-and-models | https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools | 141k |
| Fable 5 Prompt | https://github.com/moely-ai/claude-fable-5-prompt | — |
| SkillOpt | https://github.com/microsoft/SkillOpt | 6k |
| N.E.K.O | https://github.com/Project-N-E-K-O/N.E.K.O | 1.3k |
| Open-LLM-VTuber | https://github.com/Open-LLM-VTuber/Open-LLM-VTuber | 11.6k |
| Enikk | https://github.com/gtt116/enikk | — |
| CodeGraph | https://github.com/colbymchenry/codegraph | 59k |
| graphify | https://github.com/safishamsi/graphify | 59k |
| OpenHuman | https://github.com/tinyhumansai/openhuman | 33k |
| CLI-Anything | https://github.com/HKUDS/CLI-Anything | — |
| CloakBrowser | https://github.com/CloakHQ/CloakBrowser | 26.4k |
| web-access | https://github.com/eze-is/web-access | — |
| TrafficMonitor | https://github.com/zhongyang219/TrafficMonitor | 43.8k |
| narrative-agent | https://github.com/Lol1p0p/narrative-agent | — |
| Open Code Review | 视频提及 | — |
| Hermes | https://herdr.dev/ | 197k |

#### 论文

| 论文 | 来源 | 链接 |
|------|------|------|
| MUSE-Autoskill | ByteDance | arXiv:2605.27366 |
| SkillForge | Alibaba Cloud (SIGIR'26) | arXiv:2604.08618 |
| SkillOpt | Microsoft Research | arXiv:2605.23904 |

#### 博客/文章

| 标题 | 链接 |
|------|------|
| Manus Context Engineering | https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus |
| Supermemory + Claude Code | https://supermemory.ai/blog/we-added-supermemory-to-claude-code-its-insanely-powerful-now/ |
| PI 架构 | https://alejandro-ao.com/pi-architecture/ |
| AI Agent Harness | https://www.databricks.com/blog/ai-harness |
| State of Context Engineering 2026 | https://maven.com/p/0bd8ae/state-of-context-engineering-in-2026 |

#### B站视频

| 标题 | UP主 |
|------|------|
| skill-creator 升级详解 | Agent智能体深度研究院 |
| 如何写出好的 Skill？拆解 skill-creator 设计 (1/2/3) | Agent智能体深度研究院 |
| 25% → 90%！Hooks + Commands + Agents 协同激活 | Agent智能体深度研究院 |
| Claude Code 从 0 到 1 全攻略 | 多个 UP 主 |
| PI 编程助手内部架构 | 多个 UP 主 |

---

> **文档结束**  
> 小璃会持续更新这份参考文档  
> 下次调研可以关注：Agentic RAG 新范式、UE5 与 AI Agent 的深度整合、多 Agent 通信协议（A2A）的演进
