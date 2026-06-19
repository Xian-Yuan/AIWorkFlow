---
id: E013
title: 能力重复激活 "Attempted to activate ability that was already active"
category: 运行时错误
system: GAS
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E012]
keywords: [already active, 重复激活, InstancingPolicy, InstancedPerActor]
---

## 现象

```
LogAbilitySystem: Attempted to activate ability that was already active!
```

## 原因

能力使用了 `InstancedPerActor` 实例化策略（默认），即同一个能力类只有一个实例。当该能力已经在激活状态下时，再次尝试激活会失败。

## 解决方案

```cpp
// 方案 A: 允许多次实例化
// 在能力类的构造函数中:
InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerExecution;

// 方案 B: 激活前检查
if (ASC->FindAbilitySpecFromClass(AbilityClass))
{
    if (!ASC->FindAbilitySpecFromClass(AbilityClass)->IsActive())
    {
        ASC->TryActivateAbilityByClass(AbilityClass);
    }
}
```

## 预防

- 需要多次同时运行的能力（如射击）使用 `InstancedPerExecution`
- 只能同时运行一个的能力（如装填）保持默认 `InstancedPerActor`

## 检测关键词

[already active, InstancedPerActor, 重复激活, InstancingPolicy]
