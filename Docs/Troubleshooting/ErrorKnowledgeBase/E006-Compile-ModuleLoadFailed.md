---
id: E006
title: GameFeature 模块无法加载 "ModuleManager: Unable to load module"
category: 编译错误
system: Build
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E002, E016]
keywords: [ModuleManager, Unable to load module, GFP, uplugin]
---

## 现象

```
LogModuleManager: Warning: Unable to load module 'MyGame'
```

## 原因

1. `.uplugin` 中的模块名与 `Build.cs` 和 `IMPLEMENT_MODULE` 不一致
2. `Build.cs` 缺少必要的 `PublicDependencyModuleNames`
3. 添加插件后未重新生成解决方案

## 解决方案

检查三处名字一致性：

```csharp
// .uplugin 文件
"Modules": [
    {
        "Name": "MyGame",           // ← 必须与 Build.cs 目录名一致
        "Type": "Game",
        "LoadingPhase": "Default"
    }
]

// Build.cs 文件名: MyGame.Build.cs  (与 Modules[0].Name 一致)

// IMPLEMENT_MODULE
IMPLEMENT_MODULE(FDefaultGameModuleImpl, MyGame)  // ← 必须一致
```

## 预防

- 新建 GFP 时从 CodeTemplates 复制，不要手动创建
- 修改模块名时同步修改三处：.uplugin / Build.cs 文件名 / IMPLEMENT_MODULE

## 检测关键词

[Unable to load module, ModuleManager, IMPLEMENT_MODULE, uplugin]
