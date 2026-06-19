---
id: E010
title: AssetManager 未配置扫描路径导致 "Unable to load package"
category: 资产错误
system: Lyra
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: []
keywords: [Unable to load package, AssetManager, PrimaryAssetTypesToScan, Linker]
---

## 现象

```
LogLinker: Warning: Unable to load package /Game/MyGame/Experiences/B_MyExperience
```

## 原因

AssetManager 未配置扫描该目录，导致运行时无法加载资产包。

## 解决方案

在 `GameFeatureData` 的 `PrimaryAssetTypesToScan` 中添加正确目录：

```
GameFeatureData → PrimaryAssetTypesToScan → 添加新条目
  - PrimaryAssetType: Experience
  - AssetScanPaths: /Game/MyGame/Experiences/
  - bHasBlueprintClasses: true
```

## 预防

- 新建 Experience / PawnData / InputConfig 等资产目录时同步更新 GameFeatureData
- 确认 PrimaryAssetTypes 的路径与实际资产目录一致

## 检测关键词

[Unable to load package, AssetManager, PrimaryAssetTypes, Linker]
