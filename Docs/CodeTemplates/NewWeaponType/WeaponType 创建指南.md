# 创建新武器类型 完整指南

## 体系依赖链

```
Equipment System (已建好的装备)
    └─ WeaponInstance (装备 + 动画集)
        └─ RangedWeaponInstance (远程: 子弹、散布)
            └─ GameplayAbility_RangedWeapon (开火能力基类)
                └─ GA_Weapon_Fire (具体武器开火行为)
```

## 步骤 1: 创建 WeaponInstance

### C++ 类 (可选 — 大部分在 BP 中即可)

```cpp
#pragma once
#include "Weapons/LyraWeaponInstance.h"
#include "MyWeaponInstance.generated.h"

UCLASS()
class UMyWeaponInstance : public ULyraWeaponInstance
{
    GENERATED_BODY()
public:
    /** 伤害值 */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Weapon")
    float BaseDamage = 35.0f;
    
    /** 射程 */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Weapon")
    float MaxRange = 5000.0f;
    
    /** 子弹散布 */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Weapon")
    float SpreadAngle = 0.5f;
};
```

### 推荐路径 (纯蓝图)
1. 基于 `B_WeaponInstance_Base` 创建子蓝图
2. 配置装备/卸下动画集
3. 设置武器参数

## 步骤 2: 创建 EquipmentDefinition 引用 WeaponInstance

```
右键 → Miscellaneous → Data Asset → ULyraEquipmentDefinition
命名: ED_MyWeapon
配置:
  - InstancedType: ULyraWeaponInstance (或你的 BP_WeaponInstance)
  - AbilitySets:
      - LAS_MyWeaponAbilities (包含 GA_Weapon_Fire 等)
```

## 步骤 3: 创建远程武器能力

### C++ 基类 (可选)

```cpp
#pragma once
#include "Weapons/LyraGameplayAbility_RangedWeapon.h"
#include "MyRangedAbility.generated.h"

UCLASS()
class UMyRangedWeaponAbility : public ULyraGameplayAbility_RangedWeapon
{
    GENERATED_BODY()
    
protected:
    /** 生成 TargetData 的逻辑 */
    virtual void OnTargetDataReadyCallback(
        const FGameplayAbilityTargetDataHandle& InData,
        FGameplayTag ApplicationTag) override;
        
    /** 开火时的额外处理 */
    virtual void ActivateAbility(...) override;
};
```

### 推荐路径 — 从现有复制
- 复制 `GA_Weapon_Fire` 蓝图
- 修改: 投射物类、伤害 GE、开火动画
- 不同武器 (手枪/步枪/霰弹枪) 继承 `GA_Weapon_Fire`

## 步骤 4: 创建投射物 (可选)

```cpp
#pragma once
#include "Engine/EngineTypes.h"
#include "MyProjectile.generated.h"

UCLASS()
class AMyProjectile : public AActor
{
    GENERATED_BODY()
    
public:
    UPROPERTY()
    TObjectPtr<UProjectileMovementComponent> MovementComp;
    
    UPROPERTY()
    TObjectPtr<USphereComponent> CollisionComp;
    
    /** 命中的效果类 */
    UPROPERTY(EditDefaultsOnly)
    TSubclassOf<UGameplayEffect> DamageEffectClass;
    
    /** 伤害值 (SetByCaller) */
    UPROPERTY(EditDefaultsOnly)
    FGameplayTag DamageTag;
    
    FGameplayAbilitySpecHandle AbilityHandle;
    TWeakObjectPtr<UAbilitySystemComponent> SourceASC;
    
    virtual void NotifyHit(
        class UPrimitiveComponent* MyComp,
        AActor* Other,
        class UPrimitiveComponent* OtherComp,
        bool bSelfMoved,
        FVector HitLocation,
        FVector HitNormal,
        FVector NormalImpulse,
        const FHitResult& Hit) override;
};
```

## 步骤 5: 创建 ItemDefinition + 添加到背包

```cpp
// 在蓝图中调用:
// QuickBarComponent → AddItem(InventoryItemDefinition)
// 或通过 GameFeature Action 配置
```

## 关键代码位置 (Lyra 源码)

| 文件 | 路径 |
|------|------|
| ULyraWeaponInstance | LyraGame/Weapons/LyraWeaponInstance.h |
| ULyraRangedWeaponInstance | LyraGame/Weapons/LyraRangedWeaponInstance.h |
| ULyraWeaponStateComponent | LyraGame/Weapons/LyraWeaponStateComponent.h |
| ULyraGameplayAbility_RangedWeapon | LyraGame/Weapons/LyraGameplayAbility_RangedWeapon.h |
| AWeaponSpawner | LyraGame/Weapons/LyraWeaponSpawner.h |
