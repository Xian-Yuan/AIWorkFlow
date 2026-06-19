# 装备系统

## 概念

装备系统建立在 Inventory 系统之上，是武器系统的基础。装备是 Inventory Item + 装备标识 Fragment。

## 核心类

| 类 | 位置 | 职责 |
|------|------|------|
| `ULyraEquipmentDefinition` | Equipment/ | 装备定义 — 实例类 + 能力集 |
| `ULyraEquipmentInstance` | Equipment/ | 装备实例 — 生成/销毁装备 Actor |
| `ULyraEquipmentManagerComponent` | Equipment/ | 装备管理器 (PawnComponent) — 装备/卸下 |
| `ULyraQuickBarComponent` | Equipment/ | 快捷栏 (ControllerComponent) — 玩家切换装备接口 |
| `ULyraGameplayAbility_FromEquipment` | Equipment/ | 装备能力基类 — 自动获取 SourceObject 为装备实例 |

## 架构关系

```
Inventory Item
    └─ InventoryFragment_EquippableItem (标识为装备)
        └─ EquipmentDefinition
            ├─ 指定 EquipmentInstance 类
            └─ 指定要授予的能力集 (AbilitySets)

QuickBarComponent (Controller)
    └─ EquipmentManagerComponent (Pawn)
        └─ EquipmentList
            ├─ EquipmentInstance
            │   ├─ 生成装备 Actor
            │   ├─ 授予能力
            │   └─ OnEquipped / OnUnequipped
            └─ ...
```

## 装备流程

```
1. QuickBarComponent::SetActiveSlotIndex()
2. └─ UnequipItemInSlot(旧槽)
3. └─ EquipItemInSlot(新槽)
4.     └─ EquipmentManagerComponent::EquipItem()
5.         └─ FLyraEquipmentList::AddEntry()
6.             ├─ 创建 EquipmentInstance
7.             ├─ 设置 SourceObject = EquipmentInstance
8.             ├─ 授予能力 (AbilitySets → ASC)
9.             └─ 调用 OnEquipped()
```

## 关键代码位置

```
Source/LyraGame/Equipment/
├── LyraEquipmentDefinition.h
├── LyraEquipmentInstance.h
├── LyraEquipmentManagerComponent.h
├── LyraGameplayAbility_FromEquipment.h
└── LyraQuickBarComponent.h
```

## 参考链接

- X157 Equipment 详解: https://x157.github.io/UE5/LyraStarterGame/Equipment/
