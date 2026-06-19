---
id: E005
title: 继承类未标记 UCLASS 导致 "Cannot derive from"
category: 编译错误
system: UHT
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E001]
keywords: [Cannot derive from, not marked with UCLASS, forward declaration]
---

## 现象

```
error: Cannot derive from 'ULyraEquipmentInstance' as it is not marked with UCLASS(), or only forward declaration
```

## 原因

1. 头文件缺少 `UCLASS()` 宏或 `GENERATED_BODY()`
2. 只有 forward declaration（前向声明）没有完整的类定义
3. include 了错误的头文件或缺少头文件包含

## 解决方案

```cpp
// ✅ 正确：完整的类定义
UCLASS()
class UMyEquipmentInstance : public ULyraEquipmentInstance
{
    GENERATED_BODY()
    // ...
};
```

确保 include 了父类的正确头文件：
```cpp
// ❌ 只前向声明
class ULyraEquipmentInstance;

// ✅ 完整包含
#include "Equipment/LyraEquipmentInstance.h"
```

## 预防

- 新建继承类时从 CodeTemplates 复制完整模板
- 检查头文件是否包含父类的 .h 文件而非前向声明

## 检测关键词

[Cannot derive from, not marked with UCLASS, forward declaration]
