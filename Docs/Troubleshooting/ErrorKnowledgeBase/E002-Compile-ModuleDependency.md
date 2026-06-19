---
id: E002
title: 模块依赖缺失导致 "Unable to find type"
category: 编译错误
system: Build
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E003, E006]
keywords: [Unable to find type, BLUEPRINT_TYPE, 模块依赖, Build.cs, LNK2019]
---

## 现象

```
error: Unable to find type 'ULyraAbilitySet' for attribute 'BLUEPRINT_TYPE'
```

## 原因

在 GameFeature Plugin 的 `Build.cs` 中缺少 `LyraGame` 模块依赖。UHT 在编译反射信息时，需要知道包含该类型的所有模块。

## 解决方案

在 `Build.cs` 的 `PublicDependencyModuleNames` 中添加缺失模块：

```csharp
PublicDependencyModuleNames.AddRange(
    new string[]
    {
        "LyraGame",
        "GameplayAbilities",
        "GameplayTags",
        "ModularGameplay"
        // 按需添加
    }
);
```

## 案例

```csharp
// ❌ 错误：缺少 LyraGame
PublicDependencyModuleNames.Add("GameplayAbilities");

// ✅ 正确
PublicDependencyModuleNames.AddRange(new string[] {
    "LyraGame", "GameplayAbilities", "GameplayTags"
});
```

## 预防

- 新建 GFP 时从模板 Build.cs 复制，不要从零写
- 引用 Lyra 类前确保 Build.cs 包含 "LyraGame"
- 添加新模块依赖后必须重新生成解决方案

## 检测关键词

[Unable to find type, BLUEPRINT_TYPE, module dependency, Build.cs]
