# Lyra 项目概述与核心架构

## 什么是 Lyra

Lyra 是 Epic Games 官方提供的 UE5 示例游戏项目，旨在帮助开发者理解 UE5 框架。它的架构设计为**模块化**，包含核心系统和插件，随着 UE5 版本持续更新。

## 核心设计原则

1. **把 Lyra 当引擎代码看待** — 不要直接修改 Lyra 基础代码，而是通过 GameFeature Plugin 扩展
2. **模块化** — 每个游戏模式/体验是一个独立的 GameFeature Plugin
3. **异步初始化** — 使用 `IGameFrameworkInitStateInterface` 处理组件间的依赖初始化
4. **Experience 驱动** — 关卡 + Experience 取代传统的 GameMode

## 项目目录结构

```
LyraStarterGame/
├── Content/                    # 通用资源 + 主大厅
├── Plugins/
│   ├── GameFeatures/
│   │   ├── ShooterCore/        # 射击游戏核心框架
│   │   ├── ShooterMaps/        # 射击游戏关卡实现
│   │   └── TopDownArena/       # 俯视角竞技场
│   └── ...                     # 其他辅助插件
├── Source/
│   └── LyraGame/               # C++ 核心代码
└── Config/                     # 配置文件
```

## 核心系统概览

| 系统 | 描述 |
|------|------|
| Experience 系统 | 动态加载游戏模式/体验，比传统 GameMode 更灵活 |
| GameFeature Plugin | 将功能封装为按需加载的插件 |
| Modular Gameplay | 运行时向 Actor 注入组件的模式 |
| Pawn Extension | 通过 InitState 管理 Pawn 的异步初始化流程 |
| GAS | 基于 GameplayAbilitySystem 的能力/属性/效果 |
| Equipment 系统 | 基于 Inventory 的装备系统 |
| Inventory 系统 | 基于 Fragment 的通用背包系统 |
| Input 系统 | Enhanced Input + Tag 驱动的能力绑定 |
| UI Extension | 基于 GameplayTag 的 UI 扩展点系统 |
| Team 系统 | 团队/阵营管理系统 |

## 关键 C++ 类位置

```
Source/LyraGame/
├── AbilitySystem/          # GAS 扩展
├── Camera/                 # 相机系统
├── Character/              # 角色系统
├── Equipment/              # 装备系统
├── GameModes/              # 游戏模式
├── Input/                  # 输入系统
├── Inventory/              # 背包系统
├── Player/                 # 玩家状态
├── Teams/                  # 团队系统
├── UI/                     # UI 系统
├── Weapons/                # 武器系统
└── System/                 # 系统工具
```

## 官方文档链接

- Lyra 主文档: https://dev.epicgames.com/documentation/unreal-engine/lyra-sample-game-in-unreal-engine
- Lyra 导览: https://dev.epicgames.com/documentation/en-us/unreal-engine/tour-of-lyra-in-unreal-engine
- 升级 Lyra: https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-the-lyra-starter-game-to-the-latest-engine-release-in-unreal-engine
- Lyra 学习路径: https://dev.epicgames.com/community/learning/paths/Z4/lyra-starter-game
