# AbilitySystemComponent (ASC)

## 概述

`UAbilitySystemComponent` (ASC) 是 GAS 的核心。所有使用 GAS 的 Actor 都必须有一个 ASC。

## 主要职责

- 管理 GameplayAbility 的添加、移除、激活
- 管理 GameplayEffect 的应用和移除
- 持有 GameplayTag 容器
- 管理 AttributeSet
- 处理网络复制
- 处理输入绑定

## 初始化

```cpp
// 1. 创建 ASC (通常在 Actor 构造函数中)
ASC = CreateDefaultSubobject<UAbilitySystemComponent>(TEXT("ASC"));

// 2. 设置复制模式
ASC->SetReplicationMode(EGameplayEffectReplicationMode::Full);
// 或 Mixed, Minimal

// 3. 初始化 Actor 信息
ASC->InitAbilityActorInfo(OwnerActor, AvatarActor);
```

## 复制模式

| 模式 | 说明 |
|------|------|
| `Full` | 全量复制 — 单人/合作游戏 |
| `Mixed` | 混合 — 玩家控制的角色 (推荐多人游戏) |
| `Minimal` | 最小化 — AI/Bot (只复制 GameplayCue) |

## Lyra 中的 ASC

Lyra 将 ASC 放在 **PlayerState** 上:

```cpp
// ALyraPlayerState 拥有 ULyraAbilitySystemComponent
// ULyraHeroComponent + ULyraPawnExtensionComponent 负责在 Possess 时授予能力
// 在 UnPossess/死亡时自动撤销
```

优势: Pawn 销毁/重生时 ASC 和状态保持，不会丢失属性。

## 关键函数

```cpp
// 授予能力
FGameplayAbilitySpecHandle GiveAbility(FGameplayAbilitySpecHandle Handle);

// 激活能力
bool TryActivateAbilityByClass(TSubclassOf<UGameplayAbility> AbilityClass);
bool TryActivateAbilitiesByTag(const FGameplayTagContainer& Tags);

// 应用效果
FActiveGameplayEffectHandle ApplyGameplayEffectToSelf(UGameplayEffect* Effect);
FActiveGameplayEffectHandle ApplyGameplayEffectToTarget(UGameplayEffect* Effect, ...);

// 属性访问
float GetNumericAttribute(const FGameplayAttribute& Attribute);
void SetNumericAttribute(const FGameplayAttribute& Attribute, float Value);

// Tag 查询
bool HasMatchingGameplayTag(FGameplayTag Tag);
void AddLooseGameplayTag(FGameplayTag Tag);
```

## 参考链接

- 官方 GAS 概述 (ASC 章节): https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- tranek ASC 章节: https://github.com/tranek/GASDocumentation
