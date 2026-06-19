# 常用代码模式参考

## 模式 1: 为 ASC 授予 AbilitySet

```cpp
// 正确做法 (Lyra 框架):
ULyraAbilitySystemComponent* LyraASC = Cast<ULyraAbilitySystemComponent>(ASC);
if (LyraASC && AbilitySet)
{
    LyraASC->AddAbilitySets(AbilitySet);
}
```

```cpp
// 原始 GAS 方式:
FGameplayAbilitySpec Spec(AbilityClass, Level);
Spec.SourceObject = SourceObject;
ASC->GiveAbility(Spec);
```

## 模式 2: 应用伤害效果

```cpp
// 方式 A: 从能力中
TArray<FActiveGameplayEffectHandle> EffectHandles =
    ApplyGameplayEffectToTarget(DamageEffectClass, TargetData, 1.0f, 1);

// 方式 B: 从外部代码
FGameplayEffectContextHandle EffectContext = ASC->MakeEffectContext();
EffectContext.AddInstigator(Instigator, Causer);
EffectContext.AddHitResult(HitResult);

FGameplayEffectSpecHandle SpecHandle = ASC->MakeOutgoingSpec(
    DamageEffectClass, Level, EffectContext);
if (SpecHandle.IsValid())
{
    // 设置 SetByCaller 值
    SpecHandle.Data->SetSetByCallerMagnitude(
        FGameplayTag::RequestGameplayTag(FName("Data.Damage")), DamageValue);
    
    FActiveGameplayEffectHandle ActiveHandle =
        ASC->ApplyGameplayEffectSpecToTarget(*SpecHandle.Data, TargetASC);
}

// 方式 C: 从靶子 Actor
UAbilitySystemComponent* TargetASC = ...;
FGameplayEffectContextHandle Context = SourceASC->MakeEffectContext();
FGameplayEffectSpecHandle Spec = SourceASC->MakeOutgoingSpec(EffectClass, 1, Context);
TargetASC->ApplyGameplayEffectSpecToSelf(*Spec.Data);
```

## 模式 3: 创建自定义 AttributeSet

```cpp
// 步骤 1: 定义类 (见 NewAttributeSet 模板)
// 步骤 2: 在 Actor 构造函数中添加
UMyAttributeSet* AttrSet = CreateDefaultSubobject<UMyAttributeSet>(TEXT("MyAttributeSet"));
// (ASC 会自动找到并注册 AttributeSet 子对象)

// 初始化默认值: 最好用 GE 而非硬编码构造函数
// 创建 GE_DefaultAttributes, 在 AbilitySet 的 GrantedEffects 中引用
```

## 模式 4: 监听属性变化

```cpp
// 在 Actor/Component 中:
ASC->GetGameplayAttributeValueChangeDelegate(
    UMyAttributeSet::GetHealthAttribute())
    .AddUObject(this, &AMyCharacter::OnHealthChanged);

void AMyCharacter::OnHealthChanged(const FOnAttributeChangeData& Data)
{
    float OldValue = Data.OldValue;
    float NewValue = Data.NewValue;
    // 处理逻辑...
    
    if (NewValue <= 0.0f && OldValue > 0.0f)
    {
        // 死亡处理
    }
}
```

## 模式 5: 从代码触发 GameplayEvent

```cpp
FGameplayEventData EventData;
EventData.Instigator = this;
EventData.Target = TargetActor;
EventData.EventMagnitude = 50.0f;
EventData.OptionalObject = MyObject;
EventData.ContextHandle = ASC->MakeEffectContext();

ASC->HandleGameplayEvent(
    FGameplayTag::RequestGameplayTag(FName("Event.MyCustomEvent")),
    &EventData);

// 在 Ability 中:
// AbilityTrigger 配置为: GameplayEvent → Event.MyCustomEvent
// 或创建 UAbilityTask_WaitGameplayEvent
```

## 模式 6: 直接在 GameplayAbility 中对目标应用伤害

```cpp
// 在 ActivateAbility 中:
void UGA_MyAbility::ActivateAbility(...)
{
    // 1. 提交消耗
    if (!CommitAbility(Handle, ActorInfo, ActivationInfo))
    {
        EndAbility(Handle, ActorInfo, ActivationInfo, true, true);
        return;
    }
    
    // 2. 等待目标选择
    UAbilityTask_WaitTargetData* Task =
        UAbilityTask_WaitTargetData::WaitTargetData(
            this, NAME_None,
            EGameplayTargetingConfirmation::Instant,
            TargetActorClass);
    Task->ValidData.AddDynamic(this, &UGA_MyAbility::OnTargetReady);
    Task->ReadyForActivation();
}

void UGA_MyAbility::OnTargetReady(const FGameplayAbilityTargetDataHandle& Data)
{
    // 3. 应用伤害
    ApplyGameplayEffectToTarget(DamageEffectClass, Data, 1.0f, 1);
    
    // 4. 结束
    EndAbility(CurrentSpecHandle, CurrentActorInfo, CurrentActivationInfo, true, false);
}
```

## 模式 7: 授予装备/武器能力 (Lyra)

```cpp
// 这些由 EquipmentManager 自动处理:
// 1. FLyraEquipmentList::AddEntry() 在创建 EquipmentInstance 时
// 2. 从 EquipmentDefinition 的 AbilitySets 中读取
// 3. 自动授予到 ASC (PlayerState 上的)
// 4. SourceObject 设置为 EquipmentInstance
// 5. 装备卸下时自动撤销

// 在 EquipmentDefinition 蓝图中只需配置:
// AbilitiesToGrant → AbilitySets → 指向 ULyraAbilitySet
```

## 模式 8: InitState 自定义

```cpp
// 如果需要添加自定义初始化阶段:
// 1. 在 GameInstance::Init() 中注册新的 InitState Tag
// 2. 在 ULyraPawnExtensionComponent 的子类中添加新状态

// 寄存器示例:
UGameFrameworkComponentManager* Manager = 
    GameInstance->GetSubsystem<UGameFrameworkComponentManager>();
if (Manager)
{
    Manager->RegisterInitState(
        FGameplayTag::RequestGameplayTag("InitState.MyCustomState"), true);
}
```

## 模式 9: 创建 GameplayCue

```cpp
// C++ 类 (基类选择):
// UGameplayCueNotify_Static  — 无实例化，性能好
// AGameplayCueNotify_Actor   — 有实例化，支持 Tick 和生命周期

UCLASS()
class UMyCueNotify_Impact : public UGameplayCueNotify_Static
{
    GENERATED_BODY()
    
    virtual bool OnExecute_Implementation(AActor* Target,
        const FGameplayCueParameters& Parameters) const override;
};

bool UMyCueNotify_Impact::OnExecute_Implementation(AActor* Target,
    const FGameplayCueParameters& Parameters) const
{
    // 播放粒子
    // 播放音效
    return true;
}

// 配置:
// 1. 创建蓝图继承 UMyCueNotify_Impact 或直接用
// 2. 设置 GameplayTag: GameplayCue.Damage.Impact
// 3. 在 GE 的 GameplayCueTag 中引用
```

## 模式 10: Lyra 中获取 ASC

```cpp
// 从 Character:
UAbilitySystemComponent* ASC = nullptr;
if (APlayerState* PS = GetPlayerState())
{
    if (IAbilitySystemInterface* ASI = Cast<IAbilitySystemInterface>(PS))
    {
        ASC = ASI->GetAbilitySystemComponent();
    }
}

// 从 PlayerController:
ULyraAbilitySystemComponent* LyraASC = 
    GetPlayerState<ALyraPlayerState>()->GetLyraAbilitySystemComponent();

// 通用方式:
UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(Actor);
```
