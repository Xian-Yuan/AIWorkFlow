# 创建新 Experience 完整指南

## 概念

Experience 是 Lyra 的"游戏模式"。创建 Experience = 创建一套完整的游戏类型。

## 步骤 1: 创建 GameFeature Plugin

如 `NewGameFeature` 模板所述，创建 GFP。
确保在 `.uplugin` 中引用了 `GameFeatures`、`CommonGame`、`ModularGameplay`。

## 步骤 2: 创建 ActionSet (可选，用于共享)

```
右键 → Miscellaneous → Data Asset → ULyraExperienceActionSet
命名: LAS_MySharedInput
配置:
  GameFeaturesToEnable: [MyGame]
  Actions:
    - AddComponents (注入通用组件到 GameState/Controller)
    - AddInputConfig (通用输入映射)
```

## 步骤 3: 创建 PawnData

```
右键 → Miscellaneous → Data Asset → ULyraPawnData
命名: DA_MyPawnData
配置:
  PawnClass:        BP_MyCharacter (你的 Character 蓝图)
  AbilitySets:
    - DA_MyAbilitySet_Humanoid (基本能力集)
  InputConfig:      DA_MyInputConfig (输入配置)
  CameraMode:       BP_MyCameraMode (相机模式)
```

## 步骤 4: 创建 Experience Definition

```
右键 → Miscellaneous → Data Asset → ULyraExperienceDefinition
命名: B_MyExperience
配置:
  GameFeaturesToEnable:
    - MyGame (你的 GFP 名称)
  DefaultPawnData:  DA_MyPawnData
  Actions:
    - (直接添加 Action)
  ActionSets:
    - LAS_MySharedInput
```

## 步骤 5: 创建 Map

1. 创建新关卡
2. Open World Settings (Window → World Settings)
3. 设置:
   - GameMode Override: `BP_LyraGameMode` (Lyra 的 GameMode)
   - Default Gameplay Experience: `B_MyExperience` (你的 Experience)
4. 放置 `ALyraPlayerStart`
5. 添加基础场景

## 步骤 6: 测试

PIE 运行，验证:
- 角色正确生成
- 输入响应
- 能力可激活

## 关键数据资产关系

```
Map (World Settings)
    └─ Default Gameplay Experience: B_MyExperience
        ├─ GameFeaturesToEnable: [MyGame]
        ├─ DefaultPawnData: DA_MyPawnData
        │   ├─ PawnClass: BP_MyCharacter
        │   ├─ AbilitySets: [DA_MyAbilitySet]
        │   └─ InputConfig: DA_MyInputConfig
        └─ ActionSets: [LAS_SharedInput]
            └─ Actions: [AddComponents, AddInputConfig]
```

## 关键代码位置

| 类 | 路径 |
|------|------|
| ULyraExperienceDefinition | LyraGame/GameModes/LyraExperienceDefinition.h |
| ULyraExperienceActionSet | LyraGame/GameModes/LyraExperienceActionSet.h |
| ULyraExperienceManagerComponent | LyraGame/GameModes/LyraExperienceManagerComponent.h |
| ULyraPawnData | LyraGame/Characters/LyraPawnData.h |
| ULyraAbilitySet | LyraGame/AbilitySystem/LyraAbilitySet.h |
