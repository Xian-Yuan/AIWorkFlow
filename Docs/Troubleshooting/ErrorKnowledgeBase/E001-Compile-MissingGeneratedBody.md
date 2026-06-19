---
id: E001
title: GENERATED_BODY 缺失导致编译失败
category: 编译错误
system: UHT
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E004]
keywords: [GENERATED_BODY, UHT, UCLASS, Missing macro, 反射]
---

## 现象

```
error: Missing 'GENERATED_BODY()' at end of 'UMyClass'
```
或
```
error C2039: 'GetClassFromTypeHash' : is not a member of 'UMyClass'
```

## 原因

每个 `UCLASS()` / `USTRUCT()` 声明末尾必须包含 `GENERATED_BODY()`。UHT（Unreal Header Tool）依赖它生成反射代码。缺失时 UHT 无法生成对应的 .generated.h 文件。

## 解决方案

在 UCLASS() 声明块内部末尾添加 `GENERATED_BODY()`：

```cpp
UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()  // ← 必须
    // ...
};
```

## 案例

```cpp
// ❌ 错误
UCLASS()
class UMyClass : public UObject
{
    // 没有 GENERATED_BODY()
};

// ✅ 正确
UCLASS()
class UMyClass : public UObject
{
    GENERATED_BODY()
};
```

## 预防

- 所有新建 UClass 模板自带 GENERATED_BODY()
- .h 文件写完先检查每个 UCLASS/USTRUCT/UENUM 块末尾
- 如果使用 `GENERATED_UCLASS_BODY()` 旧语法，注意 UE5 已不推荐

## 检测关键词

[Missing, GENERATED_BODY, UHT, UCLASS, 反射]
