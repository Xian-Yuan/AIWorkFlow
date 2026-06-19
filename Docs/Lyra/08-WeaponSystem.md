# 武器系统

## 概念

武器系统建立在 Equipment 系统之上，进一步特化了武器的行为。

## 核心类

| 类 | 基类 | 职责 |
|------|------|------|
| `ULyraWeaponInstance` | `ULyraEquipmentInstance` | 武器实例 — 装备/卸下动画集 |
| `ULyraRangedWeaponInstance` | `ULyraWeaponInstance` | 远程武器 — 子弹、精度、散布 |
| `ULyraWeaponStateComponent` | UActorComponent | 武器状态 (ControllerComponent) — 命中标记 |
| `ULyraGameplayAbility_RangedWeapon` | `ULyraGameplayAbility_FromEquipment` | 远程武器能力基类 |
| `AWeaponSpawner` | AActor | 武器生成器 |

## 类层次

```
Inventory Item
    └─ EquippableItem (Fragment)
        └─ EquipmentDefinition
            └─ WeaponInstance
                ├─ B_WeaponInstance_Pistol
                ├─ B_WeaponInstance_Rifle
                ├─ B_WeaponInstance_Shotgun
                └─ B_WeaponInstance_NetShooter
```

## 远程武器能力

`ULyraGameplayAbility_RangedWeapon` 在激活时:

```
1. 生成 TargetData (根据武器位置)
2. 对命中目标应用 GameplayEffect
3. 处理子弹散布、精度
4. 监听"开火失败"事件 → 播放动画蒙太奇
```

## 能力蓝图

| 能力 | 描述 |
|------|------|
| `GA_Weapon_Fire` | 基础开火能力 (基类) |
| `GA_Weapon_Fire_Pistol` | 手枪开火 |
| `GA_Weapon_Fire_Rifle_Auto` | 步枪自动开火 |
| `GA_Weapon_Fire_Shotgun` | 霰弹枪开火 |
| `GA_Melee` | 近战能力 |

## 参考链接

- X157 Weapon 详解: https://x157.github.io/UE5/LyraStarterGame/Weapons/
