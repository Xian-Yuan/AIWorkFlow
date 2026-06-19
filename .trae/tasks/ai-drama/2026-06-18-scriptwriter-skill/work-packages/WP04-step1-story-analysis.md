# WP04: Step 1 — 故事分析与角色提取 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/modules/step1_story_analysis.py` (新建)
- `skills/ai-drama-scriptwriter/modules/step1_character_extraction.py` (新建)
- `skills/ai-drama-scriptwriter/tests/test_step1.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Step 1 v2.0: bone_binding_hints + voice_profile 细化 + asset_reuse_id)
- `analysis.md`
- `tasks.md` (WP04 section)
- `skills/ai-drama-scriptwriter/prompts/character_extraction.md`

## Goal
实现 Step 1 v2.0：故事分析 + 角色提取，输出含 bone_binding_hints、细化 voice_profile、asset_reuse_id 的角色列表。

## Steps
- [ ] 实现 `modules/step1_story_analysis.py` — 故事分析:
  - **v2.0 新增**: total_word_count + chapter_count
- [ ] 实现 `modules/step1_character_extraction.py` — 角色提取:
  - 调用 LLM 提取角色基本信息 (name/role/archetype/description/personality_traits/character_arc)
  - **v2.0 新增**: bone_binding_hints 生成 (face_shape/eye_style/nose_profile/body_type/height_relative/distinctive_features) — 所有字段必填
  - **v2.0 新增**: voice_profile 细化生成 (gender/age_range/timbre/pace/pitch/quirks) — 所有字段必填
  - **v2.0 新增**: asset_reuse_id 生成 (格式: global_char_NN)
  - 角色数量验证: 2-6 个
  - 视觉关键词检查: 每个 description ≥ 3 个
  - 主角必须有 character_arc
- [ ] 实现 Step 1 主入口: 串联 story_analysis + character_extraction
- [ ] 编写单元测试 (3 个用例: 奇幻/都市/古装)

## Done Definition
- 输入 1000 字故事 → 输出 story_analysis + characters JSON (v2.0 schema)
- bone_binding_hints 所有字段非空
- voice_profile 所有字段非空
- asset_reuse_id 格式正确
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-scriptwriter/tests/test_step1.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP04-result.md`
- Required status for merge: `done`
