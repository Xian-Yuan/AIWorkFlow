# AbilitySet 创建指南

## 概念

`ULyraAbilitySet` 是 Lyra 中批量授予能力、属性、效果和 Tag 映射的**数据资产**。

## 创建方式

```
Content Browser → 右键 → Miscellaneous → Data Asset → ULyraAbilitySet
命名: DA_AbilitySet_Humanoid
```

## 配置字段

```
GrantedAbilities:
  - Ability: GA_Jump (GameplayAbility)
    InputTag: InputTag.Jump (FGameplayTag)
    SourceObject: None (可选)
    Level: 1
    RemoveAfterActivation: false (激活后是否移除)
    
  - Ability: GA_Weapon_Fire
    InputTag: InputTag.Fire
    Level: 1

GrantedAttributes:
  - AttributeSet: UMyAttributeSet (AttributeSet 类)
    InitData: (可选初始化数据表)

GrantedEffects:
  - GameplayEffect: GE_DefaultAttributes (初始化属性的 GE)
    Level: 1

TagRelationshipMapping:
  - AbilityTagRelationshipMapping: DA_TagRelationshipMapping (可选)
```

## 使用方式

### 在 PawnData 中引用
```
DA_MyPawnData → AbilitySets[0] = DA_AbilitySet_Humanoid
```

### 在 EquipmentDefinition 中引用
```
ED_MyWeapon → AbilitySets[0] = DA_AbilitySet_Weapon
```

### 在 Experience 中通过 Action 授予
```
B_MyExperience → Actions → AddAbilities → AbilitySet
```

## 关键代码位置

| 类 | 路径 |
|------|------|
| ULyraAbilitySet | LyraGame/AbilitySystem/LyraAbilitySet.h |
| ULyraAbilityTagRelationshipMapping | LyraGame/AbilitySystem/LyraAbilityTagRelationshipMapping.h |
