# 目标系统 (Targeting)

## 概述

GAS 提供了一套目标数据系统，用于在能力和效果应用之间传递目标信息。

## 核心数据结构

| 结构 | 说明 |
|------|------|
| `FGameplayAbilityTargetData` | 目标数据基类 |
| `FGameplayAbilityTargetData_LocationInfo` | 位置信息 |
| `FGameplayAbilityTargetData_ActorArray` | Actor 数组 |
| `FGameplayAbilityTargetDataHandle` | 目标数据句柄 (支持网络序列化) |

## 目标选择方式

### 1. 使用 UAbilityTask_WaitTargetData

```cpp
// 在能力中
UAbilityTask_WaitTargetData* Task = 
    UAbilityTask_WaitTargetData::WaitTargetData(
        this, NAME_None, 
        EGameplayTargetingConfirmation::Instant,  // 或 UserConfirmed
        TargetActorClass);
        
Task->ValidData.AddDynamic(this, &UMyAbility::OnTargetDataReady);
Task->ReadyForActivation();
```

### 2. 自定义 TargetActor

创建 `AGameplayAbilityTargetActor` 的子类来定义目标选择逻辑:
- 射线检测 (LineTrace)
- 范围检测 (Radius)
- 屏幕点选等

### 3. 直接代码创建

```cpp
FGameplayAbilityTargetDataHandle TargetData;
// 填充目标数据...
CommitAbility(Handle, ActorInfo, ActivationInfo);
ApplyGameplayEffectToTarget(Effect, TargetData);
```

## 参考链接

- tranek Targeting 章节: https://github.com/tranek/GASDocumentation
- UnrealDirective TargetData 说明: https://unrealdirective.com/resources/cpp-reference/gas/
