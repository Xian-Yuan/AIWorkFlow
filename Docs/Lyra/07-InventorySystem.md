# 背包系统

## 概念

Lyra 的 Inventory 系统使用 **Fragment 模式** — 每个 Item 由 ItemDefinition 定义，其中包含多个 Fragment 实现不同功能。

## 核心类

| 类 | 职责 |
|------|------|
| `ULyraInventoryItemDefinition` | 物品定义 — 持有 Fragment 数组 |
| `ULyraInventoryItemInstance` | 物品实例 — 运行时数据持有者 |
| `ULyraInventoryManagerComponent` | 背包管理器 (ControllerComponent) — CRUD 操作 |
| `ULyraInventoryItemFragment` | Fragment 基类 — 定义物品的某个方面 |
| `UInventoryFragment_EquippableItem` | 可装备标识 Fragment — 持有 EquipmentDefinition 引用 |
| `UInventoryFragment_ReticleConfig` | 准星配置 Fragment |
| `UInventoryFragment_SetColor` | 物品颜色 Fragment |
| `IPickupable` | 可拾取接口 |

## Fragment 模式

```
ItemDefinition (数据资产)
    ├─ DisplayName
    └─ Fragments[]
        ├─ InventoryFragment_EquippableItem (→ EquipmentDefinition)
        ├─ InventoryFragment_ReticleConfig (→ Reticle)
        └─ InventoryFragment_SetColor (→ Color)
```

Fragment 实现了"组合优于继承"的设计模式。物品的**每个方面**由一个 Fragment 定义。

## InventoryManager 组件

- 放在 **Controller** 上
- 只在服务器和本地客户端可用
- 核心操作:

```
AddItem() / RemoveItem()
FindItem() / FindItemsByDefinition()
GetItemCount() / ConsumeItem()
```

## 可拾取接口

```cpp
// Item 要实现 IPickupable
GetPickupInventory()  // 返回如何将此物品加入背包
```

## 参考链接

- X157 Inventory 详解: https://x157.github.io/UE5/LyraStarterGame/Inventory/
