---
id: E008
title: ATTRIBUTE_ACCESSORS 宏不在 UCLASS 内导致编译失败
category: 编译错误
system: UHT
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E001]
keywords: [Only classes with UStruct, ATTRIBUTE_ACCESSORS, 结构体]
---

## 现象

```
error: Only classes with UStruct can be struct in 'ATTRIBUTE_ACCESSORS'
```

## 原因

`ATTRIBUTE_ACCESSORS` 宏必须在 `UCLASS()` 声明内部的 `public:` 段中使用，不能放在类外。

## 解决方案

```cpp
// ❌ 错误：宏在类外
ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health);

UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()
};

// ✅ 正确：宏在类内 public: 段
UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()
public:
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health);
};
```

## 预防

- 新建 AttributeSet 时从 CodeTemplates/NewAttributeSet 复制
- ATTRIBUTE_ACCESSORS 统一放在 GENERATED_BODY() 之后的 public: 段

## 检测关键词

[Only classes with UStruct, ATTRIBUTE_ACCESSORS, struct in]
