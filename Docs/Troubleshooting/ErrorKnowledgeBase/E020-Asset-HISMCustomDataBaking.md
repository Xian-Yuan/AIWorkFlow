---
id: E020
title: HISM 实例 CustomData 烘焙丢失
category: 资产错误
system: 渲染
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E027]
keywords: [HISM, CustomData, 烘焙, VertexColor, 实例随机, Merge]
---

## 现象

HISM 每实例的 CustomData（如稳定随机 Seed）在烘焙/合并为静态网格后丢失，材质表现不一致。

## 原因

直接 Merge HISM 不会自动保存每实例的 CustomData。CustomData 是运行时实例数据，烘焙成静态网格时需要转为 VertexColor 等持久化属性。

## 解决方案

```cpp
// 生成阶段：把稳定 Seed 写到 HISM 每实例 CustomData
HISM->SetNumCustomDataFloats(1);
HISM->SetCustomDataValue(InstanceIndex, 0, Seed01, bMarkRenderStateDirty);

// 烘焙前：展开 HISM 为临时网格，把 Seed 写入 VertexColor.R
UGeometryScriptLibrary_MeshVertexColorFunctions::SetMeshConstantVertexColor(
    InstanceMesh,
    FLinearColor(Seed01, 0.0f, 0.0f, 1.0f),
    ColorFlags, true, nullptr);
```

## 预防

- 稳定 Seed 由几何身份（楼层索引、边索引、跨度、实例索引）共同生成
- 仅对需要随机表现的 HISM 走"展开写顶点色"路径
- 原生 Merge 必须保持 `bBakeVertexDataToMesh = true`

## 检测关键词

[HISM, CustomData, 烘焙, VertexColor, 合并, 实例随机]
