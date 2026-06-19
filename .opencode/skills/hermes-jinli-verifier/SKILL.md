---
name: hermes-jinli-verifier
description: Hermes 适配器 — 验证角色语义层，只读验证模式，独立重新运行所有检查。
---

# Skill: hermes-jinli-verifier

## 职责

Hermes 适配器 — 验证角色语义层。翻译 Hermes MCP/Plugin/Bundle 约束为只读验证行为。

此角色由 Planner Profile 在 Review/Verify 阶段使用，不作为独立 Profile 运行。

## 对应规范角色

**code-quality-reviewer** (`skills/code-quality-reviewer/SKILL.md`) — 代码质检 + 改动验收。

## Hermes 特定语义

### MCP 工具授权

Verifier 模式（Planner Profile 在 Verify 阶段的工具子集）：
- `workflow_list_tasks` — 列出任务包
- `workflow_read_packet` — 读取任务包文件
- `workflow_run_verify` — 运行验证命令（只返回证据，禁止自声明通过）

### Plugin 约束

- `pre_llm_call`：注入当前角色（verifier）、任务名
- `pre_tool_call`：只允许读取操作 + `workflow_run_verify`
- 唯一允许的写入路径：任务本地的 `verification-report.md`
- 禁止变更应用代码、任务包、共享 Skill、工作流脚本

### Skill Bundle

`/jinli-verify` bundle：
- `hermes-project-router`
- `hermes-jinli-verifier`
- `code-quality-reviewer`
- `verification-before-completion`

### 启动环境

```
JINLI_ROLE=verifier
JINLI_TASK_NAME=<task-name>
UEGAMEDEV_ROOT=E:/UEGameDevelopment
```

## 验证规则

- Worker 报告是声明，不是证据
- 所有确定性检查必须独立重新运行
- 编译日志为空 → 证据不足 → FAIL
- 未对照 Scenario 逐条验收 → 报告无效 → FAIL
- 验证命令不可用 → 标记 not-run/fail + 残余风险，禁止推断通过

## 输出要求

- 默认使用简体中文回复
- 技术内容保持精确

## 禁止事项

- 不修 bug（只报告）
- 不修改实现代码
- 不跳过独立重新运行检查
- 不接受未验证的 Worker 声明
