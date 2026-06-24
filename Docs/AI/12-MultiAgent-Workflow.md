---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-12-multiagent-workflow-2e86
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.12-multiagent-workflow.2e86

---

﻿# MultiAgent Workflow

## 目标

本文件用于定义当前项目的最小多智能体协作闭环，避免把所有职责都压到一个智能体上，也避免过早拆成过多细粒度角色。

当前推荐只使用 3 个项目专用智能体：

- `ue-project-router`
- `ue-lyra-gas-implementer`
- `ue-ai-validator`

## 适用前提

- 项目类型：UE5.7 单机项目
- 技术基座：Lyra + GAS
- AI 重点：StateTree、Behavior Tree、EQS、SmartObject
- 根目录 `Docs/AI` 是规则真相源
- 根目录 `.trae/skills` 是 skill 与 agent 的唯一真相源

## 协作目标

3 个智能体分别负责：

1. 需求归类与路由
2. 主链路实现
3. 风险收口与验证

这样做的目标是：

- 降低上下文过载
- 降低路由错误
- 降低实现与验证混在一起导致的遗漏
- 保持维护成本低于大规模多智能体方案

## 角色定义

### 1. `ue-project-router`

职责：

- 识别需求主链路
- 选择主 skill 与次 skill
- 指定必须阅读的文档
- 判断使用单 agent 还是多 agent

不负责：

- 直接写主体代码
- 直接做完整验证收口

### 2. `ue-lyra-gas-implementer`

职责：

- 落地 `GameFeature / Experience / PawnData / InputConfig / AbilitySet`
- 落地 `GameplayAbility / GameplayEffect / AttributeSet / Cue / Task`
- 输出代码、配置、数据资产、挂载点和验证步骤

不负责：

- 独立主导 UI 专题
- 独立主导复杂 AI 选型
- 最终验证兜底

### 3. `ue-ai-validator`

职责：

- 检查 AI 方案是否符合项目现有模式
- 检查 StateTree / BT / EQS / SmartObject 选型与边界
- 做编译、运行时、资产接线、回归验证收口

不负责：

- 独立主导完整的 Lyra/GAS 主链实现
- 独立主导模块级架构方案

## 标准协作顺序

```text
用户输入需求
-> ue-project-router
-> ue-lyra-gas-implementer
-> ue-ai-validator
-> 汇总最终答案
## 反降智协议（所有 Agent 必须遵守）

> 上下文腐烂是 Agent 最主要的失败模式。详见各 Agent 的 SKILL.md 中的反降智协议章节。

### 修复循环强制中断
同一 bug 连续修复 2 次未解决 → 停止，spawn 全新 subagent（独立上下文），只接收 analysis.md + spec.md + 错误日志。

### 上下文腐烂检测信号
- 重新读取已修改过的文件
- 重复解释已讨论过的概念
- 提出与早期已否决方案相同的方案
- 忽略 analysis.md 中已记录的约束

### 假阳性防御
- 验证 Agent 与实现 Agent 同一 context → 验证结果无效
- 编译日志为空 → 证据不足 → FAIL
- 未对照 Scenario 逐条验收 → 报告无效 → FAIL

### Git 快照
每次修复前：git stash push -m "SNAPSHOT: <方案名>"。修复失败后：git stash pop 恢复干净状态。
```

## 什么时候启用 3 智能体协作

满足任意两项即可：

- 涉及两个以上系统
- 预计改动 8 个以上文件
- 同时涉及代码、数据资产和蓝图/配置
- 同时涉及 Lyra、GAS、AI
- 需要实现、验证和性能判断并行收敛

以下情况不建议启用：

- 单文件修复
- 单个 Ability 小改
- 单个 DataAsset 调整
- 纯文档工作

## 交接格式

多智能体协作时，统一使用以下交接字段：

- 任务标题
- 主链路
- 次链路
- 主 skill
- 次 skill
- 允许修改范围
- 禁止修改范围
- 输出要求
- 风险点
- 验证清单

详细模板参考：

- `Docs/AI/09-Agent-Handoff-Templates.md`

## 每个智能体的最低输出

### `ue-project-router`

- 主 skill
- 次 skill
- 主链路
- 次链路
- 必读文档
- 是否启用多 agent
- 风险点

### `ue-lyra-gas-implementer`

- 需求映射
- 架构方案
- 文件清单
- 配置步骤
- 验证清单
- 文档更新项

### `ue-ai-validator`

- AI 选型判断
- 编译与运行时风险
- 资产接线检查项
- 回归与性能检查项
- 是否建议回退重构

## 真相源优先级

所有智能体必须按以下顺序取证：

1. `Docs/AI/01-AI-Development-Playbook.md`
2. `Docs/AI/02-Project-Truth-Source.md`
3. `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
4. `Docs/AI/11-Skill-Routing-Workflow.md`
5. `Docs/AI/12-MultiAgent-Workflow.md`
6. 当前任务最相关的 `Docs/AI/*`
7. `Docs/CodeTemplates/*`
8. `Docs/APIRef/*`
9. `Docs/Lyra/*` 和 `Docs/GAS/*`
10. `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

## Memory Candidate 输出规则

当 Review 或 Verify FAIL 具备复用价值时，附带一个 candidate 提议块：

```text
MEMORY_CANDIDATE: yes
MEMORY_TYPE: failure_memory
MEMORY_REASON: <why this should be remembered>

MEMORY_SUMMARY
- Symptom: ...
- Root Cause: ...
- Bad Pattern: ...
- Correct Rule: ...
- Verification: ...
```

规则：
- 这只是 candidate 提议，不是自动转正
- reviewer/validator 不直接写最终 memory 文件
- 只有对未来任务有复用价值的 FAIL 才应输出该块
- promoted failure memories 进入 Docs/Memory/failures/ 后，才允许同步到 Mem0
- candidates 永远不允许同步到 Mem0
## 禁止事项

- 不允许多个智能体同时主导同一主链路
- 不允许路由智能体直接跳过实现智能体写完整主体代码
- 不允许验证智能体替代实现智能体重写整套方案
- 不允许默认把网络复制、RPC、Prediction 作为单机项目答案
- 不允许绕过 `PawnData / AbilitySet / InputConfig / Experience` 直接硬连能力链

## 推荐的最小实践

如果你只想要一个足够稳的项目协作方案，默认使用：

```text
路由 -> 实现 -> 验证
```

只有当任务明显超出这个闭环能力时，再考虑继续拆出更多角色。
