# WP06: 配音生成器 (TTS Generator)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/tts_generator/` (新建)
- `skills/ai-drama-producer/utils/tts_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Module 6)
- `tasks.md` (WP06 section)

## Goal
实现配音生成器：从剧本 JSON 提取对白和旁白，调用 TTS API 生成配音音频，输出时长元数据。

## Steps
- [ ] 实现 `utils/tts_client.py` — TTS API 调用抽象层 (支持豆包/GLM/Edge-TTS，统一接口)
- [ ] 实现 `modules/tts_generator/voice_mapper.py` — 角色 voice_profile → TTS 音色参数映射表
- [ ] 实现 `modules/tts_generator/emotion_mapper.py` — 情感参数 → 语速/语调映射表
- [ ] 实现 `modules/tts_generator/generator.py` — 对白 TTS 生成 + 旁白 TTS 生成
- [ ] 输出配音时长元数据 (JSON)，用于后续合成对齐

## Done Definition
- `tts_client.py` 支持至少 2 种 TTS 后端
- 输入剧本 JSON → 为每句对白生成 `audio/{shot_id}_{char_id}_{line_index}.mp3`
- 为旁白生成 `audio/{shot_id}_narration.mp3`
- 输出 `audio/duration_metadata.json` 含每段音频的时长

## Required Verification
- Command: `python -c "from pathlib import Path; import json; assert Path('test_output/audio/shot_01_char_01_0.mp3').exists(); meta=json.load(open('test_output/audio/duration_metadata.json')); assert len(meta)>0; print('TTS OK')"`
- Expected: `TTS OK`

## Return Report
- Path: `reports/<agent-name>-WP06-result.md`
- Required status for merge: `done`
