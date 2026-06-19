# 网络预测 (Prediction)

## 概述

GAS 内置了客户端预测系统，使用 `FPredictionKey` 协调客户端和服务器之间的状态。

## 工作原理

```
客户端: 预测执行能力 → 创建 PredictionKey
    ↓ (预测结果立即显示)
服务器: 收到请求 → 执行能力 → 返回结果
    ↓
    如果匹配: 客户端保留预测状态
    如果冲突: 服务器回滚(rollback)客户端状态
```

## 预测的内容

| 内容 | 是否预测 |
|------|----------|
| 能力激活 | 是 |
| 能力动画 | 是 (通过 AbilityTask) |
| 属性修改 | 是 (GameplayEffect) |
| GameplayCue | 是 (客户端本地执行) |
| 能力结束 | 是 |
| 碰撞/物理 | **否** (由 CharacterMovement 处理) |

## 关键设置

```cpp
// 设置复制模式
ASC->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);
// Mixed 模式支持预测

// 能力网络策略 (LocalPredicted)
// 在 UGameplayAbility 中设置
NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;
```

## 最佳实践

- 对于多人游戏，推荐将 ASC 放在 PlayerState 上
- 使用 `LocalPredicted` 策略获得最佳响应体验
- 不要预测涉及随机结果的操作 (除非使用确定性随机)
- 复杂预测逻辑建议使用 `UGameplayAbility` 内置的 PredictionKey 机制

## 参考链接

- tranek Prediction 章节: https://github.com/tranek/GASDocumentation
