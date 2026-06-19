---
id: E029
title: 批量烘焙主线程阻塞卡死
category: 运行时错误
system: 编辑器
severity: 严重
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E027]
keywords: [烘焙, 批量, 主线程阻塞, 多阶段, 进度反馈, GC]
---

## 现象

对多个目标执行静态网格烘焙时，编辑器窗口卡死、无响应或超时退出。

## 原因

整条烘焙链路（残差转换 + 原生 Merge + 材质槽恢复 + Spawn Actor + 清理）一次性同步跑完，某个重目标长时间阻塞主线程。大批量（100+）时进一步累积为全量中间态。

## 解决方案

```cpp
// ✅ 正确：拆成多阶段状态机，阶段边界让帧
switch (CurrentBakeStage)
{
    case EStage::CollectComponents:  ... break;
    case EStage::BakeResidualMesh:  ... break;
    case EStage::MergeComponents:   ... break;
    case EStage::RestoreSlots:      ... break;
    case EStage::Cleanup:           ... break;
}
```

**大批量规则：**
1. 必须有可取消的进度反馈
2. 按复杂度分桶，小批量闭环处理（提样条 → 生成 → 烘焙 → 清理）
3. MergeComponents 前检查可用物理内存，低于阈值提前中止
4. 临时组件支持延后到下一帧清理

## 预防

- 任何主线程超过 500ms 的逻辑拆成多阶段
- 大批量用"按桶闭环"替代"全量累积"

## 检测关键词

[烘焙, 主线程阻塞, 多阶段, 编辑器卡死, 批量处理, Merge]
