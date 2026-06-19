---
id: E027
title: O(N^4) 嵌套循环导致编辑器主线程阻塞卡死
category: 逻辑错误
system: 算法
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E029]
keywords: [O(N^4), 嵌套循环, 编辑器卡死, 主线程阻塞, 性能, AABB]
---

## 现象

编辑器无响应数分钟甚至更久，UI 完全冻结。

## 原因

多层嵌套循环（4 层或更多）加上 `while(bChanged)` 重启机制，导致时间复杂度达到恐怖的 O(N^4)。对 N=5000，需要计算数万亿次。

## 解决方案

```cpp
// ✅ 正确：AABB 包围盒快速剔除 + 单趟处理
TArray<FBox2D> Bounds = PrecomputeBounds(Splines);

TMap<int32, TArray<FSplineBreakRecord>> Breaks;
for (int32 i = 0; i < Splines.Num(); ++i)
{
    for (int32 j = i + 1; j < Splines.Num(); ++j)
    {
        if (!Bounds[i].Intersect(Bounds[j])) continue;  // O(1) 快速剔除
        RecordBreaks(Splines[i], Splines[j], Breaks);
    }
}
// 一次性处理所有打断点，无需重启
ApplyAllBreaksSinglePass(Splines, Breaks);
```

## 案例

```cpp
// ❌ 错误：while(bChanged) + 4 层嵌套循环
bool bBroken = true;
while (bBroken) {
    bBroken = false;
    for (int32 i ...)
        for (int32 j ...)
            for (int32 segI ...)
                for (int32 segJ ...)
                    if (...) { Break(); bBroken = true; break; }
}
```

## 预防

- 超过 3 层循环必须用空间索引（AABB / Grid / BVH / 四叉树）
- `while(bChanged)` 全局重启机制禁止用于密集求交
- 主线程计算超过 500ms 必须拆分或加进度反馈

## 检测关键词

[O(N^4), 嵌套循环, 编辑器卡死, AABB, 主线程阻塞]
