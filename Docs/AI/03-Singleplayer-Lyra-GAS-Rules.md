# Singleplayer Lyra GAS Rules

## 目标

本文件把项目默认假设固定为“UE5.7 + Lyra + GAS + 单机”，用于阻止 AI 在没有必要时生成多人网络导向代码。

## 默认假设

- 单机项目优先
- 本地权威逻辑优先
- `SaveGame` 和本地配置优先
- 不主动使用复制、RPC、网络预测

## Lyra 规则

- 把 Lyra 视为可升级基座，而不是业务代码落点
- 功能优先放在 `GameFeature Plugin`
- Gameplay 初始化遵守 `OnExperienceLoaded`
- 输入链路优先 `InputAction -> GameplayTag -> InputConfig -> AbilitySet`

## GAS 规则

- 行为放 `GameplayAbility`
- 数值修改优先放 `GameplayEffect`
- 状态数据放 `AttributeSet`
- 表现优先放 `GameplayCue`、动画、UI
- 持续过程优先放 `AbilityTask` 或状态机

## 单机化规则

- 若需求未明确涉及联网，禁止默认增加：
  - `Replicated`
  - `ReplicatedUsing`
  - `GetLifetimeReplicatedProps`
  - `Server / Client / NetMulticast RPC`
  - `LocalPredicted / ServerOnly` 等网络执行策略讨论

## AI 规则

- 少量敌人优先 `StateTree + AIController`
- 已有 Blackboard 或 BT 资产时再考虑 `Behavior Tree + EQS`
- 可占位交互点用 `SmartObject`
- 只有大规模实体时才评估 `Mass`

## 存档与配置

- 本地存档优先 `SaveGame`
- 项目设置优先 `DeveloperSettings` 或 `.ini`
- 运行时服务优先 `Subsystem`

## 实现前检查

- 当前功能是否真的需要网络同步
- 当前功能是否已有 Lyra 模板可复用
- 当前功能是否可以通过数据资产配置而非重写代码实现
- 当前 AI 是否只需局部状态机而非完整行为树系统

## 交付要求

若 AI 提供方案，必须显式说明：

- 该方案为何适合单机
- 是否完全不依赖复制与 RPC
- 若引用网络文档，仅作为原理参考还是实际落地
