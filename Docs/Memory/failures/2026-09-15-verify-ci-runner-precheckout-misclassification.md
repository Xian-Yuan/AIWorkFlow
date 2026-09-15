---
id: memory-verify-ci-runner-precheckout-misclassification-2026-09-15
type: failure_memory
phase: verify
project_type: other
module: ci-verification
tags:
  - phase:verify
  - mod:validator
  - dom:build
  - pat:configuration
  - pat:boundary
severity: high
write_trigger: verify_fail
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# CI 在 checkout 前失败时，不得误判为代码失败或测试通过

## Symptom
PixelLighting2D P1-C 的 GitHub Actions workflow 显示红色失败，但 job 实际在 runner setup / 分配阶段就结束，checkout、Linux quick、Windows hosted preflight 和 canonical gate 都没有真正执行。仅看 workflow conclusion 很容易走向两个错误结论：把它当成代码 FAIL 去修改功能代码，或因为测试没有报断言失败而当成 PASS。

## Root Cause
只读取 CI 的最终颜色/结论，没有追踪“最早失败步骤”和“代码是否已被 checkout、目标测试命令是否真实启动”的执行 provenance；验证状态缺少 `PASS / CODE_FAIL / INFRA_BLOCKED` 的明确区分。

## Bad Pattern
- 看到 GitHub Actions 红色就直接调试业务代码
- 没确认 checkout 是否执行就把失败归因到当前提交
- 把 skipped/not-run 测试解释为通过
- 为了消除红色而绕过、手工替代或自行触发 canonical gate
- 在基础设施没有提供有效证据时仍合并 PR

## Correct Rule
CI 失败必须先按执行阶段分类：runner allocation/setup → checkout → bootstrap → build/test → gate。只有代码成功 checkout 且相关验证命令真实启动后，才允许把后续失败归因到代码。checkout 前的失败统一标记为 `INFRA_BLOCKED`：它不是代码 FAIL，也绝不是 PASS；依赖该证据的 PR 必须继续保持阻塞状态。

## Retrieval Hint
适用于 verify 阶段分析 GitHub Actions、Hosted Runner、自托管 Runner、preflight/canonical gate 等“红了但没有测试证据”的情况。

## Verification
每次归因前至少核验：
1. runner 是否成功分配/启动；
2. checkout 是否实际执行；
3. bootstrap/依赖阶段是否执行；
4. 目标测试或 gate 命令是否真实启动；
5. 该命令的退出码/日志是什么。
若 checkout 或目标命令未执行，报告必须写 `INFRA_BLOCKED / NOT RUN`，禁止写代码 FAIL 或 PASS。
