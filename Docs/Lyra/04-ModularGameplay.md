# Modular Gameplay 模式

## 概念

Modular Gameplay 是一种模式，允许在**运行时向 Actor 动态注入组件**。这是 GameFeature Plugin 能够工作的重要基础。

## 核心组件

### UGameFrameworkComponentManager

- 类型: `UGameInstanceSubsystem`
- 作用: 管理 Actor 组件的动态注入和初始化状态
- 功能:
  - **Extension Handlers**: 向 Actor 添加组件的回调系统
  - **Initialization States**: 管理 Actor/组件的初始化状态链

### IGameFrameworkInitStateInterface

- 作用: 需要依赖初始化顺序的 Component 实现此接口
- 工作方式: 每个 Component 反复调用 `CheckDefaultInitialization()` 直到所有依赖就绪
- Lyra 使用 4 个阶段（实现为 GameplayTag）:

```
InitState_Spawned (Spawned)           # Actor 已生成
    ↓
InitState_DataAvailable (DataAvailable)  # 数据可用
    ↓
InitState_DataInitialized (DataInitialized) # 数据初始化
    ↓
InitState_GameplayReady (GameplayReady)    # 游戏逻辑就绪
```

### ModularGameplayActors 插件

- 提供现成的基类，自动注册到 `UGameFrameworkComponentManager`
- Lyra 的所有基础类都基于此:

| Lyra 类 | Modular 基类 |
|---------|-------------|
| `ALyraCharacter` | `AModularCharacter` |
| `ALyraPlayerController` | `AModularPlayerController` |
| `ALyraPlayerState` | `AModularPlayerState` |
| `ALyraGameMode` | `AModularGameMode` |
| `ALyraGameState` | `AModularGameState` |
| `ALyraHUD` | `AModularHUD` |

## Lyra 中的实现

### ULyraPawnExtensionComponent

- 驱动 Pawn 的初始化状态机
- 添加到所有 `ALyraCharacter`
- 从 `OnRegister` 调用 `RegisterInitStateFeature`
- 从 `BeginPlay` 调用 `CheckDefaultInitialization`
- 从 `OnRep` 函数（复制回调）调用 `CheckDefaultInitialization` 推动状态
- 协调 `PawnData`、`Controller` 等跨 Actor 引用

### ULyraHeroComponent

- 处理玩家控制的系统（相机、输入）
- 依赖 PawnExtensionComponent 初始化完成后继续

### 初始化流程

```
1. Actor Spawned
2. OnRegister → 注册 InitState 特性
3. BeginPlay → 开始 CheckDefaultInitialization
4. Spawned → DataAvailable: 等待 PawnData 和 Controller 就绪
5. DataAvailable → DataInitialized: 能力、输入初始化
6. DataInitialized → GameplayReady: 创建相机、绑定输入、UI 就绪
7. 广播就绪，游戏开始
```

## 参考链接

- 官方 GameFramework 组件管理: https://dev.epicgames.com/documentation/unreal-engine/game-framework-component-manager-in-unreal-engine
- X157 Modular Gameplay: https://x157.github.io/UE5/ModularGameplay/
- X157 Lyra Init 流程: https://x157.github.io/UE5/LyraStarterGame/InitGame/
