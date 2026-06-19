# UE5 Lyra + GAS 开发文档库

基于 UE5 Lyra 框架和 GAS (Gameplay Ability System) 框架的开发文档库。

## 目录结构

```
Docs/
├── index.md              # 本文件 — 文档库入口
├── AI/                   # AI 主导开发手册
│   ├── README.md                     # AI 文档总入口
│   ├── 01-AI-Development-Playbook.md
│   ├── 02-Project-Truth-Source.md
│   ├── 03-Singleplayer-Lyra-GAS-Rules.md
│   ├── 04-Asset-Checklists.md
│   ├── 05-StateTree-BT-EQS-SmartObject.md
│   ├── 06-GameplayTag-Registry.md
│   ├── 07-Test-Checklists.md
│   ├── 08-AntiPatterns.md
│   ├── 09-Agent-Handoff-Templates.md
│   ├── 10-Execution-Examples.md
│   ├── 11-Skill-Routing-Workflow.md
│   ├── 12-MultiAgent-Workflow.md
│   ├── 13-File-Placement-Convention.md
│   ├── 14-Coding-Standards.md
│   ├── 15-FailSafe-AntiBloat.md
│   ├── 16-Quality-Grade-Rules.md → 已移至项目 Documentation/Design/07_Items/
│   ├── 17-Self-Improving-Framework.md
│   ├── 18-Validation-Checklist.md
│   ├── 19-Unreal-Conventions.md
│   └── 20-Terminology-Rules.md → 已移至项目 Documentation/CodeGuidelines/
├── Lyra/                 # Lyra 项目架构文档
│   ├── 01-Overview.md              # Lyra 概述与架构
│   ├── 02-ExperienceSystem.md      # Experience 系统
│   ├── 03-GameFeaturePlugins.md    # GameFeature Plugin 系统
│   ├── 04-ModularGameplay.md       # Modular Gameplay 模式
│   ├── 05-PawnCharacterSystem.md   # Pawn 与 Character 系统
│   ├── 06-EquipmentSystem.md       # 装备系统
│   ├── 07-InventorySystem.md       # 背包系统
│   ├── 08-WeaponSystem.md          # 武器系统
│   ├── 09-InputSystem.md           # 输入系统
│   ├── 10-UIExtensionSystem.md     # UI 扩展系统
│   ├── 10-UIExtensionSystem.md     # UI 扩展系统
│   ├── 11-AnimationSystem.md       # 动画系统
│   ├── 12-Module-Dependencies.md   # 模块依赖关系
│   ├── 13-Modular-Character-System.md # 模块化角色系统
│   ├── Animation/                  # 动画蓝图指南 (10 files, 1 JM专属已移至项目)
│   └── Camera/                     # 镜头指南 (5 files)
├── GAS/                  # GAS 架构文档
│   ├── 01-Overview.md              # GAS 概述
│   ├── 02-ASC.md                   # AbilitySystemComponent
│   ├── 03-GameplayAbility.md       # GameplayAbility
│   ├── 04-GameplayEffect.md        # GameplayEffect
│   ├── 05-AttributeSet.md          # AttributeSet
│   ├── 06-GameplayCue.md           # GameplayCue
│   ├── 07-AbilityTasks.md          # AbilityTask
│   ├── 08-Targeting.md             # 目标系统
│   ├── 09-Prediction.md            # 网络预测
│   └── 10-BestPractices.md         # 最佳实践
├── UE5/                  # UE5 通用开发文档
│   ├── 01-GameplayFramework.md     # 游戏框架
│   ├── 02-Networking.md            # 网络复制
│   ├── 03-EnhancedInput.md         # 增强输入系统
│   ├── 04-CommonUI.md              # CommonUI 系统
│   └── 05-AssetManager.md          # 资源管理系统
├── UE5.7/                # UE5.7 特定文档
│   ├── 01-NewFeatures.md           # 5.7 新特性
│   └── 02-LyraUpgrade.md           # Lyra 升级指南
├── Tutorials/            # 教程
│   ├── 01-SetupLyraProject.md      # Lyra 项目搭建
│   ├── 02-First60MinGAS.md         # GAS 入门
│   └── 03-CreateGameFeature.md     # 创建 GameFeature
└── Community/            # 社区资源
    └── 01-X157DevNotes.md          # X157 开发笔记索引
```

## 补充文档（提需求→AI 自主写代码）

```
Docs/
├── AI/                      # ★ AI 执行规则、项目真相源、单机规则、资产检查表、AI/NPC 选型
├── CodeTemplates/           # ★ 完整可编译模板
│   ├── NewGameFeature/      #   完整 GFP: .uplugin + Build.cs + 源码
│   │   ├── MyGame.uplugin
│   │   ├── MyGame.uplugin 配置说明.md
│   │   ├── Source/MyGame.Build.cs
│   │   ├── Source/MyGame.h
│   │   └── Source/MyGame.cpp
│   ├── NewGameplayAbility/  #   UGameplayAbility + ULyraGameplayAbility 模板
│   │   ├── GA_MyAbility.h/.cpp           # 原始 GAS 能力
│   │   ├── GA_LyraAbility示例.h/.cpp     # Lyra 框架能力
│   │   └── AbilitySet 创建指南.md
│   ├── NewAttributeSet/     #   AttributeSet 完整实现 (含复制、回调)
│   ├── NewGameplayEffect/   #   GE 配置指南 (所有策略/修饰符/组件)
│   ├── NewEquipmentType/    #   Equipment 完整创建流程
│   ├── NewWeaponType/       #   Weapon 完整创建流程
│   ├── NewExperience/       #   Experience 完整创建流程
│   ├── NewPawnData/         #   PawnData 配置指南
│   └── NewInputConfig/      #   InputConfig + InputMapping 配置指南
├── APIRef/                  # ★ 精确 API 签名
│   ├── LyraCoreClasses.md   #   Lyra 全部核心类的 public 函数签名
│   ├── GASCoreClasses.md    #   GAS 全部核心类的 public 函数签名
│   ├── AbilityTaskSignatures.md  # 11 个 AbilityTask 完整 Create 签名
│   ├── UECommonAPIRef.md    #   UGameplayStatics/KismetSystemLibrary 高频 API
│   ├── UEMacrosRef.md       #   UE 宏全谱 (含 Blueprint 互操作速查表 §15)
│   └── CommonPatterns.md    #   10 种常用代码模式 (复制即用)
├── ConfigRef/               # ★ 配置文件参考
│   └── DefaultGameSettings.md  # .ini / .uplugin / Build.cs 完整配置
├── ErrorKB/                 # ★ 29+ 错误条目知识库 (含自动匹配规则)
│       ├── E000-TEMPLATE.md       #   新增条目模板
│       ├── E001-E009: 编译错误
│       ├── E010-E020: 资产+运行时错误
│       └── E021-E029: 逻辑错误+运行时错误
├── Troubleshooting/         # ★ 错误排查
│   ├── CompileErrors.md     #   编译错误 (10 种常见错误 + 解决)
│   ├── RuntimeErrors.md     #   运行时错误 + 调试命令
│   ├── NetworkIssues.md     #   多人网络问题排查
│   └── Project-JIANMU-*.md  #   JM项目专属错误预防 → 已移至项目 Documentation/CodeGuidelines/
├── ResourceInventory.md        # ★ 全仓库资源清单 (Skills/Docs/Templates/ErrorKB 全索引)
└── SkillKB/                   # ★ xg-uecpp-course UE C++ 知识库
    ├── knowledge/              #   37 章 + 横向模式 (~40 files)
    └── references/             #   21 个专题参考文档
```

## AI 主导开发入口

如果目标是“我只提需求，AI 主导方案、代码、配置和自检”，建议先阅读：

1. `Docs/AI/01-AI-Development-Playbook.md`
2. `Docs/AI/02-Project-Truth-Source.md`
3. `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
4. `Docs/AI/04-Asset-Checklists.md`
5. `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
6. `Docs/AI/06-GameplayTag-Registry.md`
7. `Docs/AI/07-Test-Checklists.md`
8. `Docs/AI/08-AntiPatterns.md`
9. `Docs/AI/09-Agent-Handoff-Templates.md`
10. `Docs/AI/10-Execution-Examples.md`
11. `Docs/AI/11-Skill-Routing-Workflow.md`
12. `Docs/AI/12-MultiAgent-Workflow.md`

这组文档用于把现有 `Lyra / GAS / CodeTemplates / APIRef / Troubleshooting` 组织成可执行流程，降低 AI 猜函数、漏配置、误用网络逻辑和遗漏资产接线的概率。

## 官方文档入口

| 文档 | 链接 |
|------|------|
| Lyra 主页 | https://dev.epicgames.com/documentation/unreal-engine/lyra-sample-game-in-unreal-engine |
| Lyra 导览 | https://dev.epicgames.com/documentation/en-us/unreal-engine/tour-of-lyra-in-unreal-engine |
| Lyra 能力系统 | https://dev.epicgames.com/documentation/en-us/unreal-engine/abilities-in-lyra-in-unreal-engine |
| Lyra 输入系统 | https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine |
| Lyra 交互系统 | https://dev.epicgames.com/documentation/unreal-engine/lyra-sample-game-interaction-system-in-unreal-engine |
| Lyra 动画系统 | https://dev.epicgames.com/documentation/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine |
| Lyra 扩展与设备 | https://dev.epicgames.com/documentation/en-us/unreal-engine/scalability-and-device-profiles-in-lyra-sample-game-for-unreal-engine |
| GAS 概述 | https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system |
| GAS 类参考 | https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities |
| Gameplay 框架 | https://dev.epicgames.com/documentation/unreal-engine/gameplay-framework-in-unreal-engine |
| CommonUser 插件 | https://dev.epicgames.com/documentation/unreal-engine/common-user-plugin-in-unreal-engine-for-lyra-sample-game |
| GameFramework 组件管理 | https://dev.epicgames.com/documentation/unreal-engine/game-framework-component-manager-in-unreal-engine |
