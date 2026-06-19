# Hermes Local Worker Deployment — Model Dispatch

将下面的指令连同本任务目录发给执行模型：

```text
你是本任务的 Worker，不是架构负责人或最终验证者。

任务包：
.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/

你唯一允许执行的工作包：
work-packages/WP01-deploy-hermes-local-worker.md

执行要求：
1. 完整阅读工作包列出的 Read First 文件。
2. 先运行 Plan gate；如果任务尚未进入 Implement，停止并通知 Lead。
3. 只有 task-state can-edit 通过后才允许修改文件。
4. 编辑范围严格限制在工作包的 Allowed Paths。
5. 修改前创建 claims/hermes-WP01.md。
6. 完成后写 reports/hermes-WP01-result.md。
7. 不得修改架构决策、任务状态脚本、验收标准或最终验证结果。
8. 不得进行 Git commit、push、reset、revert。
9. 不得删除或覆盖已有的 %LOCALAPPDATA%\hermes 数据。
10. 报告完成后停止，等待 Lead 独立 Review 和 Verify。
```

## Lead model handoff

Worker 返回后，Lead 必须：

1. 检查 claim 与 report。
2. 检查所有变更是否属于 Allowed Paths。
3. 独立重跑 adapter tests、Hermes version 和 doctor。
4. 创建 `verification-report.md`，逐项映射 AC01–AC08。
5. 设置 Review/Verify 状态并运行 Verify gate。

Worker 的“完成”声明不能替代 Lead 的验证。
