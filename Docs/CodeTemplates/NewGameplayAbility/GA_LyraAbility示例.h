// 基于 ULyraGameplayAbility 的模板
// 大多数 Lyra 框架中的能力应使用此基类

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystem/LyraGameplayAbility.h"  // 注意路径
#include "GA_LyraAbility示例.generated.h"

/**
 * Lyra 框架能力模板
 * 
 * 相比 UGameplayAbility 提供了:
 * - 与 Lyra Equipment/Weapon 系统的集成
 * - SourceObject 自动指向 EquipmentInstance
 * - 更好的 Tag 处理
 * - 激活失败时的 GameplayMessage 广播
 */
UCLASS()
class MYGAME_API UGA_MyLyraAbility : public ULyraGameplayAbility
{
    GENERATED_BODY()

public:
    UGA_MyLyraAbility();

    // ====== 获取对应的装备实例 (如果是装备能力) ======
    UFUNCTION(BlueprintPure, Category = "Ability")
    ULyraEquipmentInstance* GetAssociatedEquipment() const;

    // ====== 获取对应的武器实例 (如果是武器能力) ======
    UFUNCTION(BlueprintPure, Category = "Ability")
    ULyraWeaponInstance* GetAssociatedWeapon() const;

protected:
    /** 激活时对自己添加的 Tag */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    FGameplayTagContainer ActivateOwnedTags;

    /** 激活时需要拥有的 Tag (在 ASC 上) */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    FGameplayTagContainer ActivationRequiredTags;

    /** 激活时阻塞的 Tag */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
    FGameplayTagContainer ActivationBlockedTags;
};
