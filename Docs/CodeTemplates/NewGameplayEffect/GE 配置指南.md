# GameplayEffect 配置指南

## 概述

GameplayEffect 是**纯数据资产**（不需要 C++ 子类）。所有配置在蓝图/编辑器中进行。

## 创建方式

```
Content Browser → 右键 → Gameplay Effect → 命名如 GE_Heal
```

## 核心配置表

### 1. 持续策略 (Duration Policy)

| 策略 | 使用场景 | 配置 |
|------|----------|------|
| `Instant` | 一次性伤害/治疗 | Duration Policy = Instant |
| `Duration` | 临时Buff 5秒 | Duration Policy = Has Duration, Duration = 5.0 |
| `Infinite` | 持续到手动移除 | Duration Policy = Infinite |

### 2. 修饰符 (Modifiers)

每个 Modifier 需要配置:

```
Attribute:          Health (选择你的属性)
Modifier Op:        Add (加) / Multiply (乘) / Divide (除) / Override (覆盖)
Magnitude:          ScalableFloat (等级缩放) / SetByCaller (动态) / Custom (MMC)
Source/Target:      源属性 / 目标属性
```

#### Magnitude 计算方式

| 方式 | 适用 | 示例 |
|------|------|------|
| `ScalableFloat` | 等级缩放 | (50 + 10*Level) |
| `AttributeBased` | 基于另一属性 | HP的10% |
| `CustomCalculationClass` | 复杂逻辑 | 创建 UGameplayModMagnitudeCalculation 子类 |
| `SetByCaller` | 运行时动态 | 代码中 `Spec.SetSetByCallerMagnitude(Tag, Value)` |

### 3. Tag 配置

UE5.3+ 中使用 **GameplayEffectComponent** 添加:

| 组件 | 用途 |
|------|------|
| `UAbilitiesGameplayEffectComponent` | 授予一组 GameplayAbility |
| `UAdditionalEffectsGameplayEffectComponent` | 应用时追加其他 GE |
| `UBlockAbilityTagsGameplayEffectComponent` | 阻止某些能力激活 |
| `UCancelAbilityTagsGameplayEffectComponent` | 取消某些能力 |
| `UImmunityGameplayEffectComponent` | 免疫某些效果 |
| `UTargetTagsGameplayEffectComponent` | 给目标添加 Tag |
| `UTargetTagRequirementsGameplayEffectComponent` | 目标 Tag 条件要求 |

### 4. 常用 GE 配置示例

#### GE_Damage (即时伤害)
```
Duration: Instant
Modifiers:
  - Attribute: IncomingDamage (Meta属性)
    Op: Add
    Magnitude: ScalableFloat = -50.0
```

#### GE_HealOverTime (持续治疗)
```
Duration: Has Duration, 10s
Period: 1.0s (每秒触发)
Modifiers:
  - Attribute: IncomingHealing (Meta属性)
    Op: Add
    Magnitude: ScalableFloat = 10.0
```

#### GE_Stun (眩晕 — 阻塞能力)
```
Duration: Has Duration, 3.0s
Components:
  - BlockAbilityTags: Ability.Stun (Tag)
  - TargetTags: State.Stunned (Tag)
```

### 5. 执行计算 (Execution)

复杂计算步骤:

1. 创建 `UGameplayEffectExecutionCalculation` 子类
```cpp
UCLASS()
class UMyDamageExecution : public UGameplayEffectExecutionCalculation
{
    GENERATED_BODY()
    virtual void Execute_Implementation(
        const FGameplayEffectCustomExecutionParameters& ExecutionParams,
        FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const override;
};
```

2. 在 GE 中引用:
```
Executions:
  - CalculationClass: UMyDamageExecution
```
