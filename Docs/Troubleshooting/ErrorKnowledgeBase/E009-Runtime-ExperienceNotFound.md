---
id: E009
title: Lyra Experience 找不到 "Unable to find experience"
category: 运行时错误
system: Lyra
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E017, E018]
keywords: [OnExperienceLoadComplete, failed to find plugin URL, Experience, GameFeature]
---

## 现象

```
LogLyraExperience: Warning: OnExperienceLoadComplete failed to find plugin URL for PluginName MyGame
```

## 原因

1. GFP 的 `.uplugin` 文件位置不正确（必须在 `Plugins/GameFeatures/` 下）
2. GFP 名称在 Experience 的 `GameFeaturesToEnable` 中拼写错误
3. `.uplugin` 文件中 `Category` 不是 `"Game Features"`

## 解决方案

```json
// .uplugin 文件
{
    "FileVersion": 3,
    "Category": "Game Features",     // ← 必须
    "EnabledByDefault": true,
    // ...
}
```

```
// 目录结构必须正确
Plugins/GameFeatures/MyGame/MyGame.uplugin    // ✅ 正确
Plugins/MyGame/MyGame.uplugin                 // ❌ 错误
```

## 预防

- 新建 GFP 时从 CodeTemplates 复制，确认 Category："Game Features"
- GameFeaturesToEnable 中的名字与 .uplugin 所在文件夹名一致

## 检测关键词

[OnExperienceLoadComplete, plugin URL, GameFeaturesToEnable, Experience]
