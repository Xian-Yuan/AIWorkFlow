---
id: E028
title: 材质数组越界访问
category: 逻辑错误
system: 渲染
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E026]
keywords: [材质数组, 越界, IsValidIndex, 材质槽, GetNumMaterials]
---

## 现象

访问材质数组时崩溃或读取出错。

## 原因

网格体的材质槽数量多于配置数组的长度，直接使用 `SlotIndex` 访问导致越界。

## 解决方案

```cpp
// ✅ 正确：先判断配置数组是否包含该索引
for (int32 SlotIndex = 0; SlotIndex < MeshComp->GetNumMaterials(); ++SlotIndex)
{
    if (SelectedSet.Materials.IsValidIndex(SlotIndex))
    {
        UMaterialInterface* Mat = SelectedSet.Materials[SlotIndex];
        if (Mat)
        {
            MeshComp->SetMaterial(SlotIndex, Mat);
        }
    }
}
```

## 案例

```cpp
// ❌ 错误：无边界检查
for (int32 SlotIndex = 0; SlotIndex < MeshComp->GetNumMaterials(); ++SlotIndex)
{
    UMaterialInterface* Mat = SelectedSet.Materials[SlotIndex];  // 可能越界
    MeshComp->SetMaterial(SlotIndex, Mat);
}
```

## 预防

- 所有数组访问前加 `IsValidIndex()` 保护
- 使用 `TArray::GetData()` 和偏移量时确保偏移在范围内

## 检测关键词

[材质数组, 越界, IsValidIndex, 材质槽, 数组边界]
