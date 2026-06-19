# GameplayCue

## 概述

GameplayCue 是 GAS 中用于**纯客户端视听反馈**的系统 (粒子、音效、屏幕效果等)。它们**不参与游戏逻辑**。

## 关键特性

- 仅在客户端执行
- 使用 GameplayTag 标识
- 有两种类型:
  - **静态 (Static)**: 复用类处理函数，无实例化
  - **Actor (Actor)**: 生成临时 Actor，有生命周期

## 触发方式

```cpp
// 在 GameplayEffect 中配置
GameplayCueTag = GameplayTag("GameplayCue.Damage.Hit");

// 或者代码触发
ASC->ExecuteGameplayCue(Tag, Context);
ASC->AddGameplayCue(Tag, Context);   // 持续存在
ASC->RemoveGameplayCue(Tag);         // 移除
```

## 创建流程

1. 创建 GameplayCueNotify (Static 或 Actor)
2. 设置 GameplayTag (如 `GameplayCue.Damage.Blood`)
3. 配置效果 (粒子、音效、衰减等)
4. 在 GE 中引用该 Tag

## 配置路径

```
Project Settings → GameplayCueNotifyPaths
// 确保你的 GameplayCue 路径在列表中

// 对于 GameFeature Plugin，在 GameFeatureData 中添加路径
```

## Lyra 中的 GameplayCue

Lyra 的 GameplayCue 路径在 `DefaultGameplayCueNotify.cpp` 或 `GameFeatureData` 中配置。

## 参考链接

- 官方 GAS 概述 (GC 章节): https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- tranek GC 章节: https://github.com/tranek/GASDocumentation
