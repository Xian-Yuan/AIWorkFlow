# WP03: 剧本 JSON Schema + 验证器套件 (v2.0 — 8 个验证器)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/schemas/` (新建)
- `skills/ai-drama-scriptwriter/validators/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (v2.0: 3 个 Step 的输出 JSON Schema + 15 条验证规则)
- `analysis.md` (Quality Gate)
- `tasks.md` (WP03 section)

## Goal
定义 v2.0 完整剧本 JSON Schema 并实现 8 个验证器（新增 3 个）。

## Steps
- [ ] 创建 `schemas/script_schema.json` — v2.0 完整剧本 JSON Schema:
  - 覆盖所有 v1.0 字段
  - **v2.0 新增**: bone_binding_hints (face_shape/eye_style/nose_profile/body_type/height_relative/distinctive_features)
  - **v2.0 新增**: voice_profile 细化 (gender/age_range/timbre/pace/pitch/quirks)
  - **v2.0 新增**: duration_source (enum: estimated/tts_measured)
  - **v2.0 新增**: tts_pace_override, tts_pitch_override
  - **v2.0 新增**: keyframe_prompt_enhancement
  - **v2.0 新增**: tts_duration_estimate_sec, visual_duration_estimate_sec
  - **v2.0 新增**: asset_reuse_id, chapter_id, estimated_duration_sec
- [ ] 实现 `validators/schema_validator.py`
- [ ] 实现 `validators/reference_checker.py`
- [ ] 实现 `validators/duration_checker.py`
- [ ] 实现 `validators/feasibility_checker.py`
- [ ] 实现 `validators/style_checker.py`
- [ ] 实现 `validators/duplicate_checker.py`
- [ ] **v2.0 新增**: `validators/field_completeness_checker.py` — bone_binding_hints + voice_profile 所有字段非空
- [ ] **v2.0 新增**: `validators/dialogue_duration_matcher.py` — 对白文本长度与 duration_sec 匹配 (中文 3-4 字/秒)
- [ ] **v2.0 新增**: `validators/jump_axis_checker.py` — 连续镜头角色位置/朝向连贯性
- [ ] 编写验证器单元测试 (每个验证器 ≥ 3 个 test case)

## Done Definition
- `script_schema.json` 覆盖 v2.0 所有新增字段
- 8 个验证器全部实现 + 单元测试通过 (≥ 24 test cases)
- 验证器可独立调用，也可组合为 `validate_all(script_json)` 统一入口

## Required Verification
- Command: `python -m pytest skills/ai-drama-scriptwriter/validators/ -v`
- Expected: all tests pass (≥ 24 test cases)
- Command: `python -c "import json; s=json.load(open('skills/ai-drama-scriptwriter/schemas/script_schema.json')); assert 'bone_binding_hints' in str(s); assert 'duration_source' in str(s); print('v2.0 schema OK')"`
- Expected: `v2.0 schema OK`

## Return Report
- Path: `reports/<agent-name>-WP03-result.md`
- Required status for merge: `done`
