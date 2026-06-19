# UE 通用高频 API 参考

## 概述

本文档覆盖 AI 最高频误用的 UE 通用工具类 API。所有签名来自 UE5 引擎源码。
**禁止凭记忆调用以下任何函数——必须查此文档核对签名和参数顺序。**

---

## 1. UGameplayStatics

**头文件**: `#include "Kismet/GameplayStatics.h"`
**模块依赖**: 核心引擎，无需额外添加

### GetPlayerController

```cpp
static APlayerController* GetPlayerController(const UObject* WorldContextObject, int32 PlayerIndex);
```

| 参数 | 说明 |
|------|------|
| `WorldContextObject` | 任意 UObject（`this` 即可），用于获取 World |
| `PlayerIndex` | 0 = 本地玩家 |

```cpp
// ❌ 常见错误
GetWorld()->GetPlayerController();
GetPlayerController(0);

// ✅ 正确
APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0);
```

### GetPlayerCharacter

```cpp
static APawn* GetPlayerCharacter(const UObject* WorldContextObject, int32 PlayerIndex);
```

### GetPlayerPawn

```cpp
static APawn* GetPlayerPawn(const UObject* WorldContextObject, int32 PlayerIndex);
```

### GetGameInstance

```cpp
static UGameInstance* GetGameInstance(const UObject* WorldContextObject);
```

### GetGameMode

```cpp
static AGameModeBase* GetGameMode(const UObject* WorldContextObject);
```

### GetGameState

```cpp
static AGameStateBase* GetGameState(const UObject* WorldContextObject);
```

### SpawnActor

```cpp
// 模板版本（推荐）
template<class T>
static T* SpawnActor(UObject* WorldContextObject, UClass* Class,
    const FVector& Location, const FRotator& Rotation,
    const FActorSpawnParameters& SpawnParams = FActorSpawnParameters());

// 非模板版本
static AActor* SpawnActor(const UObject* WorldContextObject, TSubclassOf<AActor> Class,
    const FVector& Location, const FRotator& Rotation,
    const FActorSpawnParameters& SpawnParams = FActorSpawnParameters());
```

```cpp
// ❌ 常见错误
GetWorld()->SpawnActor<AMyActor>(...);

// ✅ 正确
AMyActor* Actor = GetWorld()->SpawnActor<AMyActor>(AMyActor::StaticClass(), Location, Rotation, SpawnParams);
// 或
AMyActor* Actor = UGameplayStatics::BeginDeferredActorSpawnFromClass(this, AMyActor::StaticClass(), Transform);
UGameplayStatics::FinishSpawningActor(Actor, Transform);
```

### SpawnEmitterAtLocation / SpawnSoundAtLocation

```cpp
static UParticleSystemComponent* SpawnEmitterAtLocation(const UObject* WorldContextObject,
    UParticleSystem* EmitterTemplate, FVector Location,
    FRotator Rotation = FRotator::ZeroRotator, FVector Scale = FVector(1.f),
    bool bAutoDestroy = true, EPSCPoolMethod PoolingMethod = EPSCPoolMethod::None,
    bool bAutoActivateSystem = true);

static void PlaySoundAtLocation(const UObject* WorldContextObject,
    USoundBase* Sound, FVector Location, FRotator Rotation = FRotator::ZeroRotator,
    float VolumeMultiplier = 1.f, float PitchMultiplier = 1.f,
    float StartTime = 0.f, class USoundAttenuation* AttenuationSettings = nullptr,
    USoundConcurrency* ConcurrencySettings = nullptr,
    const AActor* OwningActor = nullptr);
```

### GetActorOfClass

```cpp
template<class T>
static T* GetActorOfClass(const UObject* WorldContextObject, TSubclassOf<AActor> ActorClass);

// 用法
AMyActor* Actor = UGameplayStatics::GetActorOfClass<AMyActor>(this, AMyActor::StaticClass());
```

### OpenLevel

```cpp
static void OpenLevel(const UObject* WorldContextObject, FName LevelName,
    bool bAbsolute = true, FString Options = FString(TEXT("")));
```

**⚠️ 单机项目注意**：`OpenLevel` 在多 PlayerController 下行为不同。单人用 `UGameplayStatics::OpenLevel(this, FName("LevelName"))`。

### GetTimeSeconds

```cpp
static float GetTimeSeconds(const UObject* WorldContextObject);
```

### ProjectWorldToScreen

```cpp
static bool ProjectWorldToScreen(APlayerController const* Player,
    const FVector& WorldPosition, FVector2D& ScreenPosition, bool bPlayerViewportRelative = false);
```

---

## 2. UKismetSystemLibrary

**头文件**: `#include "Kismet/KismetSystemLibrary.h"`

### IsValid (最重要！)

```cpp
static bool IsValid(const UObject* Test);
```

```cpp
// ❌ UE 中 UObject 不能用 == nullptr
if (Actor == nullptr)
if (!Actor)

// ✅ UObject 有效性检查
if (!IsValid(Actor))
if (UKismetSystemLibrary::IsValid(Actor))
```

### LineTraceSingle

```cpp
static bool LineTraceSingle(const UObject* WorldContextObject,
    const FVector Start, const FVector End,
    ETraceTypeQuery TraceChannel, bool bTraceComplex,
    const TArray<AActor*>& ActorsToIgnore,
    EDrawDebugTrace::Type DrawDebugType,
    FHitResult& OutHit, bool bIgnoreSelf,
    FLinearColor TraceColor = FLinearColor::Red,
    FLinearColor TraceHitColor = FLinearColor::Green,
    float DrawTime = 5.0f);
```

```cpp
// ✅ 简化用法（忽略列表为空）
TArray<AActor*> IgnoreActors;
IgnoreActors.Add(this);
FHitResult Hit;
if (UKismetSystemLibrary::LineTraceSingle(this, Start, End,
    UEngineTypes::ConvertToTraceType(ECC_Visibility),
    false, IgnoreActors, EDrawDebugTrace::None, Hit, true))
{
    AActor* HitActor = Hit.GetActor();
}
```

### SphereTraceSingle / BoxTraceSingle

```cpp
static bool SphereTraceSingle(const UObject* WorldContextObject,
    const FVector Start, const FVector End, float Radius,
    ETraceTypeQuery TraceChannel, bool bTraceComplex,
    const TArray<AActor*>& ActorsToIgnore,
    EDrawDebugTrace::Type DrawDebugType,
    FHitResult& OutHit, bool bIgnoreSelf,
    FLinearColor TraceColor, FLinearColor TraceHitColor, float DrawTime);
```

### PrintString

```cpp
static void PrintString(const UObject* WorldContextObject, const FString& InString = FString(TEXT("Hello")),
    bool bPrintToScreen = true, bool bPrintToLog = true,
    FLinearColor TextColor = FLinearColor(0.0, 0.66, 1.0), float Duration = 2.f,
    const FName Key = NAME_None);
```

### Delay

```cpp
static void Delay(const UObject* WorldContextObject, float Duration, FLatentActionInfo LatentInfo);
```

> ⚠️ 这是**蓝图 Latent 节点**的底层。C++ 中通常不直接调用此函数，用 `FTimerHandle` 或 `UAbilityTask_WaitDelay` 替代。

### IsServer / IsClient / IsStandalone

```cpp
static bool IsServer(const UObject* WorldContextObject);
static bool IsClient(const UObject* WorldContextObject);
static bool IsStandalone(const UObject* WorldContextObject);
```

### GetGameTimeInSeconds

```cpp
static double GetGameTimeInSeconds(const UObject* WorldContextObject);
```

### DrawDebugLine / Sphere / Box

```cpp
static void DrawDebugLine(const UObject* WorldContextObject,
    const FVector LineStart, const FVector LineEnd, FLinearColor Color,
    float Duration = -1.f, float Thickness = 0.f);

static void DrawDebugSphere(const UObject* WorldContextObject,
    const FVector Center, float Radius = 100.f, int32 Segments = 12,
    FLinearColor Color = FLinearColor::White, float Duration = -1.f,
    float Thickness = 0.f);
```

### Convolution / 卷积 (GetDisplayName / GetObjectName)

```cpp
static FString GetObjectName(const UObject* Object);
static FString GetDisplayName(const UObject* Object);
static FString GetClassDisplayName(UClass* Class);
```

---

## 3. UKismetMathLibrary

**头文件**: `#include "Kismet/KismetMathLibrary.h"`

### Vector Operations

```cpp
static float Vector_Distance(const FVector& V1, const FVector& V2);
static float Vector_Size(const FVector& A);
static FVector Vector_Normalize(const FVector& A, float Tolerance = SMALL_NUMBER);
static float DotProduct(const FVector& A, const FVector& B);
static FVector CrossProduct(const FVector& A, const FVector& B);
static FVector VLerp(const FVector& A, const FVector& B, float Alpha);
static FVector VInterpTo(const FVector& Current, const FVector& Target, float DeltaTime, float InterpSpeed);
```

### Rotator Operations

```cpp
static FRotator RLerp(const FRotator& A, const FRotator& B, float Alpha, bool bShortestPath);
static FRotator RInterpTo(const FRotator& Current, const FRotator& Target, float DeltaTime, float InterpSpeed);
static FRotator NormalizedDeltaRotator(const FRotator& A, const FRotator& B);
static FVector GetForwardVector(const FRotator& InRot);
static FVector GetRightVector(const FRotator& InRot);
static FVector GetUpVector(const FRotator& InRot);
```

### Random

```cpp
static float RandomFloatInRange(float Min, float Max);
static int32 RandomIntegerInRange(int32 Min, int32 Max);
static FVector RandomUnitVector();
static bool RandomBool();
```

### Math

```cpp
static float FClamp(float Value, float Min, float Max);
static float FInterpTo(float Current, float Target, float DeltaTime, float InterpSpeed);
static float FInterpEaseInOut(float A, float B, float Alpha, float Exponent);
static float GridSnap(float Location, float GridSize);
```

---

## 4. AActor (基类)

**头文件**: `#include "GameFramework/Actor.h"`

虽然 UE 通用，但 AI 常写错以下调用：

```cpp
// ✅ 正确用法
FVector Loc = GetActorLocation();
void SetActorLocation(const FVector& NewLocation, bool bSweep = false, FHitResult* OutSweepHitResult = nullptr, ETeleportType Teleport = ETeleportType::None);
FRotator GetActorRotation();
FVector GetActorForwardVector();
FVector GetActorRightVector();
FVector GetActorUpVector();
float GetDistanceTo(const AActor* OtherActor);
void Destroy();
UWorld* GetWorld() const;
void GetComponentsByClass(TSubclassOf<UActorComponent> ComponentClass, TArray<UActorComponent*>& OutComponents) const;
```

---

## 5. UWorld

**头文件**: `#include "Engine/World.h"`

```cpp
// SpawnActor
template<class T>
T* SpawnActor(UClass* Class, const FVector* Location = nullptr, const FRotator* Rotation = nullptr,
    const FActorSpawnParameters& SpawnParams = FActorSpawnParameters());

// Timer
FTimerManager& GetTimerManager() const;

// Game Mode/State
AGameModeBase* GetAuthGameMode() const;
AGameStateBase* GetGameState() const;
```

### FTimerHandle 用法

```cpp
FTimerHandle TimerHandle;
GetWorld()->GetTimerManager().SetTimer(TimerHandle, this, &AMyActor::MyCallback, 1.0f, true);

// 取消
GetWorld()->GetTimerManager().ClearTimer(TimerHandle);

// 检查是否激活
if (GetWorld()->GetTimerManager().IsTimerActive(TimerHandle)) { /* ... */ }
```

---

## 6. UEnhancedInputComponent

**头文件**: `#include "EnhancedInputComponent.h"`
**模块依赖**: `"EnhancedInput"`

```cpp
// 绑定 InputAction
void BindAction(const UInputAction* Action, ETriggerEvent TriggerEvent,
    UObject* Object, FName FunctionName);

// Lyra 推荐用法（通过 InputConfig + AbilitySet 间接绑定，不直接使用此类）
```

---

## 7. 快速纠错表：高频误用 → 正确用法

| 错误写法 | 正确写法 |
|---------|---------|
| `GetWorld()->GetPlayerController()` | `UGameplayStatics::GetPlayerController(this, 0)` |
| `Actor == nullptr` | `!IsValid(Actor)` |
| `if (!Actor)` | `if (!IsValid(Actor))` |
| `GetWorld()->SpawnActor<AMyActor>()` | `GetWorld()->SpawnActor<AMyActor>(AMyActor::StaticClass(), Loc, Rot, Params)` |
| `UGameplayStatics::GetPlayerController(0)` | `UGameplayStatics::GetPlayerController(this, 0)` |
| `OpenLevel(this, "Level")` | `UGameplayStatics::OpenLevel(this, FName("Level"))` |
| `GetWorld()->GetGameMode()` | `UGameplayStatics::GetGameMode(this)` |
| `GetWorld()->GetGameState()` | `UGameplayStatics::GetGameState(this)` |
| `LineTrace(Start, End, ...)` | `UKismetSystemLibrary::LineTraceSingle(this, Start, End, ...)` |
| `Cast<AMyActor>(Obj)` (Unreal Cast) | `Cast<AMyActor>(Obj)` ✅ 这个是正确的 |
| `FTimerHandle::SetTimer(...)` | `GetWorld()->GetTimerManager().SetTimer(Handle, ...)` |

---

## 参考文档

- `Docs/APIRef/LyraCoreClasses.md` — Lyra 核心类
- `Docs/APIRef/GASCoreClasses.md` — GAS 核心类
- `Docs/APIRef/AbilityTaskSignatures.md` — AbilityTask 精确签名
- `Docs/APIRef/UEMacrosRef.md` — UE 宏参考
