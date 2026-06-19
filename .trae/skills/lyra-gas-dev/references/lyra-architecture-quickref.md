# Lyra 架构快速参考

## 核心架构图

```
[关卡] → 指定 Experience
    ↓
ExperienceDefinition
    ├─ GameFeaturesToEnable: [GFP 列表]
    ├─ DefaultPawnData
    │   ├─ PawnClass
    │   ├─ AbilitySets → [GA, AS, GE]
    │   ├─ InputConfig → [Tag → InputAction]
    │   └─ CameraMode
    └─ ActionSets → [共享 Actions]
    ↓
GameFeature Plugin 加载 → GameFeatureActions 执行
    ├─ AddComponents → Actor 注入组件
    ├─ AddInputConfig → 注册输入
    └─ AddWidget → UI 扩展
    ↓
OnExperienceLoaded → 游戏开始
```

## 模块依赖关系

```
GameFeature Plugin (MyGame)
    ├─ .uplugin → plugins: [CommonGame, GameFeatures, ModularGameplay]
    ├─ Build.cs → modules: [LyraGame, GameplayAbilities, GameplayTags, 
    │                        GameplayTasks, CommonGame, ModularGameplay, 
    │                        EnhancedInput, UIExtension]
    └─ GameFeatureData → primary asset scan dirs + gameplay cue paths
```

## ASC 放置规则 (多人游戏)

```
PlayerState
    └─ ULyraAbilitySystemComponent (ReplicationMode = Mixed)
        ├─ AbilitySystemActorInfo.OwnerActor = PlayerState
        │                    .AvatarActor = Pawn
        ├─ AttributeSets
        ├─ ActivatableAbilities
        └─ ActiveGameplayEffects
```

## InitState 链

```
InitState_Spawned (0) → Actor 生成
    ↓ CheckDefaultInitialization()
InitState_DataAvailable (1) → PawnData + Controller 就绪
    ↓
InitState_DataInitialized (2) → 能力授予 + 输入绑定
    ↓
InitState_GameplayReady (3) → 相机启动 + UI 就绪
```

## Experience 生命周期

```
SetCurrentExperience (Server)
    → OnRep_CurrentExperience (Client)
    → StartExperienceLoad()
        ├─ Async load Experience Asset
        └─ Async load Asset Bundles
    → OnExperienceLoadComplete()
        ├─ Collect + Load GameFeature Plugins
        └─ Wait for all plugins
    → OnExperienceFullLoadCompleted()
        └─ Execute GameFeatureActions
        └─ Broadcast OnExperienceLoaded
```

## Equipment/Inventory 关系

```
InventoryManagerComponent (Controller)
    └─ InventoryItemInstance
        └─ InventoryItemDefinition
            └─ Fragment[]
                ├─ InventoryFragment_EquippableItem
                │   └─ EquipmentDefinition
                │       └─ EquipmentInstance
                │           ├─ Spawn Actor
                │           └─ Grant Abilities → ASC
                └─ InventoryFragment_ReticleConfig
                └─ InventoryFragment_SetColor

QuickBarComponent (Controller)
    └─ Slot[] → EquipmentManagerComponent (Pawn)
        └─ EquipItem / UnequipItem
```
