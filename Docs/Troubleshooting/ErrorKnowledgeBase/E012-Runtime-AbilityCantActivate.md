---
id: E012
title: 能力无法激活（无错误日志）
category: 运行时错误
system: GAS
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E011]
keywords: [能力无法激活, Can't activate, 无错误, Tag阻塞, Cooldown, Cost]
---

## 现象

能力按了按键但完全不执行，控制台无错误或仅有 "Can't activate"。

## 原因

能力激活被以下条件阻塞（检查顺序）：

1. **Tag 阻塞**：ASC 上的 `BlockedByTags` 包含了能力需要的 Tag
2. **ActivationOwnedTags 冲突**：能力激活后自带的 Tag 与 `BlockedByTags` 冲突
3. **Cost 不足**：配置了 `CostGameplayEffectClass` 但资源不够
4. **Cooldown**：能力在冷却中
5. **CanActivateAbility 返回 false**：自定义前置条件失败
6. **NetExecutionPolicy**：ServerOnly 能力在客户端 TryActivate

## 解决方案

```cpp
// 调试方法
// 1. 启用能力调试 HUD
// 控制台: AbilitySystem.Debug.Ability 1
// 或: ShowDebug AbilitySystem

// 2. 代码检查阻塞 Tag
if (ASC->IsAbilityActiveHandle(Handle)) { /* 已激活 */ }
if (!ASC->TryActivateAbilityByClass(AbilityClass)) { /* 激活失败 */ }
```

## 案例

```
检查 Tag 链：
能力 Tag:  Ability.Melee.Attack
BlockedByTags: Ability.Melee     ← 能力自己阻塞自己！
```

## 预防

- 规划 GameplayTag 时区分阻塞 Tag 和激活 Tag
- 能力和 GE 的 Tag 配置完成后做一次交叉检查

## 检测关键词

[Can't activate, 能力无法激活, Tag阻塞, BlockedByTags, Cooldown, Cost]
