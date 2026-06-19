// GameplayAbility 实现模板

#include "GA_MyAbility.h"

// Ability Task 头文件
#include "Abilities/Tasks/AbilityTask_PlayMontageAndWait.h"
#include "Abilities/Tasks/AbilityTask_WaitTargetData.h"
#include "Abilities/Tasks/AbilityTask_WaitInputPress.h"
#include "AbilitySystemBlueprintLibrary.h"

UGA_MyAbility::UGA_MyAbility()
{
    // ====== 默认配置 ======
    
    // 实例化策略
    InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
    
    // 网络执行策略
    NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;
    
    // 复制输入事件
    bReplicateInputDirectly = false;
    
    // 服务器保留死亡后结束
    NetSecurityPolicy = EGameplayAbilityNetSecurityPolicy::ClientOrServer;
    
    // 默认冷却时间
    CooldownGameplayEffectClass = nullptr; // 在蓝图中通过设置冷却 GE 来配置
    
    // 默认消耗
    CostGameplayEffectClass = nullptr;
}

bool UGA_MyAbility::CanActivateAbility(
    const FGameplayAbilitySpecHandle Handle,
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayTagContainer* SourceTags,
    const FGameplayTagContainer* TargetTags,
    FGameplayTagContainer* OptionalRelevantTags) const
{
    // 调用基类检查 (Tag 阻塞/要求等)
    if (!Super::CanActivateAbility(Handle, ActorInfo, SourceTags, TargetTags, OptionalRelevantTags))
    {
        return false;
    }

    // ====== 自定义前置条件 ======
    // 示例: 检查拥有者是否存活
    // AActor* Owner = GetOwningActorFromActorInfo();
    // if (!IsValid(Owner)) return false;

    return true;
}

void UGA_MyAbility::ActivateAbility(
    const FGameplayAbilitySpecHandle Handle,
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo,
    const FGameplayEventData* TriggerEventData)
{
    // 调用基类
    Super::ActivateAbility(Handle, ActorInfo, ActivationInfo, TriggerEventData);

    // ====== 提交消耗 ======
    // 消耗资源 + 启动冷却
    if (!CommitAbility(Handle, ActorInfo, ActivationInfo))
    {
        // 提交失败 (不足资源/冷却中)
        EndAbility(Handle, ActorInfo, ActivationInfo, true, true);
        return;
    }

    // ====== 播放蒙太奇 ======
    if (ActivateMontage)
    {
        UAbilityTask_PlayMontageAndWait* MontageTask =
            UAbilityTask_PlayMontageAndWait::CreatePlayMontageAndWaitProxy(
                this,
                NAME_None,                     // TaskInstanceName
                ActivateMontage,               // MontageToPlay
                1.0f,                          // Rate
                NAME_None,                     // StartSection
                false,                         // bStopWhenAbilityEnds
                1.0f                           // AnimRootMotionTranslationScale
            );

        if (MontageTask)
        {
            MontageTask->OnCompleted.AddDynamic(this, &UGA_MyAbility::OnMontageCompleted);
            MontageTask->OnInterrupted.AddDynamic(this, &UGA_MyAbility::OnMontageInterrupted);
            MontageTask->ReadyForActivation();
            return;
        }
    }

    // 没有蒙太奇，直接完成
    OnMontageCompleted();
}

void UGA_MyAbility::EndAbility(
    const FGameplayAbilitySpecHandle Handle,
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo,
    bool bReplicateEndAbility,
    bool bWasCancelled)
{
    // ====== 清理 ======
    // 停止蒙太奇
    if (ActivateMontage && ActorInfo && ActorInfo->AnimInstance)
    {
        ActorInfo->AnimInstance->Montage_Stop(0.0f, ActivateMontage);
    }

    Super::EndAbility(Handle, ActorInfo, ActivationInfo, bReplicateEndAbility, bWasCancelled);
}

void UGA_MyAbility::ApplyCost(
    const FGameplayAbilitySpecHandle Handle,
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo) const
{
    Super::ApplyCost(Handle, ActorInfo, ActivationInfo);
}

void UGA_MyAbility::ApplyCooldown(
    const FGameplayAbilitySpecHandle Handle,
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo) const
{
    Super::ApplyCooldown(Handle, ActorInfo, ActivationInfo);
}

void UGA_MyAbility::NativeOnAbilityFailedToActivate(
    const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayTagContainer& FailedReason) const
{
    Super::NativeOnAbilityFailedToActivate(ActorInfo, FailedReason);
}

void UGA_MyAbility::OnMontageCompleted()
{
    // ====== 在这里实现能力的主要逻辑 ======
    // 示例: 生成投射物、对目标应用效果等
    // ApplyEffectsToTarget(TargetData);

    // ====== 结束能力 ======
    bool bReplicateEnd = true;
    bool bWasCancelled = false;
    EndAbility(CurrentSpecHandle, CurrentActorInfo, CurrentActivationInfo, bReplicateEnd, bWasCancelled);
}

void UGA_MyAbility::OnMontageInterrupted()
{
    bool bReplicateEnd = true;
    bool bWasCancelled = true;
    EndAbility(CurrentSpecHandle, CurrentActorInfo, CurrentActivationInfo, bReplicateEnd, bWasCancelled);
}

void UGA_MyAbility::ApplyEffectsToTarget(const FGameplayAbilityTargetDataHandle& TargetData)
{
    if (!HasAuthorityOrPredictionKey(CurrentActorInfo, &CurrentActivationInfo))
    {
        return;
    }

    if (TargetEffect && TargetData.IsValid())
    {
        // 对每个目标应用效果
        for (int32 i = 0; i < TargetData.Num(); ++i)
        {
            FGameplayAbilityTargetData* Data = TargetData.Get(i);
            if (Data)
            {
                TArray<FActiveGameplayEffectHandle> EffectHandles =
                    ApplyGameplayEffectToTarget(TargetEffect, Data, 1.0f, 1);
            }
        }
    }
}
