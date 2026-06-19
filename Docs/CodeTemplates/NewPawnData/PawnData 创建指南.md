# PawnData 创建指南

## 概念

`ULyraPawnData` 是数据资产，定义了创建玩家 Pawn 所需的所有配置。

## 创建方式

```
Content Browser → 右键 → Miscellaneous → Data Asset → ULyraPawnData
```

## 配置字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `PawnClass` | TSubclassOf<APawn> | 使用的 Pawn/Character 类 |
| `InputConfig` | ULyraInputConfig* | 输入配置 |
| `AbilitySets` | TArray<ULyraAbilitySet*> | 授予的能力集 |
| `CameraMode` | TSubclassOf<ULyraCameraMode> | 默认相机模式 |
| `TagRelationshipMapping` | ULyraAbilityTagRelationshipMapping* | Tag 关系映射 |

## 推荐配置

```
PawnClass:         BP_MyCharacter
InputConfig:       DA_MyInputConfig
AbilitySets[0]:    DA_AbilitySet_Basic (跳跃、移动、交互)
AbilitySets[1]:    DA_AbilitySet_Weapons (可选)
CameraMode:        BP_CameraMode_ThirdPerson
TagRelationshipMapping: DA_TagRelationshipMapping
```

## 代码路径

| 类 | 路径 |
|------|------|
| ULyraPawnData | LyraGame/Characters/LyraPawnData.h |
