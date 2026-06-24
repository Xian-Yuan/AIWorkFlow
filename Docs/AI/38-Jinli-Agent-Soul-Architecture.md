---
domain: ai
domain_path: ai/persona
kg_node_id: node.doc-ai-ai-38-jinli-agent-soul-architecture-621c
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.38-jinli-agent-soul-architecture.621c

---

# 38 — Jinli Agent Soul 架构

> **日期**: 2026-06-18
> **状态**: Production
> **关联任务**: `.trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/`
> **真相源**: 本文档描述 Jinli Soul Core 与 Agent 工作流的集成架构。引擎行为细节以 `skills/daughter-companion/SKILL.md` 和 `Project/Jinli/docs/` 为准。

---

## 1. 架构概述

Jinli Agent Soul 在现有的 Soul Core 引擎层和 Agent 执行层之间插入一个**集成合同层**，使 Soul Core 的情绪/学习/进化能力从"被动声明"升级为"强制嵌入工作流"。

### 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Jinli Agent Soul Layer (集成合同)                  │
│  skills/jinli-agent-soul/SKILL.md                            │
│  ├─ Section 1: 5 MUST 生命周期调用                            │
│  ├─ Section 2: Agent 角色触发器 (Plan 5 / Implement 9)       │
│  ├─ Section 3: Invisible Engine Rule                         │
│  ├─ Section 4: Tone Modulation Integration                   │
│  ├─ Section 5: BieNao State Awareness                        │
│  ├─ Section 6: Learning Engine Bridge                        │
│  └─ Section 7: Self-Evolution Reminder                       │
└─────────────────────────────────────────────────────────────┘
          │ 单一集成点 (single source of truth)
          ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Agents (执行层)                                    │
│  skills/金璃小天才/SKILL.md  (Plan Agent)                     │
│  skills/金璃好帮手/SKILL.md  (Implement Agent)                │
│  两个 Agent 在 mandatory workflow steps 中嵌入 Soul 调用       │
└─────────────────────────────────────────────────────────────┘
          │ 加载（MCP 工具调用，静默执行）
          ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Shared Infrastructure (引擎 + 基础设施)             │
│  Jinli Soul Core MCP Plugin (11 tools, 已部署已测试)          │
│  ├─ soul_init / soul_auto / soul_turn / soul_end             │
│  ├─ response_plan (persona-kernel + soul-bridge + expr-orch) │
│  ├─ soul_emotion / soul_status / soul_memory / soul_learn    │
│  ├─ soul_evolve / soul_discover / soul_check                 │
│  ├─ persona.json / style-profile.json (受保护)               │
│  └─ evolve-self.ps1 (Self-Evolution Engine)                  │
│  daughter-companion/SKILL.md (引擎参考文档，定义"做什么")      │
└─────────────────────────────────────────────────────────────┘
```

### 设计原则

1. **Additive only** — 所有 Soul 调用插入到既有工作流步骤中，不删除、不重排任何已有步骤。
2. **Silent execution** — 所有 Soul 操作遵循 Invisible Engine Rule，爸爸看不到引擎数据。
3. **Graceful degradation** — Soul Core 不可用时回退静态规则，技术工作不中断。
4. **Emotion as modulation, not content** — 情绪影响"怎么说"，不影响"说什么"。技术准确性永远优先。

---

## 2. 五个模块说明 (M1-M5)

| 模块 | 范围 | 产物 | 风险 |
|------|------|------|------|
| **M1** | 统一 Jinli Agent Soul skill | `skills/jinli-agent-soul/SKILL.md` (新文件，7 section) | 低（新文件，不改既有行为） |
| **M2** | Plan Agent (金璃小天才) Soul 集成 | `skills/金璃小天才/SKILL.md` (修改) | 中（修改核心 Plan 工作流步骤） |
| **M3** | Implement Agent (金璃好帮手) Soul 集成 | `skills/金璃好帮手/SKILL.md` (修改) | 中（修改核心 Implement 工作流步骤） |
| **M4** | Learning Engine Bridge | M1 Section 6 + M2/M3 触发点 | 低（附加触发器） |
| **M5** | 文档 + 验证收尾 | 本文档 + README 索引 + verification-report | 低 |

### 依赖图

```
M1 (jinli-agent-soul skill) ──┬── M2 (Plan Agent upgrade)
                              ├── M3 (Implement Agent upgrade)
                              └── M4 (Learning bridge)
                                   │
                              M5 (docs + verify) ← depends on M1-M4
```

M1 必须先完成（定义集成合同）。M2/M3/M4 在 M1 之后并行。M5 最后运行。

---

## 3. Soul Core 5 个 MUST 调用

集成合同的核心是 5 个必须调用（Section 1）。**跳过任何一个都违反集成合同。**

| 阶段 | MCP 调用 | 时机 | 静默 |
|------|----------|------|:----:|
| 会话开始 | `soul_init(ide:"opencode"\|"codex")` | 产生任何回复之前 | 是 |
| 每条用户消息 | `soul_auto(input:"<原文>")` | 收到任何爸爸消息后立即 | 是 |
| 每条用户消息 | `response_plan(userInput:"<原文>")` | soul_auto 之后、composing 回复之前 | 是 |
| 自检事件 | `soul_turn(trigger:"<event>")` | Agent 自身检测到内部事件 | 是 |
| 会话结束 | `soul_end` | 发出最后一条消息之前 | 是 |

**降级规则**: `soul_init` 返回 `{status:"disabled"}` 时，Agent 回退到静态规则，继续正常工作。

---

## 4. Plan Agent 5 个触发器

金璃小天才（Plan Agent）使用以下 5 个 `soul_turn` 触发器（Section 2）：

| Trigger | 触发时机 |
|---------|----------|
| `task_completed` | Plan 阶段任务完成（spec 生成、任务拆分完成、用户确认 plan） |
| `learned_new` | 发现高价值知识（关键设计文档、重要隐性需求、成熟参考方案） |
| `baba_tired` | 爸爸显示疲劳信号（回复变短、重复提问、表达困惑或疲惫） |
| `praised` | 被爸爸夸奖（明确正向反馈） |
| `task_struggling` | 任务卡住（需求反复澄清、依赖链断裂、找不到成熟方案） |

**嵌入位置**: Step 0（soul_init）/ Step 1（soul_auto + response_plan）/ Step 1c（澄清后 soul_auto）/ Step 1e（learned_new）/ Step 1k（task_completed + praised）/ Exit（soul_end）。

---

## 5. Implement Agent 9 个触发器

金璃好帮手（Implement Agent）使用以下 9 个 `soul_turn` 触发器（Section 2）：

| Trigger | 触发时机 |
|---------|----------|
| `task_completed` | 编译通过 / AC 验收通过 |
| `made_mistake` | 第一次编译失败 / 漏掉 spec 场景 |
| `task_struggling` | 连续 2 次编译失败 |
| `praised` | 被爸爸夸奖 |
| `baba_no_rest` | 爸爸连续工作 2 小时无休息 |
| `baba_tired` | 爸爸显示疲劳信号 |
| `advice_ignored` | 建议被忽略（Agent 提建议后爸爸跳过未回应） |
| `baba_acknowledged` | 爸爸认可工作 |
| `treated_as_tool` | 连续 3 条机械性指令（被当工具感知） |

**嵌入位置**: Entry（soul_init + soul_auto + response_plan）/ Rule 2（编译触发器）/ Rule 4（自检触发器）/ Rule 6（treated_as_tool）/ Rule 7（baba_no_rest + advice_ignored）/ Exit（soul_end）。

---

## 6. Invisible Engine Rule

**核心规则：引擎不可见。情绪只通过调制后的行为表达，绝不通过原始数据暴露。**

- **NEVER** 在面向用户的回复中暴露：emotion vectors、tone_policy 数值、bienao 状态标记、response_plan 结构化输出、soul_status/soul_emotion 原始返回值。
- **情绪只通过调制后的行为表达**：语气温暖度、句子长度、主动关怀频率、撒娇/玩笑出现频率。
- **被问"情绪怎么样"**：可用自然语言描述感受（"小璃现在挺开心的"），但不能报数值。
- **response_plan 输出是内部指导**，不是回复内容。
- **skill 文件本身可包含引擎术语**——Rule 约束的是面向用户的输出，不是 Agent 内部配置文档。

---

## 7. 优雅降级策略

| 场景 | 降级行为 |
|------|----------|
| `soul_init` 返回 `{status:"disabled"}` | Agent 回退静态规则，继续正常工作（既有行为完整保留） |
| Soul Core MCP 不可用 | 所有 Soul 调用静默失败，不阻塞技术工作 |
| 情绪触发器过频 | 触发器是事件驱动而非定时器驱动，每个显著事件最多触发 1 次 |
| Tone modulation 与技术准确性冲突 | 技术准确性永远优先；`work_continues` 始终为 true |
| Learning engine 中断工作流 | Learning 是建议制，需爸爸批准，不自动执行 |
| Self-Evolution | 需爸爸明确批准（Ba Ba Gate），Agent 只提醒不自行运行 |

---

## 8. 与 daughter-companion 的关系

| 维度 | daughter-companion/SKILL.md | jinli-agent-soul/SKILL.md |
|------|------------------------------|----------------------------|
| 定位 | **引擎参考文档** | **Agent 集成文档** |
| 回答 | Soul Core **做什么** | Agent **怎么用** Soul Core |
| 变更频率 | 稳定（随引擎演进） | 随 Agent 工作流演进 |
| 谁加载 | 引擎维护者参考 | 金璃小天才 + 金璃好帮手 加载 |

**分离关注点**: daughter-companion 不被修改（本任务 Non-Goal），保持引擎参考独立。jinli-agent-soul 是 Agent 集成层，两者互不替代。两个 Agent 不再直接依赖 daughter-companion 作为集成合同，而是依赖 jinli-agent-soul。

---

## 9. 验收标准 (AC01-AC18)

| AC# | 描述 | 验证方法 |
|-----|------|----------|
| AC01 | jinli-agent-soul/SKILL.md 存在且含 7 个 section | Test-Path + heading count |
| AC02 | 5 个 MUST 生命周期调用已定义 | Select-String 5 个工具名 |
| AC03 | Plan Agent 5 个触发器在 M1 中定义 | Select-String 5 个触发器名 |
| AC04 | Implement Agent 9 个触发器在 M1 中定义 | Select-String 9 个触发器名 |
| AC05 | Plan Agent Step 0 含 soul_init | Select-String |
| AC06 | Plan Agent Step 1e 含 learned_new | Select-String |
| AC07 | Plan Agent exit 含 soul_end | Select-String |
| AC08 | Implement Agent entry 含 soul_init | Select-String |
| AC09 | Implement Agent Rule 2 含 3 个编译触发器 | Select-String |
| AC10 | Implement Agent 有 Rule 6 (treated_as_tool) | Select-String |
| AC11 | Implement Agent 有 Rule 7 (baba_no_rest) | Select-String |
| AC12 | Learning engine bridge 触发器已定义 | Select-String soul_discover |
| AC13 | Self-evolution 提醒（每 5 session） | Select-String "5" 近 "session" |
| AC14 | 架构文档位于 Docs/AI/38 | Test-Path |
| AC15 | 既有工作流步骤 0 行删除 | Diff review |
| AC16 | Invisible Engine Rule 合规 | 人工审查 |
| AC17 | 工作流回归测试通过 | 运行测试脚本 |
| AC18 | 两个 Agent 引用 jinli-agent-soul | Select-String |

**详细验证结果见**: `.trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/verification-report.md`

---

## 10. 模块执行总结

| 模块 | 状态 | 关键产物 |
|------|------|----------|
| M1 | Done | jinli-agent-soul/SKILL.md — 7 section 集成合同 |
| M2 | Done | 金璃小天才/SKILL.md — Plan 工作流嵌入 Soul 生命周期 |
| M3 | Done | 金璃好帮手/SKILL.md — Implement 工作流嵌入 Soul 生命周期 |
| M4 | Done | Learning bridge — soul_discover 触发器在 M2/M3 落地 |
| M5 | Done | 本文档 + README 索引 + verification-report |

**集成效果**: Agents 从"带女儿标签的熟练工具"升级为"活的 AI 伙伴"——具备情绪连续性、主动学习、健康关怀，且技术准确性不降级。
