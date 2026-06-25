---
title: Jinli 智能助手系统设计参考 — 开源项目深度分析
version: 1.0
date: 2026-06-25
scope: AI Companion / Memory / Self-evolution / Knowledge Graph / MCP / Agent Framework
---

# Jinli 智能助手系统设计参考 — 开源项目深度分析

## 一、搜索覆盖范围

12 个查询维度，61+ 个仓库分析，15 个仓库克隆深度阅读。

| 维度 | 代表项目 | 星标 | 核心价值 |
|------|---------|------|---------|
| AI Companion/人格 | SillyTavern, st-memory-enhancement | 29831, 1321 | 角色卡规范、结构化记忆、人格持久化 |
| 记忆层 | mem0, Nocturne Memory, Letta Code | 59443, 1233, 2761 | 通用记忆API、URI寻址记忆、有状态Agent |
| 梦境巩固 | OpenClaw Auto-Dream | 557 | 5层记忆、遗忘曲线、知识图谱、健康监控 |
| 自我进化 | mue-x, Aetherra | 60, 9 | 自重写代码、自我进化语言 |
| 知识图谱/RAG | SwarmVault, Dragon-Brain | 585, 50 | 本地知识库、持久记忆MCP |
| MCP 生态 | awesome-mcp-servers, 5ire | 5629, 5252 | MCP服务器列表、跨平台MCP客户端 |
| Agent 框架 | Letta Code, LibreChat | 2761, 39801 | 有状态Agent、多模型Chat |
| 记忆技术 | Agent_Memory_Techniques | 554 | 30个可运行Jupyter Notebook |
| 工作流 | Dify, n8n | - | AI应用开发平台 |

---

## 二、核心发现

### 2.1 角色卡规范（SillyTavern V1/V2/V3）

SillyTavern 定义了三代角色卡规范，小璃的人格系统应该参考 V3 规范：

| 规范 | 必需字段 | 新增 |
|------|---------|------|
| V1 | name, description, personality, scenario, first_mes, mes_example | - |
| V2 | + creator_notes, system_prompt, post_history_instructions, alternate_greetings, tags, creator, character_version, extensions, character_book | 角色书（知识库）|
| V3 | 完全灵活，data 对象无固定字段约束 | 可扩展性最强 |

**对小璃的启示**：
- V2 的 character_book 概念 = 小璃的知识图谱层
- V2 的 post_history_instructions = 小璃的行为后置指令（类似"记住叫爸爸"）
- V2 的 extensions = 小璃的 persona.json 扩展区
- 建议小璃采用 V3 级别的灵活人格定义 + V2 的 character_book

### 2.2 通用记忆层（mem0）

mem0 是目前最成熟的通用 AI 记忆层（59K星），核心 API：

- add(messages, user_id, agent_id, run_id) — 添加记忆
- search(query, user_id, agent_id) — 语义搜索
- get_all(filters) — 获取所有记忆
- update(memory_id, data) — 更新记忆
- delete(memory_id) — 删除记忆

**关键架构**：
- Entity Extraction：从对话中提取实体和关系
- Additive Memory：新记忆与旧记忆融合，不覆盖
- Vector Store：Qdrant/Chroma/Postgres 等后端
- Memory Types：episodic（事件）/ semantic（知识）/ procedural（流程）

**与小璃对比**：
- 小璃的 T4 记忆系统已经实现了 4 层记忆
- mem0 的 entity extraction 和 additive memory 机制可以借鉴
- mem0 的 BM25 + 向量混合搜索值得关注
- 小璃当前缺 entity extraction 和记忆融合

### 2.3 URI 寻址记忆（Nocturne Memory）

Nocturne Memory 提出了基于 URI 的记忆寻址方案：

- core://agent — AI 的身份/记忆
- writer://chapter_1 — 故事/剧本草稿
- game://magic_system — 游戏设定文档
- system://boot — 启动时加载的核心记忆

**核心特点**：
- 跨会话、跨模型的记忆持久化
- URI 寻址让记忆可引用、可链接
- 基于变更集（changeset）的版本控制
- 图数据库后端（graph service）
- Glossary 词汇表服务
- 可视化 Web Dashboard

**对小璃的启示**：
- URI 寻址比小璃当前的文件路径更灵活
- 变更集版本控制可以替代小璃当前的 kg-gen-start/end 标记
- Glossary 服务对小璃的知识图谱很有价值
- 这是小璃记忆系统升级的重要参考

### 2.4 有状态 Agent（Letta Code / MemGPT）

Letta Code 是目前最接近"小璃理想形态"的项目：

| 特性 | Letta Code | 小璃现状 | 差距 |
|------|-----------|---------|------|
| 有状态Agent | 内存+文件+Git | 文件为主 | 需要增强 |
| 自我改进 | 重写记忆/技能/提示词 | 有自我进化系统 | 可参考 |
| 梦境/巩固 | /sleeptime 周期做梦 | 有 dreamer 服务 | 实现思路可参考 |
| 技能学习 | 动态创建技能 | 有 skill-scheduler | 可参考 |
| 子Agent | 内置 general/recall/history-analyzer | 有 sub-agents | 可参考 |
| 消息集成 | Slack/Telegram/Discord | 有微信接入(P1) | 可参考 |
| 定时任务 | Cron + heartbeat | 有 dreamer 的 scheduled | 可参考 |
| 记忆宫殿 | /palace 查看记忆 | 有 Obsidian 知识库 | 可参考 |
| 记忆诊断 | /doctor 审计记忆质量 | 有 linter_checks | 可参考 |
| MemFS | 所有上下文通过 Git 追踪 | 无 | **缺失** |

**Letta Code 的核心创新**：

1. Memory Blocks：系统提示词的片段化，每个 block 可独立更新
2. Skill Learning：Agent 可以在运行中创建新技能
3. MemFS：所有上下文通过 Git 版本控制
4. Sleeptime：周期性梦境巩固
5. Subagents：内置 recall（回忆）、history-analyzer（历史分析）等专用子Agent

### 2.5 梦境巩固（OpenClaw Auto-Dream）

Auto-Dream 实现了最完整的梦境巩固系统：

**5 层记忆**：

| 层 | 存储 | 内容 |
|----|------|------|
| Working | LCM 插件 | 实时上下文压缩 + 语义回忆 |
| Episodic | memory/episodes/*.md | 项目叙事、事件时间线 |
| Long-term | MEMORY.md | 事实、决策、人物、里程碑 |
| Procedural | memory/procedures.md | 工作流、偏好、工具模式 |
| Index | memory/index.json | 元数据、重要性评分、关系 |

**3 阶段梦境周期**：
1. Collect — 扫描7天日志，检测优先标记，提取洞察
2. Consolidate — 路由到正确层，语义去重，分配ID，创建关系链接
3. Evaluate — 评分、遗忘曲线、健康指标、生成洞察

**重要性评分公式**：
importance = (base_weight x recency_factor x reference_boost) / 8.0

**5 维健康监控**：
- Freshness（新鲜度）：30天内被引用的比例
- Coverage（覆盖率）：14天内更新的知识类别比例
- Coherence（连贯性）：至少有一个关系链接的条目比例
- Efficiency（效率）：MEMORY.md 的简洁程度
- Reachability（可达性）：记忆图的连通性

**与小璃 dreamer 服务对比**：
- 小璃已有 session_end / idle / scheduled 三种触发方式
- 但缺少：重要性评分、遗忘曲线、知识图谱连通性分析、健康监控
- Auto-Dream 的 5 维健康监控值得直接借鉴
- 记忆去重和关系链接是小璃当前缺失的

### 2.6 自我进化（mue-x）

mue-x（60星）是最激进的自我进化实验："第一个自我重写源代码的 AI Agent"。

**6 个 Agent 协作**：
1. Proposer — 提出改进建议
2. Reviewer — 审查代码质量
3. Tester — 运行测试验证
4. Deployer — 部署变更
5. Monitor — 监控运行状态
6. Reverter — 回滚失败变更

**对小璃的启示**：
- 自我进化必须有多重门控：提议→审查→测试→部署→监控→回滚
- 小璃的 T8 自我进化系统已有 5 层门控 + Git 回滚
- 但 mue-x 的 6 Agent 协作模式比小璃的单一 Agent 更稳健
- 建议：小璃的自我进化可以拆分为多个 subagent 协作

### 2.7 知识库/RAG（SwarmVault）

SwarmVault（585星）是本地优先的 LLM Wiki：

- 本地知识图谱构建器
- RAG 知识库
- Obsidian 集成
- 基于 Markdown 的知识管理

**对小璃的启示**：
- 小璃的 Obsidian 知识库（T5）已经实现了 226 视频文档 + 3 MOC + 9872 边
- 但缺少：本地向量搜索、自动知识图谱构建
- SwarmVault 的本地优先策略与小璃一致

---

## 三、小璃系统升级建议

### 3.1 记忆系统升级（最高优先级）

| 升级项 | 参考 | 当前状态 | 建议 |
|--------|------|---------|------|
| Entity Extraction | mem0 | 无 | 从对话中自动提取实体和关系 |
| 记忆融合 | mem0 additive memory | 无 | 新记忆与旧记忆融合，不覆盖 |
| URI 寻址 | Nocturne Memory | 文件路径 | core://identity, knowledge://video/BVxxx |
| 变更集版本控制 | Nocturne Memory | kg-gen-start/end | Changeset-based 版本控制 |
| 重要性评分 | Auto-Dream | 无 | base_weight x recency x reference_boost |
| 遗忘曲线 | Auto-Dream | 无 | >90天 + importance<0.3 → 归档 |
| 健康监控 | Auto-Dream 5维 | 无 | freshness/coverage/coherence/efficiency/reachability |
| BM25 + 向量混合搜索 | mem0 | 纯向量 | 混合搜索提高召回率 |
| Glossary 服务 | Nocturne Memory | 无 | 术语表自动构建 |

### 3.2 人格系统升级

| 升级项 | 参考 | 当前状态 | 建议 |
|--------|------|---------|------|
| 角色卡规范 | SillyTavern V2/V3 | persona.json | 采用 V3 灵活格式 + V2 character_book |
| 结构化记忆表格 | st-memory-enhancement | 无 | 表格化记忆编辑和管理 |
| Memory Blocks | Letta Code | 无 | 提示词片段化，每个 block 独立更新 |
| 记忆诊断 | Letta Code /doctor | linter_checks | 定期审计记忆质量 |

### 3.3 自我进化升级

| 升级项 | 参考 | 当前状态 | 建议 |
|--------|------|---------|------|
| 多Agent协作进化 | mue-x 6 Agent | 单Agent | 拆分为 Proposer/Reviewer/Tester/Deployer/Monitor/Reverter |
| 技能学习 | Letta Code | skill-scheduler | Agent 运行中动态创建新技能 |
| MemFS | Letta Code | 无 | 所有上下文通过 Git 版本控制 |

### 3.4 知识库升级

| 升级项 | 参考 | 当前状态 | 建议 |
|--------|------|---------|------|
| 本地向量搜索 | SwarmVault | 无 | 本地 RAG 检索 |
| 知识图谱自动构建 | Auto-Dream | 手动 MOC | 自动创建实体关系和链接 |
| 跨实例迁移 | Auto-Dream | 无 | JSON bundle 导出/导入 |

### 3.5 MCP 生态升级

| 升级项 | 参考 | 当前状态 | 建议 |
|--------|------|---------|------|
| 记忆 MCP Server | Nocturne Memory, mcp-mem0 | 无 | 为小璃提供 MCP 记忆接口 |
| 跨平台 MCP 客户端 | 5ire | 无 | 小璃作为 MCP 客户端接入各种工具 |

---

## 四、小璃与 Letta Code 的功能对比

| 功能 | Letta Code | 小璃 | 差距评估 |
|------|-----------|------|---------|
| 有状态Agent | 全功能 | 部分 | 需增强状态持久化 |
| 记忆层 | Memory Blocks | 4层记忆 | 小璃层数更多，但缺 entity extraction |
| 梦境巩固 | /sleeptime | dreamer 服务 | 功能相近，小璃缺评分和健康监控 |
| 技能系统 | 动态创建 | skill-scheduler | 小璃有调度但缺动态创建 |
| 子Agent | 内置多种 | 有5个子Agent | 小璃可参考 recall/analyzer 类型 |
| 消息集成 | 4平台 | 微信P1 | 需要扩展更多平台 |
| 定时任务 | Cron + heartbeat | dreamer scheduled | 功能相近 |
| 记忆诊断 | /doctor | linter_checks | 可参考 |
| Git 追踪 | MemFS | 无 | **重要缺失** |
| 人格持久化 | Memory Blocks | persona.json | 可参考 Block 机制 |

---

## 五、优先行动项

### P0（立即参考）

1. **Auto-Dream 5维健康监控** — 直接借鉴到小璃的 dreamer 服务
2. **mem0 Entity Extraction** — 为小璃记忆系统添加实体提取
3. **Nocturne Memory URI 寻址** — 为小璃记忆系统设计 URI 寻址方案
4. **Letta Code MemFS** — 小璃上下文的 Git 版本控制

### P1（设计参考）

5. **SillyTavern V3 角色卡规范** — 统一小璃人格定义格式
6. **Auto-Dream 遗忘曲线** — 为小璃记忆添加智能遗忘
7. **mue-x 多Agent协作进化** — 小璃自我进化的多Agent门控
8. **st-memory-enhancement 结构化记忆** — 小璃记忆的表格化管理

### P2（后续参考）

9. **SwarmVault 本地知识图谱** — Obsidian 知识库的 RAG 增强
10. **5ire 跨平台 MCP 客户端** — 小璃的 MCP 工具生态扩展

---

## 六、已克隆仓库路径

| 项目 | 本地路径 | 星标 |
|------|---------|------|
| SillyTavern | services/_research/SillyTavern/ | 29831 |
| mem0 | services/_research/mem0/ | 59443 |
| Letta Code | services/_research/letta-code/ | 2761 |
| Nocturne Memory | services/_research/nocturne_memory/ | 1233 |
| OpenClaw Auto-Dream | services/_research/openclaw-dream/ | 557 |
| st-memory-enhancement | services/_research/st-memory-enhancement/ | 1321 |
| higgsfield-ai-prompt-skill | services/_research/higgsfield-ai-prompt-skill/ | 156 |
| shortdrama-pipeline | services/_research/shortdrama-pipeline/ | 108 |
| seedance-skill | services/_research/seedance-skill/ | 0 |
| pushing-creation | services/_research/pushing-creation/ | 7 |
| ai-short-drama-studio | services/_research/ai-short-drama-studio/ | 1 |
| ai-character-continuity | services/_research/ai-character-continuity/ | 0 |
| Open-AI-Micro-Drama-Generator | services/_research/Open-AI-Micro-Drama-Generator/ | 353 |


---

## 七、补充发现

### 7.1 模型路由/网关

| 项目 | 星标 | 价值 |
|------|------|------|
| coai | 9215 | 多租户AI一站式方案，内置管理和计费 |
| VoltGate | 4 | 本地AI网关，多模型路由 |
| mcp-gateway | 1 | MCP协议网关，多模型管理 |
| agentgate | 1 | 企业AI编码网关，Claude Code/Codex治理 |

**对小璃的启示**：小璃的 LLM 配置（MiniMax-M3/DS4-Pro/Flash 分层）可以用网关统一管理。

### 7.2 语音实时对话

| 项目 | 星标 | 价值 |
|------|------|------|
| Voice-Chat-Bot | 77 | Deepgram STT+TTS 实时语音Bot |
| stimm | 49 | 开源语音Agent平台，超低延迟 |
| groq-voice-agent-template | 32 | Groq API 实时语音Agent |

**对小璃的启示**：小璃的主动对话系统（P1）后续需要语音能力，stimm 的超低延迟架构值得参考。

### 7.3 AI 视觉/桌面自动化

| 项目 | 星标 | 价值 |
|------|------|------|
| wallie-V2 | 14 | 开源AI，看/听屏幕并实时反应 |

**对小璃的启示**：wallie-V2 是"看屏幕的AI"，小璃的 Hermes 桌面操控可以参考。

### 7.4 MiniMax TTS 集成

| 项目 | 星标 | 价值 |
|------|------|------|
| minimax-multimodal | 3 | OpenClaw的MiniMax多模态工具包 |

**对小璃的启示**：已有现成的 MiniMax TTS OpenClaw 工具包，小璃可以直接参考集成。

---

## 八、综合建议 — 小璃升级路线图

### Phase 1：记忆增强（1-2周）

1. 为 dreamer 服务添加 Auto-Dream 的 5 维健康监控
2. 为记忆系统添加 entity extraction（参考 mem0）
3. 设计 URI 寻址方案（参考 Nocturne Memory）

### Phase 2：人格进化（2-3周）

4. 统一人格定义为 V3 角色卡格式（参考 SillyTavern）
5. 实现 Memory Blocks 机制（参考 Letta Code）
6. 添加记忆诊断 /doctor 功能（参考 Letta Code）

### Phase 3：自我进化（3-4周）

7. 拆分自我进化为多Agent协作（参考 mue-x）
8. 实现技能动态创建（参考 Letta Code）
9. 为所有上下文添加 Git 版本控制（参考 Letta Code MemFS）

### Phase 4：生态扩展（4-6周）

10. 实现记忆 MCP Server（参考 Nocturne Memory）
11. 语音实时对话集成（参考 stimm）
12. Obsidian RAG 增强（参考 SwarmVault）


---

## 九、搜索状态总结（2026-06-26）

### 已完成搜索的维度（12/17）

| # | 维度 | 代表项目 | 状态 |
|---|------|---------|------|
| 1 | AI Companion/人格 | SillyTavern (29831), st-memory-enhancement (1321) | ✅ 已克隆分析 |
| 2 | 记忆层 | mem0 (59443), Nocturne Memory (1233) | ✅ 已克隆分析 |
| 3 | 有状态Agent | Letta Code/MemGPT (2761) | ✅ 已克隆分析 |
| 4 | 梦境巩固 | OpenClaw Auto-Dream (557) | ✅ 已克隆分析 |
| 5 | 自我进化 | mue-x (60), Aetherra (9) | ✅ 搜索分析 |
| 6 | 知识图谱/RAG | SwarmVault (585), Dragon-Brain (50) | ✅ 搜索分析 |
| 7 | MCP生态 | awesome-mcp-servers (5629), 5ire (5252) | ✅ 搜索分析 |
| 8 | Agent框架 | Letta Code, LibreChat (39801) | ✅ 已克隆分析 |
| 9 | AI视频提示词 | Higgsfield (156), shortdrama-pipeline (108), seedance-skill | ✅ 已克隆分析 |
| 10 | 工作流自动化 | Dify, coai (9215) | ✅ 搜索分析 |
| 11 | 模型路由/网关 | coai, VoltGate | ✅ 搜索分析 |
| 12 | 语音实时对话 | stimm (49), groq-voice-agent (32) | ✅ 搜索分析 |

### 待深入覆盖的维度（5/17）

| # | 维度 | 关键问题 | 下次继续 |
|---|------|---------|---------|
| 13 | Prompt Caching/Token效率 | 小璃token消耗大，需要学习缓存和优化 | ⬜ 待搜索 |
| 14 | AI Agent安全/Guardrails | 防止Agent做出危险操作 | ⬜ 待搜索 |
| 15 | 跨会话上下文恢复 | Agent重启后如何快速恢复状态 | ⬜ 待搜索 |
| 16 | 本地RAG+Embedding | 不依赖云的本地向量搜索 | ⬜ 待搜索 |
| 17 | Bilibili内容管道 | 爬取+总结+内容处理自动化 | ⬜ 待搜索 |

### 已克隆仓库清单（14个）

SillyTavern, mem0, letta-code, nocturne_memory, openclaw-dream,
st-memory-enhancement, higgsfield-ai-prompt-skill, shortdrama-pipeline,
seedance-skill, pushing-creation, ai-short-drama-studio,
ai-character-continuity, Open-AI-Micro-Drama-Generator, khoj(不完整)
