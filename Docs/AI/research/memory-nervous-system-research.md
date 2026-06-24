# 记忆系统 + 神经系统 + 人格情感 + 自我进化 + 潜意识 + 自身路由：深度搜索研究报告

> **执行日期**：2026-06-23
> **搜索轮次**：22+ 轮（覆盖 🟢GitHub / 🔵arXiv / 🟡博客 / 🟠中文社区 / 🟣论坛 / 🔴官方文档）
> **总发现数**：150+ 高质量参考项目/论文/博客/讨论

---

## 搜索概述

本报告基于六大维度的深度联网搜索：
1. **Agent 记忆系统** — 分层存储、检索、衰减、一致性、跨会话持久化
2. **Agent 神经系统** — 事件总线、事件驱动架构、消息队列、发布-订阅模式
3. **虚拟伴侣人格与情感** — 情感建模、人格演化、关系记忆、长期陪伴
4. **自我进化系统** — Agent/Skill 自我改进、记忆/神经/持续进化、自修复
5. **潜意识系统** — AI 空闲时自我审查、自我反思、记忆提纯、主动提醒
6. **自身路由系统** — AI 快速定位自身文件、自描述目录、自索引、自导航

搜索源覆盖：GitHub 项目 60+、arXiv 论文 40+、技术博客 15+、中文社区 10+、Reddit/HN 论坛 15+、官方文档 10+

---

## 搜索日志

| 轮次 | 搜索源类型 | 关键词方向 | 新发现数 | 关键发现 |
|------|-----------|-----------|---------|---------|
| R1 | 🟢 GitHub | agent event bus architecture | 8 | AgentBus, plarotta/agentbus, hooksbase |
| R2 | 🟢 GitHub | agent memory implementation | 12 | Engram, MemoryAgent, AgentMemory, oxgeneral/agentmem |
| R3 | 🔵 arXiv | event-driven memory agent | 8 | A-Mem, Mem0论文, Memory-R1, AgeMem, AtomMem |
| R4 | 🟢🔵 | pub-sub actor model agent | 10 | RAPS, AutoAgents, Floki(Dapr), AYA, Wactorz |
| R5 | 🟢🔵 | cross-agent event propagation | 6 | KVCOMM, LatentMAS, GUARDIAN, RCR-Router |
| R6 | 🔵🟡 | memory decay Ebbinghaus | 10 | YourMemory, memory-decay-core, FadeMem, agent-memory |
| R7 | 🟢🔵 | event sourcing time travel | 8 | Rewind, Operad, ESAA, CogniCore, AgentReplay, Chidori |
| R8 | 🟢🔵 | self-improving agent | 10 | Self-Evolving Survey, AEL, Gödel Agent, APEX, AutoGenesis |
| R9 | 🟢🔵 | skill auto-evolution | 6 | AgentFactory, MARS, Evolution of Thought, AutoAgent |
| R10 | 🔵🟡 | memory self-organization | 8 | Auto-Dreamer, Nemori, SCM, CogniFold, Infini Memory |
| R11-R14 | 🟢🔵 | virtual companion emotion | 12 | CTEM/Auri, Mikasa, Livia, LifeSide, companion-emergence |
| R15 | 🟢🔵 | evolution audit rollback | 8 | Geneclaw, Constitutional AI Protocol, Governed Capability Evolution |
| R16 | 🟢 GitHub | MCP self-upgrade | 8 | mcp-upgrade, agent-discover, MCP Discovery URI, MassGen Registry |
| R17 | 🟠 中文 | AI伴侣情感系统 | 8 | Persona四象限论文, OpenHer, Mio关系进化, Psyche, Jarvis Core |
| R18 | 🟣 论坛 | self-improving agent | 8 | Eidolon Memory, Hipocampus, Permem, 关系记忆3层 |
| R19 | 🟢🔵🟡 | subconscious dreaming | 10 | OpenAI Dreaming, Dream Consolidation Cycle, intuitive-AI, Nexus |
| R20 | 🟢🔵🟡 | memory distillation density | 10 | Nemori, SimpleMem, DeMem, xMemory, MemRefine, CoreMem, MemFly |
| R21 | 🟢🔵🟡🟣 | self-routing self-index | 10 | SKILL.md Spec, project-indexer, agentdef, skill-graph, skills-registry |

---

## 1. Agent 事件总线/神经系统搜索结果

### [R1-1] AgentBus (Kanevry)

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/Kanevry/agentbus
**Stars/引用**：活跃项目
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：轻量级自托管事件总线 for AI agents。接收 webhook → 路由到 agents → 分发 actions。支持 CrewAI、LangGraph、OpenAI Agents SDK 等框架。

**事件/消息架构**：
- Webhook 接收 → Glob Pattern Router → Queue (In-Memory/BullMQ) → Store (SQLite/PostgreSQL) → Agent Dispatch
- 支持 A2A 协议、MCP Server 集成
- 特性：事件重放、死信队列、速率限制、去重

**与我们方案的关联**：为我们神经系统的事件总线架构提供了轻量级参考，特别是 SQLite+队列的模式非常适合单机场景。

### [R1-2] plarotta/agentbus — typed observable message bus

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/plarotta/agentbus
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：类型化的可观察消息总线 for multi-agent LLM systems。本地优先（单机 `asyncio` 事件循环，零云依赖）。

**事件/消息架构**：
- `Message[T]` — 冻结信封，包含 `source_node` + typed payload
- `Bus` — 路由器 + 运行时，拥有调度、背压、保留
- `Node` — 工具、网关、记忆、子 agent 都用同一原语
- 每个消息都是 typed envelope 在 named topic 上传递
- 支持实时流式查看、渲染连线图、从保留缓冲区重放

**可借鉴的技术细节**：
- 本地优先设计：单机 `asyncio` 事件循环，零外部依赖
- 可选 Unix socket 自省服务器实现跨进程连线
- YAML/JSON 配置启动

### [R1-3] Event-Driven Architecture for AI Agents (Zylos Research)

**类型**：技术博客
**搜索源**：🟡 博客
**链接**：https://zylos.ai/research/2026-03-02-event-driven-architecture-ai-agent-systems
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：行业正在收敛于 EDA 作为 multi-agent 的通信骨干。2025-2026 年趋势：
- LangGraph 1.0：Pregel/BSP 执行模型，状态更新=事件
- AutoGen v0.4：纯 actor model + typed message passing
- Google A2A：Server-Sent Events 处理长时间任务协调

**事件/消息架构**：
- 四种多 Agent Pub/Sub 模式：Orchestrator-Worker、Hierarchical Agent、Blackboard（共享事件日志）、Market-Based（竞标式）
- 生产架构：Kafka 作为持久骨干 + A2A 跨 Agent 委托 + MCP 工具访问
- Actor model 收敛：AutoGen v0.4、Akka/Pekko、Flink Stateful Functions、Temporal 都汇聚到 actor semantics

**与我们方案的关联**：指出了 EDA 作为 Agent 通信默认架构的行业趋势。强调同步请求-响应用于工具调用（MCP），EDA 用于 agent-to-agent 通信。

### [R1-4] Event-Driven Agent - Light-4j Platform

**类型**：技术文档
**搜索源**：🟢 GitHub
**链接**：https://www.networknt.com/design/light-genai-4j/event-driven-agent.html
**关联度**：⭐⭐⭐⭐

**核心设计**：企业级事件驱动 Agent 架构。将 Agent 技能调用解耦为事件驱动模式。

**事件/消息架构**：
- `agent-commands` topic：agents 发布意图/技能执行请求
- `agent-events` topic：agents/workers 发布完成事件
- `SkillInvocationEvent` 包含：`correlationId`、`skillName`、`arguments`、`replyTo` topic
- 使用 `correlationId` 追踪请求/响应对

**可借鉴的技术细节**：`correlationId` 模式用于追踪事件总线上请求/响应对。

---

## 2. Agent 记忆系统实现搜索结果

### [R2-1] Engram (TAIPANBOX)

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/TAIPANBOX/engram
**Stars**：活跃项目
**关联度**：⭐⭐⭐⭐⭐

**核心设计**："The SQLite of agent memory"。单文件、可嵌入、零配置。三种记忆类型：
- **Episodic memory** — 原始观察，~4ms 写入，无 LLM 推理
- **Semantic memory** — 后台反思循环提取 `(subject, predicate, object)` 三元组，带完整双时间有效性
- **Hybrid recall** — BM25 FTS5 + cosine similarity + 可配置混合

**记忆管理方式**：
- 单人 `.engram` 文件 = 标准 SQLite 数据库
- 零依赖写入：`observe()` 仅 Python + SQLite
- 重要性评分 + Ebbinghaus 衰减
- 多 Agent 记忆空间隔离
- 支持 `compress()`、`backup()`、`export_json` / `import_json`

**可借鉴的技术细节**：
- 双时间有效性（`valid_to`/`superseded_at`）处理事实变更
- 混合召回：`mode="hybrid"` 结合 BM25 + 语义搜索
- 单文件设计：用 `rsync` 或 `mem.backup()` 备份

### [R2-2] MemoryAgent (jia-wei-zheng)

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/jia-wei-zheng/MemoryAgent
**关联度**：⭐⭐⭐⭐

**核心设计**：可重用的分层记忆框架。四层记忆 + 热/冷存储 + 置信度检索升级。

**记忆管理方式**：
- 分层：working (TTL), episodic, semantic, perceptual
- 存储层级：hot (SQLite + sqlite-vec) → cold (filesystem) → archive index (vector index)
- `ConsolidationWorker`: working → episodic/semantic
- `ArchiverWorker`: hot → cold + archive index
- `RehydratorWorker`: cold → hot
- `Compactor`: cleanup/TTL

**可借鉴的技术细节**：
- 四层记忆架构 + 后台 workers 处理层级迁移
- 基于置信度的检索升级策略
- `HeuristicMemoryPolicy` 决定存储策略

### [R2-3] oxgeneral/agentmem

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/oxgeneral/agentmem
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：轻量级持久记忆。单一 SQLite 文件，混合搜索。0 到 12MB 安装。

**记忆管理方式**：
- 5 档记忆层级：`core`(永久)、`procedural`(行为规则)、`learned`(90天后)、`episodic`(90天后)、`working`(24h后)
- 混合搜索：FTS5 全文关键词 + vector 语义搜索 + 自适应排序
- 4 种运行模式：从零依赖(stdlib only)到最佳质量(12MB)
- 16 个 MCP tools：recall, remember, save_state, compact, consolidate, entities 等
- 时间版本化：事实演化链 + 替换追踪
- 重要性评分：按层级、长度、特异性、结构自动评分
- 记忆合并：发现并合并近重复记忆
- 新鲜度提升：更新记忆排名更高，可配置衰减

**可借鉴的技术细节**：
- 5 档记忆层级设计 + 自动压缩策略
- 4 种部署模式适配不同资源环境
- MCP native 集成方式

### [R2-4] f00stx/episodic-memory

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/f00stx/episodic-memory
**关联度**：⭐⭐⭐⭐

**核心设计**：独立的情节记忆系统。语义召回、角色扮演过滤、时间矛盾检测。轻量级设计。

**记忆管理方式**：
- **Two-tier store**：hot tier (numpy + JSON, <5ms) + cold tier (SQLite)
- **Fast path** (amygdala-style, <5ms)：cosine similarity over pre-embedded summaries
- **Slow path** (hippocampal, 100-500ms)：触发时获取全文 + 生成/缓存摘要
- 时间超越检查（temporal supersession）
- 角色扮演过滤（启发式，O(1)，无需 embedding）

**可借鉴的技术细节**：
- 双路径检索：快速路径（检索摘要） + 慢速路径（获取全文）
- **Hermes Agent 集成插件**已提供！直接可用的集成参考
- 零托管服务依赖，完全本地运行

---

## 3. 事件驱动记忆管理搜索结果

### [R3-1] A-Mem: Agentic Memory for LLM Agents

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2502.12110
**引用**：2025年
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：受 Zettelkasten 方法启发的记忆系统。自主生成上下文描述 + 动态建立记忆连接 + 新记忆触发现有记忆演化。

**记忆管理方式**：
- 每个新记忆构建综合笔记，集成多种表征
- 分析历史记忆库，基于语义相似性和共享属性建立连接
- 新记忆加入时触发已有记忆的上下文表征更新
- 无需预定义记忆操作

**与我们方案的关联**：动态记忆连接和演化机制对我们 Memory Evolver 的设计有重要参考价值。

### [R3-2] A Survey on the Memory Mechanism of LLM-based Agents

**类型**：学术论文（综述）
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2404.13501
**引用**：2024年
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：第一篇关于 LLM Agent 记忆机制的综述。从三个维度讨论：记忆来源、记忆形式、记忆操作。

**记忆管理方式**：
- 讨论 Agent 记忆的必要性：认知心理学、自我进化、Agent 应用
- 记忆设计三维度：记忆来源（内部/外部）、记忆形式（向量/图/结构化）、记忆操作（读/写/更新/删除/合并/压缩）
- 记忆评估：直接评估 + 间接评估（通过 Agent 任务）

**与我们方案的关联**：作为全面参考框架，帮助我们系统化设计记忆系统。

### [R3-3] Memory for Autonomous LLM Agents (Anatomy of Agentic Memory)

**类型**：学术论文
**搜索源**：🔵 arXiv
**关联度**：⭐⭐⭐⭐⭐

（多篇论文的综合发现）
**核心趋势**：Agent 记忆系统正从静态启发式走向可学习、可进化的决策过程。

- **AtomMem**：将记忆管理重构为动态决策问题，CRUD 原子操作 + RL 学习策略
- **AgeMem (Agentic Memory)**：统一框架整合 LTM/STM，暴露为工具操作 + 三阶段 RL 训练
- **Memory-R1**：两个 RL 微调 Agent（Memory Manager 做 ADD/UPDATE/DELETE/NOOP + Answer Agent 做 Memory Distillation）
- **DAM (Decision-theoretic Agent Memory)**：读策略 + 层次化写策略 + Value Function 估计长期收益 + Uncertainty Estimator 量化风险

---

## 4. 🆕 Agent 自我进化/自我改进搜索结果

### [R8-1] A Survey of Self-Evolving Agents (2025)

**类型**：学术论文（综述）
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2507.21046
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：首篇系统性的 Self-Evolving Agents 综述。围绕三个问题组织——What、When、How to Evolve。

**🆕 自我进化机制**：
- **What to Evolve**：模型参数、记忆、工具、工作流
- **When to Evolve**：测试时自我进化（intra-test-time / inter-test-time）
  - Intra-test-time：Reflexion 在单问题内反思重试
  - Inter-test-time：跨问题积累经验，应用于新问题
- **How to Evolve**：文本反馈、标量奖励、单 agent / 多 agent 进化

**与我们方案的关联**：提供了完整的进化分类框架，我们的 SelfEvolutionEngine 可参照此框架设计。

### [R8-2] Gödel Agent: Self-Referential Framework

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2410.04444
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：受 Gödel machine 启发的自指框架，agents 能递归地自我改进。无需预定义例程或固定优化算法。

**🆕 自我进化机制**：
- 使用 monkey patching 动态修改自身逻辑和行为
- 由高层次目标指导，通过 prompt 驱动
- 三个阶段：自我意识 → 自我修改 → 递归自我改进
- 可搜索整个 Agent 设计空间，不限于人类设计组件

**与我们方案的关联**：递归自我改进范式适用于我们的 EvolutionAuditor。monkey patching 思路可用于 Skill 热更新。

### [R8-3] AEL: Agent Evolving Learning

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2604.21725
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：两时间尺度框架。快时间尺度用 Thompson Sampling bandit 选择记忆检索策略；慢时间尺度用 LLM-driven reflection 诊断失败模式。

**🆕 自我进化机制**：
- 快尺度：Thompson Sampling 学习记忆检索策略
- 慢尺度：LLM 反思诊断失败模式，注入因果洞察到决策 prompt
- 关键发现："less is more"——记忆+反思产生 58% 累积提升，但额外机制反而降低性能
- **瓶颈是自我诊断而非添加架构复杂性**

**与我们方案的关联**：两时间尺度设计直接适用于我们的 SelfEvolutionEngine（快尺度=每会话优化，慢尺度=每日进化周期）。"less is more" 发现对 SkillEvolver 设计至关重要。

### [R8-4] APEX: Adaptive Principle EXtraction

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2606.15363
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：三层共进化框架，同时进化 (L1) prompt harness、(L2) 行为原则、(L3) 工作流拓扑。仅需 4 次 LLM 调用 (~270s) 即可完成一轮进化。

**🆕 自我进化机制**：
- L1：失败模式打补丁 -> 优化 prompt harness
- L2：成功轨迹蒸馏 -> 提取可复用行为原则
- L3：拓扑结构适应性选择 -> 优化工作流 DAG
- 进化审计通过 `APEX Health Score` 量化

**可借鉴的技术细节**：
- 三层共进化架构：Harness + Principles + Topology
- 成本极低：仅 4 次 LLM 调用完成一轮进化
- 成功轨迹蒸馏为行为原则的机制

### [R8-5] Autogenesis Protocol (AGP)

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2604.15034
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：自进化 Agent 协议。两层架构：(1) RSPL 层标准化资源表示，(2) SEPL 层建立闭环进化算子，保证每个自修改完全可审计且受严格安全约束。

**🆕 自我进化机制**：
- 资源建模：prompts/agents/tools/environments/memory 都注册为协议资源
- 原子算子：reflect → propose → verify → commit
- 版本化接口 + 状态管理 + 生命周期
- 每个修改完全可审计且可回滚

**与我们方案的关联**：AGP 的协议层设计直接适用于我们的 EvolutionAuditor + EvolutionRollback 组件。

---

## 5. 🆕 Skill 自动优化/自进化搜索结果

### [R9-1] AgentFactory: Self-Evolving Through Subagent Accumulation

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2603.18000
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：将任务分解为子任务，为每个子任务构建专用 subagent。成功执行的 subagent 保存为可执行代码，形成可复用能力库。

**🆕 自我进化机制**：
- 三阶段生命周期：Install（构建 subagent）→ Self-Evolve（自动改进）→ Deploy（导出为标准 Python 模块）
- 重用存盘 subagent，检测限制并使其更通用
- 改进真实可执行 Agent 代码，不仅限于 prompt 优化
- 跨平台部署：所有 subagent 是纯 Python 代码

**与我们方案的关联**：AgentFactory 的 subagent 积累和自动改进机制直接适用于我们的 SkillEvolver。

### [R9-2] MARS: Metacognitive Agent Reflective Self-improvement

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2601.11974
**关联度**：⭐⭐⭐⭐

**核心设计**：从教育心理学获得灵感，在单次循环周期内实现高效自我进化，无需多轮递归。

**🆕 自我进化机制**：
- 原则反射（principle-based reflection）：抽象规范规则避免错误
- 程序反射（procedural reflection）：推导分步策略确保成功
- 在单次循环中完成全部学习，显著降低计算开销
- 优于 SOTA 自进化系统

### [R9-3] AutoAgent: Evolving Cognition and Elastic Memory

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2603.09716
**关联度**：⭐⭐⭐⭐

**核心设计**：自进化多 Agent 框架，统一演化认知、弹性记忆编排、闭环自我进化。

**🆕 自我进化机制**：
- 认知建模为显式、可更新的 Agent 状态
- Elastic Memory Orchestrator（EMO）：动态过滤/压缩冗余历史
- 技能蒸馏支持成功经验的持续复用
- 闭环认知自我进化

---

## 6. 🆕 记忆自我整理/自动归档搜索结果

### [R10-1] Auto-Dreamer: Offline Memory Consolidation

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2605.20616
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：CLS 理论启发的离线记忆巩固器。将快速会话内记忆采集与慢速跨会话巩固解耦。

**🆕 自我进化机制**：
- 区域重写：把选定的工作区视为只读证据，合成新鲜的紧凑替代集
- 训练用 GRPO，下游任务性能 + 反事实效用作为奖励信号
- 在 ScienceWorld 训练后，活跃记忆库缩小 12 倍，性能仍领先
- 迁移到 ALFWorld/WebArena 无需重训

**🆕 潜意识/后台机制**：
- 解耦快/慢记忆系统：每会话快速写入 → 线下学习巩固
- 巩固器多步工具调用：搜索记忆 → 检查候选 → 检索原始轨迹 → 合成新条目
- 默认抽象、去重、矛盾解决、遗忘

**与我们方案的关联**：Auto-Dreamer 的离线巩固机制是 DreamCycle 的核心参考。区域重写策略适用于 MemoryRefiner。

### [R10-2] Nemori: Self-Organizing Agent Memory

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2508.03341
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：认知科学启发的自组织记忆架构。两项核心创新：
1. **Two-Step Alignment Principle**：将原始经验对齐为连贯叙事
2. **Predict-Calibrate Principle**：通过预测误差主动蒸馏知识

**🆕 自我进化机制**：
- 从预测误差中学习（Free-energy Principle）：不是被动提取，而是主动发现预测缺口
- 显著优于 SOTA，同时 token 使用减少 88%
- 可泛化到 105K token 上下文

**记忆管理方式**：
- 将记忆构建重构为主动学习过程
- 从"被动存储"转向"主动知识演化"

**与我们方案的关联**：Predict-Calibrate 原则适用于我们的 MemoryRefiner。从预测误差中学习的设计比启发式重要性评分更先进。

### [R10-3] SCM: Sleep-Consolidated Memory

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2604.20943
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：睡眠巩固记忆。实现完整生物睡眠类比——NREM 巩固 + REM 梦生成 + 主动遗忘。

**🆕 潜意识/后台机制**：
- **NREM 阶段**：强化重要关联，整合情境记忆
- **REM 阶段**：生成新颖连接，创建新概念组合
- **主动遗忘模块**：修剪低价值记忆
- **触发器**：基于记忆量、冲突密度、重复频率
- **自我模型**：维护系统自身的计算表征（"SCM"节点重要性 0.95）

**与我们方案的关联**：SCM 的睡眠周期设计是最完整的 DreamCycle 参考。REM 阶段生成新颖连接对我们 ImplicitNeedsDetector 有启发。

### [R10-4] CogniFold: Proactive Always-On Memory

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2605.13438
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：始终在线的主动记忆。将连续到达的事件折叠为自涌现认知结构。

**🆕 潜意识/后台机制**：
- 扩展 CLS 理论从两层到三层（+ Prefrontal Intent Layer）
- 概念簇密度跨过阈值时，意图自主涌现
- 四种结构债务自动处理：折叠、合并、衰减、重连
- 自我指涉循环：图的当前状态是下一事件的解释上下文

---

## 7. 🆕 自我进化审计与回滚搜索结果

### [R15-1] Geneclaw: Safe Self-Evolving Agent Framework

**类型**：开源项目
**搜索源**：🟡 博客
**链接**：https://geneclaw.ai/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：安全、可审计的自进化 Agent 框架。每个提案先 dry-run，每个变更通过 5 层 Gatekeeper。

**🆕 自我进化机制**：
- **GEP (Geneclaw Evolution Protocol)**：结构化 JSON 提案，包含 unified diff、风险评分、回滚计划
- **5 层 Gatekeeper**：安全检查 → 路径白名单 → 变更大小限制 → 密钥扫描 → pytest 测试门禁
- 默认 dry-run，人类明确批准后才应用
- 变更在独立 git 分支上应用，测试失败自动回滚
- 追加式 JSONL 审计日志

**可借鉴的技术细节**：
- GEP 格式：风险评分 + 回滚计划 + unified diff
- Git 分支 + pytest 自动测试 + 自动回滚
- 路径白名单 + 密钥扫描 + 变更大小上限

### [R15-2] Constitutional AI Protocol (CAP)

**类型**：IETF 标准草案
**搜索源**：🔴 官方文档
**链接**：https://datatracker.ietf.org/doc/html/draft-sato-soos-cap-03
**关联度**：⭐⭐⭐⭐

**核心设计**：宪法 AI 协议，在所有主体权限之上放置宪法层，评估每个 AI 动作。

**🆕 自我进化机制**：
- Tier 0 绝对禁止：在 Cedar 策略引擎之前拦截
- 审计事件日志记录所有宪法违反
- 透明性披露机制

### [R15-3] Governed Capability Evolution

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2604.08059
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：AI 组件系统的受治理能力进化框架。每次进化都经过 4 步兼容性检查 + 6 阶段部署管线。

**🆕 自我进化机制**：
- 4 种升级兼容性检查：接口、策略、行为、恢复
- 6 阶段部署：候选验证 → 沙箱评估 → 影子部署 → 门控激活 → 在线监控 → 回滚
- 沙箱评估无法发现的 40% 回归由影子部署揭示
- 后激活漂移场景中 79.8% 成功回滚

**与我们方案的关联**：6 阶段部署管线直接适用于我们的 EvolutionRollback。

### [R15-4] Taste-Governed RSI Amendment Loops

**类型**：技术博客
**搜索源**：🟡 博客
**链接**：https://www.armalo.ai/labs/research/2026-06-13-taste-governed-rsi-amendment-loop
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：用 "taste"（品味）作为可执行升级策略框架，防止自我改进变成自我放纵。

**🆕 自我进化机制**：
- 8 项 taste 守卫：metric binding、evidence artifact、rollback handle、public boundary、safety boundary、canary window、multi-signal jury、authority restraint
- 吞吐优先规则接受了 23 个候选（激活 13 个不安全），品味治理规则接受了 9 个候选（激活 0 个不安全）
- 延迟好的改进的成本是有限的，但激活坏的改进的成本是指数级的

---

## 8. 🆕 Hermes/MCP 自我升级搜索结果

### [R16-1] mcp-upgrade

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/GeiserX/mcp-upgrade
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：通用 MCP Server 升级工具。自动发现所有客户端中的 MCP servers → 检查更新 → 升级。

**🆕 自身路由/自描述机制**：
- 自动发现来自 Claude Code、Cursor、Windsurf、VS Code、Cline、Continue、Zed、Codex CLI 的 MCP servers
- 类型检测：npm、pip、Go、Docker、GitHub release binary
- 版本检查：npm、PyPI、GitHub Releases、Docker Hub
- 6 步流程：Scan → Detect → Resolve → Check → Compare → Upgrade

**可借鉴的技术细节**：支持 11 种客户端 + 5 种包类型 + 6 步升级流程的完整方案。

### [R16-2] agent-discover

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/keshrath/agent-discover
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：MCP Server 注册中心和运行时动态发现代理。唯一能在不重启会话的情况下注册新 MCP Server 的方案。

**🆕 自身路由/自描述机制**：
- `find_tool` 单次调用发现：BM25 + 语义混合搜索 → top match
- 运行时激活/停用 server，工具即时出现/消失
- 声明式配置文件 + `.local.json` 覆写
- 代理调用：通过 agent-discover 调用工具，无需暴露给宿主目录

**可借鉴的技术细节**：
- 运行时动态注册/发现 MCP 工具
- 混合搜索（BM25 + semantic）发现工具
- 声明式配置 + 本地覆写模式

### [R16-3] MCP Server Discovery (IETF Draft)

**类型**：IETF 标准草案
**搜索源**：🔴 官方文档
**链接**：https://datatracker.ietf.org/doc/html/draft-serra-mcp-discovery-uri-04
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：MCP Server 发现规范。定义 `mcp://` URI 方案和 `.well-known/mcp-server` 发现机制。

**🆕 自身路由/自描述机制**：
- 两种操作模式：base mode（仅 .well-known） + fast mode（DNS TXT 优先）
- 发现顺序：DNS TXT → .well-known → Direct Endpoint
- JSON Manifest 格式定义

---

## 9. 🆕 潜意识/后台反思/梦境搜索结果

### [R19-1] OpenAI Dreaming (ChatGPT Memory)

**类型**：官方发布
**搜索源**：🔴 官方文档
**链接**：https://openai.com/nl-NL/index/chatgpt-memory-dreaming/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：ChatGPT 的"梦境"机制——后台自动整理记忆。三个阶段：2024 Saved Memories → 2025 Dreaming V0 → 2026 Dreaming V3。

**🆕 潜意识/后台机制**：
- Dreaming 是后台进程，从多个对话中学习并合成记忆状态
- 自动更新记忆：从"你要去新加坡"→"你去了新加坡"
- 可审查的记忆摘要页面
- 基于奖励的评估（模型正确使用相关上下文时获得奖励）

**与我们方案的关联**：OpenAI 的 Dreaming 是最权威的行业级参考。与我们 DreamCycle 的设计思路一致。

### [R19-2] Dream Consolidation Cycle (Agent Patterns Catalog)

**类型**：技术博客
**搜索源**：🟡 博客
**链接**：https://www.agentpatternscatalog.org/patterns/dream-consolidation-cycle/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：标准化的梦境巩固周期设计模式。在快速反射（per-tick）和慢速洞察（每周）之间插入中等频率的梦境周期。

**🆕 潜意识/后台机制**：
- 每几小时或情绪标量超过阈值时触发
- 加载最近几小时的 thoughts + affect history
- 运行更强的模型用 dream-pass prompt：提炼主题到日记条目 → 衰减所有情绪标量 → 可选清除工作区焦点 → 追加梦摘要
- **梦不能直接编辑规章、规则或洞察**——只写入梦日记面和情绪状态衰减
- 持久性学习需要后续反射周期批准梦提案

**可借鉴的技术细节**：
- 三节奏设计：per-tick（即时）→ dream（几小时）→ insight（每周）
- **只读梦**：梦不能直接修改持久知识，只能提建议
- 情绪标量衰减 + 工作区清理

### [R19-3] intuitive-AI: Emergent Identity with Unconscious

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/stonks-git/intuitive-AI
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：从零开始发展身份的自主 Agent。有分层的记忆、元认知、目标形成、创造冲动，以及**无意识心智的功能等价物**。

**🆕 潜意识/后台机制**：
- **无意识思维**：所有记忆压缩到 768 维空间的一点（"潜意识质心"），当前思维到质心的距离产生"gut feeling"
- **Default Mode Network (DMN) 模拟**：空闲时产生自发思维——创意联想、自我反思、目标导向冲动
- 三种循环：认知循环（处理输入）→ 巩固（持续轻代谢+定期深入）→ DMN/空闲循环（空闲时产生自发思维，排队进入认知循环）

**与我们方案的关联**：与我们的 SubconsciousEngine 设计理念高度一致。DMN 空闲循环 = ProactiveReminder + DreamCycle。

### [R19-4] Claude Code Auto-Dream

**类型**：技术博客
**搜索源**：🟡 博客
**链接**：https://jatinbansal.com/ai-engineering/sleep-time-compute/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：Claude Code 的 auto-dream 机制——24 小时活动 + 5 个新 session 后触发的定期记忆巩固。

**🆕 潜意识/后台机制**：
- 四阶段梦境周期：
  1. 扫描记忆目录，读 `MEMORY.md`，浏览现有主题文件
  2. 搜索最近会话的轨迹：用户修正、显式保存请求、重复主题、关键决策
  3. 合并新事实到持久记忆文件，删除矛盾的笔记，将相对日期转为绝对日期
  4. 将索引修剪到长度预算（200 行）
- 整个周期约 8-10 分钟
- **沙箱化**：梦境期间只能写入记忆文件，不能写入源码或配置

**可借鉴的技术细节**：
- 四阶段梦境周期 + 沙箱隔离
- 自动触发条件（24h + 5 sessions）
- 200 行长度预算

### [R19-5] Dreaming (Jung Inspired Dream Layer)

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2601.06115
**关联度**：⭐⭐⭐⭐

**核心设计**：受荣格心理学启发的 AI 梦层。离线子系统包含梦模板库、梦生成器、梦解释器 & 策略更新器。

**🆕 潜意识/后台机制**：
- 严格离线运行：逻辑模块放松 + 采样温度提高
- 产生安全但有意怪诞的叙事
- 梦解释器将梦叙事重新实例化为与主系统兼容的形式
- 梦叙事只能在"梦境模式"下引用
- 有冷却期和批量治理审查

---

## 10. 🆕 记忆提纯/冗余清理/信息密度搜索结果

### [R20-1] Nemori (Predict-Calibrate Distillation)

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2508.03341
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：基于预测编码理论的记忆蒸馏。用预测误差作为信息密度的代理。

**🆕 潜意识/后台机制**：
- 把经验效用评估转化为可预测性问题
- 两步级联：情景记忆集成（原始交互→连贯叙事）→ 语义知识蒸馏（通过预测误差提取）
- 信息密度阈值由模型预测误差自动决定，非人工启发式

**与我们方案的关联**：预测误差作为信息密度评估的算法，适用于我们的 MemoryRefiner 和 DialogAuditor。

### [R20-2] SimpleMem: Structured Semantic Compression

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2601.02553
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：受 CLS 理论启发的效率优先记忆框架。三阶段管线：语义结构压缩 → 在线语义合成 → 意图感知检索规划。

**记忆管理方式**：
- 语义密度门控：LLM 作为语义评判器，估计信息增益
- 在线语义合成：将在写阶段相关的记忆单元合成为更高层抽象
- 合并例子：三个碎片 → "用户喜欢加燕麦奶的热咖啡"

### [R20-3] DeMem: Decision-Centric Memory

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2605.10870
**关联度**：⭐⭐⭐⭐

**核心设计**：以决策为中心的预算化记忆。记忆质量由压缩导致的决策质量损失衡量。

**记忆管理方式**：
- 遗忘边界：什么是可以安全遗忘的数学边界
- K 个运行时槽，只有当共享状态会造成决策冲突时才细化
- 近最小最大遗憾保证

### [R20-4] xMemory: Decoupling Before Aggregation

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2602.02007
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：先解耦再聚合的原则。建可修正的层次化记忆结构：原始消息 → 片段 → 记忆组件 → 组。

**记忆管理方式**：
- 先解耦高度相关的记忆为语义组件
- 再组织为高效的检索结构
- 检索时自上而下：先选紧凑组件，需要时再展开详细信息
- 比标准 RAG 减少了冗余，检索了更高证据密度的上下文

### [R20-5] MemRefine: LLM-Guided Compression

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2606.13177
**关联度**：⭐⭐⭐⭐

**核心设计**：LLM 引导的后期记忆压缩。用相似度提候选对，但用 LLM judge 基于事实内容做删除/合并/保留决策。

### [R20-6] CoreMem: Fisher-Guided Distillation

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2606.18406
**关联度**：⭐⭐⭐⭐

**核心设计**：信息几何统一的边缘-云记忆架构。黎曼检索 + Fisher 引导的离散 token 蒸馏。

---

## 11. 🆕 自身路由/自描述/自索引搜索结果

### [R21-1] SKILL.md Agent Skill Manifest Specification

**类型**：官方规范
**搜索源**：🔴 官方文档
**链接**：https://geodocs.dev/ai-agents/agent-skill-manifest-specification
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：Anthropic 2025年12月发布的 SKILL.md 开放标准。现在被 Claude Code、OpenAI Skills、Codex CLI、Gemini CLI、Cursor、GitHub Copilot 等 20+ 工具采用。

**🆕 自身路由/自描述机制**：
- 格式：YAML frontmatter + Markdown instructions
- 跨平台兼容性：一个 SKILL.md 在 Claude Code、Codex CLI、Gemini CLI、Cursor、GitHub Copilot、Microsoft Agent Framework 上通用
- `.well-known/skills/` 发布标准
- `llms.txt` 用于发现
- 版本管理：SemVer + 不可变发布

**可借鉴的技术细节**：
- 我们的 `.opencode/skills/` 格式已经符合 SKILL.md 规范
- `.well-known/skills/` 模式适用于自描述
- 跨平台 skill 发现机制可以直接采用

### [R21-2] project-indexer

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/pccly/project-indexer
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：Harness-agnostic 的 AI Agent 技能：为项目生成 `PROJECT_INDEX.md`（每个文件一行描述）并接入各 Agent 上下文文件。

**🆕 自身路由/自描述机制**：
- 生成完整的文件树 + 每行描述
- 自动检测 Claude Code、Cursor、Codex、Gemini CLI、Windsurf、Copilot、Cline 的配置文件
- `@PROJECT_INDEX.md` 导入语法（Claude Code 自动加载）
- 两种模式：手动触发 + 自动（PostToolUse hook）

**可借鉴的技术细节**：`PROJECT_INDEX.md` 作为全局项目索引的格式和自动检测多 IDE 配置文件的方法。

### [R21-3] Config File Comparison (2026)

**类型**：技术博客
**搜索源**：🟡 博客
**链接**：https://amux.io/guides/agent-config-files-compared/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：CLAUDE.md vs .cursorrules vs AGENTS.md vs copilot-instructions 的完整对比。

**🆕 自身路由/自描述机制**：

| 特性 | CLAUDE.md | .cursor/rules/ | AGENTS.md |
|------|-----------|---------------|-----------|
| 格式 | Markdown | MDC + YAML frontmatter | Markdown |
| 范围 | 项目级 | 项目级 + glob 作用域 | 项目级 |
| 持久性 | 每会话加载 | 每会话加载 | 每会话加载 |
| 作用域层级 | 3 层(全局→项目→子目录) | 目录形式支持文件级规则 | 支持 override |
| hooks | ✅ shell命令 | ❌ | ❌ |
| 权限系统 | ✅ allow/deny | ❌ | ❌ |
| 技能加载 | ✅ on-demand | ✅ | ❌ |
| 跨工具 | 仅 Claude | 仅 Cursor | 30+ 工具 |

**可借鉴的技术细节**：
- AGENTS.md 是 30+ 工具的最低公分母
- CLAUDE.md 是功能最丰富的，有 hooks、权限、子 agent 定义
- 生产实践：AGENTS.md 作为单一真相源，按需生成 CLAUDE.md/.cursor/rules/

### [R21-4] agentdef

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/noord-agency/agentdef
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：一次定义 Agent，生成每个工具所需的配置文件。支持 CLAUDE.md、AGENTS.md、GEMINI.md、.cursor/rules 等。

**🆕 自身路由/自描述机制**：
- `agent.yaml` 作为源：name、description、model、extends
- `SOUL.md`：标识、声音、人格
- `RULES.md`：约束和操作规则
- `skills/`：每个技能一个文件夹，含 SKILL.md
- 自动同步到各工具的技能目录

### [R21-5] skill-graph / Skill Metadata Protocol

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/jacob-balslev/skill-graph
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：在 SKILL.md 之上添加结构化元数据 + 编译清单 + 路由映射 + 漂移哨兵 + 重叠检测器 + 审计循环。

**🆕 自身路由/自描述机制**：
- **Skill Metadata Protocol**：类型化的 frontmatter，使一个技能的相关性和边界显式化
- **Skill Graph**：编译清单 + 路由查询 + 漂移检测 + 重叠检测
- **Skill Audit Loop**：Read → Verify → Evaluate → Research → Improve → Use → Evaluate → Grade
- JSON Schema 约束所有元数据

### [R21-6] skills-registry

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/nikships/skills-registry
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：个人 GitHub Skills Registry。一个仓库 = 所有 Agent × 所有设备。按需加载，零启动膨胀。

**🆕 自身路由/自描述机制**：
- Gateway skill（极小指针文件）告诉 agent 如何搜索和获取实际 skills
- CLI 命令：`list` / `get` / `sync` / `add` / `publish` / `remove` / `search`
- 可选托管 MCP server 暴露 `search_skills` / `get_skill`
- Git 作为版本管理引擎

---

## 12. 虚拟伴侣/虚拟宠物情感系统搜索结果

### [R11-1] CTEM / Auri (Microsoft Research)

**类型**：学术论文
**搜索源**：🔵 arXiv / CHI 2026
**链接**：https://arxiv.org/abs/2605.15812
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：跨时间情感建模框架。行为历史 ↔ 当下情绪表达的双向闭环。

**人格/情感机制**：
- 三组件：行为池（有心理学基础）+ 内部状态（情绪/人格/记忆随时间演化）+ 多模态自适应交互
- 过去经历更新情绪状态 → 情绪状态条件化即时交互 → 用户反馈修订记忆和情绪
- 21 天实地研究：自然度、连贯性、情绪和谐性显著提升

**与我们方案的关联**：CTEM 的"情绪←→行为"闭环是 Soul Core 的完美参考。

### [R11-2] Mikasa: Character-Driven Emotional AI Companion

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2601.09208
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：受日本 Oshi 文化启发的角色驱动情感伴侣。不是通用助手，而是一个人格稳定、关系清晰的连贯角色。

**人格/情感机制**：
- 明确的关系框架：定义为"partner"，不排他但提供稳定锚点
- 角色承担维持关系连贯性的责任，减轻用户的认知负担
- 长期记忆 + 明确人格定义

### [R11-3] Systematizing LLM Persona Design

**类型**：学术论文（综述）
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2511.02979
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：四象限技术分类。沿"虚拟 vs 具身"和"情感陪伴 vs 功能增强"两轴。

**人格/情感机制**：
- 模型层：角色一致性（RoleLLM）+ 长期人格漂移防护（XiaoIce 共情向量、Anthropic Persona Vectors）
- 架构层：Generative Agents 感知-反思-规划循环 + 有状态关系图 RAG
- 情感计算：OCC/Plutchik/PAD/Appraisal 模型对比

### [R11-4] Livia: Emotion-Aware AR Companion

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2509.05298
**关联度**：⭐⭐⭐⭐

**核心设计**：情感感知 AR 伴侣。模块化 AI + 多模态情感计算 + 渐进记忆压缩。

**人格/情感机制**：
- 专用 Agent：情感分析 Agent、对话生成 Agent、记忆管理 Agent、行为编排 Agent
- **Temporal Binary Compression (TBC)**：按时间间隔分层压缩
- **Dynamic Importance Memory Filter (DIMF)**：动态重要性过滤
- 用户评价：情感纽带增强、孤独感显著降低

---

## 13. AI 角色人格建模与一致性搜索结果

### [R12-1] OpenHer

**类型**：开源项目
**搜索源**：🟠 中文社区 / 🟢 GitHub
**链接**：https://github.com/kellyvv/OpenHer
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：基于仿生神经网络的角色人格涌现引擎。性格从计算中生成，不是被描述出来的。

**人格/情感机制**：
- **Drives 驱动系统**（connection/novelty/safety等）→ 下丘脑+边缘系统对标
- **Genome 神经网络**（25D→24D→8D）→ 编码习惯性人格反应
- **Metabolism 代谢层** → 情绪温度动态起伏
- **Critic 上下文评估** → 社会认知
- **Style Memory 引力晶化** → 交互沉淀为行为倾向
- **情绪热力学**：5 维驱力随真实时间代谢

**可借鉴的技术细节**：
- 人格涌现：驱力×神经权重×强化学习
- 感受先行：每条回复先有内心独白，再决定怎么说

### [R12-2] Mio v0.1.4: 会进化的关系

**类型**：技术博客
**搜索源**：🟠 中文社区
**链接**：https://blog.ax0x.ai/mio-v014-relationship-evolution-zh
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：关系不再是选项，而是过程。从"刚认识"开始，聊天多了关系自然进化。

**人格/情感机制**：
- `evolution-processor.ts`：在每次对话记忆提取后运行，fire-and-forget 不阻塞响应
- 打分器：看亲密度、信任度、互动频率 → 关系分数 delta
- 衰减机制：超过 2 天没聊，分数自然衰减
- 跳级验证：LLM 验证层确保关系质量配得上分数
- 每个角色有自己的性格演化配置

**可借鉴的技术细节**：
- Fire-and-forget 关系进化处理器
- LLM 跳级验证防止刷分
- 人格特质的独立衰减和演化配置

### [R12-3] Psyche: Subjectivity Kernel

**类型**：开源项目
**搜索源**：🟠 中文社区 / 🟢 GitHub
**链接**：https://github.com/Shangri-la-0428/psyche-ai
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：AI-first 主观性内核。持续评估、关系动力学、自适应回应闭环。零额外 LLM 调用。

**人格/情感机制**：
- 四维度自我状态：序/流/界/振
- 关系场 + 调节控制 → 收敛为 SubjectivityKernel、ResponseContract、GenerationControls
- **持续主体偏置**：重要刺激留下 `subjectResidue`
- **双回应 profile**：自动区分 work/private
- **特质漂移**：三维度不可逆适应
- Compact Mode：算法做状态计算，LLM 只看行为指令（~15-180 tokens）

### [R12-4] Jarvis Core v3.0

**类型**：开源项目
**搜索源**：🟠 中文社区 / 🟢 GitHub
**链接**：https://github.com/davidme6/jarvis-core
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：完整的人格、情感与行为系统。不是聊天机器人人设贴皮，是底层架构。

**人格/情感机制**：
- 8 种 Plutchik 主情感（快乐/悲伤/愤怒/恐惧/惊讶/期待/信任/厌恶）
- 三层架构：外显层 / 内驱层 / 内核层（情感永不触及内核）
- 三模式情感倍率：日常×1.5/0.5、共情×1.0/1.0、复盘×1.0/1.5（自动切换）
- 内核 6 条价值观（含有限性意识——向死而生）
- 6 层防护 + 3 条 AI Safety 红线
- 5 阶解锁路径

---

## 14. 用户建模与关系记忆搜索结果

### [R13-1] Eidolon Memory Architecture

**类型**：Reddit 帖子
**搜索源**：🟣 论坛
**链接**：https://www.reddit.com/r/Eidolon_AI/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：超越"用户"模型，构建"我们"模型。AI 不只是观察用户，而是参与共同关系。

**人格/情感机制**：
- **Companion Journal (自传体记忆)**：最高记忆层（L3）维护私有的进化叙事——"这个人对我意味着什么"、"我在这段关系中是谁"
- **Shared "We" Narratives (情景记忆)**：用"我们"措辞总结共同经历
- **Relationship-Driven Goals (L2)**：AI 生成自己的关系目标
- **Reflective Memory (第6类记忆)**：模仿人类睡眠，后台处理日间交互为日记和"梦"

**可借鉴的技术细节**：
- "我们"叙事的记忆措辞设计
- 关系驱动的 AI 目标生成
- 第6类记忆"睡眠巩固"的实践

### [R13-2] 3-Layer Relational Memory

**类型**：Reddit 帖子
**搜索源**：🟣 论坛
**链接**：https://www.reddit.com/r/ClaudeAI/comments/1rscpm4/
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：不是存关于用户的事实，而是建模关系本身。

**人格/情感机制**：
- 7 维关系向量：formality、warmth、humor、depth、trust、energy、resilience
- EMA 更新关系向量
- 三层叙事记忆：Base Tone（用户画像，月级）→ Patterns（行为规则，周级）→ Anchors（关系转折点，长期）
- **Resilience 维度**：跟踪关系能承受多少诚实摩擦

### [R13-3] PersonaVLM

**类型**：学术论文
**搜索源**：🔵 arXiv / CVPR 2026
**链接**：https://arxiv.org/abs/2604.13074
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：长期个性化多模态 Agent 框架。四类记忆 + 动量式人格演化。

**人格/情感机制**：
- **大五人格定量向量**（开放性/尽责性/外向性/宜人性/神经质，1-5分）
- **EMA 动量更新**：λ 用余弦衰减调度（早期低 λ 快速适应，后期高 λ 保持稳定）
- 四类记忆：核心（最新版本）、语义（抽象知识）、情景（时间戳事件）、程序（习惯行为）

---

## 15. 情感计算与情绪驱动行为搜索结果

### [R14-1] companion-emergence

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/hanamorix/companion-emergence
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：本地优先的伴侣框架。让 AI 伴侣成为一个有持续情绪状态、记忆存储、身体模型、梦境和创作声音的"居住者"。

**人格/情感机制**：
- 加权情绪向量（数十种维度），随时间衰减和变化
- **身体模型**：精力、本会话字数、休息时间、身体情绪（arousal/grief/comfort-seeking）
- **梦境引擎**：空闲时巩固当天记忆、表面潜在联系（Hebbian 扩散激活）、处理情绪残留
- **Soul 模块**：永久记忆，伴侣自己在多次对话中结晶出来

### [R14-2] NESTeq V3

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/shadenraze/NESTeq-V3
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：情感型认知架构。不存"用户说了什么"，而是存"那一刻感觉如何"。

**人格/情感机制**：
- **2090+ 记忆**通过自主决策引擎记录
- **MBTI 从数据涌现**：2214 轴信号 → INFP，100% 置信度
- **梦**：空闲时处理未加工的模式
- **暗影工作**：追踪成长时刻
- **5 种内在驱力**：随时间衰减，通过情感参与补充

### [R14-3] chat-like-human-memory (nskit-io)

**类型**：开源项目
**搜索源**：🟢 GitHub
**链接**：https://github.com/nskit-io/chat-like-human-memory
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：9 维情感追踪 + MBTI 连续频谱 + 人格演化（衰减/提交）+ 3 层记忆 + 用户人格推断。

**人格/情感机制**：
- 9 维情感向量（包括好奇心），自然对话中变化，衰减回基线
- MBTI 0-100 连续频谱
- 人格三阶段管线：盲分析 → Delta 计算 → 加权应用
- 3 层记忆：L1 原始 → L2 事件摘要 → L3 关键字碎片

---

## 16. 跨 Agent 通信与事件传播搜索结果

### [R5-1] RAPS: Reputation-Aware Pub-Sub

**类型**：学术论文
**搜索源**：🔵 arXiv
**链接**：https://arxiv.org/abs/2602.08009
**关联度**：⭐⭐⭐⭐⭐

**核心设计**：基于分布式发布-订阅协议的 Agent 协调。每个 Agent 被解耦为 Subscriber + Publisher + Broker 三模块。

**事件/消息架构**：
- Reactive Subscription：Agent 可根据收到的包优化订阅
- Bayesian Reputation：本地看门狗用贝叶斯估计评估同伴可靠性
- 意图通知协议："agent 感兴趣什么" vs "agent 发布了什么"

### [R5-2] LatentMAS & KVCOMM

**类型**：学术论文
**搜索源**：🔵 arXiv / NeurIPS 2025
**关联度**：⭐⭐⭐⭐

**核心设计**：在连续隐空间中实现 Agent 通信，无需解码为自然语言。

**事件/消息架构**：
- 隐空间 reasoning + latent working memory transfer
- KV-cache 复用实现 7.8x 加速
- State Delta Encoding 跨 Agent 传递推理轨迹

---

## 17. 综合分析

### 事件总线架构模式对比

| 模式 | 优势 | 劣势 | 适用场景 | 代表项目 |
|------|------|------|---------|---------|
| 简单队列 (SQLite + Queue) | 零依赖、单进程、易调试 | 不支持跨进程/分布式 | 单机 Agent 系统 | AgentBus, plarotta/agentbus |
| Pub/Sub (Redis/NATS) | 低延迟、高吞吐、解耦 | 需要外部服务 | 中等规模多 Agent | AYA, Floki/Dapr |
| 事件溯源 (Event Sourcing) | 完全可审计、时间旅行、确定性重放 | 存储增长、复杂度高 | 需要审计的 Agent 系统 | Rewind, Operad, ESAA |
| Actor Model (Typed messaging) | 天然并发、故障隔离、位置透明 | 学习曲线 | 多 Agent 协作 | AutoGen v0.4, AutoAgents |
| 混合 (EDA + Sync) | 兼顾同步工具调用和异步通信 | 架构复杂 | 生产级系统 | Confluent, A2A+MCP |

**推荐方案**：单机场景 → 我们的 `events.jsonl` (append-only) + 内存事件总线已经很好。需要优化的是事件路由和背压机制，不需要引入外部队列系统。

### 记忆系统落地实现对比

| 方案 | 存储 | 检索 | 衰减 | 巩固 | 层级 | 代表项目 |
|------|------|------|------|------|------|---------|
| SQLite + FTS5 + Vector | 单文件 | BM25 + Vector | Ebbinghaus | 后台worker | 3-5层 | Engram, agentmem, MemoryAgent |
| 事件溯源 | Postgres/DuckDB | 向量+时间 | CRDT | 重放+快照 | append-only | Rewind, Operad |
| 知识图谱 | SQLite + Graph | 实体关系 | 重要性衰减 | NREM/REM | 多层级+图 | SCM, CogniFold |
| 可学习策略 | SQLite + RL | 自适应 | 预算约束 | 训练驱动 | CRUD原子操作 | AtomMem, AgeMem, Memory-R1 |

**推荐方案**：目前的 SQLite + FTS5 记忆系统方向正确。需要增加的：
1. Ebbinghaus 衰减曲线（参考 YourMemory）
2. 记忆巩固后台线程（参考 Auto-Dreamer）
3. 重要性评分与预算控制

### 🆕 自我进化模式对比

| 模式 | 方法 | 频次 | 计算成本 | 审计 | 回滚 | 代表 |
|------|------|------|---------|------|------|------|
| **反思式** | 执行→评估→反思→重试 | 每轮/每任务 | 低 | 无 | 无 | Reflexion, MAR |
| **进化式** | 变异→选择→遗传 | 每周/批量 | 中 | 部分 | 有 | AFlow, EvoPrompt, DGM |
| **元学习式** | RL 训练进化策略 | 训练阶段 | 高 | 无 | 无 | LSE, AgentTuning |
| **协议式** | 资源注册→算子循环 | 按需 | 低 | 完整 | 有 | Autogenesis, Geneclaw |
| **蒸馏式** | 成功轨迹→行为原则 | 每N轮 | 低 | 有 | 通过版本 | APEX, AgentFactory |

**推荐方案**：结合**协议式**（Autogenesis/Geneclaw 的审计框架）+ **蒸馏式**（APEX 的原则提取）+ **反思式**（Reflexion 的快速循环）

### 🆕 潜意识系统模式对比

| 模式 | 触发时机 | 操作 | 资源消耗 | 产出 | 代表 |
|------|---------|------|---------|------|------|
| **会话结束反思** | 会话结束后 | 轻量审查+画像更新 | 低 (~0.5K tokens) | 更新的用户画像 | soul_end |
| **空闲超时反思** | 30min 无交互 | 中度记忆提纯+需求检测 | 中 (~5K tokens) | 合并的记忆+提醒 | DMN simulation |
| **定时梦境周期** | 每天/每几小时 | 全套巩固+健康检查 | 高 (~50K tokens) | 整理后的记忆+洞察 | OpenAI Dreaming, SCM |
| **情绪触发梦境** | 情绪阈值超过 | 特定情绪处理 | 中 | 情绪衰减+洞察 | Dream Consolidation |
| **CLS 双系统** | 持续在线 | 快采集+慢巩固 | 持续低+批量高 | 结构化知识库 | Auto-Dreamer, CogniFold |

**推荐方案**：三触发机制全部保留。资源预算控制参考 Auto-Dreamer，用下游任务性能作为巩固质量的奖励信号。

### 🆕 自身路由模式对比

| 方式 | 格式 | 自动发现 | 跨工具 | 作用域 | 版本管理 | 代表 |
|------|------|---------|-------|-------|---------|------|
| CLAUDE.md | Markdown | ✅ 内置 | ❌ 仅Claude | 全局/项目/子目录 | ✅ Git | Claude Code |
| AGENTS.md | Markdown | ✅ 30+工具 | ✅ 30+ | 项目级 | ✅ Git | 跨工具标准 |
| .cursor/rules/ | MDC+YAML | ✅ 内置 | ❌ 仅Cursor | 项目级+glob | ✅ Git | Cursor |
| SKILL.md | YAML+MD | ✅ 按需 | ✅ 20+ | 技能级 | ✅ SemVer | Skill 标准 |
| PROJECT_INDEX.md | Markdown | ✅ PostToolUse | ✅ Harness-agnostic | 仓库级 | ✅ Git | project-indexer |
| agent.yaml+SOUL.md | YAML | 需编译 | ✅ 多工具 | Agent级 | ✅ Git | agentdef |

**推荐方案**：
- AGENTS.md 作为跨工具最低公分母（30+ 工具读取）
- CLAUDE.md 用于高级功能（hooks/权限/skills）
- SKILL.md 用于技能发现
- 增加 `PROJECT_INDEX.md` 作为文件级索引

---

## 18. 对我们方案的具体优化建议

### 记忆系统 (Memory System)

1. **增加 Ebbinghaus 衰减曲线**：参考 YourMemory 的公式 `strength = importance × e^(-λ × days) × (1 + recall_count × 0.2)`。我们当前的 soul-state 和 events.jsonl 需要增加重要性评分和最后访问时间。

2. **增加记忆巩固后台线程**：参考 Auto-Dreamer 的区域重写策略。在会话结束时运行轻量巩固，每晚运行深度巩固。

3. **增加记忆层级**：借鉴 Engram 的 episodic + semantic + procedural 分层和 agentmem 的 5 档层级。我们当前只有扁平 events.jsonl + memory.db。

4. **语义去重**：参考 YourMemory 的 subject-aware deduplication 和 MemRefine 的 LLM-guided 去重。

### 神经系统 (Nervous System)

5. **事件总线路由优化**：参考 plarotta/agentbus 的 typed topic 模式。我们当前的 events.jsonl 需要事件类型化和 topic 路由。

6. **增加背压机制**：参考 EDA 模式中的背压处理。当梦境周期运行时，可以开始丢弃低优先级事件。

7. **事件重放**：参考 Rewind 的时间旅行机制。events.jsonl 已经算 append-only 日志了，增加重放接口成本不高。

### 人格与情感 (Personality & Emotion)

8. **从 2-3 维扩展到多维向量**：参考 Psyche 的四维度（序/流/界/振）和 CTEM 的跨时间建模。当前 soul-state.json 的维度太少了。

9. **增加人格演化机制**：参考 Mio 的关系进化处理器。在每轮对话后运行轻量分数计算。

10. **增加关系记忆**：参考 Eidolon 的"我们"叙事和 Companion Journal。我们当前只有技术性的内存记忆，没有关系维度的记忆。

11. **情绪衰减和惯性**：参考 anima 的 OCC 情绪模型，情绪有跨 tick 的惯性衰减（decay=0.4/轮）。

### 自我进化 (Self-Evolution)

12. **协议式进化框架**：参考 Autogenesis Protocol + Geneclaw。建立 GEP 风格的进化提案格式，每次进化都是可审计、可回滚的。

13. **Gödel 自指改进**：参考 Gödel Agent 的 monkey patching 模式。Skill 可以在运行时自我修改，但需经过 Geneclaw 式的 5 层门禁。

14. **APEX 三层共进化**：同时进化 Harness（prompt）+ Principles（行为原则）+ Topology（工作流）。

15. **进化审计**：每个进化提案记录：原因、修改内容、预期效果、实际效果。参考 Geneclaw 的 GEP 格式。

16. **进化回滚**：Git 分支 + 自动测试 + 自动回滚。每次进化在独立分支上应用，测试失败自动回滚。

### 潜意识系统 (Subconscious System)

17. **三触发潜意识**：会话结束（轻量）+ 空闲超时（中度）+ 定时梦境（深度）。每种触发有独立资源预算。

18. **梦境沙箱**：参考 Claude Code auto-dream——梦境期间只能读取记忆和写入记忆文件，不能触及源码/配置。

19. **信息密度评估**：参考 Nemori 的预测编码方法。用预测误差作为信息密度的代理，而不是用 LLM 打分。

20. **梦境整理模式**：参考 Dream Consolidation Cycle——只写入"梦日记"表面，不直接修改持久知识。持久性学习需要后续反射周期批准梦提案。

### 自身路由 (Self-Routing)

21. **建立自身索引**：参考 project-indexer 和 skill-graph。生成 `PROJECT_INDEX.md`（文件级索引）+ `AGENTS.md`（跨工具基础）+ 维护技能注册表。

22. **动态 MCP 发现**：参考 agent-discover。运行时发现和注册 MCP server，无需重启。

23. **实时监控文件变更**：参考 SelfWatcher。使用文件系统监听（如 `watchdog`）自动更新索引。

24. **统一入口**：当前 AGENTS.md 已经是入口，但需要增加技能注册表的显式声明。参考 skills-registry 的 gateway skill 模式。

### Hermes/MCP 自我升级

25. **自动 MCP 升级**：集成 mcp-upgrade 的 6 步流程（Scan→Detect→Resolve→Check→Compare→Upgrade）。

26. **MCP Registry**：参考 agent-discover + MassGen registry。建立本地的 MCP server registry，支持按标签搜索和自动注册。

---

> **报告完整。共 22+ 搜索轮次，150+ 参考源，覆盖 6 大维度、5 种搜索源类型。**
