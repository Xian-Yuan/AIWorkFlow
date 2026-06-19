# 创建 GameFeature Experience

## 流程概览

1. 创建 GameFeature Plugin
2. 配置 GameFeatureData
3. 创建 ActionSet (共享组件)
4. 创建 PawnData
5. 创建 Character 蓝图
6. 创建 Experience Definition
7. 创建 Map
8. 测试

## 详细步骤

### 1. 创建 GFP

```
编辑器 → 工具 → 新建插件 → Game Feature
名称: XistGame (举例)
位置: Plugins/GameFeatures/
```

### 2. 配置 GameFeatureData

创建在 `Content/GameFeatureData/`:
- PrimaryAssetTypes: 添加扫描目录
- GameplayCue 路径: 添加 `/Game/.../GameplayCues/`
- 保存

### 3. 创建 ActionSet

```
右键 → Miscellaneous → Data Asset → ULyraExperienceActionSet
名称: LAS_SharedInput
配置:
  GameFeaturesToEnable: [XistGame]
  Actions: [AddComponents, AddInputConfig]
```

### 4. 创建 PawnData

```
右键 → Miscellaneous → Data Asset → ULyraPawnData
名称: DA_PawnData_Humanoid
配置:
  PawnClass: B_Character_Humanoid
  AbilitySets: [DA_AbilitySet_Humanoid]
  InputConfig: DA_InputData_Humanoid
```

### 5. 创建 Character

基于 `B_Hero_Default` 创建蓝图:
- 设置网格、动画蓝图
- 配置移动组件

### 6. 创建 Experience

```
右键 → Miscellaneous → Data Asset → ULyraExperienceDefinition
名称: B_Experience_Dev
配置:
  DefaultPawnData: DA_PawnData_Humanoid
  ActionSets: [LAS_SharedInput]
  GameFeaturesToEnable: [XistGame]
```

### 7. 创建 Map

- 创建空关卡
- World Settings → Default Gameplay Experience = B_Experience_Dev
- 放置 LyraPlayerStart
- 添加基础地形和光照

### 8. 测试

PIE 运行，验证角色生成和输入响应

## 参考链接

- X157 完整搭建指南: https://x157.github.io/UE5/LyraStarterGame/How-To-Create-New-GameFeature-Dev-Experience.html
- X157 新建项目: https://x157.github.io/UE5/LyraStarterGame/Getting-Started-Setting-Up-a-New-LyraStarterGame-Project.html
