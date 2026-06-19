# 资源管理系统 (Asset Manager)

## 核心概念

| 概念 | 说明 |
|------|------|
| **PrimaryAssetId** | 唯一资源标识符 (Type:Name) |
| **Asset Bundle** | 资源包定义，控制加载策略 |
| **Asset Manager** | 管理 Primary Asset 的发现、加载和引用 |
| **Asset Registry** | 构建时生成的资源注册表 |

## Lyra 中的配置

在 `DefaultGame.ini` 中:

```ini
[/Script/Engine.AssetManagerSettings]
PrimaryAssetTypesToScan=(PrimaryAssetType="LyraExperienceDefinition", ...)
PrimaryAssetTypesToScan=(PrimaryAssetType="LyraUserFacingExperienceDefinition", ...)
PrimaryAssetTypesToScan=(PrimaryAssetType="LyraPawnData", ...)
PrimaryAssetTypesToScan=(PrimaryAssetType="PrimaryDataAsset", ...)
```

## 异步加载

```cpp
// 通过 PrimaryAssetId 异步加载
UAssetManager::Get().LoadPrimaryAssets(
    PrimaryAssetIdList,
    AssetBundles,
    FStreamableDelegate::CreateUObject(this, &MyClass::OnLoadComplete)
);
```

## Experience 中的应用

```
ULyraUserFacingExperienceDefinition (轻量级, 只包含 ID)
    → UI 展示不需要加载完整资源
    → 用户选择后加载对应的 Experience
    → Experience 再加载 GameFeature Plugins
```

## 参考链接

- 官方 Asset Manager 文档: https://dev.epicgames.com/documentation/unreal-engine/asset-manager
