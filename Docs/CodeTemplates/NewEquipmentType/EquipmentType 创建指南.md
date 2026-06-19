# 创建新装备类型 完整指南

## 体系依赖链

```
Inventory Item Definition
    → InventoryFragment_EquippableItem (标识为可装备)
        → Equipment Definition (定义装备实例类和能力)
            → Equipment Instance (运行时实例)
                → 可以选择 Weapon Instance (如果是武器)
```

## 步骤 1: Item Definition

创建 Data Asset:
```
右键 → Miscellaneous → Data Asset → ULyraInventoryItemDefinition
命名: ID_MyItem
```

配置:
```
Fragments:
  - UInventoryFragment_EquippableItem
      EquipmentDefinition: ED_MyEquipment
  - UInventoryFragment_ReticleConfig (如果需要)
  - UInventoryFragment_SetColor (如果需要)
```

## 步骤 2: Equipment Definition

创建 Data Asset:
```
右键 → Miscellaneous → Data Asset → ULyraEquipmentDefinition
命名: ED_MyEquipment
```

C++ 类 (如果默认实例不够用):
```cpp
#pragma once
#include "Equipment/LyraEquipmentDefinition.h"
#include "MyEquipmentDefinition.generated.h"

UCLASS()
class UMyEquipmentDefinition : public ULyraEquipmentDefinition
{
    GENERATED_BODY()
public:
    UMyEquipmentDefinition();
};
```

## 步骤 3: Equipment Instance

C++ 类:
```cpp
#pragma once
#include "Equipment/LyraEquipmentInstance.h"
#include "MyEquipmentInstance.generated.h"

UCLASS()
class UMyEquipmentInstance : public ULyraEquipmentInstance
{
    GENERATED_BODY()
    
public:
    /** 装备时额外处理 */
    virtual void OnEquipped_Implementation() override;
    
    /** 卸下时清理 */
    virtual void OnUnequipped_Implementation() override;
    
    /** 生成装备在世界的 Actor (如武器模型) */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Equipment")
    TSubclassOf<AActor> SpawnedActorClass;
    
private:
    /** 生成的装备 Actor 实例 */
    UPROPERTY()
    TObjectPtr<AActor> SpawnedActor;
};
```

```cpp
void UMyEquipmentInstance::OnEquipped_Implementation()
{
    Super::OnEquipped_Implementation();
    
    if (SpawnedActorClass)
    {
        AActor* Owner = GetOwner();
        if (Owner)
        {
            FActorSpawnParameters Params;
            Params.Owner = Owner;
            Params.Instigator = Cast<APawn>(Owner);
            SpawnedActor = GetWorld()->SpawnActor<AActor>(SpawnedActorClass, Params);
            
            if (SpawnedActor)
            {
                // 附加到 Pawn 的指定插槽
                if (USceneComponent* AttachTarget = Owner->GetRootComponent())
                {
                    SpawnedActor->AttachToComponent(
                        AttachTarget,
                        FAttachmentTransformRules::SnapToTargetNotIncludingScale,
                        TEXT("WeaponSocket"));
                }
            }
        }
    }
}

void UMyEquipmentInstance::OnUnequipped_Implementation()
{
    if (SpawnedActor)
    {
        SpawnedActor->Destroy();
        SpawnedActor = nullptr;
    }
    Super::OnUnequipped_Implementation();
}
```

## 步骤 4: 在 ED_MyEquipment 中引用

配置 EquipmentDefinition:
```
InstancedType: UMyEquipmentInstance
AbilitiesToGrant:
  - ULyraAbilitySet (包含武器对应的能力)
```

## 步骤 5: 添加到玩家

在蓝图中:
```
QuickBarComponent → 设置 Slots
通过 AddItems 给玩家 ID_MyItem
```

## 关键代码位置 (Lyra 源码)

| 文件 | 路径 |
|------|------|
| ULyraEquipmentDefinition | LyraGame/Equipment/LyraEquipmentDefinition.h |
| ULyraEquipmentInstance | LyraGame/Equipment/LyraEquipmentInstance.h |
| ULyraEquipmentManagerComponent | LyraGame/Equipment/LyraEquipmentManagerComponent.h |
| ULyraQuickBarComponent | LyraGame/Equipment/LyraQuickBarComponent.h |
| ULyraGameplayAbility_FromEquipment | LyraGame/Equipment/LyraGameplayAbility_FromEquipment.h |
