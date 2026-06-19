---
id: E019
title: GEditor LNK2019 编辑器特有链接错误
category: 编译错误
system: Build
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E007]
keywords: [GEditor, LNK2019, UnrealEd, bBuildEditor, WITH_EDITOR]
---

## 现象

```
Error LNK2019: 无法解析的外部符号 "__declspec(dllimport) class UEditorEngine * GEditor"
```

## 原因

`GEditor` 属于 `UnrealEd` 模块。在插件或游戏模块中使用编辑器特有的接口时，仅 `#if WITH_EDITOR` 和 `#include "Editor.h"` 能通过编译阶段，但链接阶段需要 `UnrealEd` 模块。

如果直接在 `Build.cs` 中无脑添加 `UnrealEd`，会导致打包（Shipping）失败。

## 解决方案

```csharp
// Build.cs 中必须用条件依赖
if (Target.bBuildEditor)
{
    PrivateDependencyModuleNames.AddRange(
        new string[]
        {
            "UnrealEd"  // 仅在编辑器构建时链接，防止打包失败
        }
    );
}
```

## 案例

```cpp
// .h 文件
#if WITH_EDITOR
#include "Editor.h"
#endif

// 使用
#if WITH_EDITOR
if (GEditor)
{
    GEditor->SelectActor(Actor, true, true);
}
#endif
```

## 预防

- 编辑器特有功能必须同时做两件事：`#if WITH_EDITOR` + Build.cs 条件依赖
- 绝不在无条件块中添加 `UnrealEd` 依赖

## 检测关键词

[GEditor, UnrealEd, bBuildEditor, LNK2019, 编辑器特有]
