# WP02: 剧本生成器 — 对接编剧 Skill (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/script_generator/` (新建)
- `skills/ai-drama-producer/schemas/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-scriptwriter/` (独立 Skill，只读引用)

## Read First
- `routing.md`
- `analysis.md` (三层 Agent 架构 + TTS-first 数据流)
- `spec.md` (Layer 3 执行层 + Phase 2)
- `tasks.md`
- `../2026-06-18-scriptwriter-skill/spec.md` (编剧 Skill v2.0 完整 spec)

## Goal
实现管线中的剧本生成适配器：加载编剧 Skill，传入故事文本 + 风格 + 目标时长，接收 v2.0 剧本 JSON，通过所有验证器。

## Steps
- [ ] 创建 `schemas/script_schema.json` — 完整剧本 JSON Schema (v2.0 字段: bone_binding_hints, voice_profile 细化, duration_source, keyframe_prompt_enhancement, tts_duration_estimate_sec)
- [ ] 实现 `modules/script_generator/adapter.py` — 编剧 Skill 适配器:
  - 加载 `ai-drama-scriptwriter` Skill
  - 传入: 故事文本 + 风格预设 + 目标时长 + (可选) 章节事件图谱
  - 接收: v2.0 剧本 JSON
  - 运行验证器套件 (Schema + 引用 + 时长 + 可行性 + 风格 + 字段完整性 + 对白匹配 + 跳轴)
- [ ] 实现 `modules/script_generator/pipeline_bridge.py` — 管线桥接:
  - 将剧本 JSON 写入 pipeline-state.json
  - 提取角色列表 → 传递给 Phase 3 (Asset Generator)
  - 提取对白列表 + voice_profile → 传递给 Phase 6 (TTS Generator)
  - 提取分镜描述 + keyframe_prompt_enhancement → 传递给 Phase 4 (Keyframe Generator)

## Done Definition
- 适配器正确加载编剧 Skill 并传入参数
- 输出通过全部 8 个验证器
- 管线桥接正确提取并传递数据给下游 Phase

## Required Verification
- Command: `python -m pytest skills/ai-drama-producer/modules/script_generator/ -v`
- Expected: all tests pass
- Command: `python -c "import json; schema=json.load(open('skills/ai-drama-producer/schemas/script_schema.json')); assert 'bone_binding_hints' in str(schema); assert 'voice_profile' in str(schema); print('v2.0 schema OK')"`
- Expected: `v2.0 schema OK`

## Return Report
- Path: `reports/<agent-name>-WP02-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
