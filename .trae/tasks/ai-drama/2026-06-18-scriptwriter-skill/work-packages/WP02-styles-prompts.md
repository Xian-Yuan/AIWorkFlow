# WP02: 风格预设与提示词模板 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/styles/` (新建)
- `skills/ai-drama-scriptwriter/prompts/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (v2.0 变更对照表)
- `spec.md` (v2.0: 风格预设注入机制 + 15 条约束规则)
- `tasks.md` (WP02 section)

## Goal
创建 10 种视觉风格预设定义（含骨骼/声线风格参数）和 4 个 LLM 提示词模板（v2.0 字段）。

## Steps
- [ ] 创建 `styles/presets.yaml` — 10 种视觉风格预设:
  - 每种含: character_keywords, scene_keywords, shot_keywords, dialogue_style
  - **v2.0 新增**: bone_style_params (eye_style/body_type/face_shape 等风格化骨骼参数)
  - **v2.0 新增**: voice_style_params (timbre/pace/pitch 等风格化声线参数)
  - color_palette, line_style
- [ ] 创建 `prompts/system_prompt.md` — 系统提示词:
  - 角色定义: 三层 Agent 架构中的执行层·编剧 Agent
  - 输出格式约束、硬规则摘要
- [ ] 创建 `prompts/character_extraction.md` — Step 1 模板:
  - **v2.0 新增**: bone_binding_hints 生成指令 (face_shape/eye_style/nose_profile/body_type/height_relative/distinctive_features)
  - **v2.0 新增**: voice_profile 细化生成指令 (gender/age_range/timbre/pace/pitch/quirks)
  - **v2.0 新增**: asset_reuse_id 全局引用
- [ ] 创建 `prompts/scene_breakdown.md` — Step 2 模板:
  - **v2.0 新增**: chapter_id 关联 + estimated_duration_sec 估算
- [ ] 创建 `prompts/shot_design.md` — Step 3 模板:
  - **v2.0 新增**: 15 条约束规则注入
  - **v2.0 新增**: duration_source, tts_pace_override, tts_pitch_override
  - **v2.0 新增**: keyframe_prompt_enhancement, tts_duration_estimate_sec

## Done Definition
- `presets.yaml` 含 10 种风格 + bone_style_params + voice_style_params
- 4 个提示词模板均覆盖 v2.0 新增字段
- `shot_design.md` 注入全部 15 条约束规则

## Required Verification
- Command: `python -c "import yaml; d=yaml.safe_load(open('skills/ai-drama-scriptwriter/styles/presets.yaml')); assert len(d['presets'])==10; assert 'bone_style_params' in d['presets']['日漫']; assert 'voice_style_params' in d['presets']['日漫']; print('presets v2.0 OK')"`
- Expected: `presets v2.0 OK`

## Return Report
- Path: `reports/<agent-name>-WP02-result.md`
- Required status for merge: `done`
