# WP08: 集成测试与验证 (v2.0 — 13 AC)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/tests/` (新建/更新)
- `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/verification-report.md` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-scriptwriter/modules/` (只读)
- `skills/ai-drama-scriptwriter/validators/` (只读)

## Read First
- `routing.md`
- `spec.md` (Acceptance Criteria AC01-AC13)
- `tasks.md` (WP08 + Final Verification)
- `analysis.md` (Rejected Shortcuts 8 条)

## Goal
运行集成测试，验证 AC01-AC13 全部通过，产出 verification-report.md。

## Steps
- [ ] 准备 3 个测试用例 (短篇: 1000字/2000字/5000字，日漫/写实/国风)
- [ ] 运行 Quick Mode 端到端测试 (3 个用例)
- [ ] 运行 Review Mode 分步测试
- [ ] 验证 AC01: 输入小说 → 输出完整剧本 JSON
- [ ] 验证 AC02: 剧本 JSON 通过 Schema 校验
- [ ] 验证 AC03: 引用完整性
- [ ] 验证 AC04: 总时长 ≤ target × 1.2
- [ ] 验证 AC05: 所有镜头 duration_sec 在 2-8 范围
- [ ] 验证 AC06: 无 risky 镜头
- [ ] 验证 AC07: 角色外观描述只出现一次
- [ ] 验证 AC08: 风格关键词正确注入
- [ ] 验证 AC09: 分步模式可用
- [ ] 验证 AC10: 增量修改可用
- [ ] **v2.0 新增** AC11: bone_binding_hints + voice_profile 字段完整性
- [ ] **v2.0 新增** AC12: 对白时长匹配 (中文 3-4 字/秒)
- [ ] **v2.0 新增** AC13: 长文本章节事件图谱
- [ ] 验证 mature path 被实现，8 条 rejected shortcut 无一被引入
- [ ] 收集所有验证证据，写入 verification-report.md

## Done Definition
- 3 个测试用例全部通过
- 13 个 AC 有明确 pass/fail 证据
- verification-report.md 包含: Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, Residual Risk

## Required Verification
- Command: `python -m pytest skills/ai-drama-scriptwriter/tests/ -v`
- Expected: all tests pass (≥ 30 test cases)

## Return Report
- Path: `reports/<agent-name>-WP08-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
