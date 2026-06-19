# 运行时错误排查指南

## 错误 1: "LogAbilitySystem: Warning: Can't activate ability because ability system component is not valid"

**原因**: ASC 或 ActorInfo 未正确初始化。

**检查**:
1. `InitAbilityActorInfo(OwnerActor, AvatarActor)` 是否已调用
2. ASC 是否添加到正确的 Actor 上 (Lyra: PlayerState)
3. PlayerState 是否已复制到客户端

**排查代码**:
```cpp
if (!ASC) { UE_LOG(LogTemp, Error, TEXT("ASC is null")); }
if (!ASC->GetActorInfo()) { UE_LOG(LogTemp, Error, TEXT("ActorInfo is null")); }
```

## 错误 2: 能力无法激活 (无错误日志)

**检查链**:
```
1. 检查 AbilityTag 阻塞:
   - ASC 上是否有 BlockedByTags 指定了阻塞 Tag
   - ActivationOwnedTags 与 BlockedByTags 冲突
2. 检查 Cost:
   - 是否有 CostGameplayEffectClass 配置但资源不足
3. 检查 Cooldown:
   - 是否在冷却中
4. 检查 CanActivateAbility:
   - 是否有自定义前置条件返回 false
5. 检查 NetExecutionPolicy:
   - ServerOnly 能力不能在客户端 TryActivate
```

**调试**:
```cpp
// 在 BP 中启用调试:
// Ability System Debug HUD → 勾选 Show Ability Info
// 或控制台: AbilitySystem.Debug.Ability 1
// 或: ShowDebug AbilitySystem
```

## 错误 3: "LogAbilitySystem: Attempted to activate ability that was already active!"

**原因**: `InstancedPerActor` 能力已经在激活中，又尝试再次激活。

**解决**: 
- 使用 `EGameplayAbilityInstancingPolicy::InstancedPerExecution` 允许多次实例化
- 或在激活前检查 `ASC->FindAbilitySpecFromClass(AbilityClass)` → `IsActive()`

## 错误 4: 属性不复制到客户端

**检查**:
```cpp
// 1. AttributeSet 必须有 Replicated 标记
UPROPERTY(ReplicatedUsing = OnRep_Health)
FGameplayAttributeData Health;

// 2. GetLifetimeReplicatedProps 必须正确实现
void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, Health, COND_None, REPNOTIFY_Always);
}

// 3. RepNotify 必须正确
void OnRep_Health(const FGameplayAttributeData& OldValue)
{
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, Health, OldValue);
}

// 4. ASC 必须设置复制
ASC->SetIsReplicated(true);
```

## 错误 5: GameplayEffect 不生效

**检查**:
```
1. Duration Policy 是否正确 (Instant 必须选 Instant)
2. Modifier 的 Attribute 是否确实在目标 AttributeSet 中
3. 目标 Actor 是否有 ASC
4. GE 的 Application Tag Requirements 是否满足
```

## 错误 6: GameplayCue 不触发

**检查**:
```
1. GameplayCue 路径是否在 DefaultGame.ini 或 GameFeatureData 中配置
2. Tag 命名是否以 "GameplayCue." 开头
3. GE 中是否引用了正确的 GameplayCue Tag
```

## 错误 7: 网络 — 客户端看不到能力激活的效果

**检查**:
```cpp
// 能力 NetExecutionPolicy:
// LocalPredicted — 客户端预测 + 服务器验证 (推荐)
// ServerOnly — 仅服务器执行 (客户端看不到预测)

// ASC ReplicationMode:
// 推荐: EGameplayEffectReplicationMode::Mixed
```

## 错误 8: GameFeature 加载失败

```
LogGameFeatures: Error: Failed to load game feature plugin 'MyGame' — missing dependency
```

**检查**:
```
1. .uplugin 中 Plugins 依赖是否都 enabled = true
2. 项目插件是否都已启用 (编辑 → 插件)
3. 是否有循环依赖
```

## 错误 9: Lyra Experience 加载无限循环

**检查链**:
```
1. OnExperienceLoaded 是否正确触发
2. GameFeatureActions 是否执行成功
3. AddComponents Action 的 Actor 类是否存在
4. GameFeatureData 中 PrimaryAssetTypes 配置是否正确
```

## 调试控制台命令

```
# GAS 调试
AbilitySystem.Debug.Ability 1       # 显示能力信息
AbilitySystem.Debug.Effects 1       # 显示效果信息
AbilitySystem.Debug.Attributes 1    # 显示属性信息
AbilitySystem.Debug.NextCategory    
AbilitySystem.Debug.ToggleCategories

# Lyra 调试
ShowDebug AbilitySystem             # 调试 HUD

# 网络
net.Ping 1                          # 显示 Ping
net.ShowBindAddress                 # 显示绑定地址
