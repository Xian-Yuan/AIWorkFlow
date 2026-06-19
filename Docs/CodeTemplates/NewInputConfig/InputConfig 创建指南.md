# InputConfig 创建指南

## 概念

Lyra 输入系统用 **GameplayTag 映射 InputAction**，取代传统数字 InputID。

## 创建 InputConfig Data Asset

```
Content Browser → 右键 → Miscellaneous → Data Asset → ULyraInputConfig
命名: DA_MyInputConfig
```

## InputAction → Tag 映射

```
配置映射数组:
  Tag: InputTag.Move          → InputAction: IA_Move
  Tag: InputTag.Look          → InputAction: IA_Look
  Tag: InputTag.Jump          → InputAction: IA_Jump
  Tag: InputTag.Fire          → InputAction: IA_Fire
  Tag: InputTag.Aim           → InputAction: IA_Aim
  Tag: InputTag.Reload        → InputAction: IA_Reload
  Tag: InputTag.Interact      → InputAction: IA_Interact
  Tag: InputTag.QuickBarSlot1 → InputAction: IA_Slot1
  Tag: InputTag.QuickBarSlot2 → InputAction: IA_Slot2
```

## InputAction 创建

```
右键 → Input → Input Action
命名: IA_Move
Value Type: Axis2D (Vector 2D)
```

## InputMappingContext

```
右键 → Input → Input Mapping Context
命名: IMC_Default
配置:
  IA_Move      → W/A/S/D (Modifier: 方向)
  IA_Look      → Mouse XY
  IA_Jump      → Spacebar
  IA_Fire      → Left Mouse Button
  IA_Aim       → Right Mouse Button
```

## 与 Ability 的绑定

AbilitySet 中:
```
GrantedAbilities:
  - Ability: GA_Jump
    InputTag: InputTag.Jump     ← 通过此 Tag 自动绑定输入
  - Ability: GA_Weapon_Fire
    InputTag: InputTag.Fire
```

Lyra 的 `UGameplayAbilitySet` 会自动检查 InputTag 匹配，按下键时激活对应的 Ability。

## 关键代码位置

| 类 | 路径 |
|------|------|
| ULyraInputConfig | LyraGame/Input/LyraInputConfig.h |
| ULyraInputComponent | LyraGame/Input/LyraInputComponent.h |
| ULyraSettingsLocal | LyraGame/Player/LyraSettingsLocal.h |
| ULyraSettingsShared | LyraGame/Player/LyraSettingsShared.h |
