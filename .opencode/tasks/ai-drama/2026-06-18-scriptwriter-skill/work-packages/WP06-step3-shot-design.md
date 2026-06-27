# WP06: Step 3 — 分镜设计 + 15 条约束规则 (v2.0)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/modules/step3_shot_design.py` (新建)
- `skills/ai-drama-scriptwriter/rules/constraint_engine.py` (新建)
- `skills/ai-drama-scriptwriter/tests/test_step3.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Step 3 v2.0: 15 条约束规则 + duration_source + keyframe_prompt_enhancement + TTS 参数)
- `analysis.md`
- `tasks.md` (WP06 section)
- `skills/ai-drama-scriptwriter/prompts/shot_design.md`

## Goal
实现 Step 3 v2.0：分镜设计 + 15 条硬约束规则引擎 + TTS-first 时长标记 + 关键帧增强提示词。

## Steps
- [ ] 实现 `rules/constraint_engine.py` — **15 条**硬约束规则引擎:
  - 规则 1-13: 同 v1.0
  - **v2.0 新增规则 14** (SHOULD): 对白文本长度与 duration_sec 匹配 (中文约 3-4 字/秒)
  - **v2.0 新增规则 15** (SHOULD): 角色在连续镜头中的位置/朝向保持连贯 (跳轴检查)
  - MUST 违规 → 自动修正或拒绝
  - SHOULD 违规 → 警告但允许通过
- [ ] 实现 `modules/step3_shot_design.py` — 分镜设计主逻辑:
  - 调用 LLM 生成分镜 (15 条规则注入 prompt)
  - **v2.0 新增**: duration_source 标记为 "estimated"
  - **v2.0 新增**: dialogue[].tts_pace_override + tts_pitch_override
  - **v2.0 新增**: keyframe_prompt_enhancement 生成 (构图/光影/色彩细节)
  - **v2.0 新增**: tts_duration_estimate_sec + visual_duration_estimate_sec 分离估算
  - 后处理: 规则引擎检查 + 自动修正 MUST 违规
  - visual_feasibility 自动标记
  - 镜头类型变化检测
  - 首镜头 wide/panorama 检查
  - 角色首次出场 medium/close-up 检查
- [ ] 编写单元测试 (3 个用例 + 规则引擎专项测试)

## Done Definition
- 输入角色列表 + 场景列表 + 目标时长 → 输出完整 shots JSON (v2.0 schema)
- 15 条规则全部实现，MUST 违规自动修正
- duration_source 正确标记
- keyframe_prompt_enhancement 非空
- tts_duration_estimate_sec + visual_duration_estimate_sec 合理
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-scriptwriter/tests/test_step3.py -v`
- Expected: all tests pass
- Command: `python -m pytest skills/ai-drama-scriptwriter/rules/ -v`
- Expected: all constraint engine tests pass

## Return Report
- Path: `reports/<agent-name>-WP06-result.md`
- Required status for merge: `done`
