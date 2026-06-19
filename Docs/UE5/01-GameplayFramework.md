# UE5 游戏框架 (Gameplay Framework)

## 核心类关系

```
GameInstance (游戏生命周期)
    └─ GameInstanceSubsystems
    
World (关卡容器)
    ├─ GameMode (服务器规则) → GameSession
    ├─ GameState (全局状态)
    ├─ PlayerController (玩家控制)
    │   └─ PlayerState (玩家状态)
    └─ Pawn / Character (游戏角色)
```

## 关键类

| 类 | 职责 |
|------|------|
| **GameInstance** | 全局生命周期，跨关卡持久化 |
| **GameMode** | 游戏规则、角色生成、通关条件 (仅服务器) |
| **GameState** | 所有客户端的全局游戏状态 |
| **PlayerController** | 玩家输入和视角控制 (仅拥有客户端 + 服务器) |
| **PlayerState** | 玩家数据 (分数、队伍等) |
| **Pawn** | 物理代表的游戏对象 |
| **Character** | Pawn 子类，添加角色移动组件 |
| **HUD** | HUD 绘制 (已部分被 UMG 替代) |
| **GameInstanceSubsystem** | 全局子系统，生命周期同 GameInstance |

## 初始化顺序

```
1. GameInstance::Init()
2. World 加载
3. GameMode::InitGame()
4. GameMode::PreLogin() / PostLogin()
5. PlayerController::BeginPlay()
6. 生成 Pawn: GameMode::SpawnDefaultPawnFor()
7. PlayerController::Possess()
8. Pawn::BeginPlay()
```

## UE5 框架变更

- **GameFeature Plugin**: 模块化游戏类型加载
- **Modular Gameplay**: 组件动态注入
- **Enhanced Input**: 替代传统 InputComponent
- **CommonUI**: 跨平台 UI 框架
- **World Partition**: 大规模世界管理
- **One File Per Actor (OFPA)**: 新 Actor 管理模式

## 参考链接

- 官方 Gameplay Framework: https://dev.epicgames.com/documentation/unreal-engine/gameplay-framework-in-unreal-engine
