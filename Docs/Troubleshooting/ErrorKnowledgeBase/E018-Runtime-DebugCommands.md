---
id: E018
title: Lyra 调试控制台命令速查
category: 运行时错误
system: Lyra
severity: 建议
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [控制台命令, 调试, AbilitySystem.Debug, ShowDebug]
---

## 现象

需要调试 GAS / Lyra 运行时状态但不知道用什么命令。

## 解决方案

```
# GAS 调试
AbilitySystem.Debug.Ability 1       # 显示能力信息
AbilitySystem.Debug.Effects 1       # 显示效果信息
AbilitySystem.Debug.Attributes 1    # 显示属性信息
AbilitySystem.Debug.NextCategory    # 切换类别
AbilitySystem.Debug.ToggleCategories

# Lyra 调试
ShowDebug AbilitySystem             # 调试 HUD

# 性能
stat FPS
stat GameplayTags
stat AbilitySystem
```

## 预防

- 遇到 GAS 相关问题先尝试 `AbilitySystem.Debug.Ability 1`

## 检测关键词

[控制台, 调试命令, AbilitySystem.Debug, ShowDebug]
