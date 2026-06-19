---
id: E025
title: BFS 队列越界与重复访问
category: 逻辑错误
system: 容器
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E021, E023]
keywords: [BFS, 队列, 越界, 重复入队, 未标记已访问, Queue]
---

## 现象

队列操作时越界崩溃，或无限循环（同一元素被反复入队出队）。

## 原因

1. `while (Queue.Num() >= 0)` 应为 `> 0`
2. 未使用 `bGrouped` / `bVisited` 标记已访问节点
3. 新元素入队时未立即标记为已访问（出队时再标记会导致重复入队）

## 解决方案

```cpp
// ✅ 正确：严格的边界检查 + 入队即标记
TArray<int32> Queue;
Queue.Add(i);
DataList[i].bGrouped = true;  // 关键：入队即标记

while (Queue.Num() > 0)       // 正确：> 0
{
    int32 CurrentIdx = Queue[0];
    Queue.RemoveAt(0);

    for (int32 j = 0; j < DataList.Num(); ++j)
    {
        if (DataList[j].bGrouped) continue;  // 跳过已处理
        if (Dist < Threshold)
        {
            Queue.Add(j);
            DataList[j].bGrouped = true;  // 入队即标记
        }
    }
}
```

## 预防

- 队列循环条件永远是 `> 0` 不是 `>= 0`
- 入队时立即标记已访问，不要等到出队时

## 检测关键词

[BFS, Queue, 越界, 重复入队, bGrouped, 已标记]
