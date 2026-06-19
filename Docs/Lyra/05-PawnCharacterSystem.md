# Pawn 与 Character 系统

## 架构概述

Lyra 的 Pawn/Character 系统采用**分层设计**，由多个组件协同完成初始化。

```
Controller (拥有 InventoryManager)
    └─ PlayerState (拥有 ASC — AbilitySystemComponent)
        └─ Character (拥有 PawnExtensionComponent)
            └─ HeroComponent (玩家特有: 相机、输入)
```

## 关键组件

### ULyraPawnExtensionComponent
- 附加到所有 `ALyraCharacter`
- 驱动 4 阶段 InitState 初始化
- 协调 PawnData、Controller 的跨 Actor 依赖
- 负责: 从 PawnData 加载能力集、输入配置

### ULyraHeroComponent
- 仅玩家 Pawn 拥有
- 处理: 相机模式设置、输入绑定、角色创建
- 在 PawnExtensionComponent 完成 DataInitialized 后工作

### ULyraPawnData
- 数据资产，定义 Pawn 的配置:
  - `PawnClass`: Pawn 的子类
  - `AbilitySets`: 授予的能力集
  - `InputConfig`: 输入配置
  - `CameraMode`: 相机模式
  - `TagRelationshipMapping`: Tag 关系映射

### ALyraPlayerState
- 拥有 `ULyraAbilitySystemComponent`
- 将 GAS 状态逻辑与 Pawn 数据分离
- 玩家和 AI Bot 各有一个

## 初始化流程

```
1. PlayerState 生成 (含 ASC)
2. Character 生成 (含 PawnExtensionComponent)
3. Controller 拥有 Character
4. PawnExtensionComponent 开始 CheckDefaultInitialization
5. DataAvailable: PawnData + Controller 就绪
6. DataInitialized: 能力、属性、输入配置从 PawnData 授予
7. GameplayReady: HeroComponent 设置相机和输入
8. 游戏逻辑开始
```

## 角色基类

| 类 | 路径 | 描述 |
|------|------|------|
| `ALyraCharacter` | Characters/LyraCharacter.h | 所有角色的基类 |
| `B_Hero_Default` | Lyra/Characters/Heros | 默认英雄蓝图 |
| `B_Hero_ShooterMannequin` | ShooterCore/Characters | 射击游戏角色(最重要的示例) |

## 官方文档

- Lyra 能力系统: https://dev.epicgames.com/documentation/en-us/unreal-engine/abilities-in-lyra-in-unreal-engine
- X157 角色系统: https://x157.github.io/UE5/LyraStarterGame/
