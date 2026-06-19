---
id: E022
title: 二维射线线段求交时浮点数除零
category: 逻辑错误
system: 数学
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [浮点数除零, 射线求交, IsNearlyZero, 叉积, NaN]
---

## 现象

射线与线段求交时结果不稳定，出现 NaN 值或跨线程崩溃。

## 原因

射线与线段平行或共线时，叉积 `r_cross_s` 为 0，直接用于除法会产生 NaN 或 Infinity。

## 解决方案

```cpp
// ✅ 正确：除法前用 FMath::IsNearlyZero 保护
float r_cross_s = r.X * s.Y - r.Y * s.X;

if (FMath::IsNearlyZero(r_cross_s, 1e-4f))
{
    // 射线与线段平行，无有效交点
    return false;
}

float t = (q_minus_p.X * s.Y - q_minus_p.Y * s.X) / r_cross_s;
```

## 预防

- 所有浮点数除法前检查除数是否接近 0
- 使用 `FMath::IsNearlyZero(Value, Tolerance)` 而非 `== 0.0f`
- 容差 `1e-4f` 对 UE 世界单位（厘米）足够

## 检测关键词

[浮点数, 除零, IsNearlyZero, NaN, 叉积, 射线求交]
