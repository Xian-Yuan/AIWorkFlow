---
domain: ue
domain_path: ue/gas-lyra
kg_node_id: node.doc-ai-ai-19-unreal-conventions-a8cd
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.19-unreal-conventions.a8cd

---

﻿# Unreal 特有规范（反射、宏、Blueprint）

## 反射宏使用
- UCLASS/USTRUCT/UENUM：仅在需要反射与蓝图暴露时使用
- UPROPERTY：用于GC管理与编辑器暴露；明确 EditAnywhere/BlueprintReadOnly 等元数据
- UFUNCTION：BlueprintCallable/BlueprintPure 合理区分；避免在性能关键路径暴露过多蓝图接口

## 指针与内存
- UObject 指针：TObjectPtr 优先；跨对象引用使用 TWeakObjectPtr；非UObject资源使用 TSharedPtr/TUniquePtr
- 生命周期：清晰的拥有者与释放责任；避免隐式所有权

## Blueprint 友好实践
- Category 分类规范；工具提示（Tooltip）简洁明确
- 使用结构体封装复杂参数，减少蓝图节点复杂度

## 风格与可读性
- 保持头/源文件内的函数顺序与声明一致
- 使用详尽中文注释解释设计与边界条件
