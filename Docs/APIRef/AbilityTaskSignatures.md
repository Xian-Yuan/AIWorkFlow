# AbilityTask 精确签名快照

## 概述

本文档记录所有常用 AbilityTask 的精确 `static Create*` 函数签名。
**所有签名来自 UE5 引擎源码，禁止凭记忆修改。**

> 如需验证，在引擎安装目录搜索：
> `Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/Abilities/Tasks/`

---

## 1. UAbilityTask_PlayMontageAndWait

**源文件**: `AbilityTask_PlayMontageAndWait.h`

### Create 签名

```cpp
static UAbilityTask_PlayMontageAndWait* CreatePlayMontageAndWaitProxy(
    UGameplayAbility* OwningAbility,
    FName TaskInstanceName,
    UAnimMontage* MontageToPlay,
    float Rate = 1.f,
    FName StartSection = NAME_None,
    bool bStopWhenAbilityEnds = true,
    float AnimRootMotionTranslationScale = 1.f,
    float StartTimeSeconds = 0.f,
    bool bAllowInterruptAfterBlendOut = false);
```

### 委托

| 委托 | 触发时机 |
|------|---------|
| `OnCompleted` | 蒙太奇正常播放完毕 |
| `OnBlendOut` | 蒙太奇开始 BlendOut |
| `OnInterrupted` | 蒙太奇被打断 |
| `OnCancelled` | 能力取消 |
| `OnCompleted` + `OnBlendOut` + `OnInterrupted` + `OnCancelled` | **全部绑定后才能安全使用** |

### 使用示例

```cpp
UAbilityTask_PlayMontageAndWait* Task = UAbilityTask_PlayMontageAndWait::CreatePlayMontageAndWaitProxy(
    this,                   // OwningAbility
    NAME_None,              // TaskInstanceName
    MontageToPlay,          // UAnimMontage*
    1.f,                    // Rate
    NAME_None,              // StartSection
    true,                   // bStopWhenAbilityEnds
    1.f,                    // AnimRootMotionTranslationScale
    0.f,                    // StartTimeSeconds
    false);                 // bAllowInterruptAfterBlendOut

Task->OnCompleted.AddDynamic(this, &UGA_MyAbility::OnMontageComplete);
Task->OnBlendOut.AddDynamic(this, &UGA_MyAbility::OnMontageBlendOut);
Task->OnInterrupted.AddDynamic(this, &UGA_MyAbility::OnMontageInterrupted);
Task->OnCancelled.AddDynamic(this, &UGA_MyAbility::OnMontageCancelled);
Task->ReadyForActivation();
```

---

## 2. UAbilityTask_WaitTargetData

**源文件**: `AbilityTask_WaitTargetData.h`

### Create 签名

```cpp
static UAbilityTask_WaitTargetData* WaitTargetData(
    UGameplayAbility* OwningAbility,
    FName TaskInstanceName,
    EGameplayTargetingConfirmation::Type ConfirmationType,
    TSubclassOf<AGameplayAbilityTargetActor> InTargetClass);
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `OwningAbility` | 拥有此 Task 的 Ability（通常传 `this`） |
| `TaskInstanceName` | Task 实例名（通常 `NAME_None`） |
| `ConfirmationType` | `Instant` = 立即返回; `UserConfirmed` = 等待玩家确认 |
| `InTargetClass` | TargetActor 类（如 `AGameplayAbilityTargetActor_Trace`） |

### 委托

| 委托 | 说明 |
|------|------|
| `ValidData` | 目标数据有效时触发 |
| `Cancelled` | 目标选择取消 |

### 使用示例

```cpp
UAbilityTask_WaitTargetData* Task = UAbilityTask_WaitTargetData::WaitTargetData(
    this,
    NAME_None,
    EGameplayTargetingConfirmation::Instant,
    AGameplayAbilityTargetActor_Trace::StaticClass());

Task->ValidData.AddDynamic(this, &UGA_MyAbility::OnTargetDataReady);
Task->Cancelled.AddDynamic(this, &UGA_MyAbility::OnTargetCancelled);
Task->ReadyForActivation();
```

---

## 3. UAbilityTask_WaitDelay

**源文件**: `AbilityTask_WaitDelay.h`

### Create 签名

```cpp
static UAbilityTask_WaitDelay* WaitDelay(
    UGameplayAbility* OwningAbility,
    float Time);
```

### 使用示例

```cpp
UAbilityTask_WaitDelay* Task = UAbilityTask_WaitDelay::WaitDelay(this, 0.5f);
Task->OnFinish.AddDynamic(this, &UGA_MyAbility::OnDelayComplete);
Task->ReadyForActivation();
```

**注意**: UE5.5+ 中，`WaitDelay` 的 TaskInstanceName 参数已移除，只有 2 个参数。

---

## 4. UAbilityTask_WaitGameplayEvent

**源文件**: `AbilityTask_WaitGameplayEvent.h`

### Create 签名

```cpp
static UAbilityTask_WaitGameplayEvent* WaitGameplayEvent(
    UGameplayAbility* OwningAbility,
    FGameplayTag EventTag,
    AActor* OptionalExternalTarget = nullptr,
    bool OnlyTriggerOnce = false,
    bool OnlyMatchExact = false);
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `EventTag` | 等待的 GameplayTag 事件 |
| `OptionalExternalTarget` | 指定监听特定 Actor 的事件（null = 监听 ASC Owner） |
| `OnlyTriggerOnce` | 触发一次后自动结束 |
| `OnlyMatchExact` | 只匹配精确 Tag（不匹配父 Tag） |

### 委托

| 委托 | 说明 |
|------|------|
| `EventReceived` | `FGameplayEventData` Payload |

### 使用示例

```cpp
FGameplayTag EventTag = FGameplayTag::RequestGameplayTag(FName("Event.Damage.Received"));
UAbilityTask_WaitGameplayEvent* Task = UAbilityTask_WaitGameplayEvent::WaitGameplayEvent(
    this, EventTag, nullptr, false, true);
Task->EventReceived.AddDynamic(this, &UGA_MyAbility::OnGameplayEvent);
Task->ReadyForActivation();

void UGA_MyAbility::OnGameplayEvent(FGameplayEventData Payload)
{
    AActor* Instigator = Payload.Instigator;
    float Magnitude = Payload.EventMagnitude;
}
```

---

## 5. UAbilityTask_WaitAttributeChange

**源文件**: `AbilityTask_WaitAttributeChange.h`

### Create 签名

```cpp
static UAbilityTask_WaitAttributeChange* WaitForAttributeChange(
    UGameplayAbility* OwningAbility,
    FGameplayAttribute InAttribute,
    FGameplayTag InWithTag,
    FGameplayTag InWithoutTag,
    bool TriggerOnce = true,
    AActor* OptionalExternalOwner = nullptr);
```

### 委托

| 委托 | 说明 |
|------|------|
| `OnAttributeChange` | `FOnGameplayAttributeChange` (旧值 + 新值) |

---

## 6. UAbilityTask_WaitInputPress

**源文件**: `AbilityTask_WaitInputPress.h`

### Create 签名

```cpp
static UAbilityTask_WaitInputPress* WaitInputPress(
    UGameplayAbility* OwningAbility,
    bool bTestAlreadyPressed = false);
```

### 使用示例

```cpp
UAbilityTask_WaitInputPress* Task = UAbilityTask_WaitInputPress::WaitInputPress(this, false);
Task->OnPress.AddDynamic(this, &UGA_MyAbility::OnInputPressed);
Task->ReadyForActivation();
```

---

## 7. UAbilityTask_WaitCancel

**源文件**: `AbilityTask_WaitCancel.h`

### Create 签名

```cpp
static UAbilityTask_WaitCancel* WaitCancel(UGameplayAbility* OwningAbility);
```

### 委托: `OnCancel`

---

## 8. UAbilityTask_WaitConfirm

**源文件**: `AbilityTask_WaitConfirm.h`

### Create 签名

```cpp
static UAbilityTask_WaitConfirm* WaitConfirm(UGameplayAbility* OwningAbility);
```

### 委托: `OnConfirm`

---

## 9. UAbilityTask_WaitOverlap

**源文件**: `AbilityTask_WaitOverlap.h`

### Create 签名

```cpp
static UAbilityTask_WaitOverlap* WaitForOverlap(UGameplayAbility* OwningAbility);
```

### 委托

| 委托 | 说明 |
|------|------|
| `OnOverlapBegin` | `AActor* OtherActor, bool bFromSweep, const FHitResult& SweepResult` |

---

## 10. UAbilityTask_ApplyRootMotionConstantForce

**源文件**: `AbilityTask_ApplyRootMotionConstantForce.h`

### Create 签名

```cpp
static UAbilityTask_ApplyRootMotionConstantForce* ApplyRootMotionConstantForce(
    UGameplayAbility* OwningAbility,
    FName TaskInstanceName,
    FVector WorldDirection,
    float Strength,
    float Duration,
    bool bIsAdditive,
    UCurveFloat* StrengthOverTime,
    ERootMotionFinishVelocityMode VelocityOnFinishMode,
    FVector SetVelocityOnFinish,
    float ClampVelocityOnFinish,
    bool bEnableGravity);
```

**注意**: UE5.5+ 中部分参数有变化，实际使用时查头文件。

---

## 11. UAbilityTask_NetworkSyncPoint

**源文件**: `AbilityTask_NetworkSyncPoint.h`

### Create 签名

```cpp
static UAbilityTask_NetworkSyncPoint* WaitNetSync(
    UGameplayAbility* OwningAbility,
    EAbilityTaskNetSyncType SyncType);
```

---

## 快速参考：所有 Task 的 ReadyForActivation

**所有 AbilityTask 创建后必须调用 `ReadyForActivation()`**：

```cpp
UAbilityTask_PlayMontageAndWait* Task = UAbilityTask_PlayMontageAndWait::CreatePlayMontageAndWaitProxy(...);
// 绑定委托...
Task->ReadyForActivation();  // ← 必须！否则 Task 永远不开始执行
```

---

## 验证方法

如果安装了引擎源码，用以下命令验证签名：

```bash
# Windows
rg "static.*Create" "C:\Program Files\Epic Games\UE_5.7\Engine\Plugins\Runtime\GameplayAbilities\Source\GameplayAbilities\Public\Abilities\Tasks" --type cpp -A 10

# 或在 Lyra 的 Intermediate/Build/ 中查找
rg "UAbilityTask_" "G:\UEGameDevelopment\MLCase\Intermediate"
```
