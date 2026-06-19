# GameFeature Plugin 系统

## 概念

GameFeature Plugin (GFP) 是 UE5 的一种特殊插件，相比传统插件：

- 可以访问基础游戏代码
- 可以**在运行时动态加载/卸载**
- 可以独立分发给 DLC
- 通过 GameFeature Actions 在加载时执行操作

## GFP 核心结构

```
Plugins/GameFeatures/YourPlugin/
├── YourPlugin.uplugin           # 插件描述文件
├── Content/                     # 资源
└── Source/
    └── YourPlugin/
        ├── Public/
        └── Private/
```

**关键文件**: 每个 GFP **必须**有一个 `UGameFeatureData` 数据资产，保存在 `Content/GameFeatureData/` 下。

## GameFeature Action

GFP 加载时执行的原子操作，常见 Action：

| Action | 作用 |
|--------|------|
| `UGameFeatureAction_AddComponents` | 向指定 Actor 类注入组件 |
| `UGameFeatureAction_AddInputBinding` | 绑定输入配置 |
| `UGameFeatureAction_AddInputConfig` | 注册 Enhanced Input 映射 |
| `UGameFeatureAction_AddAbilities` | 授予能力集 |
| `UGameFeatureAction_AddAttributeDefaults` | 设置属性默认值 |
| `UGameFeatureAction_DataRegistrySource` | 注册数据源 |
| `UGameFeatureAction_AddWidget` | 添加 UI 控件 |
| `UGameFeatureAction_WorldActionBase` | 基础 Action 基类 |

## Lyra 内置 GFP

| Plugin | 描述 | 用途 |
|--------|------|------|
| LyraExampleContent | 共享材质资源 | 基础资源 |
| ShooterCore | 射击游戏核心逻辑 | 游戏模式、能力、武器、UI |
| ShooterMaps | 射击游戏关卡 | Expanse, Convolution |
| TopDownArena | 俯视角模式 | 地图生成器、能力道具 |

## 创建自己的 GFP

1. 在 `Plugins/GameFeatures/` 下创建文件夹
2. 创建 `.uplugin` 描述文件，或在编辑器中使用"Game Feature"模板创建
3. 创建 `UGameFeatureData` 资源在 `Content/GameFeatureData/`
4. 配置 `GameFeatureData`：
   - 指定扫描目录（如 `/Experiences/`、`/Characters/`）
   - 添加 GameplayCue 路径
5. 创建 `ULyraExperienceDefinition` 引用你的 GFP
6. 创建关卡并在 World Settings 中指定 Experience

## 加载与激活流程

```
GameFeatureData 
    → Asset Manager 发现资产
    → Experience 被选择 
    → UGameFeaturesSubsystem::LoadAndActivateGameFeaturePlugin()
    → 执行所有 GameFeature Actions
    → Actions 注入组件、绑定输入、添加 UI 等
```

## 最佳实践

- **不修改 Lyra 基础代码**，所有自定义代码放在自己的 GFP 中
- GFP 更像是"mod"而非传统插件
- 使用 ActionSet 组合共享功能，避免重复
- 资源必须放在正确的扫描目录下才能被 Asset Manager 发现
- 所有 Gameplay 初始化必须等待 `OnExperienceLoaded`

## 参考链接

- 官方 Modular Gameplay 文档: https://dev.epicgames.com/documentation/unreal-engine/game-framework-component-manager-in-unreal-engine
- X157 GameFeature 详解: https://x157.github.io/UE5/GameFeatures/
- UE5 Modular Gameplay: https://x157.github.io/UE5/ModularGameplay/
