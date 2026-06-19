# Lyra Experience 系统

## 概念

Experience（体验）是 Lyra 的核心概念，相当于**更高级、更灵活的 GameMode**。每个关卡可以指定默认的 Experience，Experience 决定：

- 使用哪些 GameFeature Plugin
- 玩家 Pawn 的默认数据（类、能力集、输入配置等）
- 执行哪些 GameFeature Action

## 核心类

| 类 | 职责 |
|------|------|
| `ULyraExperienceDefinition` | Experience 数据资产，定义要加载的 GFP、PawnData、Actions |
| `ULyraUserFacingExperienceDefinition` | 轻量级数据资产，持有 ID 而非引用，用于 UI 展示 |
| `ULyraExperienceActionSet` | Action 组合集，可被多个 Experience 复用 |
| `ULyraExperienceManagerComponent` | 管理 Experience 生命周期的组件（附在 GameState 上） |
| `ALyraGameState` | 拥有 ExperienceManagerComponent 和 ASC |

## Experience 定义属性

| 属性 | 说明 |
|------|------|
| `GameFeaturesToEnable` | 此 Experience 需要加载的 GameFeature Plugin 列表 |
| `DefaultPawnData` | ULyraPawnData — Pawn 类、能力集、输入、相机 |
| `Actions` | 实例化的 GameFeature Action 列表 |
| `ActionSets` | 可复用的 ActionSet 列表 (组合模式) |

## Experience 生命周期

```
1. ALyraGameMode::SetCurrentExperience()
     └─ 服务器设置 CurrentExperience，复制到客户端
2. OnRep_CurrentExperience() / 服务器直接调用
     └─ StartExperienceLoad()
         ├─ Async Load Experience Asset + ActionSets + Asset Bundles
         └─ 计数等待加载完成
3. OnExperienceLoadComplete()
     ├─ CollectGameFeaturePluginURLs()
     ├─ LoadAndActivateGameFeaturePlugin() (异步)
     └─ 等待所有插件加载完成
4. OnExperienceFullLoadCompleted()
     ├─ 执行 GameFeature Actions
     ├─ 广播 OnExperienceLoaded
     └─ 游戏正式开始
5. EndPlay() — 停用并卸载 GameFeature
```

## 初始化状态链

Lyra 使用 4 阶段初始化状态来协调组件依赖：

```
InitState_Spawned
    → InitState_DataAvailable
    → InitState_DataInitialized
    → InitState_GameplayReady
```

- `ULyraPawnExtensionComponent` 驱动整个初始化流程
- `ULyraHeroComponent` 处理玩家控制的系统（相机、输入）
- 组件通过 `CheckDefaultInitialization()` 推动状态前进
- 使用 `BindOnActorInitStateChanged` 监听状态变更

## 关键函数

```
ULyraExperienceManagerComponent:
├── SetCurrentExperience()          # 设置当前 Experience
├── StartExperienceLoad()           # 开始异步加载
├── OnExperienceLoadComplete()      # 资源加载完成
├── OnGameFeaturePluginLoadComplete() # GFP 加载完成
└── OnExperienceFullLoadCompleted() # 全部完成

AsyncAction_OnExperienceLoaded:    # BP 中等待 Experience 加载
```

## 最佳实践

- **不要**通过继承 Experience BP 创建相似体验，应使用 **ActionSet 组合**
- 所有 Gameplay 逻辑必须等待 `OnExperienceLoaded` 事件，不能依赖 `BeginPlay`
- 将代码和资源放在自己的 GameFeature Plugin 中，不修改 Lyra 基础代码
- 使用 `ActionSets` 共享公共功能（如输入组件、HUD 组件）

## 参考链接

- 官方 Experience 文档: https://dev.epicgames.com/documentation/en-us/unreal-engine/abilities-in-lyra-in-unreal-engine
- X157 Experience 详解: https://x157.github.io/UE5/LyraStarterGame/Experience/
- Unrealist Experience 生命周期: https://unrealist.org/lyra-part-3/
