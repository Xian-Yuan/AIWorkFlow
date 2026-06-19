---
id: E026
title: DynamicMeshComponent 材质槽污染导致 HISM 材质丢失
category: 逻辑错误
system: 渲染
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E028]
keywords: [DynamicMeshComponent, ConfigureMaterialSet, 材质槽, 污染, HISM]
---

## 现象

同 Actor 下的 HISM 材质槽被重置为灰色空槽，材质 ID 映射错乱。

## 原因

在 `DynamicMeshComponent` 上使用 `ConfigureMaterialSet` 强行分配一组材质槽（如 6 个），覆盖了同 Actor 下 HISM 的材质槽。

## 解决方案

使用 `SetMaterial` 精确设置，只分配需要的材质槽：

```cpp
// ❌ 错误：配置 6 个空槽覆盖了同 Actor 下 HISM 的材质
TargetComponent->ConfigureMaterialSet({Mat1, Mat2, Mat3, Mat4, Mat5, Mat6});

// ✅ 正确：只 SetMaterial 所需的最小集合
TargetComponent->SetMaterial(0, WallMat);   // MaterialID = 0
TargetComponent->SetMaterial(1, RoofMat);   // MaterialID = 1

// 生成三角形时指定 MaterialID
AppendOrientedTriangleWithUV(..., 0, ...);  // 使用 MaterialID 0
PrimOptions.MaterialID = 1;                 // 使用 MaterialID 1
```

## 预防

- 优先用 `SetMaterial` 而非 `ConfigureMaterialSet`
- 控制生成的三角形 MaterialID 不超过设置的材料数

## 检测关键词

[DynamicMeshComponent, ConfigureMaterialSet, 材质槽, HISM, 材质丢失]
