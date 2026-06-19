# GameplayAbility

## 概述

`UGameplayAbility` 是 GAS 中定义游戏行为的基本单位。每个能力是一个**自包含的 UObject**。

## 核心概念

### 实例化策略

| 策略 | 说明 | 适用 |
|------|------|------|
| `InstancedPerActor` | 每个 Actor 一个实例 (默认) | 通用 |
| `InstancedPerExecution` | 每次激活创建新实例 | 需要状态隔离 |
| `NonInstanced` | 类级别共享 (无实例) | 无状态能力 |

### 网络执行策略

| 策略 | 说明 |
|------|------|
| `LocalPredicted` | 本地预测触发，服务器验证 |
| `LocalOnly` | 仅客户端执行 |
| `ServerOnly` | 仅服务器执行 |
| `ServerInitiated` | 服务器触发 |

### 激活方式

1. **直接调用**: `TryActivateAbility()`
2. **输入绑定**: 通过 InputAction → Tag → ASC 自动激活
3. **GameplayEvent**: `FGameplayEventData` 触发
4. **GameplayEffect Tag**: GE 上的 Tag 自动触发

## 生命周期

```
CanActivateAbility() → 检查 Tag 要求、消耗、冷却
    ↓ (返回 true)
ActivateAbility() → 开始执行
    ├─ AbilityTasks (异步操作)
    ├─ CommitAbility() → 消耗资源、启动冷却
    └─ EndAbility() → 结束
```

## Tag 控制

```cpp
// 激活时添加到拥有者的标签
ActivationOwnedTags

// 拥有这些标签时阻止激活
BlockedByTags

// 激活时自动取消拥有这些标签的能力
CancelAbilitiesWithTag

// 激活必须拥有这些标签
PrerequisiteTags
```

## Lyra 中的 GameplayAbility

| 类 | 用途 |
|------|------|
| `ULyraGameplayAbility` | 基础能力 — 集成 Lyra 框架 |
| `ULyraGameplayAbility_FromEquipment` | 装备能力 — 自动获取 SourceObject |
| `ULyraGameplayAbility_RangedWeapon` | 远程武器能力 |
| `ULyraGamePhaseAbility` | 游戏阶段能力 |

Lyra 能力的特性:
- 使用 Tag 激活 (不依赖硬编码 InputID)
- `SourceObject` 指向 EquipmentInstance
- 通过 `ULyraAbilitySet` 定义 Tag → Ability 映射

## 关键函数

```cpp
// 必须重写
virtual void ActivateAbility(...);

// 可选重写
virtual bool CanActivateAbility(...);
virtual void EndAbility(...);

// 内置功能
void CommitAbility(Handle, ActorInfo, ActivationInfo);  // 消耗+冷却
void K2_CommitAbility();
void CancelAbility(Handle, ActorInfo, ActivationInfo, bReplicateCancel);
```

## 参考链接

- 官方 UGameplayAbility API: https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility
- tranek GA 章节: https://github.com/tranek/GASDocumentation
