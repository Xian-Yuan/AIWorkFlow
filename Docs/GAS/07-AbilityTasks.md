# AbilityTask

## 概述

AbilityTask 是 GAS 中用于**异步操作**的构建块。能力通过组合多个 Task 来实现复杂行为。

## 内置 Task

| Task | 用途 |
|------|------|
| `UAbilityTask_WaitInputPress` | 等待按下输入 |
| `UAbilityTask_WaitInputRelease` | 等待释放输入 |
| `UAbilityTask_WaitTargetData` | 等待目标选择 |
| `UAbilityTask_PlayMontageAndWait` | 播放蒙太奇并等待 |
| `UAbilityTask_WaitGameplayEvent` | 等待 GameplayEvent |
| `UAbilityTask_WaitGameplayTag` | 等待 Tag 添加/移除 |
| `UAbilityTask_WaitDelay` | 等待延迟 |
| `UAbilityTask_WaitAttributeChange` | 等待属性变化 |
| `UAbilityTask_MoveToLocation` | 移动到位置 |
| `UAbilityTask_WaitConfirmCancel` | 等待确认/取消 |

## 使用示例

```cpp
// C++: 在 ActivateAbility 中启动 Task
UAbilityTask_PlayMontageAndWait* Task = 
    UAbilityTask_PlayMontageAndWait::PlayMontageAndWait(
        this, NAME_None, MontageToPlay);
        
Task->OnCompleted.AddDynamic(this, &UMyAbility::OnMontageCompleted);
Task->OnInterrupted.AddDynamic(this, &UMyAbility::OnMontageInterrupted);
Task->ReadyForActivation();
```

## Lyra 中的 Task

Lyra 扩展了部分 Task，也使用标准 Task 组合能力的执行流程。

## 参考链接

- 官方 GAS Task 说明: https://dev.epicgames.com/documentation/en-us/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
- tranek Tasks 章节: https://github.com/tranek/GASDocumentation
