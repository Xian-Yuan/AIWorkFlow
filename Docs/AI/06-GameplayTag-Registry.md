---
domain: ue
domain_path: ue/gameplay-system
kg_node_id: node.doc-ai-ai-06-gameplaytag-registry-b9eb
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.06-gameplaytag-registry.b9eb

---

# GameplayTag Registry

## 目标

本文件用于约束项目中 GameplayTag 的命名、分层、注册与变更流程，降低 AI 和多人协作时的标签漂移、重复命名和语义冲突。

## 总原则

- 优先复用已有 Tag，不重复创建近义标签
- 先设计根节点，再扩展叶子节点
- Tag 名称表达“用途”而不是“实现细节”
- Tag 变更必须同步更新引用点、文档和相关数据资产

## 推荐根节点

以下根节点可作为项目默认规划起点：

- `InputTag.*`
- `GameplayEvent.*`
- `Status.*`
- `State.*`
- `Ability.*`
- `Ability.Type.*`
- `Ability.Trigger.*`
- `Cue.*`
- `GameplayCue.*`
- `AI.*`
- `AI.State.*`
- `AI.Command.*`
- `Interaction.*`
- `Equipment.*`
- `Weapon.*`
- `UI.*`
- `SaveGame.*`
- `Debug.*`

## 命名规则

- 使用 PascalCase 片段，例如 `InputTag.Ability.Primary`
- 同一层级命名风格保持一致
- 不使用缩写不明的短词
- 不把类名、资源名直接塞进 Tag

## 常见示例

### 输入

- `InputTag.Move`
- `InputTag.Look`
- `InputTag.Ability.Primary`
- `InputTag.Ability.Secondary`

### 战斗与能力

- `Ability.Type.Attack`
- `Ability.Type.Skill`
- `Ability.Trigger.OnHit`
- `Ability.Trigger.OnDeath`

### 状态

- `Status.Dead`
- `Status.Stunned`
- `Status.Casting`
- `AI.State.Patrol`
- `AI.State.Chase`
- `AI.State.Attack`

### 事件

- `GameplayEvent.Death`
- `GameplayEvent.Hit`
- `GameplayEvent.Ability.Commit`

### 交互

- `Interaction.Use`
- `Interaction.Loot`
- `Interaction.Dialog`

## AI 使用规则

AI 在创建新 Tag 前必须检查：

1. 现有文档与代码中是否已有语义相同 Tag
2. 是否能放进已有根节点
3. 该 Tag 是输入、状态、事件、能力分类还是交互语义
4. 是否需要同步更新 `InputConfig`、`AbilitySet`、`StateTree`、`Blackboard` 或 `SmartObject`

## 变更流程

每次新增或修改 Tag，至少要记录：

- Tag 全名
- 所属根节点
- 设计目的
- 主要使用位置
- 是否影响蓝图、数据资产或 AI 资产

## 交付要求

AI 在交付方案或代码时，如涉及新 Tag，必须附带：

- 新增 Tag 列表
- 被修改的资源列表
- 是否存在旧 Tag 替换
- 回归检查点
