# 文档映射表 — 需求 → Docs 路径

本文件将常见开发需求直接映射到 `Docs/` 文件夹中的具体文档。

## Lyra 系统

| 需求 | 参考文档 |
|------|----------|
| 理解 Lyra 整体架构 | Docs/Lyra/01-Overview.md |
| 创建新 Experience | Docs/Lyra/02-ExperienceSystem.md + Docs/CodeTemplates/NewExperience/ |
| 创建 GameFeature Plugin | Docs/Lyra/03-GameFeaturePlugins.md + Docs/CodeTemplates/NewGameFeature/ |
| 理解 Modular Gameplay | Docs/Lyra/04-ModularGameplay.md |
| 自定义 Character/Pawn | Docs/Lyra/05-PawnCharacterSystem.md |
| 创建装备系统 | Docs/Lyra/06-EquipmentSystem.md + Docs/CodeTemplates/NewEquipmentType/ |
| 创建背包物品 | Docs/Lyra/07-InventorySystem.md + Docs/CodeTemplates/NewEquipmentType/ |
| 创建武器 | Docs/Lyra/08-WeaponSystem.md + Docs/CodeTemplates/NewWeaponType/ |
| 绑定输入 | Docs/Lyra/09-InputSystem.md + Docs/CodeTemplates/NewInputConfig/ |
| 创建 UI | Docs/Lyra/10-UIExtensionSystem.md + Docs/UE5/04-CommonUI.md |

## GAS 系统

| 需求 | 参考文档 |
|------|----------|
| 理解 GAS 整体 | Docs/GAS/01-Overview.md |
| 配置 ASC | Docs/GAS/02-ASC.md |
| 创建能力 | Docs/GAS/03-GameplayAbility.md + Docs/CodeTemplates/NewGameplayAbility/ |
| 创建效果 (Buff/伤害) | Docs/GAS/04-GameplayEffect.md + Docs/CodeTemplates/NewGameplayEffect/ |
| 创建属性 | Docs/GAS/05-AttributeSet.md + Docs/CodeTemplates/NewAttributeSet/ |
| 创建 GameplayCue | Docs/GAS/06-GameplayCue.md |
| 使用 AbilityTask | Docs/GAS/07-AbilityTasks.md |
| 目标选择 | Docs/GAS/08-Targeting.md |
| 网络预测 | Docs/GAS/09-Prediction.md |
| GAS 最佳实践 | Docs/GAS/10-BestPractices.md |

## 代码模板 (复制即用)

| 需求 | 模板位置 |
|------|----------|
| 完整的 GFP (.uplugin + Build.cs + 源码) | Docs/CodeTemplates/NewGameFeature/ |
| GA 头文件 + 实现文件 (原始 GAS) | Docs/CodeTemplates/NewGameplayAbility/GA_MyAbility.h/.cpp |
| GA (Lyra 框架) | Docs/CodeTemplates/NewGameplayAbility/GA_LyraAbility示例.h/.cpp |
| AbilitySet 创建指南 | Docs/CodeTemplates/NewGameplayAbility/AbilitySet创建指南.md |
| AttributeSet 完整实现 | Docs/CodeTemplates/NewAttributeSet/MyAttributeSet.h/.cpp |
| GE 配置指南 | Docs/CodeTemplates/NewGameplayEffect/GE配置指南.md |
| Equipment 创建流程 | Docs/CodeTemplates/NewEquipmentType/EquipmentType创建指南.md |
| Weapon 创建流程 | Docs/CodeTemplates/NewWeaponType/WeaponType创建指南.md |
| Experience 创建流程 | Docs/CodeTemplates/NewExperience/Experience创建指南.md |
| PawnData 配置 | Docs/CodeTemplates/NewPawnData/PawnData创建指南.md |
| InputConfig 配置 | Docs/CodeTemplates/NewInputConfig/InputConfig创建指南.md |

## API 签名

| 需求 | 文档 |
|------|------|
| Lyra 类所有公开函数签名 | Docs/APIRef/LyraCoreClasses.md |
| GAS 类所有公开函数签名 | Docs/APIRef/GASCoreClasses.md |
| 常用代码模式 (10种) | Docs/APIRef/CommonPatterns.md |

## 配置

| 需求 | 文档 |
|------|------|
| DefaultGame.ini AssetManager | Docs/ConfigRef/DefaultGameSettings.md |
| DefaultEngine.ini 网络 | Docs/ConfigRef/DefaultGameSettings.md |
| Build.cs 标准配置 | Docs/ConfigRef/DefaultGameSettings.md |
| .uplugin 标准配置 | Docs/ConfigRef/DefaultGameSettings.md |

## 调试排查

| 问题 | 文档 |
|------|------|
| 编译错误 10 种 | Docs/Troubleshooting/CompileErrors.md |
| 运行时错误 9 种 + 控制台命令 | Docs/Troubleshooting/RuntimeErrors.md |
| 多人网络问题 8 种 | Docs/Troubleshooting/NetworkIssues.md |

## 社区资源

| 需求 | 链接 |
|------|------|
| X157 全部 Lyra 文章 | x157.github.io/UE5/LyraStarterGame/ |
| tranek GAS 完整文档 | github.com/tranek/GASDocumentation |
| Unrealist Lyra 深度分析 | unrealist.org/series/lyra/ |
| 官方 Lyra 学习路径 | dev.epicgames.com/community/learning/paths/Z4/lyra-starter-game |
