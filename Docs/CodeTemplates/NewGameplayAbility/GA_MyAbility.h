// 自定义 GameplayAbility 完整模板
// UE5.7 + Lyra + GAS

#pragma once

#include "CoreMinimal.h"
#include "Abilities/GameplayAbility.h"
// 如果继承 Lyra 基类:
// #include "AbilitySystem/LyraGameplayAbility.h"
#include "GA_MyAbility.generated.h"

/**
 * 自定义能力 — 基于 UGameplayAbility
 * 
 * 如果使用 Lyra 框架，基类应改为 ULyraGameplayAbility:
 * UCLASS()
 * class UGA_MyAbility : public ULyraGameplayAbility
 */
UCLASS()
class MYGAME_API UGA_MyAbility : public UGameplayAbility
{
    GENERATED_BODY()

public:
    UGA_MyAbility();

    // ====== 必须实现的接口 ======

    /** 检查是否可激活 — 可在蓝图中覆盖 */
    virtual bool CanActivateAbility(
        const FGameplayAbilitySpecHandle Handle,
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayTagContainer* SourceTags,
        const FGameplayTagContainer* TargetTags,
        FGameplayTagContainer* OptionalRelevantTags
    ) const override;

    /** 激活能力 — 必须实现 */
    virtual void ActivateAbility(
        const FGameplayAbilitySpecHandle Handle,
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayAbilityActivationInfo ActivationInfo,
        const FGameplayEventData* TriggerEventData
    ) override;

    /** 结束能力 */
    virtual void EndAbility(
        const FGameplayAbilitySpecHandle Handle,
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayAbilityActivationInfo ActivationInfo,
        bool bReplicateEndAbility,
        bool bWasCancelled
    ) override;

    // ====== 常用可重写 ======

    /** 消耗资源 + 启动冷却 */
    virtual void ApplyCost(
        const FGameplayAbilitySpecHandle Handle,
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayAbilityActivationInfo ActivationInfo
    ) const override;

    /** 应用冷却 */
    virtual void ApplyCooldown(
        const FGameplayAbilitySpecHandle Handle,
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayAbilityActivationInfo ActivationInfo
    ) const override;

    // ====== 错误处理 ======

    /** 激活失败时的回调 */
    virtual void NativeOnAbilityFailedToActivate(
        const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayTagContainer& FailedReason
    ) const override;

protected:
    // ====== 常用配置 (可在子类/蓝图覆写) ======

    /** 播放的蒙太奇 */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    TObjectPtr<UAnimMontage> ActivateMontage;

    /** 应用的效果 (激活时对自己) */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    TSubclassOf<UGameplayEffect> SelfEffect;

    /** 对目标应用的效果 */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    TSubclassOf<UGameplayEffect> TargetEffect;

private:
    /** 播放蒙太奇并等待完成 — 内部辅助 */
    void PlayMontageAndWaitForCompletion();

    /** 蒙太奇完成回调 */
    UFUNCTION()
    void OnMontageCompleted();

    /** 蒙太奇中断回调 */
    UFUNCTION()
    void OnMontageInterrupted();

    /** 应用施加的效果到目标 */
    void ApplyEffectsToTarget(const FGameplayAbilityTargetDataHandle& TargetData);
};
