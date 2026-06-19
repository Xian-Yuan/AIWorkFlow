# GAS (Gameplay Ability System) 概述

## 什么是 GAS

GAS 是 UE 的插件，提供了一套完整的框架用于**定义、管理、复制和执行游戏中的能力和交互**。被 Fortnite、Lyra 等商业项目验证。

## 适用场景

- RPG、MOBA、动作冒险游戏
- 需要能力/技能系统
- 需要 Buff/Debuff 系统
- 需要属性 (Attribute) 系统
- 需要**多人网络复制**的能力系统

## 核心组件

| 组件 | 职责 |
|------|------|
| **UAbilitySystemComponent (ASC)** | 核心组件，管理所有能力、效果、属性、标签 |
| **UGameplayAbility** | 能力定义 — 具体的游戏行为逻辑 |
| **UGameplayEffect** | 效果定义 — 修改属性、授予标签/能力 |
| **UAttributeSet** | 属性集 — 定义和管理属性 (Health, Mana 等) |
| **UGameplayCue** | 游戏提示 — 音效、粒子等视觉反馈 (仅客户端) |
| **UAbilityTask** | 异步任务 — 等待动画、输入、事件等 |
| **UGameplayEffectExecutionCalculation** | 执行计算 — 自定义伤害计算逻辑 |

## 启用 GAS

### 1. 启用插件
```
编辑 → 插件 → GameplayAbilities → 启用
```

### 2. Build.cs 添加模块
```cpp
PublicDependencyModuleNames.AddRange(new string[] {
    "GameplayAbilities",
    "GameplayTags",
    "GameplayTasks"
});
```

### 3. 初始化 (UE 5.3+ 自动调用，旧版本手动)
```cpp
// 在 UAssetManager::StartInitialLoading() 中
UAbilitySystemGlobals::Get().InitGlobalData();
```

## 核心设计原则

| 原则 | 说明 |
|------|------|
| 自包含 | 能力封装自己的所有行为 |
| GameplayTag 驱动 | 使用 Tag 系统控制能力激活/阻塞/取消 |
| 网络感知 | 内置多人游戏复制和预测支持 |
| 数据驱动 | 效果 (GameplayEffect) 为纯数据资产，无需继承 |
| 组件架构 (5.3+) | GameplayEffect 使用组件系统定义行为 |

## ASC 放置位置

| 位置 | 适用场景 |
|------|----------|
| **PlayerState** | 多人游戏推荐 (角色死亡/重生时 ASC 保留) |
| **Character** | 单玩家游戏 / AI 小兵 |
| **Pawn** | 非角色 Actor（如载具） |
| **Actor** | 任何需要能力的对象 |

## 参考链接

- 官方 GAS 概述: https://dev.epicgames.com/documentation/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- 官方 GAS API: https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities
- tranek GAS 文档: https://github.com/tranek/GASDocumentation
- UnrealDirective GAS 参考: https://unrealdirective.com/resources/cpp-reference/gas/
