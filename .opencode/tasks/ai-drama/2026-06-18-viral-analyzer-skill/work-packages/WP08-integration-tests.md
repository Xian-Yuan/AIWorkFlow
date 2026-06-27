# WP08: 集成测试与验证

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/tests/` (新建/更新)
- `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/verification-report.md` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-viral-analyzer/modules/` (只读)

## Read First
- `routing.md`
- `spec.md` (Acceptance Criteria AC01-AC13)
- `tasks.md` (WP08 + Final Verification)
- `analysis.md` (Rejected Shortcuts 7 条)

## Goal
运行集成测试，验证 AC01-AC13 全部通过，产出 verification-report.md。

## Steps
- [ ] 准备测试用例:
  - 视频: 3 个不同平台的爆款视频 URL
  - 小说: 2 篇不同风格的短篇小说 (1000字/3000字)
  - 频道: 1 个博主主页
- [ ] 运行 VideoAnalyzer 端到端测试 (3 个视频)
- [ ] 运行 NovelAnalyzer 端到端测试 (2 篇小说)
- [ ] 运行 ChannelAnalyzer 端到端测试 (1 个频道)
- [ ] 运行 StyleCopy + FusionCreate + ScriptInject 测试
- [ ] 验证 AC01-AC13 全部通过
- [ ] 验证 mature path 被实现，7 条 rejected shortcut 无一被引入
- [ ] 收集所有验证证据，写入 verification-report.md

## Done Definition
- 6 个测试用例全部通过
- 13 个 AC 有明确 pass/fail 证据
- verification-report.md 包含: Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk

## Required Verification
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/ -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP08-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
