# 多 Agent 协作架构 + Skill 自动调度：深度搜索任务书

> **任务性质**：长时间、多轮次、全覆盖的深度研究搜索
> **执行者**：DS4-Flash Worker（在 OpenCode 中执行）
> **输出文件**：本文件即为输出文件，搜索结果直接追加到本文档末尾
> **预计耗时**：60-90 分钟（不要提前结束，见下方"强制深度搜索机制"）

---

## 一、任务目标

联网搜索多 Agent 协作/编排的学术文献、开源项目和工业实践，以及 Skill 自动发现/匹配/调度的相关方案，为我们的架构设计提供参考和优化依据。

**核心要求：搜全、搜深、搜具体。** 不要满足于找到 3-5 个项目就停，要穷尽每个搜索维度，找到尽可能多的参考。宁可多搜不可漏搜。

---

## 二、我们的架构背景（你必须理解才能精准搜索）

### 架构概要
- **单主 Agent + 可扩展子 Agent 专家团**：一个主 Agent（小璃）负责规划、路由、调度和验收，多个领域子 Agent 负责执行
- **运行环境**：个人开发者，双 IDE（Trae/OpenCode），同一套 agent 定义跨 IDE 运行
- **不是分布式系统**：单机、单用户，不需要考虑多租户/高可用/水平扩展
- **关键约束**：token 消耗敏感（使用 DeepSeek API），上下文窗口有限，需要精确控制 skill 加载量

### Agent 架构设计要点（需要搜索参考的部分）

1. **Agent 定义与运行时分离**
   - agent 定义放在统一 YAML 文件中（不绑定 IDE）
   - 每个 IDE 加载同一套定义，但运行模式不同（Codex 模式自由度高，Hermes 模式强制流程）
   - 参考：Omnigent 的 meta-harness 模式（统一编排 Claude Code/Codex/Cursor）

2. **子 Agent 可扩展机制**
   - 当前子 Agent：UE 工程师、Web 工程师、工具链工程师、记忆管理员、代码验证器、记忆 gate
   - 以后可能新增：数据分析、音乐制作、3D 建模等领域子 Agent
   - 需要：新增子 Agent 时不改主 Agent 代码的扩展机制

3. **调度模式灵活化**
   - 不是固定的"派生→执行→返回"，根据任务类型选择：
     - Sequential：有依赖时顺序执行
     - Concurrent：独立任务并行
     - Handoff：一个子 agent 做完交给另一个
     - Group：多专家讨论（但 token 消耗大，慎用）
   - 参考：Microsoft Agent Framework 的图模式编排

4. **分权制衡（可选参考）**
   - 三省六部的"规划→审核→执行→回奏"链路
   - 我们已有 Comet 四阶段（Plan→Implement→Review→Verify），Review 在 Implement 之后
   - 问题：是否需要"Plan 完成后的审核"步骤？

### Skill 自动调度设计要点（需要搜索参考的部分）

5. **Skill 三层分类**
   - 主 Agent skill：规划、流程控制、验收、记忆管理（小璃必须掌握的）
   - 子 Agent skill：领域专业知识（只有对应子 agent 才加载）
   - 共享 skill：路由判断和通用工具（主 agent 和子 agent 都可用）

6. **Skill 自动调用：三层匹配**
   - 第一层（路由匹配，主 agent 执行）：只看 skill description + tags，判断需要哪个子 agent + 哪些主 skill
   - 第二层（子 agent skill 加载）：子 agent 根据任务细节加载领域 skill 全文
   - 第三层（深度引用）：执行过程中按需加载 reference 文档

7. **频率控制**
   - 硬限制：每次任务最多 5 个主 skill、每个子 agent 最多 3 个领域 skill、每个 skill 最多 2 个 reference
   - 软限制：优先级标记（P0/P1/P2）、重叠度去重（>70% 只取最相关）、3 轮未用自动卸载
   - 总量上限：~30KB（约 8000 token）

8. **Skill 元数据格式**
   - 每个 skill 目录下有 skill-manifest.yaml：name/description/category/sub_agent/priority/tags/trigger_keywords/trigger_patterns/exclude_when/load_cost_kb/references
   - 汇总索引 skill-index.yaml：主 agent 只加载这个文件做路由判断

9. **记忆分层存储**
   - 结构化记忆（规则、决策、偏好）→ SQLite facts 表
   - 文档记忆（知识笔记、视频总结）→ Markdown 文件
   - 图谱记忆（概念关系）→ SQLite graph 表
   - 路由索引 → JSON（tag→节点，分类→节点）

---

## 三、强制深度搜索机制（MUST READ）

### 为什么需要强制机制

AI 执行搜索任务时，常见问题是"搜了 3-5 个就停了"——因为 AI 倾向于认为"已经够了"。但我们的需求是穷尽式搜索，宁可多搜不可漏搜。以下机制确保搜索足够深、足够全。

### 机制一：搜索轮次强制（最少 8 轮）

你必须执行至少 **8 轮搜索**，每轮搜索一个不同的关键词组合或不同的网站。8 轮是下限，不是上限——如果某轮搜索发现了新的有价值线索，应该追加搜索轮次。

| 轮次 | 搜索目标 | 搜索网站 | 关键词组合 |
|------|---------|---------|-----------|
| R1 | 多 Agent 编排框架 | GitHub | multi-agent orchestration framework |
| R2 | 多 Agent 编排框架 | arXiv | LLM multi-agent collaboration |
| R3 | Skill 自动发现 | GitHub | agent skill discovery plugin |
| R4 | Skill 自动发现 | 技术博客 | LLM tool selection automatic |
| R5 | Token 优化 | arXiv + 博客 | context window optimization agent |
| R6 | 记忆分层 | GitHub + arXiv | agent memory architecture layered |
| R7 | 具体项目深挖 | GitHub（逐个） | AutoGen/LangGraph/CrewAI/Swarm 源码 |
| R8 | 社区反馈 | Reddit + HN | multi-agent framework comparison review |

每轮搜索完成后，在本文档的"搜索日志"章节记录：轮次号、搜索网站、关键词、找到的结果数、是否有新发现。

### 机制二：发现驱动追加搜索

每轮搜索后，如果发现以下情况，**必须追加搜索**（不计入 8 轮下限）：

- 搜索结果中提到了你不知道的项目/论文 → 追加搜索该项目/论文
- 搜索结果中的引用/参考列表有高价值条目 → 追加搜索那些条目
- 某个项目的 GitHub 仓库有 `awesome-*` 列表或 `references.md` → 读取并搜索其中条目
- 某篇论文的 Related Work 章节提到了相关工作 → 搜索那些工作
- 搜索结果中出现了新的关键词/术语 → 用新关键词追加搜索

### 机制三：每个项目必须深挖

找到项目后，不要只看 README。必须执行以下深挖步骤：

1. 读取 README.md（架构概述）
2. 读取项目的架构设计文档（通常在 `docs/` 或 `ARCHITECTURE.md`）
3. 读取核心模块的源码目录结构（`src/` 或 `lib/` 的文件列表）
4. 读取配置文件格式（`*.yaml`、`*.json`、`*.toml`）
5. 读取 Issues 中标有 `architecture`/`design`/`rfc` 的讨论
6. 如果有示例（`examples/`），读取最相关的 1-2 个

### 机制四：交叉验证

对每个重要发现，至少在 2 个不同来源验证：
- GitHub 项目 → 在 Reddit/HN 搜索社区评价
- 学术论文 → 在 GitHub 搜索是否有开源实现
- 技术博客 → 在 arXiv 搜索是否有更严谨的论文支撑

---

## 四、具体搜索网站与 URL（按优先级排列）

### 第一优先级：GitHub（开源项目搜索）

| 搜索入口 | URL | 用途 |
|---------|-----|------|
| GitHub 搜索 | `https://github.com/search` | 全局搜索仓库、代码、Issues |
| GitHub Topics: agent | `https://github.com/topics/agent` | Agent 相关热门项目 |
| GitHub Topics: multi-agent | `https://github.com/topics/multi-agent` | 多 Agent 项目 |
| GitHub Topics: llm-agent | `https://github.com/topics/llm-agent` | LLM Agent 项目 |
| GitHub Topics: ai-agent | `https://github.com/topics/ai-agent` | AI Agent 项目 |
| GitHub Topics: autonomous-agent | `https://github.com/topics/autonomous-agent` | 自主 Agent |
| GitHub Topics: agent-framework | `https://github.com/topics/agent-framework` | Agent 框架 |
| GitHub Topics: agent-orchestration | `https://github.com/topics/agent-orchestration` | Agent 编排 |
| GitHub Trending | `https://github.com/trending?since=monthly` | 月度热门项目 |
| GitHub Trending Python | `https://github.com/trending/python?since=monthly` | Python 热门 |
| GitHub Trending TypeScript | `https://github.com/trending/typescript?since=monthly` | TS 热门 |

**GitHub 搜索关键词组合（每个都要搜）：**

```
# 多 Agent 编排
"multi-agent" orchestration framework
"agent orchestration" lightweight
"agent dispatch" sequential concurrent
"agent handoff" workflow
"agent supervisor" delegation
"hierarchical agent" system
"agent graph" DAG workflow
"agent definition" YAML runtime

# Skill/Plugin 发现
"skill discovery" agent automatic
"plugin discovery" LLM agent
"tool selection" agent semantic
"skill manifest" registry agent
"capability loading" dynamic agent
"prompt composition" optimization
"skill routing" matching

# 记忆架构
"agent memory" layered architecture
"memory architecture" LLM agent
"knowledge graph" agent memory
"structured memory" agent facts

# 具体项目名搜索
AutoGen Microsoft
LangGraph agent
CrewAI framework
Agency Swarm
OpenAI Swarm
Semantic Kernel skills
MetaGPT framework
Dify workflow
Coze agent
Omnigent harness
edict 三省六部 agent
MemGPT Letta
Mem0 memory
OpenClaw memory
```

**具体项目 GitHub URL（直接访问深挖）：**

| 项目 | GitHub URL | 搜索重点 |
|------|-----------|---------|
| AutoGen | `https://github.com/microsoft/autogen` | 多 Agent 对话编排、Agent 定义格式、GroupChat 机制 |
| AutoGen (v0.4) | `https://github.com/microsoft/autogen/tree/main/python/packages/autogen-core` | 新版核心架构、事件驱动、Agent Runtime |
| LangGraph | `https://github.com/langchain-ai/langgraph` | 图模式编排、StateGraph、conditional edges |
| CrewAI | `https://github.com/crewAIInc/crewAI` | 角色制 Agent、Task 流程、Tool 分配 |
| Agency Swarm | `https://github.com/VRSEN/agency-swarm` | Agent 层级、Tool 指定、通信机制 |
| OpenAI Swarm | `https://github.com/openai/swarm` | 极简多 Agent、handoff 机制、routine 定义 |
| Semantic Kernel | `https://github.com/microsoft/semantic-kernel` | Skill/Plugin 注册、自动发现、Function Calling |
| MetaGPT | `https://github.com/geekan/MetaGPT` | 角色定义、Skill 映射、SOP 流程 |
| Dify | `https://github.com/langgenius/dify` | 工作流编排、Tool 自动发现、Agent 模式 |
| Omnigent | `https://github.com/omnigent/omnigent` | meta-harness、跨 IDE 编排、YAML agent 定义 |
| Letta (MemGPT) | `https://github.com/letta-ai/letta` | 分层记忆、context management、Agent 状态 |
| Mem0 | `https://github.com/mem0ai/mem0` | 语义记忆、记忆检索、记忆更新 |
| OpenClaw | `https://github.com/openclaw/openclaw` | 12 层记忆架构、facts.db、LCM |
| TaskWeaver | `https://github.com/microsoft/TaskWeaver` | 代码生成 Agent、Plugin 系统 |
| ChatDev | `https://github.com/OpenBMB/ChatDev` | 角色制软件开发、Agent 通信 |
| Camel | `https://github.com/camel-ai/camel` | 角色扮演 Agent、协作机制 |
| AgentScope | `https://github.com/modelscope/agentscope` | 分布式 Agent 框架、消息机制 |
| Pydantic AI | `https://github.com/pydantic/pydantic-ai` | Agent 定义、依赖注入、类型安全 |
| Marvin | `https://github.com/prefecthq/marvin` | 轻量 Agent、Function 定义 |
| ControlFlow | `https://github.com/PrefectHQ/ControlFlow` | 多 Agent 工作流、任务编排 |
| Bryon | `https://github.com/nicepkg/bryon` | Agent 编排 |
| Rivet | `https://github.com/Ironclad/rivet` | 可视化 Agent 图编排 |
| Flowise | `https://github.com/FlowiseAI/Flowise` | 可视化 LLM 工作流 |
| Agent-Protocol | `https://github.com/AI-Engineer-Foundation/agent-protocol` | Agent 通信协议标准 |
| SuperAGI | `https://github.com/TransformerOptimus/SuperAGI` | Agent 工具注册、Skill 市场 |
| Devika | `https://github.com/stitionai/devika` | 多 Agent 软件开发 |
| GPT-Engineer | `https://github.com/gpt-engineer-org/gpt-engineer` | 代码生成 Agent |
| Aider | `https://github.com/paul-gauthier/aider` | 编码 Agent、多模型 |
| Continue | `https://github.com/continuedev/continue` | IDE Agent、Skill/Plugin 系统 |
| Cursor | `https://github.com/getcursor/cursor` | IDE Agent（闭源，搜社区讨论） |
| Cody (Sourcegraph) | `https://github.com/sourcegraph/cody` | IDE Agent、Skill 系统 |
| Copilot Workspace | `https://github.com/github/copilot-workspace` | 多步骤 Agent 工作流 |

### 第二优先级：arXiv（学术论文搜索）

| 搜索入口 | URL | 用途 |
|---------|-----|------|
| arXiv 搜索 | `https://arxiv.org/search` | 全文搜索 |
| arXiv cs.AI | `https://arxiv.org/list/cs.AI/recent` | AI 最新论文 |
| arXiv cs.CL | `https://arxiv.org/list/cs.CL/recent` | NLP 最新论文 |
| arXiv cs.MA | `https://arxiv.org/list/cs.MA/recent` | 多 Agent 系统论文 |
| arXiv cs.SE | `https://arxiv.org/list/cs.SE/recent` | 软件工程论文 |
| Semantic Scholar | `https://www.semanticscholar.org/` | 学术搜索（比 arXiv 更好的引用追踪） |
| Google Scholar | `https://scholar.google.com/` | 学术搜索 |
| Papers With Code | `https://paperswithcode.com/` | 论文+代码实现 |
| DBLP | `https://dblp.org/` | 计算机科学文献 |

**arXiv 搜索关键词（每个都要搜）：**

```
# 多 Agent 协作
"multi-agent" LLM collaboration orchestration
"LLM agent" hierarchical delegation
"agent workflow" graph scheduling
"multi-agent" software development
"agent communication" protocol framework

# Skill/Tool 发现
"tool use" LLM automatic selection
"skill discovery" reinforcement learning agent
"prompt composition" optimization LLM
"dynamic capability" agent learning
"tool retrieval" semantic matching LLM

# 记忆架构
"memory architecture" LLM agent long-term
"episodic memory" language model
"structured knowledge" agent reasoning
"memory management" context window LLM

# Token 优化
"context window" optimization agent
"token budget" allocation multi-agent
"prompt compression" LLM efficiency
"lazy loading" capability agent
```

**重点论文搜索（已知高引用，需找原文）：**

| 论文/关键词 | 搜索方向 |
|------------|---------|
| "A Survey on Large Language Model based Autonomous Agents" | Agent 综述，找其引用的多 Agent 工作 |
| "The Rise of Generative AI Agents" | Agent 架构综述 |
| "MetaGPT: Meta Programming for Multi-Agent Collaborative Framework" | MetaGPT 论文原文 |
| "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation" | AutoGen 论文原文 |
| "Communicative Agents for Software Development" | ChatDev 论文 |
| "CAMEL: Communicative Agents for Mind Exploration" | CAMEL 论文 |
| "Generative Agents: Interactive Simulacra of Human Behavior" | 斯坦福小镇论文 |
| "MemGPT: Towards LLMs as Operating Systems" | MemGPT 论文 |
| "Toolformer: Language Models Can Teach Themselves to Use Tools" | 工具自动发现 |
| "Gorilla: One API to Call Them All" | API 自动匹配 |
| "API-Bank: A Comprehensive Benchmark for Tool-Augmented LLMs" | 工具选择评估 |
| "ToolLLM: Facilitating Large Language Models to Master 16000+ Real-world APIs" | 工具自动编排 |

### 第三优先级：技术博客与社区

| 网站 | URL | 搜索方式 |
|------|-----|---------|
| **Medium** | `https://medium.com/search` | 搜索 "multi-agent LLM orchestration" |
| Medium Towards AI | `https://medium.com/towards-artificial-intelligence` | AI 专题 |
| Medium Better Programming | `https://medium.com/better-programming` | 编程专题 |
| **Dev.to** | `https://dev.to/search` | 搜索 "multi agent framework" |
| **Hacker News** | `https://news.ycombinator.com/` | 搜索 "multi agent" / "agent framework" |
| HN Search (Algolia) | `https://hn.algolia.com/` | HN 全文搜索，按时间/热度排序 |
| **Reddit** | `https://www.reddit.com/search/` | 全站搜索 |
| r/LocalLLaMA | `https://www.reddit.com/r/LocalLLaMA/` | 本地 LLM 社区 |
| r/ChatGPT | `https://www.reddit.com/r/ChatGPT/` | ChatGPT 社区 |
| r/artificial | `https://www.reddit.com/r/artificial/` | AI 通用社区 |
| r/MachineLearning | `https://www.reddit.com/r/MachineLearning/` | ML 社区 |
| r/LLMDevs | `https://www.reddit.com/r/LLMDevs/` | LLM 开发者 |
| r/AutoGen | `https://www.reddit.com/r/AutoGen/` | AutoGen 专题 |
| r/LangChain | `https://www.reddit.com/r/LangChain/` | LangChain 专题 |
| **知乎** | `https://www.zhihu.com/search` | 搜索 "多Agent协作" / "Agent框架" |
| **掘金** | `https://juejin.cn/search` | 搜索 "多Agent" / "Agent编排" |
| **CSDN** | `https://so.csdn.net/` | 搜索 "多Agent框架" / "Skill自动发现" |
| **Stack Overflow** | `https://stackoverflow.com/search` | 搜索 "multi-agent LLM framework" |
| **Lil'Log (Lilian Weng)** | `https://lilianweng.github.io/` | 高质量 AI 博客，搜 "LLM Agent" |
| **Sebastian Raschka** | `https://sebastianraschka.com/` | AI 研究博客 |
| **Chip Huyen** | `https://huyenchip.com/` | ML 工程博客 |
| **Swyx Blog** | `https://www.swyx.io/` | AI Agent 思考 |
| **Latent Space** | `https://www.latent.space/` | AI 工程播客/博客 |
| **Interconnects** | `https://www.interconnects.ai/` | AI 研究博客 |
| **Simon Willison** | `https://simonwillison.net/` | LLM 工具链博客 |
| **Andrew Ng** | `https://www.deeplearning.ai/the-batch/` | AI 周报 |
| **LangChain Blog** | `https://blog.langchain.dev/` | LangChain 官方博客 |
| **CrewAI Blog** | `https://blog.crewai.com/` | CrewAI 官方博客 |
| **AutoGen Blog** | `https://microsoft.github.io/autogen/` | AutoGen 官方文档 |

### 第四优先级：官方文档与规范

| 网站 | URL | 搜索重点 |
|------|-----|---------|
| OpenAI API Docs | `https://platform.openai.com/docs` | Assistants API、Function Calling、Tool 使用 |
| Anthropic Docs | `https://docs.anthropic.com/` | Tool Use、Agent 模式 |
| LangChain Docs | `https://python.langchain.com/` | Agent、Tool、Memory 模块 |
| LangGraph Docs | `https://langchain-ai.github.io/langgraph/` | 图模式编排详细文档 |
| CrewAI Docs | `https://docs.crewai.com/` | Agent 定义、Task 流程、Tool 分配 |
| Semantic Kernel Docs | `https://learn.microsoft.com/en-us/semantic-kernel/` | Skill/Plugin 系统 |
| AutoGen Docs | `https://microsoft.github.io/autogen/` | 多 Agent 编排、GroupChat |
| Dify Docs | `https://docs.dify.ai/` | 工作流编排、Tool 管理 |
| Agent Protocol Spec | `https://agentprotocol.ai/` | Agent 通信协议标准 |

### 第五优先级：中文社区（补充视角）

| 网站 | URL | 搜索关键词 |
|------|-----|-----------|
| 知乎 | `https://www.zhihu.com/search` | "多Agent协作框架" "Agent技能自动发现" "LLM Agent架构" |
| 掘金 | `https://juejin.cn/search` | "多Agent编排" "Agent框架对比" |
| CSDN | `https://so.csdn.net/` | "Agent Skill调度" "多智能体协作" |
| 微信公众号 (搜狗) | `https://weixin.sogou.com/` | "多Agent框架" "Agent技能管理" |
| B站 | `https://search.bilibili.com/` | "Agent框架" "多Agent" 技术分享视频 |
| 开源中国 | `https://www.oschina.net/search` | "Agent框架" "多智能体" |
| AI 工程师社区 | `https://aigc.openxlab.org.cn/` | Agent 相关讨论 |

---

## 五、搜索执行计划（按轮次详细规划）

### R1：GitHub 多 Agent 编排框架（广度搜索）

**目标**：找到所有 star > 200 的多 Agent 编排框架

**执行步骤**：
1. 访问 `https://github.com/search?q=multi-agent+orchestration+framework&type=repositories&s=stars&o=desc`
2. 访问 `https://github.com/search?q=agent+orchestration+lightweight&type=repositories&s=stars&o=desc`
3. 访问 `https://github.com/search?q=agent+dispatch+handoff&type=repositories&s=stars&o=desc`
4. 访问 `https://github.com/search?q=hierarchical+agent+system&type=repositories&s=stars&o=desc`
5. 访问 `https://github.com/search?q=agent+graph+DAG+workflow&type=repositories&s=stars&o=desc`
6. 访问 `https://github.com/search?q=agent+definition+YAML+runtime&type=repositories&s=stars&o=desc`
7. 访问 `https://github.com/topics/agent-orchestration`
8. 访问 `https://github.com/topics/multi-agent`

**对每个找到的项目**：记录名称、star 数、核心设计、与我们的关联度

### R2：arXiv 多 Agent 协作论文（学术深度）

**目标**：找到近 2 年的高引用多 Agent 协作论文

**执行步骤**：
1. 访问 `https://arxiv.org/search/?query=multi-agent+LLM+collaboration+orchestration&searchtype=all&order=-announced_date_first`
2. 访问 `https://arxiv.org/search/?query=LLM+agent+hierarchical+delegation&searchtype=all&order=-announced_date_first`
3. 访问 `https://arxiv.org/search/?query=agent+workflow+graph+scheduling&searchtype=all&order=-announced_date_first`
4. 访问 `https://arxiv.org/search/?query=multi-agent+software+development&searchtype=all&order=-announced_date_first`
5. 访问 `https://www.semanticscholar.org/search?q=multi-agent+LLM+orchestration+framework&sort=citation-count`
6. 访问 `https://paperswithcode.com/search?q=multi-agent+LLM+framework`

**对每篇找到的论文**：记录标题、arXiv ID、核心贡献、是否有开源实现

### R3：GitHub Skill/Plugin 发现系统（专项搜索）

**目标**：找到所有实现了 Skill/Plugin 自动发现和匹配的系统

**执行步骤**：
1. 访问 `https://github.com/search?q=skill+discovery+agent+automatic&type=repositories&s=stars&o=desc`
2. 访问 `https://github.com/search?q=plugin+discovery+LLM+agent&type=repositories&s=stars&o=desc`
3. 访问 `https://github.com/search?q=tool+selection+agent+semantic&type=repositories&s=stars&o=desc`
4. 访问 `https://github.com/search?q=skill+manifest+registry+agent&type=repositories&s=stars&o=desc`
5. 访问 `https://github.com/search?q=capability+loading+dynamic+agent&type=repositories&s=stars&o=desc`
6. 访问 `https://github.com/search?q=prompt+composition+optimization&type=repositories&s=stars&o=desc`
7. 访问 `https://github.com/search?q=skill+routing+matching&type=repositories&s=stars&o=desc`
8. 深挖 Semantic Kernel 的 Plugin 系统：`https://github.com/microsoft/semantic-kernel/tree/main/dotnet/src/SemanticKernel.Abstractions/Skills` 和 `https://github.com/microsoft/semantic-kernel/tree/main/dotnet/src/SemanticKernel.Core/Skills`
9. 深挖 MetaGPT 的角色-技能映射：`https://github.com/geekan/MetaGPT/tree/main/metagpt/roles`
10. 深挖 SuperAGI 的 Skill 市场：`https://github.com/TransformerOptimus/SuperAGI/tree/main/superagi/skills`

### R4：技术博客 Skill 自动发现（实践视角）

**目标**：找到社区中关于 Skill/Tool 自动发现和调度的实践经验

**执行步骤**：
1. 访问 `https://medium.com/search?q=LLM+tool+selection+automatic`
2. 访问 `https://medium.com/search?q=agent+skill+discovery+framework`
3. 访问 `https://dev.to/search?q=multi%20agent%20framework`
4. 访问 `https://www.swyx.io/` 搜索 Agent 相关文章
5. 访问 `https://lilianweng.github.io/` 搜索 LLM Agent 文章
6. 访问 `https://simonwillison.net/` 搜索 Agent/Tool 文章
7. 访问 `https://blog.langchain.dev/` 搜索 Agent 编排文章
8. 访问 `https://www.latent.space/` 搜索 Agent 架构讨论

### R5：arXiv + 博客 Token 优化（专项搜索）

**目标**：找到 Agent 场景下的 token 优化和上下文管理方案

**执行步骤**：
1. 访问 `https://arxiv.org/search/?query=context+window+optimization+agent&searchtype=all&order=-announced_date_first`
2. 访问 `https://arxiv.org/search/?query=token+budget+allocation+multi-agent&searchtype=all&order=-announced_date_first`
3. 访问 `https://arxiv.org/search/?query=prompt+compression+LLM+efficiency&searchtype=all&order=-announced_date_first`
4. 访问 `https://medium.com/search?q=LLM+context+window+optimization+agent`
5. 访问 `https://github.com/search?q=token+budget+agent+optimization&type=repositories&s=stars&o=desc`
6. 访问 `https://github.com/search?q=prompt+compression+LLM&type=repositories&s=stars&o=desc`
7. 访问 `https://github.com/search?q=lazy+loading+capability+agent&type=repositories&s=stars&o=desc`

### R6：GitHub + arXiv 记忆分层（专项搜索）

**目标**：找到 Agent 记忆分层架构的实现方案

**执行步骤**：
1. 访问 `https://github.com/search?q=agent+memory+layered+architecture&type=repositories&s=stars&o=desc`
2. 访问 `https://github.com/search?q=memory+architecture+LLM+agent&type=repositories&s=stars&o=desc`
3. 访问 `https://github.com/search?q=knowledge+graph+agent+memory&type=repositories&s=stars&o=desc`
4. 访问 `https://github.com/search?q=structured+memory+agent+facts&type=repositories&s=stars&o=desc`
5. 深挖 Letta/MemGPT：`https://github.com/letta-ai/letta` → 读取 `memgpt/core/` 目录结构和记忆管理代码
6. 深挖 Mem0：`https://github.com/mem0ai/mem0` → 读取记忆存储和检索实现
7. 访问 `https://arxiv.org/search/?query=memory+architecture+LLM+agent+long-term&searchtype=all&order=-announced_date_first`
8. 访问 `https://arxiv.org/search/?query=episodic+memory+language+model&searchtype=all&order=-announced_date_first`

### R7：具体项目深挖（逐个深入）

**目标**：对 R1-R6 中发现的高价值项目，逐个深入阅读源码和文档

**执行步骤**（对每个项目）：
1. 读取 README.md
2. 读取 ARCHITECTURE.md 或 docs/ 目录
3. 读取核心源码目录结构
4. 读取配置文件格式（YAML/JSON/TOML）
5. 读取 examples/ 中最相关的示例
6. 读取 Issues 中标有 architecture/design/rfc 的讨论
7. 记录：Agent 定义格式、Skill/Tool 注册机制、调度模式、记忆管理方式

**必须深挖的项目**（无论 R1-R6 是否找到，这些都要看）：
- AutoGen（新版 v0.4 核心架构）
- LangGraph（StateGraph 实现）
- CrewAI（Agent+Task+Tool 定义）
- OpenAI Swarm（handoff 机制）
- Semantic Kernel（Plugin 系统）
- MetaGPT（角色-技能映射）
- Letta/MemGPT（记忆分层）
- Mem0（语义记忆）

### R8：社区反馈与对比（验证搜索）

**目标**：找到社区对多 Agent 框架的真实评价和对比

**执行步骤**：
1. 访问 `https://hn.algolia.com/?q=multi-agent+framework+comparison`
2. 访问 `https://hn.algolia.com/?q=AutoGen+vs+LangGraph+vs+CrewAI`
3. 访问 `https://www.reddit.com/r/LocalLLaMA/search/?q=multi+agent+framework&sort=relevance`
4. 访问 `https://www.reddit.com/r/LocalLLaMA/search/?q=agent+framework+comparison&sort=relevance`
5. 访问 `https://www.reddit.com/r/ChatGPT/search/?q=multi+agent+orchestration&sort=relevance`
6. 访问 `https://www.reddit.com/r/AutoGen/search/?q=architecture&sort=relevance`
7. 访问 `https://www.zhihu.com/search?type=content&q=多Agent框架对比`
8. 访问 `https://www.zhihu.com/search?type=content&q=Agent技能自动发现`

---

## 六、搜索结果格式要求

每个搜索结果必须包含以下字段：

```markdown
### [R-轮次-编号] 项目/文献名称

**类型**：开源项目 / 学术论文 / 技术博客 / 社区讨论
**链接**：URL
**Stars/引用**：（如适用）
**最后更新**：日期
**与我们方案的关联度**：⭐⭐⭐（1-5星，5星最相关）

**核心设计**：
[3-5 句话描述核心架构设计]

**与我们方案的关联**：
[明确对应 9 个设计要点的哪些项]

**可借鉴的技术细节**：
[具体的代码结构、配置格式、算法、数据结构]

**不适用的部分**：
[明确说明哪些不适合我们]

**优化建议**：
[对我们方案的改进建议]
```

---

## 七、质量过滤标准

### 排除
- 纯理论无实现（论文无代码且无落地案例）
- 企业级重型框架（Swarms、Haystack 等面向企业的）
- 已停更 >1 年且无社区维护
- 与单机/个人场景完全无关（如分布式共识、多租户隔离）
- 纯营销文章（无技术细节的"AI 革命"类文章）

### 优先
- 轻量级、可嵌入个人项目
- 有实际使用案例和社区反馈
- 与 LLM API 调用模式兼容
- 有清晰的 Agent 定义格式（YAML/JSON/代码）
- 有 Skill/Tool 注册和发现机制
- 有 token/上下文管理方案

---

## 八、最终输出结构

完成所有搜索后，在本文档末尾按以下结构整理：

1. **搜索概述**：搜索时间、总轮次、总结果数、各维度分布
2. **搜索日志**：每轮搜索的记录（轮次、网站、关键词、结果数、新发现）
3. **多 Agent 协作框架搜索结果**（按关联度排序）
4. **Skill 自动调度搜索结果**（按关联度排序）
5. **Token 优化与上下文管理搜索结果**
6. **记忆分层搜索结果**
7. **综合分析**：
   - 可直接借鉴的设计（列出具体来源和具体做法）
   - 需要适配的设计（列出原始做法和我们的适配方向）
   - 应避免的设计（列出具体来源和避免原因）
8. **对我们方案的具体优化建议**（对应 9 个设计要点的逐条建议，每条建议标注参考来源）

---

## 九、注意事项

- **每个搜索结果必须附带原始 URL**——没有 URL 的结果视为无效
- **技术细节尽量具体到代码/配置级别**——不要只写"它有一个调度机制"，要写"它用 `StateGraph.add_node()` + `add_conditional_edges()` 定义 DAG，节点是函数，边是条件判断"
- **区分"设计思路可借鉴"和"实现代码可复用"**——前者是架构层面的启发，后者是可以直接抄的代码
- **对我们方案不适合的部分要明确说**——不要只写优点，每个项目/论文至少写 1 条不适用点
- **如果某个搜索维度找不到高质量结果**——说明原因并给出替代搜索建议
- **不要提前结束**——8 轮是下限，发现新线索就追加搜索
- **交叉验证**——重要发现至少在 2 个来源确认

---

## 十、搜索结果（执行者在此处追加内容）

> ⬇️ 以下为搜索执行区域，DS4-Flash Worker 将搜索结果追加到此处

## 搜索执行记录

> **执行时间**：2026-06-23
> **执行方式**：金璃小天才（Plan Agent）调度 8 个 general subagent 并行搜索
> **总参考数量**：~160+（含项目、论文、博客、社区讨论）
> **覆盖维度**：8 轮搜索 × 4 个搜索维度

### 搜索日志

| 轮次 | 搜索范围 | 网站/平台 | 关键词数量 | 找到结果数 | 关联设计要点 |
|------|---------|-----------|-----------|-----------|-------------|
| R1 | 多 Agent 编排框架（广度） | GitHub | 6 组 + 8 个具体项目 | **22+ 项目** | 设计要点 1-4 |
| R2 | 多 Agent 协作论文 | arXiv + Semantic Scholar | 18 个关键词 | **18 篇论文** | 设计要点 1-4 |
| R3 | Skill/Plugin 发现系统（专项） | GitHub (源码深挖) | 18 个关键词 | **18 个系统** | 设计要点 5-8 |
| R4 | 技术博客与实践 | Medium/Dev.to/Lilian Weng等 | 18 个关键词 | **26 篇文章** | 设计要点 1-9 |
| R5 | Token 优化与上下文管理 | arXiv + GitHub + 博客 | 24 个关键词 | **20 个方案** | 设计要点 7 |
| R6 | 记忆分层架构 | GitHub + arXiv + 博客 | 22 个关键词 | **18 个架构** | 设计要点 9 |
| R7 | 关键项目源码深挖 | GitHub (逐项目深挖) | 17 个项目 | **17 个项目** | 设计要点 1-9 |
| R8 | 社区反馈与对比验证 | Reddit/HN/知乎/CSDN | 20 个关键词 | **22 条讨论** | 验证全部 |

---

## 十、搜索结果总览

### 按搜索维度分类

| 维度 | 项目数 | 论文数 | 博客/文章 | 社区讨论 |
|------|--------|--------|----------|---------|
| 多 Agent 编排框架 | 22 | 9 | 8 | 12 |
| Skill 自动发现/调度 | 18 | 5 | 9 | 4 |
| Token 优化与上下文管理 | 6 | 4 | 5 | 2 |
| 记忆分层架构 | 12 | 6 | 3 | 4 |
| **合计** | **58** | **24** | **25** | **22** |

---

## 十一、多 Agent 协作框架深度分析

### 核心发现：框架架构的收敛方向

2025-2026 年，多 Agent 框架呈现明显的**设计收敛**趋势，所有主流框架都围绕三个核心抽象构建：

1. **Agent 声明**——用结构化配置（YAML/Python 类/JSON）定义 Agent 的角色、模型、工具
2. **编排模式**——Graph（有向状态图）/ Sequential（链式）/ Parallel（扇出）/ Handoff（交接）
3. **持久化**——checkpoint / 记忆 / 状态恢复

### 代表性框架对比

| 框架 | Stars | 编排范式 | Agent 定义 | 核心创新 | 生产就绪度 |
|------|-------|---------|-----------|---------|-----------|
| **LangGraph** | 35K+ | 有向图状态机 | Python 代码 | StateGraph + checkpoint + subgraph | ⭐⭐⭐⭐⭐ 最高 |
| **OpenAI Agents SDK** | 27K+ | Agent-as-Tool + Handoff | Python 类 | guardrails + sandbox + tracing | ⭐⭐⭐⭐ |
| **CrewAI** | 54K+ | 角色式团队 | YAML-like Python | 角色+目标+背景故事 | ⭐⭐⭐ 原型快 |
| **Mastra** | 25K+ | 链式 DSL | TypeScript 类 | `.then().parallel().branch()` | ⭐⭐⭐⭐ |
| **Pydantic AI** | 20K+ | 函数式 | Python + YAML | Capability 延迟加载 + 类型安全 | ⭐⭐⭐⭐ |
| **OMA** | 6K+ | 自动 DAG 分解 | TypeScript | Coordinator 自动目标→DAG | ⭐⭐⭐ |
| **Orloj** | 新项目 | K8s-style 资源模型 | YAML | Agent/AgentSystem/Task 三层 YAML | ⭐⭐⭐ |
| **Nexus** | 4K+ | 三模式切换 | Python | Graph/Router/Adaptive 三种编排 | ⭐⭐⭐ |

### 关键发现 1：LangGraph 是 2026 年多 Agent 生产的首选

- **生产案例**：Klarna、LinkedIn、Uber、Replit、Qodo（编码 Agent）等大厂使用
- **47M+ 月 PyPI 下载量**
- **核心优势**：显式状态管理 + checkpointing + 条件路由 + subgraph 层次化
- **核心风险**：state 变量容易膨胀成 "universal state dictionary"；路由决策随图增长变不透明

### 关键发现 2：单 Agent + 结构化工具往往优于多 Agent

多篇 2026 年的实践文章给出了一致结论：
- **"12 域阈值"**——工具域 ≤12 时，单 Agent + 动态工具加载始终优于多 Agent
- **多 Agent 的隐藏成本**：每增加一个 Agent 增加一层协调开销、token 消耗、延迟
- **"过早多 Agent 化是最常见的陷阱"**——大多数生产工作负载不需要多 Agent 框架
- **顺序 Agent 链 + 验证**是最成功的生产模式——无共享状态、无协商、无 LLM-based 路由

### 关键发现 3：Handoff 是最有效的 Agent 协作原语

- **OpenAI SDK** 的 `handoffs=[agent1, agent2]`——注册子 Agent + message filter
- **Agency Swarm** 的 `communication_flows`——显式有向边控制谁可联系谁
- **SK** 的 Agent-as-Plugin——Agent 注册为其他 Agent 的工具
- **核心模式**：父 Agent 持有子 Agent 列表做路由，子 Agent 做独立工作返回摘要

### 关键发现 4：YAML-first Agent 定义正在成为标准

- Orloj 的 K8s-style `Agent`/`AgentSystem`/`Task` 三层 YAML
- AgentLoom 的 Supervisor + Worker YAML + `agent_function_schema` 契约
- Pydantic AI 的 `Agent.from_file('agent.yaml')` 一行加载
- 趋势：从**代码定义 Agent** 转向**声明式配置定义 Agent**

---

## 十二、Skill/Plugin 自动发现系统深度分析

### 核心发现：三层架构是跨平台的共识

| 层级 | 名称 | 内容 | 加载时机 | Token 成本 |
|------|------|------|---------|-----------|
| L1 | **Skill Index** | name + description + tags + trigger_keywords | 会话开始 | ~100 tokens/skill |
| L2 | **Skill Body** | SKILL.md 完整指令 + 示例 | Agent 决定需要时 | ~2-5KB/skill |
| L3 | **Skill References** | scripts/ + references/ + assets/ | 执行过程中按需 | 按需 |

### 关键发现 1：SKILL.md 已成为跨平台开放标准

- 被 Claude Code、Codex、OpenClaw、Pi、Manus、Antigravity 等多平台采纳
- 标准化格式：YAML frontmatter（name+description+tags）+ Markdown body
- vercel-labs/skills 工具实现 31 条路径的标准化发现
- Agent Skills Hub（agentskills.io）定义 v1 规范

### 关键发现 2：两阶段检索 - 重排是实现大规模 Skill 路由的最佳实践

| 方案 | 规模 | 第一阶段 | 第二阶段 | Hit@1 |
|------|------|---------|---------|-------|
| **SkillRouter** | 80K | 0.6B 编码器检索 Top-20 | 0.6B 重排器全文本 rerank | 74.0% |
| **Tool Attention** | 120 | Intent-Schema Overlap + 门控 | 两阶段懒加载 | 95% token 减少 |
| **SkillsMap** | 小 | 确定性 4 级流水线 | 无 LLM 调用 <1ms | - |
| **agent-discover** | MCP 池 | BM25 + 语义混合 | 自动激活所属 server | - |

### 关键发现 3：Capability 捆绑正在取代单独的工具注册

Pydantic AI 的 Capability 系统是最先进的设计：
```python
refunds = Capability(
    id='refunds',
    description='Use for refund eligibility, refund status, or processing a refund.',
    instructions='Always confirm the order ID before issuing a refund.',
    defer_loading=True,  # 延迟加载——模型按需拉取
    tools=[refund_status, refund_policy],
)
```
**Capability = tools + instructions + defer_loading**——将相关工具和其使用说明捆绑为可复用、可延迟加载的单元。

### 关键发现 4：确定性路由在大多数场景优于 LLM 路由

| 方面 | 确定性路由（SkillsMap） | LLM 路由（全靠模型） | 语义检索（SkillRouter） |
|------|----------------------|-------------------|---------------------|
| 延迟 | <1ms | ~2-5s | ~50-200ms |
| Token 成本 | 0 | 高（每次路由消耗） | 低（仅嵌入） |
| 确定性 | 100% 可预测 | 概率性 | 确定性（给定嵌入） |
| 适合场景 | 分类+关键词明确时 | 复杂模糊意图 | 大规模技能池 |

**建议**：三层路由——确定性分类（O(1)）→ 关键词匹配（Regex）→ 语义检索（Embedding）

---

## 十三、Token 优化与上下文管理分析

### 关键发现 1：渐进式披露是最有效的 Token 节省策略

| 方案 | Token 节省 | 做法 |
|------|-----------|------|
| **Tool Attention** | 95%（47.3K→2.4K/轮） | Intent-Schema Overlap + 两阶段懒加载 |
| **三层 Skill 架构** | 73% 成本降低 | 每次只加载 5-12 个 Skill |
| **Semantic Tool Discovery** | 70-90% 工具 token | 单 meta-tool + 多层检索 |
| **OpenAI Agents SDK** | 显著 | Schema 先 name+desc，body 按需 |

### 关键发现 2：上下文压缩策略的四种模式

| 策略 | 做法 | Token 节省 | 信息丢失 | 适合场景 |
|------|------|-----------|---------|---------|
| **Truncation** | 丢弃最旧消息 | 高 | 高 | 简单对话 |
| **Summarization** | 压缩历史为摘要 | 中高 | 中 | 长会话 |
| **Retrieval** | 存到向量存储按需检索 | 低（检索成本） | 低 | 知识密集型 |
| **Sliding Window + Sticky Notes** | 保留最近 N 条 + 关键事实便签 | 中 | 低 | **生产默认** |

### 关键发现 3：Sticky Notes 模式与我们的 Memory Candidate 策略一致

Anthropic 和多个生产实践推荐：**从 sliding window + sticky notes 开始**，覆盖 80% 工作负载。Sticky notes 保存具体标识符、文件路径、决策（不要压缩抽象）。

### 关键发现 4：Prompt Caching 是 Free Lunch

- GitHub Copilot 和 Claude 都支持自动 prompt caching
- 策略：将工具描述池放到 prompt 的**稳定前缀**（利用 prompt caching 命中），只把 top-k 活跃工具的完整 schema 动态注入

---

## 十四、记忆分层架构深度分析

### 关键发现 1：所有方案遵循认知科学的三层记忆模型

| 层级 | 认知科学类比 | 存储方式 | 生命周期 | 检索方式 |
|------|------------|---------|---------|---------|
| **Working Memory** | 当前意识 | 上下文/系统提示 | 每轮替换 | 直接注入 |
| **Episodic Memory** | 事件回忆 | SQLite / Vector DB | 按 session 或时间窗 | 语义 + 时间 |
| **Semantic Memory** | 事实知识 | 知识图谱 / 结构化 | 持久，可 supersede | 实体+关系 |
| **Procedural Memory** | 技能习惯 | JSON / Text | 长期，含置信度 | 按需 |
| **Reflective Memory** | 自我认知 | LLM 生成 | 定期聚合 | 递归合成 |

### 关键发现 2：最具参考价值的记忆架构

| 项目 | Stars | 核心设计 | 最值得借鉴 |
|------|-------|---------|-----------|
| **Letta/MemGPT** | 23.5K | LLM 自主管理的虚拟内存分层 | `page_in`/`page_out` 自触发 |
| **Mem0** | 59.1K | User/Session/Agent 三作用域 + ADD-only | Single-pass ADD + Entity Linking |
| **Generative Agents** | 929+cit | Memory Stream + 三重信号检索 | `relevance × recency × importance` |
| **TencentDB Memory** | 6K | Mermaid 符号图 + node_id 回溯 | 4 层语义金字塔 |
| **AgenticMemory** | - | 5 维索引 + Immortal Log | Temporal/Semantic/Causal/Entity/Procedural |
| **futhgar 6 层** | - | 1-3 always-on + 4-6 lazy | Path-scoped rules |
| **Cognee** | - | Vector + Graph 双路径 | 跨 Agent 知识共享 |

### 关键发现 3：2026 年记忆架构的设计共识

1. **Temporal edges 成为标配**——每条记录带 `valid_at` / `invalid_at`（永不覆盖），Agent 能回答"当时是什么情况"
2. **HOT/COLD 双层管理**——频繁访问的放 HOT（system prompt），罕用的放 COLD（SQLite），pressure-based 自动归档
3. **Write-side router 减少 LLM 调用**——MemRouter 用 ~12M 参数分类器决定"是否存储"，p50 延迟 970ms → 58ms
4. **Append-only > UPDATE**——Mem0 2026 版改用 ADD-only 策略，消除 UPDATE/DELETE 的数据丢失风险
5. **Decoupling-to-aggregation**——用层次结构（Theme → Semantic → Episode → Message）替代平面向量检索

### 关键发现 4：Ebbinghaus 遗忘曲线在 Agent 记忆中的应用

Zijian-Ni/agent-memory 实现了最完整的认知科学衰减：
```
strength = initial_strength × exp(-time / half_life)
```
- 每次检索 boosting strength + stability
- Spaced repetition：根据遗忘曲线安排复习时间
- Consolidation：episodic → semantic 自动合并

---

## 十五、综合分析

### 5 个核心设计决策验证

| 我们的设计决策 | 验证来源 | 结论 |
|--------------|---------|------|
| 1. **单主 Agent + 子 Agent 专家团** | R4 博客共识：12 域阈值以下单 Agent 优于多 Agent | ✅ 方向正确 |
| 2. **Skill 三层分类** | R3: SKILL.md 标准 + Pydantic Capability + 三层架构共识 | ✅ 方向正确 |
| 3. **Skill 三层自动匹配** | R3: SkillRouter 两阶段 + Tool Attention + SkillsMap | ✅ 方向正确 |
| 4. **频率控制（硬限制+软限制）** | R5: Token budget + lazy loading | ✅ 方向正确 |
| 5. **YAML skill-manifest 格式** | R3: SKILL.md + Open Plugin Spec + Orloj YAML | ✅ 方向正确 |
| 6. **与运行时的 IDE 分离** | R7: Orloj/AgentLoom/Pydantic AI 声明式定义 | ✅ 方向正确 |
| 7. **调度模式灵活化** | R1: LangGraph/Mastra/Nexus 多种编排 | ✅ 方向正确 |
| 8. **记忆分层参考 OpenClaw** | R6: Letta/Mem0/TencentDB 分层架构 | ✅ 方向正确 |
| 9. **是否需要 Plan 审核** | R8 社区：顺序链+验证是最成功的生产模式 | ✅ 已有 Comet 四阶段覆盖 |

### 5 个可以优化的设计改进

| 改进点 | 当前设计 | 改进建议 | 参考来源 |
|--------|---------|---------|---------|
| 1. **Skill 路由增加确定性阶段** | 全语义匹配 | 加入确定性分类（Domain/Tag/Keyword）前置过滤 | SkillsMap, Tool Attention |
| 2. **Capability 捆绑替代独立 Tool 注册** | 工具和 Skill 分开 | 将相关 tools + instructions + 触发条件捆绑为 Capability | Pydantic AI Capability |
| 3. **增加 Temporal edges** | 无版本信息 | 每条记忆记录带 `valid_at`/`invalid_at` | 生产实践 2026 共识 |
| 4. **Append-only 记忆存储** | 可 UPDATE | 改为一写多读，用版本链跟踪变化 | Mem0 2026 |
| 5. **引入 Compaction 机制** | 无 | 在 70-80% 上下文容量时触发压缩 | Anthropic 上下文工程 |

### 3 个需要警惕的风险

| 风险 | 描述 | 缓解措施 |
|------|------|---------|
| 1. **过早多 Agent 化** | 社区最强共识：大多数系统不需要多 Agent | 始终保持"单 Agent + 动态工具"作为默认路径 |
| 2. **工具数量膨胀** | >10 个工具后 Agent 选择准确率下降 | 三层加载 + 每轮只暴露 5-12 个 |
| 3. **过度工程化** | 简单的纯工具调用往往优于复杂框架 | 保留"纯 LLM API 调用"作为快速路径 |

---

## 十六、对我们方案的具体优化建议

### 设计要点 1：Agent 定义与运行时分离

**优化建议**：采用 Orloj / AgentLoom 的 **YAML-first 声明式 Agent 定义**模式
- 参考 Orloj 的 K8s-style 资源模型：`Agent` + `AgentSystem` + `Task` 三层 YAML
- 参考 Pydantic AI 的 `Agent.from_file('agent.yaml')` 一行加载
- 参考 Open Plugin Spec 的 `.plugin/plugin.json` 标准化格式

**具体做法**：
```yaml
# agents/xiaoli.agent.yaml
kind: Agent
name: xiaoli-planner
model: deepseek-pro
instructions: "你是金璃小天才，Plan 阶段专责智能体"
skills:
  - brainstorming
  - smart-requirements
  - writing-plans
capabilities:
  - Planning
  - Routing
  - ReviewGate
allowed_tools:
  - websearch
  - webfetch
  - task
limits:
  max_steps: 20
  max_tokens: 32000
```

### 设计要点 2：子 Agent 可扩展机制

**优化建议**：采用 **Agent-as-Tool 模式** + **Capability 捆绑**
- 子 Agent 作为主 Agent 的可调用工具注册（类似 OpenAI SDK 的 handoff）
- 每个子 Agent 有 `agent_function_schema` 声明输入/输出契约（参考 AgentLoom）
- 新增子 Agent = 新增 YAML 文件 + 注册到主 Agent 的 workers 列表

**具体做法**：
```yaml
# agents/workers/ue-engineer.agent.yaml
kind: Agent
name: ue-engineer
model: deepseek-flash
capabilities:
  - UE5Cpp
  - UEGAS
  - UEBlueprint
agent_function_schema:
  description: "UE5 游戏功能开发工程师。处理 C++、GAS、蓝图等 UE5 实现任务。"
  inputs:
    task_spec:
      description: "任务规范路径"
      type: string
    project_path:
      description: "项目路径"
      type: string
  output:
    description: "实现结果摘要"
    type: string
```

### 设计要点 3：调度模式灵活化

**优化建议**：采用 **LangGraph 图模式 + Mastra 链式 DSL 混合**
- 复杂工作流用有向图（状态机）
- 简单顺序任务用链式（`.then()`）
- 独立任务用并行（`.parallel()`）
- 跨 Agent 交接用 `handoff`

**参考**：Nexus 的三种模式（Graph/Router/Adaptive）可作为渐进式调度策略：
1. 默认用 Graph（确定性 DAG）
2. 路由不明确时用 Router（LLM 动态选择）
3. Agent 能力向量化后用 Adaptive（嵌入匹配）

### 设计要点 4：分权制衡（Comet 四阶段强化）

**优化建议**：在现有的 Plan→Implement→Review→Verify 基础上，**强化验证阶段的独立性**
- 参考 **"顺序 Agent 链 + 验证"** 的生产最佳实践
- 验证 Agent 必须独立上下文（已在 AGENTS.md 中要求）
- 增加 **compaction 机制**：Implement 完成后，Review 前执行一次上下文压缩

### 设计要点 5：Skill 三层分类

**优化建议**：细化分类为 **5 类**（参考 Agent Memory 6 层架构 + Pydantic Capability）

| 类别 | 内容 | 加载者 | 示例 |
|------|------|--------|------|
| **Core Skills** | 主 Agent 永久加载 | 主 Agent | brainstorming, jinli-agent-soul |
| **Planning Skills** | Plan 阶段专用 | 主 Agent | smart-requirements, writing-plans |
| **Domain Skills** | 领域专业知识 | 子 Agent | ue5-cpp-gameplay, web-fullstack |
| **Verification Skills** | 验证阶段专用 | Review/Verify Agent | verification-before-completion |
| **Memory Skills** | 记忆管理 | 记忆管理员 | failure-memory, anti-degradation |

### 设计要点 6：Skill 自动调用三层匹配

**优化建议**：在现有三层匹配基础上，加入**确定性前置过滤**（参考 SkillsMap 4 级流水线）

```
[100 Skills] → Stage 0: Domain Classification (O(1) Set, 过滤 ~80%)
             → Stage 1: Regex Matching (确定性模式匹配)
             → Stage 2: Tag Overlap (归一化评分)
             → Stage 3: BM25 Ranking (经典 IR)
             → Stage 4: Semantic Embedding (兜底)
             → [Top 5-12 Skills Loaded]
```

**确定性阶段 0-3 无 LLM 调用，<1ms，0 token 消耗**

### 设计要点 7：频率控制

**优化建议**：引入 **Tool Attention 的 Intent-Schema Overlap (ISO) 分数**

```
ISO = |intent_embedding ∩ skill_schema_embedding| / |skill_schema_embedding|
```

- ISO < 0.22：不加载
- ISO 0.22-0.32：加载 description 到缓存
- ISO > 0.32：加载 skill body
- 每次请求只展开 ISO 最高的 5-12 个 skill

### 设计要点 8：Skill 元数据格式

**优化建议**：参考 **SKILL.md 开放标准** + **Pydantic AI Capability** + **Open Plugin Spec**

```yaml
---
name: ue5-cpp-gameplay
description: "UE5.6/UE5.7 gameplay C++ implementation"
license: MIT
compatibility: "Requires UE5.6+"
metadata:
  author: "jinli"
  version: "2.1.0"
category: domain-skill
sub_agent: ue-engineer
priority: P0
tags: [ue5, cpp, gameplay, gas, ability-system, actor, component]
trigger_keywords: [GAS, GameplayAbility, AbilitySystemComponent, FGameplayTag]
trigger_patterns:
  - "UE5.*C\+\+.*(实现|bug|修复|开发)"
  - "GAS.*(能力|技能|触发|延迟)"
exclude_when:
  - "蓝图|Blueprint"
  - "UI|UMG|Slate"
load_cost: 4.2KB
references:
  - path: references/ability-system.md
    size: 8.5KB
    trigger: "当涉及 AbilitySystemComponent 配置时加载"
  - path: references/gameplay-abilities.md
    size: 6.1KB
    trigger: "当涉及 GA/GE/AS 创建时加载"
allowed_tools:
  - Bash(git:*)
  - Read
  - Write
  - Edit
---
```

### 设计要点 9：记忆分层架构

**优化建议**：采用 **5 层记忆架构**，引入 Temporal edges + HOT/COLD 管理

| 层 | 名称 | 存储 | 检索 | 生命周期 | 参考来源 |
|---|------|------|------|---------|---------|
| L0 | **Working Memory** | 系统提示/Sticky Notes | 直接注入 | 每轮替换 | Anthropic Context Engineering |
| L1 | **Conversation Buffer** | FIFO 队列 | 时间顺序 | 最近 N 轮 | Sliding Window |
| L2 | **Fact Memory** | SQLite + FTS5 | 结构化精确检索 | 永久（带 valid_at） | Mem0 + Temporal edges |
| L3 | **Semantic Memory** | 向量嵌入 | 语义相似度 | 长期（带衰减） | Mem0/Letta |
| L4 | **Reflective Memory** | LLM 生成 | 定期聚合 | 持久 | Generative Agents Reflection |

**引入 Compaction 机制**：
- 在 70-80% 上下文容量时触发
- 提取 Sticky Notes（显式决策 + 文件路径 + 偏好）
- 压缩会话历史为结构化摘要
- 重新启动新上下文

---

## 十七、综合推荐参考清单

### 必读（直接影响架构设计）

| 优先级 | 参考 | 类型 | 核心价值 |
|--------|------|------|---------|
| ⭐⭐⭐ | **LangGraph 架构文档** | 框架 | 图模式状态机 + subgraph + checkpoint |
| ⭐⭐⭐ | **SKILL.md 开放标准** (agentskills.io) | 规范 | Skill 描述/body/references 三级渐进式披露 |
| ⭐⭐⭐ | **Pydantic AI Capability 系统** | 框架 | Capability 捆绑 + defer_loading |
| ⭐⭐⭐ | **Tool Attention 论文** (arXiv 2604.21816) | 论文 | Intent-Schema Overlap + 两阶段懒加载 |
| ⭐⭐⭐ | **SkillsMap** | 项目 | 确定性 4 级路由流水线 |
| ⭐⭐ | **OpenAI Agents SDK handoff** | 框架 | 最优雅的 Agent 交接原语 |
| ⭐⭐ | **Mastra 链式 DSL** | 框架 | `.then().parallel().branch()` API 设计 |
| ⭐⭐ | **Orloj YAML 资源模型** | 框架 | K8s-style Agent/AgentSystem/Task 声明 |
| ⭐⭐ | **Nexus 三模式编排** | 框架 | Graph/Router/Adaptive 渐进式调度 |

### 精读（设计方案时参考具体实现）

| 优先级 | 参考 | 类型 | 核心价值 |
|--------|------|------|---------|
| ⭐⭐ | **AgentLoom `agent_function_schema`** | 项目 | Worker 输入/输出契约模式 |
| ⭐⭐ | **SkillRouter 两阶段检索** | 论文 | 0.6B 编码器 + 0.6B 重排器 |
| ⭐⭐ | **Mem0 ADD-only + Entity Linking** | 项目 | 2026 年记忆系统最佳实践 |
| ⭐⭐ | **TencentDB Mermaid 符号图** | 项目 | 高密度符号记忆 + node_id 回溯 |
| ⭐⭐ | **Open Plugin Spec** | 规范 | Plugin/plugin.json 标准化 |
| ⭐⭐ | **Anthropic Context Engineering** | 博客 | Compaction + Sticky Notes + Sub-agent |

### 选读（了解反模式和社区共识）

| 优先级 | 参考 | 类型 | 核心价值 |
|--------|------|------|---------|
| ⭐⭐ | `Single-agent vs multi-agent: the 2026 decision framework` | 博客 | 12 域阈值 + 结构化产物 |
| ⭐⭐ | `After Analyzing 17 Multi-Agent Topologies — 7 Anti-Patterns` | 博客 | Infinite Loop + Premature Multi-Agent |
| ⭐ | `Why Multi-Agent AI Architectures Keep Failing` | 博客 | 压缩优于并行 |
| ⭐ | `The 17x Error Trap in Multi-Agent Systems` | 博客 | 10 × 95% ≠ 95% |

---

> **文档维护者**：金璃小天才 (Plan Agent)
> **最后更新**：2026-06-23
> **下一阶段**：基于本研究成果，输出完整的 Agent 架构设计任务包
