---
id: E017
title: Lyra Experience 加载无限循环
category: 运行时错误
system: Lyra
severity: 阻断
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E009]
keywords: [Experience, 无限循环, OnExperienceLoaded, GameFeatureAction]
---

## 现象

编辑器卡死或在加载 Experience 时无限循环。

## 原因

1. `OnExperienceLoaded` 回调链中存在循环触发
2. GameFeatureActions 执行失败导致状态机卡住
3. `AddComponents` Action 引用了不存在的 Actor 类
4. `GameFeatureData` 中 `PrimaryAssetTypes` 配置的路径不存在

## 解决方案

检查链：
```
1. OnExperienceLoaded 是否正确触发一次
2. GameFeatureActions 是否全部执行成功
3. AddComponents 的 Actor 类是否存在于当前项目
4. GameFeatureData → PrimaryAssetTypes → 路径必须存在
```

**调试方法：**
```cpp
// 在 Experience 加载回调中添加日志
void UMyExperienceAction::OnActionActivated_Implementation()
{
    UE_LOG(LogTemp, Log, TEXT("Action activated: %s"), *GetClass()->GetName());
}
```

## 预防

- 每个 GameFeatureAction 执行前后添加日志
- 新增 Action 时先测试单次执行是否正常

## 检测关键词

[Experience, 无限循环, OnExperienceLoaded, GameFeatureAction, 卡死]
