---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-36-post-audit-improvement-plan-5618
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.36-post-audit-improvement-plan.5618

---

﻿# 审计后改进计划 (Post-Audit Improvement Plan)

> **版本**: v1.0 | **日期**: 2026-06-18 | **来源**: Docs/AI/34 审计报告 + 金璃小天才分析

---

## 概述

基于审计报告和金璃小天才的 7 条改进建议（采纳 6 条），制定本实施计划。

---

## I1: 双 IDE 适配 — Codex Native Task Adapter (P0)

### 问题
Codex 借道 `.trae/tasks/`，`codex-project-router` 标注了 "until a native .codex/tasks adapter exists"。两套 IDE 任务根目录不一致时可能产生分叉。

### 方案
创建 `.codex/tasks/` 目录 + Codex 版 task-state adapter，支持 multi-root 解析。

### 实施
1. 创建 `.codex/tasks/` 目录结构（镜像 `.trae/tasks/`）
2. 创建 `engine/task-state.ps1` multi-root 版本（支持 `--root .trae|.codex|.opencode`）
3. 更新 `codex-project-router/SKILL.md` 移除 "until native adapter" 标注
4. 创建 `.codex/tasks/README.md` 说明与 `.trae/tasks/` 的关系

### Scenario: Codex 创建新任务
```
GIVEN Codex 收到新 UE5 开发需求
WHEN 执行 task-state.ps1 init --root .codex
THEN .codex/tasks/<task-name>/.task.yaml 被创建
AND 结构与 .trae/tasks/ 完全一致
AND task-guard.ps1 可同时校验 .codex/tasks 和 .trae/tasks
```

### 验收
- [ ] `.codex/tasks/` 目录存在
- [ ] `engine/task-state.ps1` 支持 `--root` 参数
- [ ] `codex-project-router` 不再有 "until native adapter" 标注
- [ ] `task-guard.ps1 plan` 对 `.codex/tasks` 任务通过

---

## I2: 实验脚本边界 — 不一致测试加 _DISABLED 标记 (P1)

### 问题
`engine/_experimental/test-doc-guard.ps1` 和 `test-workflow-regression.ps1` 与 `.trae/scripts/` 正式版本行为不一致，容易制造假故障。

### 方案
给不一致的实验测试脚本加 `_DISABLED_` 前缀，防止误执行。

### 实施
1. 重命名 `engine/_experimental/test-doc-guard.ps1` → `_DISABLED_test-doc-guard.ps1`
2. 重命名 `engine/_experimental/test-workflow-regression.ps1` → `_DISABLED_test-workflow-regression.ps1`
3. 更新 `engine/_experimental/README.md` 说明 `_DISABLED_` 前缀含义

### Scenario: 防止误执行
```
GIVEN engine/_experimental/ 中有 _DISABLED_ 前缀的测试脚本
WHEN Agent 或自动化扫描 engine/_experimental/ 寻找测试
THEN _DISABLED_ 前缀明确表示"当前不可用，不要运行"
AND 只有 .trae/scripts/test-*.ps1 被识别为正式测试
```

### 验收
- [ ] `_DISABLED_test-doc-guard.ps1` 存在
- [ ] `_DISABLED_test-workflow-regression.ps1` 存在
- [ ] 原文件名不存在
- [ ] `_experimental/README.md` 包含 `_DISABLED_` 说明

---

## I3: engine/ 双轨决策 — 废弃 engine/ 脚本目录 (P0)

### 问题
`27-Manifest` 声明 `.trae/scripts/` 是权威路径，`engine/` 是重构候选。但 `engine/` 中 15 个脚本仍在并行维护，存在双写风险。

### 方案
废弃 `engine/` 中的脚本副本，保留 `engine/rule-enforcer.ps1` + `engine/rule-registry.json` + `engine/engine-config.json`（这三个是 engine/ 独有的，非副本）。其余脚本添加 `REFACTOR_CANDIDATE` 标记头，禁止作为权威入口调用。

### 实施
1. 保留: `engine/rule-enforcer.ps1`, `engine/rule-registry.json`, `engine/engine-config.json`
2. 其余 15 个脚本添加统一标记头:
```powershell
# REFACTOR_CANDIDATE — NOT AUTHORITATIVE
# Authoritative version: .trae/scripts/<same-name>.ps1
# Do NOT use this copy. See Docs/AI/27 for current authoritative runtime.
exit 1
```
3. 更新 `Docs/AI/35-Workflow-Tooling-Inventory.md` 将这些脚本从 "Refactor Candidate" 移到 "Disabled (pending promotion)"

### Scenario: 防止误用 engine/ 脚本
```
GIVEN engine/task-state.ps1 有 REFACTOR_CANDIDATE 标记
WHEN Agent 尝试调用 engine/task-state.ps1
THEN 脚本输出 "NOT AUTHORITATIVE" 并 exit 1
AND Agent 被引导到 .trae/scripts/task-state.ps1
```

### 验收
- [ ] `engine/rule-enforcer.ps1` 保持可用
- [ ] `engine/rule-registry.json` 保持可用
- [ ] `engine/engine-config.json` 保持可用
- [ ] 其余 15 个脚本全部有 REFACTOR_CANDIDATE 标记
- [ ] `35-Workflow-Tooling-Inventory.md` 已更新

---

## I4: 门禁自动化 hook — 阶段转换事件触发门禁 (P1)

### 问题
当前所有门禁依赖 AI 主动调用 PowerShell。如果 AI 忘记调用 `task-guard.ps1 plan`，没有机械阻拦。

### 方案
在 `engine/rule-enforcer.ps1` 中增加 `check-phase-gates` 命令，Agent 在阶段转换前必须调用。同时在 `anti-degradation/SKILL.md` 中增加门禁遗漏检测——如果 Agent 连续 3 次操作未触发门禁检查，视为上下文腐烂信号。

### 实施
1. `engine/rule-enforcer.ps1` 新增 `check-phase-gates` 命令:
   - 检查当前 phase 是否已通过对应门禁
   - Plan → 检查 task-guard plan 是否已执行
   - Implement → 检查 can-edit 是否已通过
   - Verify → 检查 task-guard verify 是否已执行
2. `anti-degradation/SKILL.md` 新增规则: 连续 3 次 Write/Edit 未触发门禁 → 上下文腐烂信号
3. `spec-living/SKILL.md` 新增: SessionStart 时自动提醒当前 phase 需要哪些门禁

### Scenario: 门禁遗漏检测
```
GIVEN Agent 在 Implement 阶段连续 3 次 Edit 未调用 can-edit
WHEN anti-degradation 检测到此信号
THEN 输出 "[ANTI-DEGRADATION] Gate bypass detected: 3 edits without can-edit check"
AND 建议暂停并执行 task-guard.ps1 implement
```

### 验收
- [ ] `rule-enforcer.ps1 check-phase-gates` 可用
- [ ] `anti-degradation/SKILL.md` 包含门禁遗漏检测规则
- [ ] `spec-living/SKILL.md` 包含门禁提醒

---

## I5: Flash 质量风险 — Implement 末尾自动化验证 (P1)

### 问题
Implement 阶段用 Flash 模型，对照 spec 自检可能流于形式。

### 方案
创建 `engine/verify-implement.ps1`，在 Implement 阶段末尾自动运行，不依赖模型自觉:
1. 编译状态检查（编译日志最后 10 行）
2. Spec Scenario 覆盖率检查（spec.md 中 done/total）
3. 文件放置合规检查（所有新增/修改文件路径验证）
4. 单机约束检查（grep Replicated/Server/Client/RPC 关键词）

### 实施
1. 创建 `engine/verify-implement.ps1`
2. 集成到 `spec-living.ps1` — Task 全部完成时自动调用
3. 更新 `Docs/AI/24-Pro-Flash-Model-Tiering.md` — Implement 末尾增加 verify-implement 步骤

### Scenario: 自动化验证拦截
```
GIVEN Implement 阶段所有 Task 标记为 done
WHEN spec-living.ps1 检测到所有 Task 完成
THEN 自动调用 verify-implement.ps1
AND 如果编译失败 → 阻止 phase transition 到 Review
AND 如果 Spec Scenario 未全覆盖 → 警告
AND 如果检测到 Replicated 关键词 → 阻止 (单机违规)
```

### 验收
- [ ] `engine/verify-implement.ps1` 可用
- [ ] `spec-living.ps1` 在 Task 全部完成时自动调用 verify-implement
- [ ] `24-Pro-Flash-Model-Tiering.md` 已更新

---

## I6: Memory 层升级 — ruflo 语义搜索集成 (P1)

### 问题
Plan 阶段的 failure memory 注入是关键词匹配，可能漏掉语义相关但关键词不同的教训。

### 方案
`memory-retrieve.ps1` 增加 `--semantic` 模式，调用 ruflo 的语义搜索作为增强层。保留关键词匹配作为 fallback。

### 实施
1. `memory-retrieve.ps1` 新增 `-Semantic` 开关
2. Semantic 模式: 调用 `ruflo memory search -q "<query>" --format json`
3. 结果与关键词匹配结果合并去重
4. ruflo 不可用时自动 fallback 到关键词匹配
5. 更新 `failure-memory/SKILL.md` — Plan 阶段默认使用 semantic 模式

### Scenario: 语义搜索命中关键词漏掉的教训
```
GIVEN Docs/Memory/failures/ 中有 "GameFeature 加载顺序导致编译失败"
AND 当前任务是 "新增 GameFeature Plugin"
WHEN memory-retrieve.ps1 -Semantic -Query "新增 GameFeature"
THEN 语义搜索命中 "GameFeature 加载顺序导致编译失败" (score > 0.7)
AND 关键词匹配可能漏掉 (因为不含 "编译失败" 关键词)
```

### 验收
- [ ] `memory-retrieve.ps1 -Semantic` 可用
- [ ] ruflo 不可用时自动 fallback
- [ ] `failure-memory/SKILL.md` 已更新

---

## 优先级与时间估算

| 优先级 | 项目 | 预估时间 | 依赖 |
|:---:|------|:---:|------|
| **P0** | I3: engine/ 双轨废弃 | 0.5h | 无 |
| **P0** | I1: Codex Native Task Adapter | 2h | 无 |
| **P1** | I2: 实验脚本 _DISABLED | 0.2h | 无 |
| **P1** | I5: Flash 质量验证脚本 | 1h | 无 |
| **P1** | I6: Memory 语义搜索 | 1h | ruflo 可用 |
| **P1** | I4: 门禁自动化 hook | 1.5h | I3 完成 |

---

## 实施顺序

```
I3 (engine/ 废弃) → I1 (Codex adapter) → I2 (_DISABLED) → I5 (Flash 验证) → I6 (语义搜索) → I4 (门禁 hook)
```

I3 和 I1 是 P0，先做。I2 最简单，顺手做。I5/I6/I4 是 P1，按依赖顺序。
