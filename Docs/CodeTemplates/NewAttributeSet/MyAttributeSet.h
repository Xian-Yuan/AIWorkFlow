// AttributeSet 完整模板
// 必须用 C++ 实现，Blueprint 无法创建 AttributeSet

#pragma once

#include "CoreMinimal.h"
#include "AttributeSet.h"
#include "AbilitySystemComponent.h"
#include "MyAttributeSet.generated.h"

/**
 * Macro: 为属性生成 Getter/Setter
 * 用法: ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health)
 * 生成: float GetHealth() / void SetHealth(float) / FGameplayAttribute GetHealthAttribute()
 */
#define ATTRIBUTE_ACCESSORS(ClassName, PropertyName) \
    GAMEPLAYATTRIBUTE_PROPERTY_GETTER(ClassName, PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_GETTER(PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_SETTER(PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_INITTER(PropertyName)

/**
 * 自定义属性集
 * 每个类的属性集作为 UObject 子对象注册到 ASC
 */
UCLASS()
class MYGAME_API UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()

public:
    UMyAttributeSet();

    // ====== 属性定义 ======
    // 使用 FGameplayAttributeData 类型，必须标记 Replicated

    /** 生命值 */
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Health, Category = "Attributes")
    FGameplayAttributeData Health;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health);

    /** 最大生命值 */
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxHealth, Category = "Attributes")
    FGameplayAttributeData MaxHealth;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, MaxHealth);

    /** 体力 */
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Stamina, Category = "Attributes")
    FGameplayAttributeData Stamina;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, Stamina);

    /** 最大体力 */
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxStamina, Category = "Attributes")
    FGameplayAttributeData MaxStamina;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, MaxStamina);

    /** 移动速度 */
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MoveSpeed, Category = "Attributes")
    FGameplayAttributeData MoveSpeed;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, MoveSpeed);

    // ====== Meta 属性 (不复制，用于中间计算) ======
    /** 受伤值 (Meta: 不复制，在 PostGameplayEffectExecute 中处理) */
    UPROPERTY(BlueprintReadOnly, Category = "Attributes")
    FGameplayAttributeData IncomingDamage;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, IncomingDamage);

    /** 治疗值 (Meta) */
    UPROPERTY(BlueprintReadOnly, Category = "Attributes")
    FGameplayAttributeData IncomingHealing;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, IncomingHealing);

public:
    // ====== 关键回调 ======

    /** 属性值即将变更前 (用于 Clamp) */
    virtual void PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue) override;

    /** GameplayEffect 执行完毕后 (用于处理 Damage/Healing) */
    virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data) override;

    /** 被效果修改时 (更底层) */
    virtual void PreAttributeBaseChange(const FGameplayAttribute& Attribute, float& NewValue) const override;

protected:
    // ====== RepNotifies ======
    UFUNCTION()
    virtual void OnRep_Health(const FGameplayAttributeData& OldValue);

    UFUNCTION()
    virtual void OnRep_MaxHealth(const FGameplayAttributeData& OldValue);

    UFUNCTION()
    virtual void OnRep_Stamina(const FGameplayAttributeData& OldValue);

    UFUNCTION()
    virtual void OnRep_MaxStamina(const FGameplayAttributeData& OldValue);

    UFUNCTION()
    virtual void OnRep_MoveSpeed(const FGameplayAttributeData& OldValue);
};
