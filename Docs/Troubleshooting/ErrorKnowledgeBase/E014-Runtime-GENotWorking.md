---
id: E014
title: GameplayEffect 不生效
category: 运行时错误
system: GAS
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E011]
keywords: [GameplayEffect, 不生效, Duration, Modifier, Attribute, ApplicationTag]
---

## 现象

GE 应用后没有产生任何效果（属性未变化、无 Tag 变化）。

## 原因

检查链：

1. **Duration Policy 错误**：瞬时效果必须选 `Instant`，周期性效果选 `Duration` 或 `Infinite`
2. **Modifier 的 Attribute 不存在**：Modifier 中引用的 Attribute 不在目标 AttributeSet 中
3. **目标没有 ASC**：目标 Actor 没有 AbilitySystemComponent
4. **Application Tag Requirements 不满足**：GE 配置了 `ApplicationTagRequirements` 但目标不满足
5. **GE 的 GrantedTags 互相冲突**

## 解决方案

```cpp
// 调试：在代码中手动应用并检查返回值
FGameplayEffectContextHandle Context = ASC->MakeEffectContext();
FGameplayEffectSpecHandle Spec = ASC->MakeOutgoingSpec(GE_Class, 1, Context);
if (Spec.IsValid())
{
    FActiveGameplayEffectHandle Handle = ASC->ApplyGameplayEffectSpecToSelf(*Spec.Data);
    if (!Handle.WasSuccessfullyApplied())
    {
        UE_LOG(LogTemp, Warning, TEXT("GE failed to apply"));
    }
}
```

## 预防

- 所有 GE 配置完成后在蓝图中测试一次
- Modifier 的 Attribute 必须下拉选择，不要手写

## 检测关键词

[GameplayEffect, 不生效, Modifier, Duration Policy, ApplicationTag]
