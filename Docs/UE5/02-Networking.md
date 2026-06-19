# UE5 网络复制

## 核心概念

| 概念 | 说明 |
|------|------|
| Server | 权威服务器，拥有最终状态 |
| Client | 客户端，显示预测状态 |
| Replication | 服务器 → 客户端的数据同步 |
| RPC | 远程过程调用 |
| Ownership | Actor 所属关系 |

## 复制属性

```cpp
UPROPERTY(Replicated)
float Health;

UPROPERTY(ReplicatedUsing = OnRep_Health)
float Health;

UFUNCTION()
void OnRep_Health();
```

## RPC 类型

| 类型 | 方向 | 执行位置 |
|------|------|----------|
| `Server` | Client → Server | 服务器 |
| `Client` | Server → Client | 拥有该 Actor 的客户端 |
| `NetMulticast` | Server → All | 所有客户端 |
| ` unreliable / reliable` | - | 可靠保证 / 不保证送达 |

## 复制条件

```cpp
// 只有拥有者客户端执行
if (GetNetMode() != NM_DedicatedServer && IsLocallyControlled())

// 只在服务器执行
if (HasAuthority())

// 只在客户端执行
if (!HasAuthority())
```

## Lyra/GAS 中的网络

- GAS 内置复制机制
- ASC 的 ReplicationMode 控制复制粒度
- 多人游戏推荐 Mixed 模式
- PredictionKey 处理客户端预测
- 能力激活使用 LocalPredicted 策略

## 参考链接

- UE 官方网络文档: https://dev.epicgames.com/documentation/unreal-engine/networking-and-multiplayer
