---
domain: ue
domain_path: ue/ai-behavior
kg_node_id: node.doc-ai-ai-05-statetree-bt-eqs-smartobject-e3bb
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.05-statetree-bt-eqs-smartobject.e3bb

---

# StateTree BT EQS SmartObject

## 目标

本文件为 AI/NPC 相关开发提供统一选型与落地规则，避免在没有明确依据时随意混用 `StateTree`、`Behavior Tree`、`EQS` 与 `SmartObject`。

## 选型顺序

### 优先 1: StateTree

适用场景：

- 单机敌人
- 行为可自然拆成状态
- 需要较低运行成本
- 需要清晰的状态切换可视化

推荐状态示例：

- `Idle`
- `Patrol`
- `Detect`
- `Chase`
- `Attack`
- `Recover`
- `Dead`

## 优先 2: Behavior Tree + Blackboard

适用场景：

- 已有成熟 BT 资产
- 条件组合复杂
- 需要 Service 持续刷感知或环境上下文

约束：

- BT 负责决策，不负责复杂伤害与数值结算
- 技能执行仍优先交给 GAS

## 优先 3: EQS

适用场景：

- 找攻击点
- 找掩体点
- 找最近目标或交互位

约束：

- EQS 只负责“找位置/找对象”
- 不把业务结算或状态切换逻辑写进 EQS

## 优先 4: SmartObject

适用场景：

- 世界交互点
- 占位动作
- 预约/释放式使用

约束：

- 必须定义失败回退
- 必须定义释放时机
- 优先用 GameplayTag 过滤可用对象

## 与 GAS 的分工

- AI 系统决定“何时做”
- GAS 决定“能力如何做”
- 状态切换优先通过 Tag、事件或显式条件驱动
- 避免 AI 任务直接承担完整伤害计算与技能生命周期

## 与 Lyra 的分工

- 玩家与世界交互优先参考 Lyra 的交互能力链
- 角色能力仍通过 `PawnData / AbilitySet / InputConfig / Experience` 串接
- AI 行为扩展尽量挂在现有控制器、组件或插件扩展点，而非改 Lyra 核心

## 默认实现建议

### 普通敌人

- `StateTree + AIController`
- 必要时配合感知与简单查询

### 精英/Boss

- `StateTree` 或 `Behavior Tree`
- 配合 GAS 技能窗口、Montage、GameplayEvent

### 环境交互实体

- `SmartObject`
- 必要时由 `StateTree` 决定何时进入交互

### 大规模群体

- 仅在明确需要时评估 `Mass + StateTree`

## 交付要求

AI 给出方案时必须明确：

- 为什么选择当前框架
- 为什么不选其他框架
- 主状态或主黑板键有哪些
- 与 GAS 的协同边界在哪里
