// Lyra 框架能力实现

#include "GA_LyraAbility示例.h"

// 如果是装备能力
#include "Equipment/LyraEquipmentInstance.h"
// 如果是武器能力
// #include "Weapons/LyraWeaponInstance.h"

UGA_MyLyraAbility::UGA_MyLyraAbility()
{
    // Lyra 能力的默认设置
    InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
    NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;
    
    // 使用 Lyra 的 Tag 激活机制
    // 不需要在此绑定输入，由 LyraInputConfig + AbilitySet 处理
}

ULyraEquipmentInstance* UGA_MyLyraAbility::GetAssociatedEquipment() const
{
    // 装备能力的 SourceObject 在 EquipmentManager 授能时设为 EquipmentInstance
    if (FGameplayAbilitySpec* Spec = FindAbilitySpec())
    {
        return Cast<ULyraEquipmentInstance>(Spec->SourceObject.Get());
    }
    return nullptr;
}

ULyraWeaponInstance* UGA_MyLyraAbility::GetAssociatedWeapon() const
{
    // 武器能力需要先获取 EquipmentInstance 再转型
    if (ULyraEquipmentInstance* EquipInst = GetAssociatedEquipment())
    {
        return Cast<ULyraWeaponInstance>(EquipInst);
    }
    return nullptr;
}
