---
id: E003
title: 头文件路径错误导致 "Cannot open include file"
category: 编译错误
system: Build
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E002]
keywords: [Cannot open include file, C1083, include 路径, No such file]
---

## 现象

```
fatal error C1083: Cannot open include file: 'AbilitySystem/LyraAbilitySet.h': No such file or directory
```

## 原因

include 路径错误，或缺少模块依赖导致编译器找不到头文件。

## 解决方案

1. 确认 `Build.cs` 中添加了对应模块依赖（如 "LyraGame"）
2. 确认 include 路径正确。在 GFP 中，include 路径相对于 `Public/Private` 目录：

```cpp
// 文件实际在: LyraGame/Source/LyraGame/Public/AbilitySystem/LyraAbilitySet.h

// ✅ 正确 (在 GFP 的 Source/MyGame/Public/ 中):
#include "AbilitySystem/LyraAbilitySet.h"

// ❌ 错误: 使用完整物理路径
#include "LyraGame/AbilitySystem/LyraAbilitySet.h"
```

## 案例

```cpp
// ❌ 错误：缺少模块或路径错误
#include "LyraAbilitySet.h"

// ✅ 正确
#include "AbilitySystem/LyraAbilitySet.h"
```

## 预防

- GFP 中引用 LyraGame 的头文件：路径相对于 LyraGame 的 Public/ 目录
- 添加 include 前先确认 Build.cs 包含对应模块

## 检测关键词

[C1083, include file, No such file, fatal error]
