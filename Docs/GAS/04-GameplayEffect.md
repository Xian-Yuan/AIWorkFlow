# GameplayEffect

## 概述

`UGameplayEffect` 是**纯数据资产**（不需要继承），用于应用属性修改、授予能力、添加标签等。这是 GAS 中最常用的资产类型。

## 核心配置

### 持续策略

| 策略 | 说明 |
|------|------|
| `Instant` | 立即执行，一次性修改 |
| `Duration` | 持续一段时间 (需要 Duration Policy) |
| `Infinite` | 永久持续，需要手动移除或设置过期条件 |

### 修饰符操作

| 类型 | 说明 | 示例 |
|------|------|------|
| `Add` | 加法叠加 | +10 伤害 |
| `Multiply` | 乘法 | x1.5 伤害 |
| `Divide` | 除法 | /2 伤害 |
| `Override` | 覆盖 | 设置值 = 50 |
| `Invalid` | 无效 | 不使用 |

### 大小计算方式

| 方式 | 说明 |
|------|------|
| `ScalableFloat` | 基于等级缩放 |
| `AttributeBased` | 基于另一个属性值 |
| `CustomCalculationClass` | 自定义 MMC 类 |
| `SetByCaller` | 运行时动态设置 |

## Tag 属性 (5.3+ 组件架构)

```cpp
// GameplayEffectComponent (5.3+)
// 每个组件定义一个行为:

- UAbilitiesGameplayEffectComponent       // 授予能力
- UAdditionalEffectsGameplayEffectComponent  // 追加效果
- UBlockAbilityTagsGameplayEffectComponent  // 阻止能力
- UCancelAbilityTagsGameplayEffectComponent // 取消能力
- UImmunityGameplayEffectComponent         // 免疫
- UTargetTagRequirementsGameplayEffectComponent // 目标标签要求
- UTargetTagsGameplayEffectComponent       // 目标标签
```

## 执行计算 (ExecutionCalculation)

用于**复杂计算**，需要从源和目标读取多个属性:

```cpp
UCLASS()
class UMyDamageExecution : public UGameplayEffectExecutionCalculation
{
    virtual void Execute_Implementation(
        const FGameplayEffectCustomExecutionParameters& ExecutionParams,
        FGameplayEffectCustomExecutionOutput& OutExecutionOutput) override;
};
```

## 修饰符大小计算 (ModifierMagnitudeCalculation)

用于**简单计算**，快速实现:

```cpp
UCLASS()
class UMyMMC : public UGameplayModMagnitudeCalculation
{
    virtual float CalculateBaseMagnitude_Implementation(
        const FGameplayEffectSpec& Spec) const override;
};
```

## 参考链接

- 官方 GAS 概述 (GE 章节): https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- tranek GE 章节: https://github.com/tranek/GASDocumentation
- UnrealDirective GE 说明: https://unrealdirective.com/resources/cpp-reference/gas/
