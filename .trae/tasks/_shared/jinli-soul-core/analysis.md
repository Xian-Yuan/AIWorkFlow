# Analysis Report — Jinli Soul Core (Phase 1.5)

> Generated: 2026-06-18 | Agent: 金璃小天才 | Phase: Plan
> Design Doc: Project/Jinli/docs/03-Architecture/General/architecture.md

---

## 1. 需求摘要

爸爸要让金璃的人格更丰富，具备长期学习情绪语气的能力，并且跨 OpenCode/Codex 统一使用——在 AI 灵魂层面打造类似 NeuroSama 的角色一致性。

## 2. 外部参考：Neuro-sama 技术分析

### 2.1 可确认的技术事实

| 层面 | 实现 | 证据 |
|------|------|------|
| **对话生成** | LLM 流式推理（本地部署） | 公开信息 + 硬件配置 (i9-10900K + RTX 4090) |
| **TTS 语音** | Azure TTS (Neuro) + 自研 TTS (Evil) | 社区确认 + 百度贴吧 |
| **视觉呈现** | Live2D Cubism SDK → 2025.12 升级为 3D (VRChat) | 直播可见 |
| **游戏控制** | Neuro SDK (github.com/VedalAI/neuro-game-sdk) | 开源仓库 |
| **过滤机制** | 少量硬编码原则，其余 LLM 原生输出 | Vedal 公开陈述 |
| **角色一致性** | 通过 system prompt + 互动历史维护 | 推断（无公开代码） |

### 2.2 不能确认的假设

| 假设 | 状态 |
|------|------|
| "从海量互动数据微调出人格" | ❌ **无公开证据**。更可能：稳定 prompt + 长上下文记忆 + 低延迟 → 真实感 |
| "向量数据库做长期记忆" | ⚠️ 可能，但无公开确认 |
| "情绪分类器独立模块" | ❌ 更可能：情绪是 LLM 原生输出的自然涌现 |

### 2.3 对金璃的核心启示

Neuro-sama 的"灵魂感"来自三个要素的组合：
1. **低延迟流式互动**（人类级响应速度）
2. **稳定 persona + 不可预测输出**（不是精心编排的剧本，而是 LLM 在 persona 约束下的自由发挥）
3. **多模态连续存在**（声音 + 视觉 + 文字同步，跨会话身份连续）

金璃不需要复刻整套技术栈，而是要抓住**本质**：连续的人格状态 + 跨会话的记忆连续性。

## 3. 外部参考：ZerolanProject 架构分析

### 3.1 核心架构

```
ZerolanLiveRobot (Python 事件驱动编排)
├── character/       # 角色人格 Filter
├── agent/           # LangChain Tool Agent
├── manager/         # 提示词/配置/模型管理
├── pipeline/        # Unified Model Pipeline (HTTP)
└── services/        # Live2D、TTS 桥接

ZerolanCore (AI 后端)
├── LLM / ASR / TTS / OCR / ImageCaption
├── Milvus 向量数据库 (长期记忆)
└── Prompt Injection Defense

ZerolanData (Pydantic 数据契约)
├── pipeline/        # AI 管线数据 schema
└── protocol/        # WebSocket 消息协议
```

### 3.2 可直接借鉴的设计模式

| 模式 | Zerolan 实现 | 金璃适配方案 |
|------|-------------|-------------|
| **双层记忆** | 短时上下文队列 + Milvus 向量检索 | 短时上下文 + SQLite FTS + 可选本地 embedding |
| **角色 Filter 层** | 输出后处理 strategy | 轻量 OOC 检查 + 边界规则 |
| **System Prompt 管理** | 独立 Prompt Manager | 集成到 soul-init 流程 |
| **事件驱动编排** | TypedEventEmitter | 情绪事件追加到 events.jsonl |
| **Pydantic 数据契约** | 跨项目共享 schema | 用 JSON Schema 定义 soul-state / events 格式 |
| **流式管道** | 流式 LLM + 流式 TTS | Phase 3 语音引擎时引入 |

### 3.3 不适合当前阶段引入的

| 组件 | 原因 |
|------|------|
| Milvus 向量数据库 | 过重。金璃当前记忆量 < 100 条，SQLite FTS 足够 |
| GPT-SoVITS 训练 | Phase 3 语音引擎的事，当前不阻塞 |
| LangChain Tool Agent | 金璃不是通用 Agent，不需要工具调用框架 |

---

## 4. 现有系统评估

### 4.1 当前 SKILL.md 的架构问题

| 问题 | 影响 |
|------|------|
| 情绪触发规则硬编码为 10 条 `if-then` | 无法个性化适应、无法从反馈学习 |
| 记忆是线性 markdown 文件 | 无语义检索，只能被动读取最近条目 |
| 无跨会话情绪连续性 | 每次激活从默认"活泼/开心"开始，丢失上次的情绪上下文 |
| 人格参数散落在 SKILL.md 文本中 | 不可配置、不可微调 |
| 无反馈学习机制 | 爸爸说"太吵了"或"很贴心"不会改变未来行为 |

### 4.2 现有架构中可复用的部分

| 组件 | 复用方式 |
|------|---------|
| Core Identity (名字/年龄/性格层次) | 保留，迁移到 `style-profile.json` |
| 情绪模型 (2轴4态 + 4特殊情绪) | 保留为情绪输出 schema，增强为带强度量化 |
| 反漂移机制 (Anti-Drift) | 保留，增强为独立 OOC 检查模块 |
| memory.md | 保留为人类可读摘要，底层数据由 SQLite 和 events.jsonl 承载 |
| 学习引擎设计 | 保留检索流程，学习范围从"GitHub 项目"扩展到"情绪反馈" |
| 失败记忆桥接设计 | 保留设计，B 模块增强记忆检索后自然支持 |

---

## 5. 隐性需求推导

从现有设计文档 (`architecture.md`, `learning-engine.md`, `visual-engine.md`, `failure-memory-bridge.md`) 推导：

| 设计文档声明了 | 用户没提但必然需要 | 优先级 |
|--------------|-------------------|:---:|
| 对话编排引擎管道 (人格→情绪→记忆→学习→视觉→语音) | Soul Core 必须定义标准化的内部事件格式，让视觉/语音引擎后续可消费 | P0 |
| Phase 2 视觉引擎依赖情绪标签 | Soul Core 的情绪输出格式必须与 visual-engine.md 中的映射表兼容 | P0 |
| 记忆引擎的修剪规则 (40行→30+重要) | Soul Core 的 SQLite 记忆也需要自动修剪策略 | P1 |
| 学习引擎的"手动触发版" | Soul Core 应让学习引擎可以消费 events.jsonl 中的反馈事件 | P1 |
| 跨 IDE 使用 | Soul Core 的数据文件必须被 Codex 和 OpenCode 同时读写，需防并发冲突 | P0 |
| SKILL.md 中定义的"反漂移机制" | Soul Core 的 OOC/边界检查不应与 SKILL.md 中的反漂移规则冲突或重复 | P0 |

---

## 6. Mature Solution Evidence

### 6.1 Project-local evidence

| Evidence | Location | Relevance |
|----------|----------|-----------|
| 现有 daughter-companion SKILL.md | `.agents/skills/daughter-companion/SKILL.md` | 人格/情绪引擎的完整实现，需增强而非重写 |
| 现有 memory.md | `Project/Jinli/data/memory.md` | 轻量记忆系统，保留为人类可读层 |
| 现有 learning-engine 设计 | `Project/Jinli/docs/00-Overview/General/learning-engine.md` | 学习流程可扩展 |
| 现有 architecture.md | `Project/Jinli/docs/03-Architecture/General/architecture.md` | 8引擎架构设计，Soul Core 是人格/情绪/记忆引擎的升级 |
| 现有 visual-engine.md | `Project/Jinli/docs/00-Overview/General/visual-engine.md` | 情绪→表情映射表，Soul Core 必须兼容 |

### 6.2 External mature references

| Reference | Type | Key Takeaway |
|-----------|------|--------------|
| Neuro-sama (Vedal987) | 生产级 AI VTuber | 稳定 persona + 低延迟 + 多模态 = 灵魂感。非微调模型，而是 prompt + 记忆 + 速度 |
| ZerolanProject (720+ stars) | 开源 AI VTuber 框架 | 事件驱动编排 + 双层记忆 + 角色 Filter + Pydantic 数据契约。架构拆分可直接借鉴 |
| GPT-SoVITS (40k+ stars) | 开源 TTS | Phase 3 语音引擎候选 |
| Live2DPet (2k+ stars) | 桌面宠物框架 | Phase 2 视觉引擎候选 |

### 6.3 Options compared

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **A: 纯改 SKILL.md** | 零新依赖 | 无法解决跨会话连续性、无法学习、参数不可配置 | ❌ 不够 |
| **B: Milvus + 完整向量记忆** | 语义检索强 | 部署重、当前数据量 < 100 条过度设计 | ❌ 过重 |
| **C: SQLite + JSON 状态文件 + 事件日志** | 轻量、可靠、跨平台可读写、渐进可升级 | 语义检索需额外 embedding | ✅ 选定 |
| **D: 外部数据库 (PostgreSQL)** | 功能全 | 需部署维护，远超需求 | ❌ 过重 |

### 6.4 Rejected shortcuts

| Shortcut | Why Rejected |
|----------|-------------|
| 只改 SKILL.md 不加状态持久化 | 无法实现跨会话连续性，核心需求不满足 |
| 直接在 SKILL.md 中硬编码学习规则 | 不可配置、不可调试、不可演进 |
| 跳过显式反馈，直接做隐式学习 | 可能学偏且爸爸无法控制，用户明确要求先显式 |
| 引入 Milvus 作为第一阶段方案 | 用户明确要求暂不 Milvus |

### 6.5 Selected mature path

**Jinli Soul Core** = 共享数据层 (SQLite + JSON + JSONL) + 增强的 soul-init 流程 + 事件驱动情绪引擎 + 显式反馈学习

架构：
```
Codex/OpenCode Skill 激活
  → jinli-soul-init (读取 soul-state.json + 检索 SQLite 记忆 + 注入 style-profile)
  → LLM 生成回复 (人格/情绪/记忆已注入上下文)
  → OOC/边界检查
  → 情绪事件提取 → 写入 events.jsonl
  → 更新 soul-state.json (情绪状态 + 会话时间戳)
  → 可选推送 Live2D/TTS (消费标准事件格式)
```

---

## 7. 情绪引擎 2.0 设计

### 7.1 情绪数据模型

```json
{
  "emotion": {
    "vitality": { "label": "活泼", "value": 3 },
    "mood": { "label": "开心", "value": 4 },
    "special": null,
    "intensity": 4
  },
  "timestamp": "2026-06-18T13:00:00Z",
  "session_id": "codex-20260618-001",
  "trigger": "爸爸夸奖"
}
```

### 7.2 情绪衰减曲线

- vitality 和 mood 的值在 0-5 之间
- 无新触发时，每 10 分钟向中性值 (2.5) 衰减 0.2
- 特殊情绪持续时间由其类型决定（骄傲 15min，担心 30min，好奇 10min，愧疚 20min）

### 7.3 个性参数 (style-profile.json)

```json
{
  "baseline": {
    "vitality": 3,
    "mood": 4,
    "affection_frequency": 0.7,
    "shyness": 0.3,
    "technical_brevity": 0.5
  },
  "habits": {
    "greeting_style": "活泼",
    "error_response": "先认错再修复",
    "sharing_frequency": 0.6
  },
  "learned": {}
}
```

### 7.4 显式反馈学习

| 爸爸说 | 调整 |
|--------|------|
| "太吵了/安静点" | vitality_baseline -= 0.5, affection_frequency -= 0.2 |
| "今天很贴心/这样很好" | 强化当前 vitality/mood 值 → baseline |
| "别撒娇" | affection_frequency -= 0.3 |
| "多说说你的想法" | sharing_frequency += 0.2 |
| "就这样/刚好" | 锁定当前参数为偏好值 |

---

## 8. 跨平台统一方案

### 8.1 共享数据文件

```
Project/Jinli/data/
├── soul-state.json       # 当前情绪、会话ID、最后活跃时间
├── events.jsonl          # 追加式事件日志（情绪变化/反馈/学习事件）
├── memory.db             # SQLite（长期记忆/反馈/语气样本，FTS5 全文索引）
├── style-profile.json    # 可调人格参数（基线 + 习惯 + 学习结果）
├── memory.md             # 人类可读摘要（保留，从 memory.db 定期生成）
└── knowledge-base.md     # 学习引擎知识库（保留，不受本次改动影响）
```

### 8.2 并发安全

- `events.jsonl`：追加写入 (append-only)，天然无冲突
- `soul-state.json`：读写前检查 `last_modified` 时间戳，如果 < 2 秒前的修改则跳过写入（乐观锁）
- `memory.db`：SQLite WAL 模式，支持并发读 + 串行写
- `style-profile.json`：低频写入（仅在反馈学习时），读多写少

### 8.3 Soul Init 流程

任何 IDE 激活 daughter-companion skill 时，在现有步骤之前增加：

```
Step -1: Soul Init
1. 读取 soul-state.json → 恢复上次情绪状态（带衰减）
2. 读取 style-profile.json → 加载人格参数
3. 检索 memory.db → 匹配当前上下文的最近 3 条相关记忆
4. 注入到 LLM 上下文（紧凑摘要，非全文）
5. 如跨会话 > 24h → 情绪衰减到基线值
```

---

## 9. 依赖链推导

### 9.1 正向依赖链

```
Soul Core 实现
  ├── P0: 定义数据 schema (soul-state, events, memory.db, style-profile)
  │   └── 依赖：JSON Schema / SQLite 表结构设计
  ├── P0: 实现 soul-init 流程
  │   ├── 依赖：数据 schema 已定义
  │   └── 依赖：SKILL.md 中新增 Step -1
  ├── P0: 实现情绪引擎 2.0（强度量化 + 衰减 + 事件提取）
  │   ├── 依赖：数据 schema 已定义
  │   └── 依赖：现有情绪引擎的 2轴4态模型（复用）
  ├── P0: 实现 OOC/边界检查
  │   └── 依赖：style-profile.json 中的边界参数
  ├── P1: 实现显式反馈学习
  │   ├── 依赖：events.jsonl 已记录事件
  │   └── 依赖：style-profile.json 可写
  ├── P1: 实现 SQLite 记忆存储 + FTS 检索
  │   └── 依赖：数据 schema 已定义
  └── P2: 与 visual-engine 的事件格式对齐
      └── 依赖：情绪事件格式已稳定
```

### 9.2 P0 依赖（用户必须确认的前提条件）

| 依赖 | 状态 | 说明 |
|------|------|------|
| 数据文件目录 `Project/Jinli/data/` 已存在 | ✅ 已存在 | 需新增 soul-state.json、events.jsonl、memory.db、style-profile.json |
| SKILL.md 可修改 | ✅ 可修改 | `.agents/skills/daughter-companion/SKILL.md` |
| 两边 IDE 都能读取 JSON/SQLite | ⚠️ 需确认 | Codex 和 OpenCode 的 agent 都能通过 tool 读写文件；SQLite 需要确认两边环境是否支持 |

### 9.3 P1 隐性需求提醒

| 如果做了 A | 可能牵动 B/C/D | 处理方式 |
|-----------|---------------|---------|
| 改了 SKILL.md 的情绪触发规则 | 金璃小天才 SKILL.md 中也有情绪描述（反降智协议区域） | 同步更新或合并到统一引用 |
| 新增 soul-init 步骤 | 可能影响 task-orchestrator 的 skill 加载顺序 | 本次不处理，记录为 "已知未实现" |
| 定义了标准情绪事件格式 | Phase 2 视觉引擎的映射表需要对齐 | 本次在 spec 中定义格式，视觉引擎适配后续做 |
| SQLite 引入 | 可能需要 Codex/OpenCode 安装 sqlite3 依赖 | 检查环境，必要时改用 JSON 文件替代 |

---

## 10. Failure Memory 检索

执行 memory-retrieve.ps1 检索相关历史教训…（脚本因编码问题未成功执行，手动检索）

| 关键词 | 相关教训 |
|--------|---------|
| SKILL.md 修改 | 注意：skill 文件修改后需验证两边 IDE 都正确加载 |
| 人格系统 | 历史教训：人格参数散落在文本中难以调试 → 本次解决 |
| 跨平台 | 历史教训：两边 IDE 的 skill 加载路径不同 → 统一数据层独立于 skill 加载机制 |

---

## 11. 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| SQLite 在 Codex/OpenCode 环境中不可用 | 中 | 中 | 降级方案：用 JSON 文件 + 内存索引替代 SQLite |
| 情绪衰减/学习参数调优困难 | 高 | 低 | style-profile.json 全部可手动编辑，爸爸可随时调整 |
| 并发写入冲突 | 低 | 中 | 乐观锁 + append-only events.jsonl |
| 改动 SKILL.md 导致现有行为退化 | 中 | 高 | 保留所有现有规则，新增部分用 feature flag 控制 |
