---
id: E021
title: TArray 正序遍历时 RemoveAt 导致元素跳过
category: 逻辑错误
system: 容器
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E023]
keywords: [TArray, RemoveAt, 正序遍历, 元素跳过, 索引越界]
---

## 现象

遍历 TArray 时按条件移除元素，结果**不是所有**符合条件的元素都被移除，或索引越界崩溃。

## 原因

正序遍历（`i` 从 0 递增）并在循环内 `RemoveAt(i)` 会导致后续元素前移，`i++` 后跳过紧挨着的下一个元素。

## 解决方案

用**倒序遍历**：

```cpp
// ✅ 正确：倒序遍历，移除不影响未遍历的索引
for (int32 i = Array.Num() - 1; i >= 0; --i)
{
    if (ShouldRemove(Array[i]))
    {
        Array.RemoveAt(i);
    }
}
```

## 案例

```cpp
// ❌ 错误：正序 RemoveAt，索引 1 的元素被移除后，原索引 2 的移到 1，i++ 后跳到 2，跳过了一个元素
for (int32 i = 0; i < Array.Num(); ++i)
{
    if (ShouldRemove(Array[i]))
    {
        Array.RemoveAt(i);
    }
}

// ✅ 正确：倒序
for (int32 i = Array.Num() - 1; i >= 0; --i)
{
    if (ShouldRemove(Array[i]))
    {
        Array.RemoveAt(i);
    }
}
```

## 预防

- 所有遍历中移除 TArray 元素的场景，优先用倒序遍历
- 或使用 `TArray::RemoveAll()` / `TArray::FilterByPredicate()` 声明式 API

## 检测关键词

[TArray, RemoveAt, Remove, 正序遍历, 元素跳过]
