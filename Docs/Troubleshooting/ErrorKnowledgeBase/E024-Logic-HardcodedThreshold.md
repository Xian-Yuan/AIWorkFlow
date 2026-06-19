---
id: E024
title: 使用硬编码绝对阈值导致分类失效
category: 逻辑错误
system: 数学
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [硬编码阈值, 分类, Percentile, 动态推导, 数据集分布]
---

## 现象

在不同缩放级别的场景中，100% 的数据被划分为同一类，分类逻辑完全失效。

## 原因

使用了硬编码的固定数值（如 `Height >= 5000.0f = 高层建筑`），当场景尺度变化时，该固定值不再有效。

## 解决方案

使用百分位数（Percentile）动态推导：

```cpp
// ✅ 正确：对数据排序，提取前 N% 的分类
Buildings.Sort([](const FBuildingData& A, const FBuildingData& B) {
    return A.Height > B.Height;  // 降序
});

int32 HighRiseCount = FMath::RoundToInt(Buildings.Num() * 0.30f);  // 最高 30%
for (int32 i = 0; i < HighRiseCount && i < Buildings.Num(); ++i)
{
    HighRises.Add(Buildings[i]);
}
```

## 案例

```cpp
// ❌ 错误：硬编码阈值
float HighRiseHeightThreshold = 5000.0f;
for (FBuildingData& Data : Buildings)
{
    if (Data.Height >= HighRiseHeightThreshold)
        HighRises.Add(Data);  // 微缩场景中无一入选
}
```

## 预防

- 所有数值分类先用数据分布分析
- 优先用百分位数、标准差、中位数绝对偏差等统计方法
- 绝不在坐标/尺寸维度上使用硬编码绝对阈值

## 检测关键词

[硬编码阈值, 分类, Percentile, 动态推导, 绝对阈值]
