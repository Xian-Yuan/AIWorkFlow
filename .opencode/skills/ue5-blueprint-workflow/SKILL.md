---
name: "ue5-blueprint-workflow"
description: "Implements or modifies Blueprint features with a validate-first workflow. Invoke when user asks about Blueprints, nodes, Enhanced Input, interactions, or UMG wiring."
---

# UE5 Blueprint Workflow

## 关键事实

- Blueprint 资源（.uasset）通常无法直接当作纯文本分析；需要用户提供“节点文本复制内容”或“截图/录屏”。
- 已接入 BlueprintAutomationBridge 时，可直接导出图结构并执行节点级改写（新增节点、连线、编译、保存）。

## 输入契约（你需要用户提供）

至少满足其一：
- Blueprint 截图：包含变量面板、节点连线、关键细节（节点名/Pin/默认值）
- 节点文本：在蓝图里框选节点 → Ctrl+C → 粘贴到对话（会是可读文本）
- 最小复现描述：哪个 BP（类/路径）、哪个 Graph、触发方式、期望行为、实际行为

补充信息：
- 输入系统：Enhanced Input 还是旧 Input
- 发生场景：角色/武器/交互物/Widget/关卡蓝图
- 性能/可维护性约束：是否允许 Tick、是否需要组件化、是否需要数据驱动（DataAsset/DT）

## 插件优先工作流（有 BlueprintAutomationBridge 时）

1. 健康检查：`/health`
2. 导出蓝图：`export_blueprint`
3. 规划修改：基于导出 JSON 设计新增节点与连线
4. 执行修改：`add_callfunction_node` + `connect_pins`
5. 收尾验证：`compile_save`，回传结果与影响范围

当插件不可用时，再退回截图/节点文本模式。

## 产出流程（按顺序执行）

1. 明确行为规格
   - 触发条件、状态机、边界条件（例如：暂停、UI 焦点、移动中是否允许）
2. 选择实现落点
   - 优先 ActorComponent（可复用、可测试）
   - UI 逻辑优先在 Widget，自上而下传参，避免在 Widget 内硬引用世界对象
3. 画数据流
   - 输入 → 状态 → 动作 → 反馈（动画/音效/特效/UI）
4. 蓝图节点级落地
   - 给出“需要添加/修改的节点清单”和“连线逻辑”
   - 避免每帧查找：缓存引用、用 BeginPlay 初始化、必要时用定时器替代 Tick
5. 验证与自检
   - 运行时验证步骤（怎么触发、看什么指标）
   - 常见陷阱排查（输入未生效、UI 抢焦点、Cast 失败、引用失效）

## 常见验证清单

- 输入：Action 映射是否添加到正确的 Mapping Context；优先级是否被覆盖
- 执行：事件是否被触发（用 Print String/日志最小验证）
- 引用：对象是否有效（IsValid），是否在切换关卡后失效
- 性能：是否引入不必要 Tick；是否反复 GetAllActorsOfClass
