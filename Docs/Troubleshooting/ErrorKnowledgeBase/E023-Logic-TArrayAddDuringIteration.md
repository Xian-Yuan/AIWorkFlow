---
id: E023
title: TArray 遍历时动态 Add 导致无限循环
category: 逻辑错误
system: 容器
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E021]
keywords: [TArray, 无限循环, 遍历时Add, 动态扩容, 编辑器卡死]
---

## 现象

编辑器卡死（无响应），或程序进入无限循环。

## 原因

遍历 TArray 时直接向正在被遍历的数组中 `Add` 新元素，导致 `Array.Num()` 不断增大，循环条件 `i < Array.Num()` 永远满足。

## 解决方案

使用临时数组收集，循环结束后统一追加：

```cpp
// ✅ 正确：用临时数组收集，循环结束后一次性 Append
TArray<TArray<FVector>> NewSegmentsToAdd;
for (int32 i = 0; i < Array.Num(); ++i)
{
    if (NeedSplit(Array[i]))
    {
        TArray<FVector> NewSegment = Split(Array[i]);
        NewSegmentsToAdd.Add(NewSegment);  // 安全：暂存到临时数组
    }
}
Array.Append(NewSegmentsToAdd);  // 循环结束后一次性合并
```

## 案例

```cpp
// ❌ 错误：直接 Add 到正在遍历的数组
for (int32 i = 0; i < Array.Num(); ++i)
{
    if (NeedSplit(Array[i]))
    {
        Array.Add(Split(Array[i]));  // 致命：Array.Num() 持续增长
    }
}
```

## 预防

- 遍历期间永远不要修改正在遍历的容器
- 需要添加新元素的场景：临时数组暂存 → 遍历结束后合并
- 需要移除元素的场景：用倒序遍历（见 E021）

## 检测关键词

[TArray, 无限循环, 遍历时Add, Add, 动态扩容]
