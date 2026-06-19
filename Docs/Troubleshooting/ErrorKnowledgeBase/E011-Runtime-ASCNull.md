---
id: E011
title: ASC 未初始化导致 "Ability system component is not valid"
category: 运行时错误
system: GAS
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [AbilitySystemComponent, ASC, not valid, InitAbilityActorInfo, ActorInfo]
---

## 现象

```
LogAbilitySystem: Warning: Can't activate ability because ability system component is not valid
```

## 原因

ASC（AbilitySystemComponent）或 ActorInfo 未正确初始化。最常见原因是 `InitAbilityActorInfo()` 未调用。

## 解决方案

```cpp
// 在 Pawn 的 Possess 或初始化流程中：
if (UAbilitySystemComponent* ASC = GetAbilitySystemComponent())
{
    ASC->InitAbilityActorInfo(OwnerActor, AvatarActor);
    // OwnerActor = PlayerState (Lyra 默认)
    // AvatarActor = Pawn
}
```

**检查链：**
1. `InitAbilityActorInfo(OwnerActor, AvatarActor)` 是否已调用
2. ASC 是否添加到正确的 Actor 上（Lyra 单机模式：PlayerState 或 Pawn）
3. 调用时机是否在 Experience 加载完成之后

**调试代码：**
```cpp
if (!ASC) { UE_LOG(LogTemp, Error, TEXT("ASC is null")); }
if (!ASC->GetActorInfo()) { UE_LOG(LogTemp, Error, TEXT("ActorInfo is null")); }
```

## 预防

- 所有涉及 GAS 的 Actor 在 PostInitializeComponents 或 Possess 中调用 InitAbilityActorInfo
- 使用 Lyra 的 InitState 链确保初始化顺序：`InitState_GameplayReady` 之后才能安全使用 ASC

## 检测关键词

[AbilitySystemComponent, not valid, InitAbilityActorInfo, ASC null, ActorInfo null]
