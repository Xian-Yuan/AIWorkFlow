---
id: E015
title: GameplayCue 不触发
category: 运行时错误
system: GAS
severity: 一般
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [GameplayCue, 不触发, GameplayCue路径, 无表现]
---

## 现象

GE 应用后 GameplayCue 的表现（粒子/音效/动画）没有播放。

## 原因

1. GameplayCue 资产路径未在配置中注册
2. Tag 命名不以 `GameplayCue.` 开头
3. GE 的 `GameplayCueTag` 没有引用正确的 GameplayCue Tag

## 解决方案

```cpp
// 1. 路径注册
// 在 DefaultGame.ini 或 GameFeatureData 中添加:
// +GameplayCueNotifyPaths = /Game/MyGame/GameplayCues

// 2. Tag 命名规范
// GameplayCue.Damage.Impact      ✅ 正确
// Damage.Impact                  ❌ 错误（缺少 GameplayCue. 前缀）

// 3. GE 配置
// GE → GameplayCueTag → 选择 GameplayCue.Damage.Impact
```

## 预防

- 所有 GameplayCue 的 Tag 以 `GameplayCue.` 开头
- 新建 Cue 资产后在 GameFeatureData 中注册路径

## 检测关键词

[GameplayCue, 不触发, GameplayCue路径, 无表现, Cue不生效]
