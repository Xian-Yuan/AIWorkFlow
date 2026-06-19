// AttributeSet 实现

#include "MyAttributeSet.h"
#include "GameplayEffectExtension.h"     // FGameplayEffectModCallbackData
#include "Net/UnrealNetwork.h"

UMyAttributeSet::UMyAttributeSet()
{
    // 初始化默认值
    Health.Initialize(100.0f);
    MaxHealth.Initialize(100.0f);
    Stamina.Initialize(100.0f);
    MaxStamina.Initialize(100.0f);
    MoveSpeed.Initialize(600.0f);
    
    IncomingDamage.Initialize(0.0f);
    IncomingHealing.Initialize(0.0f);
}

// ====== 复制 ======

void UMyAttributeSet::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, Health, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, MaxHealth, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, Stamina, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, MaxStamina, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, MoveSpeed, COND_None, REPNOTIFY_Always);
    // 不复制 Meta 属性
}

// ====== PreAttributeChange — Clamp 值 ======

void UMyAttributeSet::PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue)
{
    Super::PreAttributeChange(Attribute, NewValue);

    if (Attribute == GetHealthAttribute())
    {
        NewValue = FMath::Clamp(NewValue, 0.0f, GetMaxHealth());
    }
    else if (Attribute == GetStaminaAttribute())
    {
        NewValue = FMath::Clamp(NewValue, 0.0f, GetMaxStamina());
    }
    else if (Attribute == GetMoveSpeedAttribute())
    {
        NewValue = FMath::Max(NewValue, 0.0f);
    }
}

// ====== PostGameplayEffectExecute — 处理伤害/治疗 ======

void UMyAttributeSet::PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data)
{
    Super::PostGameplayEffectExecute(Data);

    // 处理伤害
    if (Data.EvaluatedData.Attribute == GetIncomingDamageAttribute())
    {
        const float LocalDamageDone = GetIncomingDamage();
        SetIncomingDamage(0.0f);  // 重置

        if (LocalDamageDone > 0.0f)
        {
            const float NewHealth = GetHealth() - LocalDamageDone;
            SetHealth(FMath::Clamp(NewHealth, 0.0f, GetMaxHealth()));

            // 如果死亡
            if (GetHealth() <= 0.0f && !Data.EvaluatedData.bIsDamageFromSelf)
            {
                // 在这里处理死亡事件
                // 可以通过 ASC 发送 GameplayEvent
                if (Data.Target.AbilitySystemComponent)
                {
                    FGameplayEventData EventData;
                    EventData.Instigator = Data.EffectSpec.GetContext().GetInstigator();
                    EventData.Target = Data.Target.AbilitySystemComponent->GetOwnerActor();
                    Data.Target.AbilitySystemComponent->HandleGameplayEvent(
                        FGameplayTag::RequestGameplayTag(FName("Event.Died")), &EventData);
                }
            }
        }
    }
    // 处理治疗
    else if (Data.EvaluatedData.Attribute == GetIncomingHealingAttribute())
    {
        const float LocalHealingDone = GetIncomingHealing();
        SetIncomingHealing(0.0f);

        if (LocalHealingDone > 0.0f)
        {
            const float NewHealth = GetHealth() + LocalHealingDone;
            SetHealth(FMath::Clamp(NewHealth, 0.0f, GetMaxHealth()));
        }
    }
}

void UMyAttributeSet::PreAttributeBaseChange(const FGameplayAttribute& Attribute, float& NewValue) const
{
    Super::PreAttributeBaseChange(Attribute, NewValue);
}

// ====== RepNotifies ======

void UMyAttributeSet::OnRep_Health(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, Health, OldValue);
}

void UMyAttributeSet::OnRep_MaxHealth(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, MaxHealth, OldValue);
}

void UMyAttributeSet::OnRep_Stamina(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, Stamina, OldValue);
}

void UMyAttributeSet::OnRep_MaxStamina(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, MaxStamina, OldValue);
}

void UMyAttributeSet::OnRep_MoveSpeed(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, MoveSpeed, OldValue);
}
