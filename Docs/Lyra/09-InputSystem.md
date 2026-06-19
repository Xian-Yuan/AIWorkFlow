# 输入系统

## 概念

Lyra 输入系统基于 **Enhanced Input**，使用 **GameplayTag 驱动能力激活**，取代了传统的数字 InputID。

## 核心类

| 类 | 职责 |
|------|------|
| `ULyraInputConfig` | 输入配置数据资产 — Tag → InputAction 映射 |
| `ULyraInputComponent` | 自定义输入组件 — 管理 PlayerMappableInputConfig |
| `ULyraSettingsLocal` | 本地设置 — 存放所有输入映射和自定义按键 |
| `ULyraSettingsShared` | 共享设置 — 按键绑定（可云同步） |
| `UGameFeatureAction_AddInputConfig` | GFP Action — 注册 Enhanced Input 配置 |
| `ULyraAbilitySet` | 能力集 — Tag → GameplayAbility 映射，自动检测 Input Tag 激活 |

## Tag 驱动的工作流

```
Input Action (键盘/手柄)
    ↓ 映射到
GameplayTag (如: InputTag.Move, InputTag.Jump)
    ↓
LyraInputConfig 查找 InputAction → Tag
    ↓
ULyraInputComponent 处理输入
    ↓
AbilitySystemComponent 根据 Tag 激活对应 Ability
```

**优势**: 输入与能力解耦。替换输入方式只需重新映射 Tag，无需修改能力。

## 输入修饰器

| 修饰器 | 作用 |
|--------|------|
| `ULyraInputModifierGamepadSensitivity` | 手柄灵敏度 |
| `ULyraInputModifierAimInversion` | 反转视角 |
| 死区修饰器 | 手柄摇杆死区 |

## 配置层次

1. **ULyraInputConfig** — 定义 Tag → InputAction 基础映射
2. **ULyraSettingsLocal** — 存储当前激活的所有 InputConfig
3. **ULyraSettingsShared** — 用户自定义按键绑定（云同步）

## 参考链接

- 官方 Lyra 输入文档: https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine
- X157 输入说明: https://x157.github.io/UE5/LyraStarterGame/
