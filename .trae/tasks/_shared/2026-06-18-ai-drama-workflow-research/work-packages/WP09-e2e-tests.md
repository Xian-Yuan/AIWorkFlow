# WP09: 端到端集成测试与验证

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/tests/` (新建)
- `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/verification-report.md` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-producer/modules/` (只读，不修改)

## Read First
- `routing.md`
- `spec.md` (Acceptance Criteria 全表)
- `tasks.md` (WP09 section + Final Verification)
- `analysis.md` (Rejected Shortcuts)

## Goal
运行端到端集成测试，验证所有 Acceptance Criteria，产出 verification-report.md。

## Steps
- [ ] 准备 3 个测试用例 (短剧本: 5镜头/10镜头/15镜头)
- [ ] 运行全管线集成测试 (3 个测试用例)
- [ ] 验证 AC01: 输入小说 → 输出 .mp4
- [ ] 验证 AC02: 角色一致性 (人工目视 + 参考图传递链路)
- [ ] 验证 AC03: 分镜 JSON Schema 校验
- [ ] 验证 AC04: 断点续传
- [ ] 验证 AC05: 单镜头失败重试
- [ ] 验证 AC06: 工具后端可替换
- [ ] 验证 AC07: 视频时长偏差 < 5%
- [ ] 验证 AC08: 字幕与对白一致
- [ ] 验证 mature path 被实现，无 rejected shortcut 被引入
- [ ] 收集所有验证证据，写入 verification-report.md

## Done Definition
- 3 个测试用例全部通过
- 所有 8 个 AC 有明确 pass/fail 证据
- verification-report.md 包含所有必需章节 (Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk)
- 确认无 rejected shortcut 被引入

## Required Verification
- Command: `python -m pytest skills/ai-drama-producer/tests/ -v`
- Expected: all integration tests pass
- Command: `.\.trae\scripts\task-guard.ps1 2026-06-18-ai-drama-workflow-research verify`
- Expected: exit code 0

## Return Report
- Path: `reports/<agent-name>-WP09-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.
