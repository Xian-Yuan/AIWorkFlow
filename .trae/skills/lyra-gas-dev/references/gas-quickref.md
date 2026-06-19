# GAS 快速参考

## 核心类关系

```
UAbilitySystemComponent (ASC) — 心脏
    ├─ UAttributeSet — 数据 (不复制 Meta 属性)
    ├─ UGameplayAbility — 行为 (自包含 UObject)
    │   └─ UAbilityTask — 异步操作 (蒙太奇/等待/目标)
    ├─ UGameplayEffect — 修改 (数据资产)
    │   ├─ UGameplayEffectComponent (5.3+) — 标签/能力/免疫
    │   ├─ UGameplayEffectExecutionCalculation — 复杂计算
    │   └─ UGameplayModMagnitudeCalculation — 简单计算
    └─ UGameplayCue — 反馈 (仅客户端)
```

## GE 持续策略

| 类型 | 何时用 | 是否复制 |
|------|--------|----------|
| Instant | 一次性伤害/治疗 | 不直接复制 (通过属性) |
| Duration | 5秒 Buff | 复制 |
| Infinite | 持续到手动移除 | 复制 |
| Period | 每秒扣血 (Duration/Infinite + Period) | 复制 |

## 伤害数据流 (标准模式)

```
GameplayAbility::ApplyGameplayEffectToTarget(GE_Damage)
    → GE (Instant) → Modifier: IncomingDamage += Value
    → ASC::ApplyGameplayEffectToTarget
    → AttributeSet::PostGameplayEffectExecute
        → Damage 转换 → Health -= Damage
        → Damage 归零
        → 死亡检查 → HandleGameplayEvent(Event.Died)
        → 广播 OnHealthChanged
```

## 能力实例化策略

| 策略 | 说明 | 性能 | 适用 |
|------|------|------|------|
| InstancedPerActor | 每个 Actor 一个实例 (默认) | 中 | 大多数能力 |
| InstancedPerExecution | 每次激活创建 | 低 | 需要隔离状态 |
| NonInstanced | 类级别共享 | 高 | 无状态能力 |

## 网络执行策略

| 策略 | 执行位置 | 适用 |
|------|----------|------|
| LocalPredicted | 客户端预测 + 服务器验证 | 玩家操作能力 (推荐) |
| LocalOnly | 仅客户端 | 纯本地效果 |
| ServerOnly | 仅服务器 | AI/环境能力 |
| ServerInitiated | 服务器触发，客户端同步 | 服务器主动的能力 |

## Tag 命名约定

| 前缀 | 用途 | 示例 |
|------|------|------|
| `InputTag.` | 输入绑定 | `InputTag.Jump` |
| `Ability.` | 能力标签 | `Ability.Jump` |
| `GameplayCue.` | 视听反馈 | `GameplayCue.Impact` |
| `GameplayEvent.` | 事件触发 | `GameplayEvent.Died` |
| `State.` | 状态标记 | `State.Stunned` |
| `SetByCaller.` | 动态数值 | `SetByCaller.Damage` |
| `InitState.` | 初始化状态 | `InitState.GameplayReady` |

## 常见错误

| 错误 | 原因 | 修复 |
|------|------|------|
| 能力不激活 | Tag 阻塞/冷却/资源不足 | 检查 BlockedByTags/Cost/CoolDown |
| 属性不复制 | 缺少 DOREPLIFETIME/OnRep | 添加复制配置 |
| 客户端看不到效果 | ASC ReplicationMode 不对 | 设为 Mixed |
| GE 不生效 | Duration Policy 不对/Attribute 拼错 | 检查配置 |
