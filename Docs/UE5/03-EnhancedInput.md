# Enhanced Input 系统

## 核心概念

| 概念 | 说明 |
|------|------|
| **InputAction** | 定义输入的类型和触发条件 |
| **InputMappingContext** | 键位映射上下文，将按键映射到 InputAction |
| **PlayerMappableInputConfig** | 玩家可配置的输入配置集合 |
| **Modifier** | 输入修饰器 (灵敏度、反转等) |
| **Trigger** | 触发条件 (按下、释放、长按等) |

## Lyra 中的集成

```
PlayerMappableInputConfig
    └─ InputMappingContexts (优先级排序)
        └─ Mapping: Key → InputAction
            ├─ Modifiers
            └─ Triggers

ULyraInputConfig: GameplayTag → InputAction 映射
    └─ ASC 通过 Tag 自动激活对应 Ability
```

## 输入配置注册

通过 GameFeatureAction 注册:

```cpp
// UGameFeatureAction_AddInputConfig 在 GFP 加载时
// 自动将 PlayerMappableInputConfig 注册到 LocalPlayer
```

## 参考链接

- 官方 Lyra Input: https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine
- 官方 Enhanced Input 文档: https://dev.epicgames.com/documentation/unreal-engine/enhanced-input
