# MyGame.uplugin 配置说明

## 关键字段

| 字段 | 值 | 说明 |
|------|------|------|
| `FriendlyName` | 显示名称 | 编辑器插件列表中显示 |
| `Category` | `Game Features` | 必须为 `Game Features` 才能被系统识别 |
| `CanContainContent` | `true` | 必须有资源文件 |
| `Modules[0].Name` | 模块名称 | 必须与模块文件名一致 |
| `Modules[0].Type` | `Runtime` | 运行时模块 |
| `Modules[0].LoadingPhase` | `Default` | 默认加载阶段 |

## 必须依赖的插件

```json
"Plugins": [
    { "Name": "CommonGame", "Enabled": true },
    { "Name": "GameFeatures", "Enabled": true },
    { "Name": "ModularGameplay", "Enabled": true }
]
```

CommonGame、GameFeatures、ModularGameplay 是 Lyra GFP 必须的依赖。

## 推荐存放位置

```
LyraStarterGame/
└── Plugins/
    └── GameFeatures/
        └── MyGame/
            ├── MyGame.uplugin
            ├── Content/
            │   └── GameFeatureData/
            │       └── GFD_MyGame.uasset
            └── Source/
                ├── MyGame.Build.cs
                └── MyGame/
                    ├── MyGame.h
                    └── MyGame.cpp
```

## GameFeatureData 蓝图配置

在 Content Browser 中创建：
1. 右键 → Miscellaneous → Data Asset → 选择 `UGameFeatureData`
2. 保存到 `Content/GameFeatureData/GFD_MyGame`

编辑该 Data Asset 时必须配置：

### Asset Types
```
PrimaryAssetType: "LyraExperienceDefinition"
Directories: ["/Game/Experiences/"]

PrimaryAssetType: "LyraPawnData"
Directories: ["/Game/PawnData/"]

PrimaryAssetType: "LyraInputConfig"
Directories: ["/Game/Input/"]

PrimaryAssetType: "LyraAbilitySet"
Directories: ["/Game/Abilities/"]
```

### GameplayCue Paths
```
[/Script/GameplayAbilities.AbilitySystemGlobals]
GameplayCueNotifyPaths = [/Game/MyGame/GameplayCues/]
```
