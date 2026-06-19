# 多人游戏问题排查

## 问题 1: 客户端能力不预测

**症状**: 客户端按了按键但能力延迟后才触发，或完全不触发。

**检查**:
```cpp
// 1. 能力 NetExecutionPolicy
NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;
// 如果设成 ServerOnly，客户端不会预测，需要等待服务器返回

// 2. ASC ReplicationMode
ASC->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);
// Full — 全量复制 (单人)
// Mixed — 混合 (推荐多人)
// Minimal — 最小 (AI)

// 3. 输入绑定
// Lyra: 确保 InputTag 在 AbilitySet 中配置正确
// AbilitySet → GrantedAbilities → Ability + InputTag
```

## 问题 2: 属性不同步

**症状**: 服务器属性变了但客户端没更新。

**检查链**:
```
1. UPROPERTY(Replicated) — 属性标记
2. GetLifetimeReplicatedProps — DOREPLIFETIME 配置
3. COND_None — 没有条件限制
4. OnRep 实现 — GAMEPLAYATTRIBUTE_REPNOTIFY
5. ASC->SetIsReplicated(true) — ASC 复制打开
6. AttributeSet 是 ASC 的子对象 — 通过 UClass 默认添加或 AddAttributeSetSubobject
```

## 问题 3: RPC 不触发

**症状**: Server/Client 函数没调用。

**检查**:
```cpp
// Server RPC:
UFUNCTION(Server, Reliable, WithValidation)
void Server_MyFunction();

// Client RPC:
UFUNCTION(Client, Reliable)
void Client_MyFunction();

// 常见错误:
// 1. 缺少 WithValidation: Server RPC 必须有验证
// 2. 调用者不是 Owner: 只有 Owner 可以调用 Server RPC
// 3. 函数名以 Server_ / Client_ 开头
// 4. Actor 没有复制: bReplicates = true
```

## 问题 4: GameplayEffect 在客户端不复制

**检查**:
```cpp
// ASC 复制模式
ASC->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);
// 或 Full

// GE 的 Tag Requirements
// 客户端是否满足 ApplicationTagRequirements

// GE 的 Duration
// 默认只复制 Duration/Infinite 的效果，不复制 Instant
// Instant 效果在服务器执行，通过属性复制影响客户端
```

## 问题 5: 属性不同步的调试方法

```cpp
// 在 BP 或 C++ 中添加:
// 1. 控制台: AbilitySystem.Debug.Attributes 1
// 2. 在 PostGameplayEffectExecute 中添加日志:
void UMyAttributeSet::PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data)
{
    Super::PostGameplayEffectExecute(Data);
    
    if (Data.EvaluatedData.Attribute == GetHealthAttribute())
    {
        UE_LOG(LogTemp, Log, TEXT("Health changed to: %f (Server: %d)"),
            GetHealth(), GetWorld()->GetNetMode() == NM_DedicatedServer);
    }
}
```

## 问题 6: 多人游戏中 ASC 的位置选择

```
推荐: ASC 在 PlayerState 上

优点:
  - Pawn 销毁时 ASC 不销毁 (死亡重生时属性保留)
  - PlayerState 在所有客户端都存在
  - 输入处理更简单

缺点:
  - 需要额外代码处理 AvatarActor 切换
  - 更复杂的初始化顺序

不推荐: ASC 在 Character/Pawn 上 (多人)
  - 角色死亡/重生时需要重建 ASC
  - 角色没复制到客户端时 ASC 不可用
  - 仅适合单人游戏或 AI 小兵
```

## 问题 7: InitActorInfo 时序

```cpp
// 正确调用顺序:
// 1. ASC->InitAbilityActorInfo(OwnerActor, AvatarActor);
//    OwnerActor = PlayerState (拥有者)
//    AvatarActor = Pawn (代表者)

// 2. Possess 时重新设置
void AMyPlayerController::OnPossess(APawn* InPawn)
{
    Super::OnPossess(InPawn);
    if (UAbilitySystemComponent* ASC = ...)
    {
        ASC->InitAbilityActorInfo(GetPlayerState<APlayerState>(), InPawn);
    }
}
```

## 问题 8: 权限检查

```cpp
// 只应在服务器执行的逻辑
if (!HasAuthority())
{
    return;
}

// 只应在拥有者客户端执行的逻辑
if (!IsLocallyControlled())
{
    return;
}

// 在 Ability 中:
// 直接使用 CurrentActorInfo 判断
// EGameplayAbilityNetExecutionPolicy 已经处理大部分场景
```
