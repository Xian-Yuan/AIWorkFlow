# AttributeSet

## 概述

`UAttributeSet` 定义和管理游戏属性。属性使用 `FGameplayAttributeData` 类型，支持 BaseValue (永久) 和 CurrentValue (当前) 双值系统。

## 定义属性

```cpp
UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Health)
    FGameplayAttributeData Health;
    
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxHealth)
    FGameplayAttributeData MaxHealth;
};
```

## 属性值系统

| 值 | 说明 |
|------|------|
| **BaseValue** | 基值 (永久) — 不受 GameplayEffect 修饰符影响 |
| **CurrentValue** | 当前值 = BaseValue + 所有活跃 GE 修饰符之和 |

## 关键回调

```cpp
// 属性变更前调用 (用于限制值范围)
virtual void PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue);

// GameplayEffect 执行后调用 (用于处理死亡等逻辑)
virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data);
```

## 属性初始化

```cpp
// 方式 1: 在构造函数中设置默认值
Health.Initialize(100.0f);

// 方式 2: 使用 GameplayEffect 初始化
// 创建一个 GE 设置 Health = 100, MaxHealth = 100

// 方式 3: 数据表格
// 创建 FAttributeMetaData 数据表格
```

## 添加到 ASC

```cpp
// 方式 1: 在 Actor 构造函数中创建
AttributeSet = CreateDefaultSubobject<UMyAttributeSet>(TEXT("AttributeSet"));

// 方式 2: 通过 GE 授予
// 在 GE 的 Attributes 数组中添加
```

## Meta Attribute (防御属性)

用于实现先防御计算再扣血的模式:

```cpp
// 定义 Damage 为 MetaAttribute (不复制)
UPROPERTY(BlueprintReadOnly)
FGameplayAttributeData Damage;  // Meta 属性

// 在 PostGameplayEffectExecute 中:
void UMyAttributeSet::PostGameplayEffectExecute(...)
{
    if (Attribute == GetDamageAttribute())
    {
        float DamageDone = GetDamage();
        SetDamage(0.0f);  // 重置
        
        float NewHealth = GetHealth() - DamageDone;
        SetHealth(FMath::Clamp(NewHealth, 0.0f, GetMaxHealth()));
        
        if (GetHealth() <= 0.0f)
        {
            // 处理死亡
        }
    }
}
```

## Lyra 中的应用

Lyra 使用 `ULyraHealthSet` 处理生命值。AttributeSet 通过 `ULyraAbilitySet` 授予。

## 参考链接

- tranek AttributeSet 章节: https://github.com/tranek/GASDocumentation
- UnrealDirective AttributeSet 说明: https://unrealdirective.com/resources/cpp-reference/gas/
