---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-10-execution-examples-0a20
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.10-execution-examples.0a20

---

# Execution Examples

## 目标

本文件给出“规则如何真正落地”的样例，帮助 AI 从规则集过渡到可执行手册。

## 示例 1：新增玩家主动技能

### 任务描述

玩家按下技能键后，释放一个短冷却主动技能，对命中目标造成伤害并播放表现。

### 需求映射

- 主链路：Lyra + GAS
- 次链路：Input + GameplayCue

### 推荐实现链

```text
InputAction
-> GameplayTag
-> InputConfig
-> AbilitySet
-> GameplayAbility
-> GameplayEffect
-> GameplayCue
-> PawnData / Experience
```

### 必查文档

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/04-Asset-Checklists.md`
- `Docs/Lyra/09-InputSystem.md`
- `Docs/GAS/03-GameplayAbility.md`
- `Docs/GAS/04-GameplayEffect.md`
- `Docs/APIRef/GASCoreClasses.md`

### 典型交付

- 新增 Ability 类
- 新增或修改 AbilitySet
- 新增或修改 InputConfig
- 新增 GameplayEffect
- 可选新增 GameplayCue
- 更新 PawnData 或 Experience 引用

### 关键验证

- 输入 Tag 与 AbilitySet 一致
- Ability 能正确激活
- GE 修改的属性真实存在
- 表现资源已正确接线

## 示例 2：新增普通敌人 AI

### 任务描述

创建一个单机敌人，具备待机、巡逻、发现玩家、追击、攻击、死亡等行为。

### 需求映射

- 主链路：AI
- 次链路：GAS

### 推荐实现链

```text
AIController
-> StateTree
-> 目标获取 / 感知
-> Ability Trigger
-> GameplayAbility
-> GameplayEffect / Cue
```

### 推荐选型

- 默认优先 `StateTree + AIController`
- 若项目已有 BT/Blackboard 资产，再考虑 `Behavior Tree + EQS`

### 必查文档

- `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
- `Docs/AI/07-Test-Checklists.md`
- `Docs/AI/08-AntiPatterns.md`
- `Docs/GAS/03-GameplayAbility.md`

### 典型交付

- 新增或复用 AIController
- 新建 StateTree 或扩展现有 StateTree Task
- 增加 AI 相关 Tag
- 能力触发与伤害结算接入 GAS

### 关键验证

- Pawn 能被正确 Possess
- AI 能进入核心状态
- 丢失目标、失败、中断、死亡路径完整
- 没有把伤害结算写死在 AI Task 中

## 示例 3：新增可交互世界对象

### 任务描述

玩家靠近一个世界对象后，可触发交互，执行拾取、开启、对话或激活效果。

### 需求映射

- 主链路：交互
- 次链路：Lyra + SmartObject 或 GAS

### 推荐实现链

```text
Lyra Interaction / Ability
-> 可交互对象
-> 可选 SmartObject
-> GameplayEvent / Cue / UI 反馈
```

### 必查文档

- `Docs/AI/04-Asset-Checklists.md`
- `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
- `Docs/Lyra/03-GameFeaturePlugins.md`
- `Docs/APIRef/CommonPatterns.md`

### 关键验证

- 交互入口统一
- 失败回退与重复交互处理清晰
- 若使用 SmartObject，占位与释放逻辑明确

## 示例 4：多智能体协作任务

### 任务描述

新增一套“精英敌人战斗包”，涉及 AI 行为、玩家技能响应、敌人技能、世界交互提示和回归验证。

### 推荐拆分

1. 架构代理：定义目录、Tag 根节点、主挂载点
2. Lyra/GAS 代理：实现玩家与敌人能力链
3. AI 代理：实现 StateTree / AIController 行为
4. 内容代理：接线 PawnData、GameFeatureData、蓝图资源
5. 测试代理：给出编译、冒烟、回归清单
6. 性能代理：检查 Tick、感知频率、异步边界

### 必查文档

- `Docs/AI/09-Agent-Handoff-Templates.md`
- `Docs/AI/06-GameplayTag-Registry.md`
- `Docs/AI/07-Test-Checklists.md`

### 最终汇总要求

- 统一 Tag 清单
- 统一资产清单
- 统一验证清单
- 统一风险说明

## 使用建议

AI 在处理新需求时，可先从最接近的示例开始，再替换：

- 主链路
- 挂载点
- 数据资产
- 验证步骤

这样可以减少跳过步骤、漏配资源和写错路径的概率。
