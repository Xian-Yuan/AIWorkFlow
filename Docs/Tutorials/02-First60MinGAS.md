# GAS 入门 (60 分钟)

## 前置准备

1. 使用 **Third Person C++ 模板** 创建项目
2. 启用 **GameplayAbilities** 插件
3. 在 `.Build.cs` 添加模块:

```cpp
PublicDependencyModuleNames.AddRange(new string[] {
    "GameplayAbilities", "GameplayTags", "GameplayTasks"
});
```

## 步骤 1: 添加 AbilitySystemComponent

在 Character 类中:

```cpp
// MyCharacter.h
UAbilitySystemComponent* AbilitySystemComponent;

// MyCharacter.cpp (构造函数)
AbilitySystemComponent = CreateDefaultSubobject<UAbilitySystemComponent>("ASC");
AbilitySystemComponent->SetIsReplicated(true);
AbilitySystemComponent->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);
```

## 步骤 2: 实现 IAbilitySystemInterface

```cpp
// MyCharacter.h
class AMyCharacter : public ACharacter, public IAbilitySystemInterface
{
    virtual UAbilitySystemComponent* GetAbilitySystemComponent() const override;
};
```

## 步骤 3: 创建 AttributeSet

```cpp
UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()
    
    UPROPERTY(ReplicatedUsing = OnRep_Health)
    FGameplayAttributeData Health;
    
    UPROPERTY(ReplicatedUsing = OnRep_MaxHealth)
    FGameplayAttributeData MaxHealth;
};
```

## 步骤 4: 创建 GameplayEffect

1. 右键 → GameplayEffect → `GE_Heal`
2. 设置 Modifiers: Health, Add, 50

## 步骤 5: 创建 GameplayAbility

1. 右键 → GameplayAbility → `GA_Fire`
2. 实现蓝图逻辑 (播放动画、生成投射物)

## 步骤 6: 授予和激活

```cpp
// 授予
FGameplayAbilitySpec Spec(AbilityClass, Level);
ASC->GiveAbility(Spec);

// 激活
ASC->TryActivateAbilityByClass(UMyAbility::StaticClass());
```

## 完整教程

- 官方 60 分钟 GAS 教程: https://dev.epicgames.com/community/learning/tutorials/8Xn9/unreal-engine-epic-for-indies-your-first-60-minutes-with-gameplay-ability-system
- 官方 GAS 5.6 入门: https://dev.epicgames.com/community/learning/tutorials/d6DL/getting-started-with-the-gameplay-ability-system-gas-in-unreal-engine-5-6
