# GAS 核心类 API 签名参考

## UAbilitySystemComponent

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/AbilitySystemComponent.h

// ====== 初始化 ======
void InitAbilityActorInfo(AActor* InOwnerActor, AActor* InAvatarActor);
void SetReplicationMode(EGameplayEffectReplicationMode NewReplicationMode);

// ====== 能力管理 ======
FGameplayAbilitySpecHandle GiveAbility(const FGameplayAbilitySpec& AbilitySpec);
FGameplayAbilitySpecHandle GiveAbilityAndActivateOnce(const FGameplayAbilitySpec& AbilitySpec);
void SetRemoveAbilityOnEnd(FGameplayAbilitySpecHandle AbilityHandle);
void ClearAbility(FGameplayAbilitySpecHandle Handle);
void ClearAllAbilities();

// 查询
bool HasAbility(TSubclassOf<UGameplayAbility> InAbilityClass, int32* OutAbilityLevel = nullptr) const;
FGameplayAbilitySpec* FindAbilitySpec(TSubclassOf<UGameplayAbility> InAbilityClass);
FGameplayAbilitySpec* FindAbilitySpecFromHandle(FGameplayAbilitySpecHandle Handle);
int32 GetActivatableAbilitiesCount() const;
TArray<FGameplayAbilitySpec>& GetActivatableAbilities();

// 激活
bool TryActivateAbility(FGameplayAbilitySpecHandle AbilityHandle, bool bAllowRemoteActivation = true);
bool TryActivateAbilityByClass(TSubclassOf<UGameplayAbility> InAbilityToActivate, bool bAllowRemoteActivation = true);
bool TryActivateAbilitiesByTag(const FGameplayTagContainer& GameplayTagContainer, bool bAllowRemoteActivation = true);
bool TryActivateAbilityByClassWithContext(TSubclassOf<UGameplayAbility> InAbilityToActivate, bool bAllowRemoteActivation = true, FPredictionKey* PredictionKey = nullptr);
bool TriggerAbilityFromGameplayEvent(FGameplayAbilitySpecHandle AbilityHandle, FGameplayAbilityActorInfo* ActorInfo, FGameplayTag EventTag, const FGameplayEventData* Payload, UAbilitySystemComponent& Component);

// 取消
void CancelAbility(FGameplayAbilitySpecHandle Handle);
void CancelAbilityByClass(TSubclassOf<UGameplayAbility> InAbilityClass);
void CancelAllAbilities(UGameplayAbility* IgnoreAbility = nullptr);

// 输入绑定
void AbilityInputTagPressed(const FGameplayTag& InputTag);
void AbilityInputTagReleased(const FGameplayTag& InputTag);
void ProcessAbilityInput(float DeltaTime, bool bGamePaused);
void ClearAbilityInput();

// ====== GameplayEffect 管理 ======
FActiveGameplayEffectHandle ApplyGameplayEffectToSelf(const UGameplayEffect* Effect, float Level, const FGameplayEffectContextHandle& EffectContext);
FActiveGameplayEffectHandle ApplyGameplayEffectToTarget(const UGameplayEffect* Effect, UAbilitySystemComponent* Target, float Level, const FGameplayEffectContextHandle& Context);
TArray<FActiveGameplayEffectHandle> ApplyGameplayEffectToSpec(const FGameplayEffectSpecHandle& SpecHandle);

// 批量
void ApplyGameplayEffectSpecToSelf(const FGameplayEffectSpec& Spec);
FActiveGameplayEffectHandle ApplyGameplayEffectSpecToTarget(const FGameplayEffectSpec& Spec, UAbilitySystemComponent* Target);

// 移除
bool RemoveActiveGameplayEffect(FActiveGameplayEffectHandle Handle, int32 StacksToRemove = -1);
void RemoveActiveGameplayEffectBySourceEffect(TSubclassOf<UGameplayEffect> EffectClass, UAbilitySystemComponent* InstigatorASC, int32 StacksToRemove = -1);

// 查询
bool IsActiveGameplayEffectActive(FActiveGameplayEffectHandle Handle) const;
const FActiveGameplayEffect* GetActiveGameplayEffect(FActiveGameplayEffectHandle Handle) const;
float GetGameplayEffectMagnitude(FActiveGameplayEffectHandle Handle, FGameplayAttribute Attribute) const;
int32 GetGameplayEffectCount(TSubclassOf<UGameplayEffect> EffectClass, UAbilitySystemComponent* OptionalInstigatorASC = nullptr, bool bEnforceOnGoingCheck = true) const;

// ====== 属性管理 ======
float GetNumericAttribute(const FGameplayAttribute& Attribute) const;
void SetNumericAttribute(const FGameplayAttribute& Attribute, float NewValue);
float GetNumericAttributeBase(const FGameplayAttribute& Attribute) const;
void SetNumericAttributeBase(const FGameplayAttribute& Attribute, float NewValue);

// ====== Tag 管理 ======
bool HasMatchingGameplayTag(FGameplayTag TagToCheck) const;
bool HasAllMatchingGameplayTags(const FGameplayTagContainer& TagContainer) const;
bool HasAnyMatchingGameplayTags(const FGameplayTagContainer& TagContainer) const;
void AddLooseGameplayTag(const FGameplayTag& Tag, int32 Count = 1);
void AddLooseGameplayTags(const FGameplayTagContainer& GameplayTags, int32 Count = 1);
void RemoveLooseGameplayTag(const FGameplayTag& Tag, int32 Count = 1);
void RemoveLooseGameplayTags(const FGameplayTagContainer& GameplayTags, int32 Count = 1);

FOnGameplayEffectAppliedDelegate& OnGameplayEffectAppliedDelegateToSelf();
FOnGameplayEffectAppliedDelegate& OnGameplayEffectAppliedDelegateToTarget();

// ====== GameplayEvent ======
int32 HandleGameplayEvent(FGameplayTag EventTag, const FGameplayEventData* Payload);

// ====== GameplayCue ======
void ExecuteGameplayCue(const FGameplayTag GameplayCueTag, FGameplayEffectContextHandle EffectContext);
void ExecuteGameplayCue(const FGameplayTag GameplayCueTag, const FGameplayCueParameters& GameplayCueParameters);
void AddGameplayCue(const FGameplayTag GameplayCueTag, FGameplayEffectContextHandle EffectContext);
void AddGameplayCue(const FGameplayTag GameplayCueTag, const FGameplayCueParameters& GameplayCueParameters);
void RemoveGameplayCue(const FGameplayTag GameplayCueTag);
void RemoveAllGameplayCues();

// ====== 调试 ======
void PrintDebug();
```

## UGameplayAbility

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/Abilities/GameplayAbility.h

// ====== 核心生命周期 ======
virtual bool CanActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayTagContainer* SourceTags, const FGameplayTagContainer* TargetTags,
    FGameplayTagContainer* OptionalRelevantTags) const;
virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData);
virtual void EndAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo, bool bReplicateEndAbility, bool bWasCancelled);

// ====== 消耗和冷却 ======
virtual void ApplyCost(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo) const;
virtual void ApplyCooldown(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo) const;
virtual bool CheckCost(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    OUT TArray<FActiveGameplayEffectHandle>* OutPendingCosts = nullptr) const;
virtual bool CheckCooldown(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    OUT FGameplayTagContainer* OptionalRelevantTags = nullptr) const;
bool CommitAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo, OUT FGameplayTagContainer* OptionalRelevantTags = nullptr);
bool CommitCheck(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
    const FGameplayAbilityActivationInfo ActivationInfo);

// ====== GameplayEffect 应用 ======
TArray<FActiveGameplayEffectHandle> ApplyGameplayEffectToTarget(
    TSubclassOf<UGameplayEffect> EffectClass, const FGameplayAbilityTargetDataHandle& TargetData,
    float Level, int32 Stacks);
FActiveGameplayEffectHandle ApplyGameplayEffectToOwner(
    TSubclassOf<UGameplayEffect> EffectClass, float Level, int32 Stacks);

// ====== 任务管理 ======
void AddAbilityTask(UAbilityTask* AbilityTask);
void RemoveAbilityTask(UAbilityTask* AbilityTask);

// ====== Actor 信息访问 ======
AActor* GetOwningActorFromActorInfo() const;
AActor* GetAvatarActorFromActorInfo() const;
AController* GetControllerFromActorInfo() const;
UAbilitySystemComponent* GetAbilitySystemComponentFromActorInfo() const;

// ====== Tag 系统 ======
FGameplayTagContainer GetAbilityTags() const;

// ====== 配置属性 ======
EGameplayAbilityInstancingPolicy InstancingPolicy;    // InstancedPerActor / InstancedPerExecution / NonInstanced
EGameplayAbilityNetExecutionPolicy NetExecutionPolicy; // LocalPredicted / LocalOnly / ServerOnly / ServerInitiated
EGameplayAbilityNetSecurityPolicy NetSecurityPolicy;   // ClientOrServer / ServerOnlyExecution / ServerOnlyTermination

UPROPERTY(EditDefaultsOnly)
FGameplayTagContainer ActivationOwnedTags;
UPROPERTY(EditDefaultsOnly)
FGameplayTagContainer BlockedByTags;
UPROPERTY(EditDefaultsOnly)
FGameplayTagContainer CancelAbilitiesWithTag;

UPROPERTY(EditDefaultsOnly)
TSubclassOf<UGameplayEffect> CostGameplayEffectClass;
UPROPERTY(EditDefaultsOnly)
TSubclassOf<UGameplayEffect> CooldownGameplayEffectClass;

bool bReplicateInputDirectly;
```

## UGameplayEffect

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/GameplayEffect.h

// 持续策略
EGameplayEffectDurationType DurationPolicy; // Instant / HasDuration / Infinite

// 持续期
FScalableFloat DurationMagnitude;

// 周期
float Period;                 // 每个周期触发的间隔秒数
bool bExecutePeriodicEffectOnApplication; // 应用时立即触发一次

// 修饰符数组
TArray<FGameplayModifierInfo> Modifiers;
// FGameplayModifierInfo:
//   FGameplayAttribute Attribute
//   EGameplayModOp::Type ModifierOp (Add/Multiply/Divide/Override)
//   FGameplayEffectModifierMagnitude Magnitude

// 执行计算数组 (Executions)
TArray<FGameplayEffectExecutionDefinition> Executions;
// FGameplayEffectExecutionDefinition:
//   TSubclassOf<UGameplayEffectExecutionCalculation> CalculationClass

// 应用要求
TSubclassOf<UGameplayEffectCustomApplicationRequirement> ApplicationRequirement;

// 条件 (旧版本)
FGameplayTagRequirements ApplicationTagRequirements; // 应用条件
FGameplayTagRequirements OngoingTagRequirements;     // 持续条件
FGameplayTagRequirements RemovalTagRequirements;     // 移除条件

// 堆叠
FGameplayEffectStackingDefinition Stacking;  // 堆叠行为

// 授予能力 (旧版本, 5.3+ 推荐用 GE Component)
TArray<FGameplayAbilitySpecDef> GrantedAbilities;
```

## UAttributeSet

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/AttributeSet.h

// 关键回调
virtual void PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue);
virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data);
virtual void PreAttributeBaseChange(const FGameplayAttribute& Attribute, float& NewValue) const;
virtual void OnAttributeAggregatorCreated(const FGameplayAttribute& Attribute,
    FAggregator* NewAggregator) const;

// 属性查询
UAbilitySystemComponent* GetOwningAbilitySystemComponent() const;
AActor* GetOwningActor() const;

// 复制辅助宏
#define ATTRIBUTE_ACCESSORS(ClassName, PropertyName) \
    GAMEPLAYATTRIBUTE_PROPERTY_GETTER(ClassName, PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_GETTER(PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_SETTER(PropertyName) \
    GAMEPLAYATTRIBUTE_VALUE_INITTER(PropertyName)

#define GAMEPLAYATTRIBUTE_REPNOTIFY(ClassName, PropertyName, OldValue)
```

## UGameplayEffectExecutionCalculation

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/GameplayEffectExecutionCalculation.h

virtual void Execute_Implementation(
    const FGameplayEffectCustomExecutionParameters& ExecutionParams,
    FGameplayEffectCustomExecutionOutput& OutExecutionOutput) const;

// ExecutionParams 提供:
//   const FGameplayEffectSpec& GetOwningSpec() const;
//   TArray<FGameplayTag> GetSourceTags() const;
//   TArray<FGameplayTag> GetTargetTags() const;
//   const FGameplayEffectContextHandle& GetEffectContext() const;

// OutExecutionOutput 提供:
//   void MarkConditionalGameplayEffectsToTrigger();
//   void AddOutputModifier(const FGameplayModifierEvaluatedData& OutputData);
```

## UGameplayModMagnitudeCalculation

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/GameplayModMagnitudeCalculation.h

virtual float CalculateBaseMagnitude_Implementation(const FGameplayEffectSpec& Spec) const;

// Spec 提供:
//   float GetSetByCallerMagnitude(FGameplayTag DataTag, bool bWarnIfNotFound = true, float DefaultIfNotFound = 0.0f) const;
//   const FGameplayEffectContextHandle& GetEffectContext() const;
//   UAbilitySystemComponent* GetContextActor() const;
//   int32 GetLevel() const;
```

## UAbilityTask

```cpp
// 文件: Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/AbilityTask.h

void ReadyForActivation();  // 启动任务
void EndTask();              // 手动结束
```

### 派生类 — 完整精确签名

> **所有派生类 Create 签名参见 [`Docs/APIRef/AbilityTaskSignatures.md`](AbilityTaskSignatures.md)**
> 包含 11 个常用 AbilityTask 的完整参数列表 + 委托定义 + 使用示例。
> **禁止凭记忆调用——必须查签名后使用。**

| Task | 核心用途 | 参考 |
|------|---------|------|
| `UAbilityTask_PlayMontageAndWait` | 播放蒙太奇并等待完成/打断 | `AbilityTaskSignatures.md` §1 |
| `UAbilityTask_WaitTargetData` | 等待目标选择结果 | `AbilityTaskSignatures.md` §2 |
| `UAbilityTask_WaitDelay` | 等待指定时间 | `AbilityTaskSignatures.md` §3 |
| `UAbilityTask_WaitGameplayEvent` | 等待 GameplayTag 事件 | `AbilityTaskSignatures.md` §4 |
| `UAbilityTask_WaitAttributeChange` | 等待属性值变化 | `AbilityTaskSignatures.md` §5 |
| `UAbilityTask_WaitInputPress` | 等待输入按下 | `AbilityTaskSignatures.md` §6 |
| `UAbilityTask_WaitCancel` | 等待能力取消 | `AbilityTaskSignatures.md` §7 |
| `UAbilityTask_WaitConfirm` | 等待确认 | `AbilityTaskSignatures.md` §8 |
| `UAbilityTask_WaitOverlap` | 等待重叠事件 | `AbilityTaskSignatures.md` §9 |
| `UAbilityTask_ApplyRootMotionConstantForce` | 施加 RootMotion | `AbilityTaskSignatures.md` §10 |
| `UAbilityTask_NetworkSyncPoint` | 网络同步点 | `AbilityTaskSignatures.md` §11 |

### 通用规则

**所有 AbilityTask 创建后必须调用 `ReadyForActivation()`**，否则永远不会开始执行。
