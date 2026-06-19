# Lyra 核心类 API 签名参考

## ALyraCharacter

```cpp
// 文件: LyraGame/Characters/LyraCharacter.h

ALyraCharacter(const FObjectInitializer& ObjectInitializer);

// 组件
ULyraPawnExtensionComponent* GetPawnExtensionComponent() const;
ULyraHealthComponent* GetHealthComponent() const;

// 初始化状态
virtual void OnAbilitySystemInitialized();
virtual void OnAbilitySystemUninitialized();

// Possession
virtual void PossessedBy(AController* NewController) override;
virtual void UnPossessed() override;
virtual void OnRep_PlayerState() override;
```

## ALyraPlayerState

```cpp
// 文件: LyraGame/Player/LyraPlayerState.h

ALyraPlayerState(const FObjectInitializer& ObjectInitializer);

// ASC 访问
UAbilitySystemComponent* GetAbilitySystemComponent() const;
ULyraAbilitySystemComponent* GetLyraAbilitySystemComponent() const;

// 属性
bool IsDead() const;
void SetDead(bool bDead);
```

## ALyraPlayerController

```cpp
// 文件: LyraGame/Player/LyraPlayerController.h

ALyraPlayerController(const FObjectInitializer& ObjectInitializer);

// 输入
void SetInputMode(const FLyraInputMode& InputMode);

// 相机
ALyraCameraManager* GetLyraCameraManager() const;

// UI
ULyraHUD* GetLyraHUD() const;
```

## ULyraPawnExtensionComponent

```cpp
// 文件: LyraGame/Characters/LyraPawnExtensionComponent.h

ULyraPawnExtensionComponent(const FObjectInitializer& ObjectInitializer);

// PawnData 管理
void SetPawnData(const ULyraPawnData* InPawnData);
const ULyraPawnData* GetPawnData() const;

// 初始化
void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent);

// 初始化状态 (IGameFrameworkInitStateInterface)
virtual void RegisterInitStateFeature() override;
virtual bool CheckDefaultInitialization() override;
virtual void OnActorInitStateChanged(const FActorInitStateChangedParams& Params) override;
void TryToInitializeIntialState();

// 查询
static ULyraPawnExtensionComponent* FindPawnExtensionComponent(const AActor* Actor);
bool IsPawnReadyToInitialize() const;

// 事件
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnPawnReadyToInitialize);
FOnPawnReadyToInitialize OnPawnReadyToInitialize;
```

## ULyraHeroComponent

```cpp
// 文件: LyraGame/Characters/LyraHeroComponent.h

ULyraHeroComponent(const FObjectInitializer& ObjectInitializer);

// 初始化
virtual void RegisterInitStateFeature() override;
virtual bool CheckDefaultInitialization() override;

// 相机
void SetCameraMode(TSubclassOf<ULyraCameraMode> CameraMode);
void ClearCameraMode();
bool IsInFirstPersonCamera() const;

// 输入
void AddAdditionalInputConfig(const ULyraInputConfig* InputConfig);
void RemoveAdditionalInputConfig(const ULyraInputConfig* InputConfig);
```

## ULyraAbilitySystemComponent

```cpp
// 文件: LyraGame/AbilitySystem/LyraAbilitySystemComponent.h

ULyraAbilitySystemComponent(const FObjectInitializer& ObjectInitializer);

// 能力集
void AddAbilitySets(const ULyraAbilitySet* AbilitySet);
void RemoveAbilitySets(const ULyraAbilitySet* AbilitySet);

// Tag 关系
void AddAbilityTagRelationshipMapping(ULyraAbilityTagRelationshipMapping* Mapping);
void RemoveAbilityTagRelationshipMapping(ULyraAbilityTagRelationshipMapping* Mapping);

// 输入
void AbilityInputTagPressed(const FGameplayTag& InputTag);
void AbilityInputTagReleased(const FGameplayTag& InputTag);
void ProcessAbilityInput(float DeltaTime, bool bGamePaused);
void ClearAbilityInput();
```

## ULyraInputConfig

```cpp
// 文件: LyraGame/Input/LyraInputConfig.h

// 查找能力
const UInputAction* FindInputActionForTag(const FGameplayTag& InputTag) const;

// 映射条目
// TArray<FLyraInputAction> InputActions
// FLyraInputAction:
//   FGameplayTag InputTag
//   TObjectPtr<UInputAction> InputAction
//   bool bTriggerWhenPaused
```

## ULyraAbilitySet

```cpp
// 文件: LyraGame/AbilitySystem/LyraAbilitySet.h

// 授予能力
void GiveToAbilitySystem(
    ULyraAbilitySystemComponent* ASC,
    ULyraAbilitySet** OutGrantedAbilitySpecHandles,
    UObject* SourceObject = nullptr) const;
```

## ULyraExperienceDefinition

```cpp
// 文件: LyraGame/GameModes/LyraExperienceDefinition.h

// 属性
UPROPERTY(EditDefaultsOnly, Category = "Experience")
TArray<FString> GameFeaturesToEnable;

UPROPERTY(EditDefaultsOnly, Category = "Experience")
TObjectPtr<ULyraPawnData> DefaultPawnData;

UPROPERTY(EditDefaultsOnly, Instanced, Category = "Experience")
TArray<TObjectPtr<UGameFeatureAction>> Actions;

UPROPERTY(EditDefaultsOnly, Category = "Experience")
TArray<TObjectPtr<ULyraExperienceActionSet>> ActionSets;
```

## ULyraExperienceManagerComponent

```cpp
// 文件: LyraGame/GameModes/LyraExperienceManagerComponent.h

// 核心方法
void SetCurrentExperience(FPrimaryAssetId ExperienceId);
void StartExperienceLoad();
void OnExperienceLoadComplete();
void OnExperienceFullLoadCompleted();

// 查询
bool IsExperienceLoaded() const;
const ULyraExperienceDefinition* GetCurrentExperience() const;

// 事件
DECLARE_MULTICAST_DELEGATE_OneParam(FOnLyraExperienceLoaded, const ULyraExperienceDefinition*);
FOnLyraExperienceLoaded OnExperienceLoaded;
```

## ULyraEquipmentManagerComponent

```cpp
// 文件: LyraGame/Equipment/LyraEquipmentManagerComponent.h

// 装备管理
ULyraEquipmentInstance* EquipItem(TSubclassOf<ULyraEquipmentDefinition> EquipmentDefinition);
void UnequipItem(ULyraEquipmentInstance* ItemInstance);
bool IsEquipped(const ULyraEquipmentInstance* ItemInstance) const;

// 查询
TArray<ULyraEquipmentInstance*> GetEquipmentInstances() const;
ULyraEquipmentInstance* GetEquipmentInstance(TSubclassOf<ULyraEquipmentDefinition> DefClass) const;

// 事件
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnEquipmentChanged,
    const ULyraEquipmentInstance* Instance, int32 SlotCount);
FOnEquipmentChanged OnEquipmentChanged;

// 委托
DECLARE_DELEGATE_OneParam(FOnEquipmentChangedNative, const ULyraEquipmentInstance*);
FOnEquipmentChangedNative OnEquipmentChangedNative;
```

## ULyraQuickBarComponent

```cpp
// 文件: LyraGame/Equipment/LyraQuickBarComponent.h

// 槽位管理
void SetActiveSlotIndex(int32 NewIndex);
int32 GetActiveSlotIndex() const;

// 物品管理
void AddItem(TSubclassOf<ULyraInventoryItemDefinition> ItemDef);
void RemoveItem(TSubclassOf<ULyraInventoryItemDefinition> ItemDef);

// 查询
ULyraInventoryItemInstance* GetActiveItem() const;
TArray<ULyraInventoryItemInstance*> GetSlots() const;
int32 GetSlotCount() const;

// 事件
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnActiveSlotChanged, int32, SlotIndex);
FOnActiveSlotChanged OnActiveSlotChanged;
```

## ULyraInventoryManagerComponent

```cpp
// 文件: LyraGame/Inventory/LyraInventoryManagerComponent.h

// 物品 CRUD
ULyraInventoryItemInstance* AddItem(TSubclassOf<ULyraInventoryItemDefinition> ItemDef);
void RemoveItem(ULyraInventoryItemInstance* Item);
TArray<ULyraInventoryItemInstance*> GetAllItems() const;
ULyraInventoryItemInstance* FindFirstItemByDefinition(TSubclassOf<ULyraInventoryItemDefinition> ItemDef) const;
int32 GetItemCount(TSubclassOf<ULyraInventoryItemDefinition> ItemDef) const;
bool ConsumeItem(ULyraInventoryItemInstance* Item);
```

## ULyraInventoryItemDefinition

```cpp
// 文件: LyraGame/Inventory/LyraInventoryItemDefinition.h

// 属性
UPROPERTY(EditDefaultsOnly, Category = "Display")
FText DisplayName;

UPROPERTY(EditDefaultsOnly, Instanced, Category = "Display")
TArray<TObjectPtr<ULyraInventoryItemFragment>> Fragments;

// 查询
ULyraInventoryItemFragment* FindFragmentByClass(TSubclassOf<ULyraInventoryItemFragment> FragmentClass) const;
```

## ULyraGameplayAbility (基类)

```cpp
// 文件: LyraGame/AbilitySystem/LyraGameplayAbility.h

// Lyra 扩展功能:
// 1. 激活失败时广播 GameplayMessage: Ability.FailedToActivate.Message
// 2. 与 Lyra Equipment/Weapon 系统集成
// 3. 更好的 Tag 管理

// SourceObject 查询 (如果是 Equipment 授予的)
UFUNCTION(BlueprintPure, Category = "Ability")
UObject* GetSourceObject() const;

// 附加 Tag 处理
UFUNCTION(BlueprintPure, Category = "Ability")
FGameplayTagContainer GetAbilityTags() const;
```
