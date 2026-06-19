---
id: E016
title: GameFeature 加载失败 "Failed to load game feature plugin"
category: 运行时错误
system: Lyra
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E006, E009]
keywords: [GameFeature, Failed to load, missing dependency, plugin]
---

## 现象

```
LogGameFeatures: Error: Failed to load game feature plugin 'MyGame' — missing dependency
```

## 原因

1. `.uplugin` 中 `Plugins` 依赖的模块未启用
2. 项目插件列表中没有启用该 GFP
3. 存在循环依赖

## 解决方案

```json
// .uplugin 依赖检查
{
    "Plugins": [
        {
            "Name": "LyraGame",
            "Enabled": true       // ← 必须 true
        },
        {
            "Name": "ModularGameplay",
            "Enabled": true
        }
    ]
}
```

同时检查：编辑 → 插件 → Game Features → MyGame → 已启用

## 预防

- GFP 依赖的插件必须全部启用
- 依赖链：GFP → LyraGame → GameplayAbilities

## 检测关键词

[Failed to load game feature, missing dependency, GameFeature plugin]
