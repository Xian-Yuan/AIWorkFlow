---
name: lyra-gas-dev
description: Lyra+GAS全栈开发。覆盖Experience/GameFeature/GAS/Equipment/Weapon/Input/UI。用户提需求即自主完成架构设计+代码+配置。
---

# Lyra + GAS 全栈开发技能

## 定位

本技能适用于：**用户提需求 → AI 自主设计框架 + 写全部代码 + 配置资源** 的开发模式。

**核心规则**：
- 不修改 Lyra 基础代码，所有自定义逻辑放在 GameFeature Plugin 中
- 不猜测 API — 必须参考 `Docs/APIRef/` 中的精确签名
- 所有 Gameplay 逻辑必须等待 `OnExperienceLoaded` 事件
- 遵循 Lyra 的 Modular Gameplay 模式 + InitState 初始化链

## 文档库引用规则

所有代码生成必须按以下优先级参考文档：

```
1. Docs/CodeTemplates/*        → 完整可复制的 C++ 模板 (最高优先级)
2. Docs/APIRef/*               → 精确 API 签名参考
3. Docs/ConfigRef/*             → 配置文件和 Build 配置
4. Docs/Lyra/*                  → Lyra 架构说明
5. Docs/GAS/*                   → GAS 架构与模式
6. Docs/Troubleshooting/*       → 错误排查 (代码出错时查阅)
7. Docs/Community/*             → X157 等社区深度分析
```

## 输入契约

### 必须收集的信息

1. **需求类型**: 新功能 / 修改 / 重构 / 修复
2. **功能描述**: 具体行为、触发方式、预期效果
3. **所属系统**: Experience / Character / Equipment / Weapon / UI / GAS / Input
4. **网络需求**: 单人 / 多人合作 / 多人对战
5. **数据持久化**: 是否需要存档

### 示例输入格式

```
需求: 创建一个火焰魔法技能
类型: 新功能
系统: GAS + Weapon (可选: Equipment)
网络: 多人对战 (LocalPredicted)
行为: 玩家按 Q 键 → 播放施法动画 → 生成火球投射物 → 命中造成范围伤害
```

## 架构决策树

根据需求类型自动选择实现路径：

```
需求类型 → 判断所属系统 → 选择模板 → 生成代码
```

### 能力/技能类需求
```
[技能/能力/Spell/Ability]
    ├─ 基础能力 (无装备关联)
    │   └─ 模板: CodeTemplates/NewGameplayAbility/GA_MyAbility.h/.cpp
    │   └─ 基类: ULyraGameplayAbility
    │   └─ AbilitySet: CodeTemplates/NewGameplayAbility/AbilitySet创建指南.md
    │
    ├─ 装备能力 (武器/道具)
    │   └─ 模板: CodeTemplates/NewGameplayAbility/GA_LyraAbility示例.h/.cpp
    │   └─ 基类: ULyraGameplayAbility_FromEquipment
    │   └─ Equipment: CodeTemplates/NewEquipmentType/
    │
    └─ 远程武器能力
        └─ 模板: CodeTemplates/NewWeaponType/
        └─ 基类: ULyraGameplayAbility_RangedWeapon
```

### 装备/武器需求
```
[装备/武器/Weapon/Equipment]
    └─ 模板: CodeTemplates/NewEquipmentType/EquipmentType创建指南.md
    └─ 模板: CodeTemplates/NewWeaponType/WeaponType创建指南.md
    └─ 架构: Docs/Lyra/06-EquipmentSystem.md
    └─ 架构: Docs/Lyra/08-WeaponSystem.md
```

### 属性需求
```
[属性/Attribute/Stats]
    └─ 模板: CodeTemplates/NewAttributeSet/MyAttributeSet.h/.cpp
    └─ 文档: Docs/GAS/05-AttributeSet.md
```

### 效果需求
```
[效果/Buff/伤害/Damage/Heal]
    └─ 模板: CodeTemplates/NewGameplayEffect/GE配置指南.md
    └─ 文档: Docs/GAS/04-GameplayEffect.md
```

### 游戏模式/体验需求
```
[游戏模式/Experience/关卡]
    └─ 模板: CodeTemplates/NewExperience/Experience创建指南.md
    └─ 模板: CodeTemplates/NewGameFeature/
    └─ 架构: Docs/Lyra/02-ExperienceSystem.md
```

### UI 需求
```
[UI/界面/HUD/Widget]
    └─ 文档: Docs/Lyra/10-UIExtensionSystem.md
    └─ 文档: Docs/UE5/04-CommonUI.md
```

### 输入需求
```
[输入/按键/Input/Key]
    └─ 模板: CodeTemplates/NewInputConfig/InputConfig创建指南.md
    └─ 文档: Docs/Lyra/09-InputSystem.md
```

## 代码生成工作流

### Stage 1: 设计确认

输出实现计划，包含：
- 使用的模板和基准类
- 新建/修改的文件列表
- 依赖关系（Build.cs、.uplugin 修改）
- 网络策略（复制模式、RPC 需求）

### Stage 2: 配置生成

```
1. .uplugin — 确保 Category 为 "Game Features"，依赖 CommonGame/GameFeatures/ModularGameplay
2. Build.cs — 确保包含 GameplayAbilities/GameplayTags/GameplayTasks/LyraGame/ModularGameplay
3. GameFeatureData — 配置 PrimaryAssetTypes 扫描目录和 GameplayCue 路径
```

### Stage 3: 代码生成

按以下顺序生成文件：

```
1. 数据资产类 (AttributeSet, ItemDefinition, EquipmentDefinition 等)
2. 能力类 (GameplayAbility)
3. 组件类 (Components)
4. Actor/Character 修改
5. Controller/PlayerState 修改
6. ASC 扩展 (如果需要)
7. 配置 (AbilitySet, InputConfig, PawnData, Experience)
```

### Stage 4: 配置资源

在蓝图中需配置的资源：
```
1. GameFeatureData
2. ExperienceDefinition
3. PawnData
4. AbilitySet (引用所有能力)
5. InputConfig + InputMappingContext
6. GameplayEffect
7. EquipmentDefinition (如果涉及装备)
```

### Stage 5: 验证

```
□ Build.cs 依赖完整，无循环依赖
□ .uplugin Category = "Game Features"
□ 所有 .h/.cpp 成对存在
□ GENERATED_BODY() 存在
□ 复制属性: GetLifetimeReplicatedProps + DOREPLIFETIME + OnRep
□ ASC InitAbilityActorInfo 在正确的时机调用
□ Experience 引用正确的 GameFeature Plugin
□ PawnData 引用正确的 AbilitySet
```

## API 调用规则

### GAS 核心 API (精确签名见 Docs/APIRef/GASCoreClasses.md)

| 操作 | 正确 API |
|------|----------|
| 授予能力 | `ASC->GiveAbility(FGameplayAbilitySpec(AbilityClass, Level, Index))` |
| 通过 Tag 激活 | `ASC->TryActivateAbilitiesByTag(TagContainer, true)` |
| 应用效果给自己 | `ASC->ApplyGameplayEffectToSelf(Effect, Level, Context)` |
| 应用效果给目标 | `ASC->ApplyGameplayEffectToTarget(Effect, TargetASC, Level, Context)` |
| 监听属性变化 | `ASC->GetGameplayAttributeValueChangeDelegate(Attr).AddUObject(...)` |
| 发送 GameplayEvent | `ASC->HandleGameplayEvent(Tag, &EventData)` |
| 执行 GameplayCue | `ASC->ExecuteGameplayCue(Tag, Context)` |

### Lyra 核心 API (精确签名见 Docs/APIRef/LyraCoreClasses.md)

| 操作 | 正确 API |
|------|----------|
| 获取 Lyra ASC | `GetPlayerState<ALyraPlayerState>()->GetLyraAbilitySystemComponent()` |
| 添加 AbilitySet | `LyraASC->AddAbilitySets(AbilitySet)` |
| 设置快捷栏槽位 | `QuickBarComp->SetActiveSlotIndex(Index)` |
| 添加物品到背包 | `InventoryManager->AddItem(ItemDefClass)` |
| 装备物品 | `EquipmentManager->EquipItem(EquipDefClass)` |
| 注册输入映射 | `HeroComponent->AddAdditionalInputConfig(InputConfig)` |
| 获取 PawnData | `PawnExtComp->GetPawnData()` |

## 初始化顺序规则

```
正确顺序 (Lyra):
1. GameInstance::Init() → 注册 InitState Tags
2. 关卡加载
3. Experience 开始加载 (async)
4. OnExperienceLoaded → 游戏逻辑开始
5. PlayerState 生成 → ASC 创建
6. Character 生成 → PawnExtensionComponent
7. Controller Possess → InitAbilityActorInfo
8. PawnExtensionComponent 完成 InitState 链
9. HeroComponent 完成相机/输入设置
10. GameplayReady

错误做法:
✗ 在 BeginPlay 中直接使用 ASC
✗ 在构造函数中授予能力
✗ 假设 InitAbilityActorInfo 在 Pawn 生成时已可用
```

## 关键约束

### 代码规范
- 始终提供 `.h` + `.cpp` 配对
- Include 路径相对于模块 `Public/` 目录
- 使用 `TObjectPtr<>` 替代原始指针在头文件中
- 使用 `TSubclassOf<>` 引用类
- 避免硬编码资源路径
- AttributeSet 必须使用 `FGameplayAttributeData` 类型
- Damage 模式: Meta属性 (不复制) → PostGameplayEffectExecute 处理

### Lyra 特定约束
- **不修改** `Source/LyraGame/` 下的任何文件
- 所有新功能放在 `Plugins/GameFeatures/YourPlugin/` 中
- Character 基类应继承 `ALyraCharacter` 而非直接继承 `ACharacter`
- ASC 放在 PlayerState 上 (多人游戏)
- 输入绑定通过 InputTag + AbilitySet，不直接绑定 InputAction
- 所有 Gameplay 需等待 `OnExperienceLoaded`

### 网络约束
- 多人推荐 `ASC ReplicationMode = Mixed`
- 能力推荐 `NetExecutionPolicy = LocalPredicted`
- 属性必须标记 `Replicated` + `DOREPLIFETIME` + `OnRep`
- Instant 效果在服务器执行，通过属性复制影响客户端

## 常见模式参考

### 模式: 创建新能力 → 通过 InputTag 激活

```
1. 创建 ULyraGameplayAbility 子类 (参考 GA_MyAbility 模板)
2. 创建 InputAction
3. 在 InputConfig 中添加 Tag → InputAction 映射
4. 在 AbilitySet 中将能力关联 InputTag
5. 确保 PawnData 引用了这个 InputConfig + AbilitySet
```

### 模式: 创建新武器装备

```
1. 创建 WeaponInstance 子类 (BP 或 C++)
2. 创建 EquipmentDefinition 引用该 WeaponInstance
3. 创建 ItemDefinition (带 EquippableItem Fragment)
4. 创建 GameplayAbility (远程/近战)
5. 在 EquipmentDefinition 的 AbilitySets 中引用
6. 通过 QuickBarComponent 给玩家
```

### 模式: 创建新 GameplayEffect

```
1. 创建 GE 数据资产
2. 配置 DurationPolicy / Modifiers / Tags
3. 对于复杂伤害: 创建 UGameplayEffectExecutionCalculation
4. 在 GameplayAbility 中引用
5. (可选) 关联 GameplayCue
```

## RPG 系统模式（提取自 GAS 教程）

### 模式: WidgetController MVC（UI ↔ GAS 桥接）

```
场景：用 C++ 控制器类连接 ASC 委托到 UMG Widget
```
```cpp
// 基类
class UAuraWidgetController : public UObject
{
    // 初始化
    void SetWidgetControllerParams(APlayerController*, APlayerState*, UAbilitySystemComponent*, UAttributeSet*);
    
    // 子类重写：广播初始值
    virtual void BroadcastInitialValues();
    // 子类重写：绑定 ASC 属性变化回调
    virtual void BindCallbacksToDependencies();
};

// 子类示例
class UOverlayWidgetController : public UAuraWidgetController
{
    UPROPERTY(BlueprintAssignable) FOnHealthChangedSignature OnHealthChanged;
    UPROPERTY(BlueprintAssignable) FOnManaChangedSignature OnManaChanged;
    
    void BroadcastInitialValues() override {
        OnHealthChanged.Broadcast(HealthCurrent);
    }
    void BindCallbacksToDependencies() override {
        ASC->GetGameplayAttributeValueChangeDelegate(Attribute)
            .AddLambda([](const FOnAttributeChangeData& Data) { OnHealthChanged.Broadcast(Data.NewValue); });
    }
};
```

### 模式: RPG 角色职业配置 DataAsset

```cpp
USTRUCT(BlueprintType)
struct FCharacterClassDefaultInfo
{
    GENERATED_BODY()
    UPROPERTY(EditDefaultsOnly) TSubclassOf<UGameplayEffect> PrimaryAttributes;
    UPROPERTY(EditDefaultsOnly) TSubclassOf<UGameplayEffect> SecondaryAttributes;
    UPROPERTY(EditDefaultsOnly) TArray<TSubclassOf<UGameplayAbility>> StartupAbilities;
    UPROPERTY(EditDefaultsOnly) FCurveTableRowHandle XPRewardCurve;
};

UCLASS()
class UCharacterClassInfo : public UDataAsset
{
    UPROPERTY(EditDefaultsOnly) TMap<ECharacterClass, FCharacterClassDefaultInfo> CharacterClassInfoMap;
    UPROPERTY(EditDefaultsOnly) TSubclassOf<UGameplayEffect> SecondaryAttributes_Infinite;
    UPROPERTY(EditDefaultsOnly) TSubclassOf<UGameplayEffect> VitalAttributes;
};
```

### 模式: MMG 推导二级属性（含等级缩放）

```cpp
// MaxHealth = 80 + 2.5 * Vigor + 10 * Level
float CalculateBaseMagnitude_Implementation(const FGameplayEffectSpec& Spec) const
{
    float Vigor = Spec.GetSetByCallerMagnitude(Tag_Vigor);
    float Level = Spec.GetSetByCallerMagnitude(Tag_Level);
    return 80.f + 2.5f * Vigor + 10.f * Level;
}
```

### 模式: Cost + Cooldown GE 模式

```
每个技能单独两个 GE：
  GE_Cost_FireBolt → Instant，消耗 Mana
  GE_Cooldown_FireBolt → Duration，添加 Cooldown.Fire.FireBolt 阻塞 Tag

Ability 构造函数中：
  CostGameplayEffectClass = GE_Cost_FireBolt;
  CooldownGameplayEffectClass = GE_Cooldown_FireBolt;

ActivateAbility 中：
  CommitAbility(Handle, ActorInfo, ActivationInfo); // 自动扣除 Cost，应用 Cooldown
  if (!CommitAbility(...)) { EndAbility(...); return; }
```

### 模式: XP/等级系统（PlayerState 上）

```cpp
// PlayerState 上
UPROPERTY(ReplicatedUsing=OnRep_XP) int32 XP;
UPROPERTY(ReplicatedUsing=OnRep_Level) int32 Level;
UPROPERTY(ReplicatedUsing=OnRep_AttributePoints) int32 AttributePoints;
UPROPERTY(ReplicatedUsing=OnRep_SpellPoints) int32 SpellPoints;

// 升级信息 DataAsset
USTRUCT() struct FLevelUpInfo {
    int32 Level;
    int32 RequiredXP;
    int32 AttributePointReward;
    int32 SpellPointReward;
};

// XP 事件驱动：AttributeSet::PostGameplayEffectExecute 检测 XP 变化 → SendXPEvent → LevelUpCheck
```

### 模式: 被动技能（Infinite GE）

```cpp
void UAuraPassiveSpell::ActivateAbility(...)
{
    // 激活后自动永久生效
    FGameplayEffectSpecHandle Spec = MakeOutgoingGameplayEffectSpec(PassiveEffectClass, Level);
    ApplyGameplayEffectSpecToOwner(Handle, ActorInfo, ActivationInfo, Spec);
}
// Duration = Infinite, 装备即生效，卸载时 RemoveActiveEffect
```

### 模式: 多投射物扇形生成

```cpp
// 11 个投射物以弧形排列
FVector Forward = GetAvatarActor()->GetActorForwardVector();
float SpreadRad = FMath::DegreesToRadians(180.f); // 扇形角度
for (int32 i = 0; i < 11; ++i) {
    float Angle = -SpreadRad/2 + (SpreadRad * i / 10.f);
    FVector Dir = Forward.RotateAngleAxis(FMath::RadiansToDegrees(Angle), FVector::UpVector);
    SpawnProjectile(Location + Dir * Radius, Dir);
}
```

### 模式: 连锁技能（Looping GameplayCue）

```cpp
// 电击连锁：从主目标向外传递
void ApplyChainEffect(AActor* Current, TArray<AActor*> AlreadyHit, int32 Depth = 0)
{
    if (Depth >= MaxChainLength) return;
    // 径向检测下一个目标
    // 应用伤害 GE
    // ExecuteGameplayCueLocal(ArcTag, Params); // 视觉电弧
    ApplyChainEffect(NextTarget, AlreadyHit, Depth + 1);
}
```

### 模式: 技能装备系统（SpellMenu → Input Slot）

```cpp
// SpellMenuWidgetController
void SpawnSpellGlobes();            // 根据 FAbilityInfo[] 生成技能球
void OnSpellGlobeSelected(FGameplayTag AbilityTag);
void OnEquipButtonPressed();         // 将选中技能绑定到 CurrentInputSlot
void OnSpendPointButtonPressed();    // 消耗 SpellPoints 升级技能

// FAbilityInfo DataAsset 定义技能元数据
UPROPERTY() FGameplayTag AbilityTag;
UPROPERTY() TSubclassOf<UGameplayAbility> AbilityClass;
UPROPERTY() int32 LevelRequirement;
UPROPERTY() EAbilityType Type;     // Active / Passive
UPROPERTY() FText Description;

| 错误 | 检查点 | Docs 参考 |
|------|--------|-----------|
| 编译: 找不到头文件 | Build.cs 是否缺失模块？Include 路径是否正确？ | Troubleshooting/CompileErrors.md |
| 编译: 链接错误 | 函数声明与实现是否匹配？ | Troubleshooting/CompileErrors.md |
| 运行时: 能力不激活 | NetExecutionPolicy？Cost/Cool-down？Tag阻塞？ | Troubleshooting/RuntimeErrors.md |
| 运行时: 属性不更新 | Replicated标记？DOREPLIFETIME？OnRep？ | Troubleshooting/RuntimeErrors.md |
| 运行时: GFP不加载 | .uplugin Category？Plugins路径？ | Troubleshooting/RuntimeErrors.md |
| 网络: 客户端看不到效果 | ASC ReplicationMode？能力 LocalPredicted？ | Troubleshooting/NetworkIssues.md |

## 文档快速查找表

| 我需要... | 打开... |
|-----------|---------|
| 完整可编译的 GFP 模板 | Docs/CodeTemplates/NewGameFeature/ |
| 能力 (GA) 模板 + API 签名 | Docs/CodeTemplates/NewGameplayAbility/ + Docs/APIRef/GASCoreClasses.md |
| 属性集 (AS) 模板 | Docs/CodeTemplates/NewAttributeSet/ |
| 效果 (GE) 配置 | Docs/CodeTemplates/NewGameplayEffect/ |
| 装备系统模板 | Docs/CodeTemplates/NewEquipmentType/ |
| 武器系统模板 | Docs/CodeTemplates/NewWeaponType/ |
| Experience 创建 | Docs/CodeTemplates/NewExperience/ |
| PawnData 配置 | Docs/CodeTemplates/NewPawnData/ |
| InputConfig 配置 | Docs/CodeTemplates/NewInputConfig/ |
| Lyra 架构详解 | Docs/Lyra/ |
| GAS 架构详解 | Docs/GAS/ |
| Build 配置 .ini / .uplugin | Docs/ConfigRef/ |
| 错误排查 | Docs/Troubleshooting/ |
| 社区深度分析 | Docs/Community/01-X157DevNotes.md |
| 常用代码模式 | Docs/APIRef/CommonPatterns.md |

## Escalation

以下情况应当上报或请求用户澄清：
1. 需求涉及修改 Lyra 基础代码 — 指出风险并建议用 GFP 方式
2. 需求涉及引擎源码修改 — 指出不可行性
3. 需求信息不足 — 请求用户补充具体行为描述
4. 需求涉及违规操作（如 GAS 不支持的网络模式）— 指出不支持并建议替代方案
5. 跨技能领域（如需要 UI + 后端 + 网络）— 拆分为多个阶段处理
