---
id: E007
title: LNK2019 无法解析的外部符号
category: 编译错误
system: Build
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E002, E027]
keywords: [LNK2019, unresolved external symbol, 链接错误, 外部符号]
---

## 现象

```
LNK2019: unresolved external symbol "public: void __cdecl UMyClass::MyFunction()"
```

## 原因

函数在 .h 中声明了但没有在 .cpp 中实现，或实现不在编译中包含的文件中。

## 解决方案

1. 确认函数的 `.cpp` 文件在 `Source/ModuleName/Private/` 中
2. 确认 `.cpp` 文件被编译（检查 `Build.cs` 的 `PrivateDefinitions`）
3. 确认 `GENERATED_BODY()` 在类中（UHT 生成的函数需要它）
4. 如果是编辑器特有函数（如 `GEditor`），检查 `Build.cs` 是否条件包含 `UnrealEd`

## 案例

```cpp
// MyGame.Build.cs
// 编辑器特有功能需要条件依赖
if (Target.bBuildEditor)
{
    PrivateDependencyModuleNames.Add("UnrealEd");
}
```

## 预防

- 所有 .h 声明都在 .cpp 中有实现
- 编辑器特有功能用 `#if WITH_EDITOR` 包裹并用条件依赖

## 检测关键词

[LNK2019, unresolved external, 链接错误, linker]
