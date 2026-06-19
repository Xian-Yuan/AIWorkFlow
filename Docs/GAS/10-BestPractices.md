# GAS 最佳实践

## ASC 放置位置

| 场景 | 推荐位置 | 原因 |
|------|----------|------|
| 多人游戏 | PlayerState | Pawn 销毁时属性保留 |
| 单人游戏 | Character | 简单直接 |
| AI 小兵 | Pawn/Character | 不需要持久化 |
| 载具/物体 | Actor | 不需要持久化 |

## 编码规范

### 使用 Tag 而非硬编码
```cpp
// 推荐: Tag 驱动
ASC->TryActivateAbilitiesByTag(TagContainer);

// 不推荐: 硬编码类
ASC->TryActivateAbilityByClass(UMyAbility::StaticClass());
```

### 正确使用 Meta Attribute
```cpp
// Damage 设为 MetaAttribute (不复制)
// 在 PostGameplayEffectExecute 中处理后归零
// 避免复制不必要的属性
```

### 避免在 ASC Actor 死亡后立即销毁
```cpp
// Destroy 前需要:
// 1. 取消所有能力
// 2. 移除所有 GE
// 3. 清理 GameplayCue
// 推荐: 将 ASC 放在 PlayerState 上
```

## Effect 设计

- **Instant** 用于一次性修改 (伤害、治疗)
- **Duration** 用于临时效果 (毒药 5 秒)
- **Infinite** 用于永久状态 (buff/debuff，手动移除)
- 使用 **SetByCaller** 处理运行时动态数值
- 执行计算 (ExecutionCalculation) 用于复杂公式

## 性能注意事项

- ASC 的复制模式要根据角色类型选择 (Mixed / Minimal)
- 避免在每个 Tick 中查询属性，使用回调代替
- GameplayCue 应仅用于视听反馈，不包含游戏逻辑
- 大量同时活跃的 GE 会影响性能，考虑合并

## 多人游戏注意事项

- 使用 `LocalPredicted` 能力获得流畅体验
- 将重逻辑放在 `ServerOnly` 能力中
- 使用 `UGameplayAbility::CanActivateAbility` 做客户端预测检查
- 确保 `IAbilitySystemInterface` 正确实现

## Lyra 集成要点

- 使用 `ULyraAbilitySystemComponent` 替代原始 ASC
- 通过 `ULyraAbilitySet` 批量授予能力
- 使用 `ULyraGameplayAbility` 替代原始 GA
- 输入绑定通过 Tag 映射而非 Hard Reference

## 参考链接

- 官方 GAS 概述: https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- 官方 GAS 设置教程 (60分钟): https://dev.epicgames.com/community/learning/tutorials/8Xn9/unreal-engine-epic-for-indies-your-first-60-minutes-with-gameplay-ability-system
- 官方 ASC 最佳实践: https://dev.epicgames.com/community/learning/tutorials/DPpd/unreal-engine-gameplay-ability-system-best-practices-for-setup
- 官方 GAS 5.6 入门: https://dev.epicgames.com/community/learning/tutorials/d6DL/getting-started-with-the-gameplay-ability-system-gas-in-unreal-engine-5-6
- tranek GAS 完整文档: https://github.com/tranek/GASDocumentation
