# WP09: 端到端集成测试与验证 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/tests/` (新建)
- `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/verification-report.md` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-producer/modules/` (只读)

## Read First
- `routing.md`
- `spec.md` (Acceptance Criteria AC01-AC11)
- `tasks.md` (WP09 + Final Verification)
- `analysis.md` (Rejected Shortcuts 8 条)

## Goal
运行端到端集成测试，验证 AC01-AC11 全部通过，产出 verification-report.md。

## Steps
- [ ] 准备 3 个测试用例 (短篇: 1000字/2000字/5000字，分别对应日漫/写实/国风)
- [ ] 运行 StandardPipeline 端到端测试 (3 个用例)
- [ ] 运行 AssetBasedPipeline 和 LinearPipeline 变体测试
- [ ] 验证 AC01: 输入小说 → 输出 .mp4 + .srt
- [ ] 验证 AC02: 角色一致性 (SSIM > 0.85)
- [ ] 验证 AC03: 分镜 JSON Schema 校验
- [ ] 验证 AC04: 断点续传
- [ ] 验证 AC05: 单镜头失败重试
- [ ] 验证 AC06: 工具后端可替换 (Wan2.2↔Kling)
- [ ] 验证 AC07: 视频时长偏差 < 5%
- [ ] 验证 AC08: 字幕与对白一致，时间轴偏差 < 200ms
- [ ] 验证 AC09: 音画同步 (TTS-first 策略)
- [ ] 验证 AC10: 长文本不丢失上下文
- [ ] 验证 AC11: 资产跨项目复用 (全局资产库)
- [ ] 验证 mature path 被实现，8 条 rejected shortcut 无一被引入
- [ ] 收集所有验证证据，写入 verification-report.md

## Done Definition
- 3 个测试用例全部通过
- 11 个 AC 有明确 pass/fail 证据
- verification-report.md 包含: Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk
- 确认 8 条 rejected shortcut 无一被引入

## Required Verification
- Command: `python -m pytest skills/ai-drama-producer/tests/ -v`
- Expected: all integration tests pass

## Return Report
- Path: `reports/<agent-name>-WP09-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
