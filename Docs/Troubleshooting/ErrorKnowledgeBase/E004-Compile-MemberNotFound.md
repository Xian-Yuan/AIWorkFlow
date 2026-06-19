---
id: E004
title: 调用了不存在的成员函数 "UClass has no member"
category: 编译错误
system: UHT
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E001]
keywords: [has no member, C2039, 函数不存在, _Implementation]
---

## 现象

```
error C2039: 'SetActiveSlotIndex': is not a member of 'ULyraQuickBarComponent'
```

## 原因

调用了不存在的函数。常见原因：
1. 函数名拼写错误
2. 函数在目标 UE 版本中不存在（Lyra API 在 UE5.4→5.7 间有改动）
3. 混淆了 `BlueprintImplementableEvent` 和 `Native` 函数的调用方式

## 解决方案

1. 查 Docs/APIRef/LyraCoreClasses.md 或 GASCoreClasses.md 确认函数签名
2. 如无文档，在 LyraGame/Source/ 中搜索函数名
3. 注意：`BlueprintCallable` 和 `BlueprintImplementableEvent` 函数不需要 `_Implementation` 后缀

```cpp
// ✅ BlueprintImplementableEvent — 直接调用
UFUNCTION(BlueprintImplementableEvent)
void OnSomethingHappened();
// C++ 调用: OnSomethingHappened();

// ✅ Native 函数 — 有实现体
UFUNCTION()
void OnSomethingHappened_Implementation();
// C++ 调用: OnSomethingHappened_Implementation(); 或 OnSomethingHappened();
```

## 预防

- 不猜函数名，优先查 Docs/APIRef/
- 搜索 UE 源码确认函数在当前版本存在

## 检测关键词

[has no member, C2039, is not a member of]
