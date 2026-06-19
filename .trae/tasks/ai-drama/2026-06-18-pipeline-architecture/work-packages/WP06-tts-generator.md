# WP06: TTS 配音生成器 (v2.0 — TTS-first 策略核心)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/tts_generator/` (新建)
- `skills/ai-drama-producer/utils/tts_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (TTS-first 音画同步 — Pilipili 验证)
- `spec.md` (Phase 6)
- `tasks.md`

## Goal
实现 TTS-first 策略：先生成所有配音音频 → 测量毫秒级实际时长 → 反馈给 Phase 5 (Video Generator) 控制 duration。

## Steps
- [ ] 实现 `utils/tts_client.py` — TTS API 调用抽象层:
  - MiniMax Speech 2.8 HD (中文最佳，情感表现力第一梯队)
  - Edge-TTS (免费降级，30+ 语言)
  - ChatTTS (开源自部署)
  - 统一接口: synthesize(text, voice_params) → audio_file_path
- [ ] 实现 `modules/tts_generator/voice_mapper.py` — 角色 voice_profile → TTS 参数精确映射:
  - gender → 音色库选择
  - age_range → 音高基准
  - timbre → 音色微调参数
  - pace → 语速参数
  - pitch → 音高偏移
  - quirks → 发音规则
- [ ] 实现 `modules/tts_generator/emotion_mapper.py` — emotion → 语速/语调映射
- [ ] 实现 `modules/tts_generator/generator.py` — TTS-first 主逻辑:
  1. 遍历所有 shot.dialogue，生成配音音频
  2. 对每段音频测量毫秒级实际时长 (使用 ffprobe 或 wave 库)
  3. 更新 shots[].duration_source = "tts_measured"
  4. 更新 shots[].duration_sec = 实际时长
  5. 更新 total_duration_sec
  6. 将更新后的剧本 JSON 写回 pipeline-state.json (供 Phase 5 读取)
- [ ] 输出配音时长元数据 (audio/duration_metadata.json)

## Done Definition
- MiniMax + Edge-TTS 双引擎可用
- voice_profile 精确映射到 TTS 参数
- 所有对白音频生成完毕
- 毫秒级时长测量完成
- 剧本 JSON 中 duration_source 更新为 "tts_measured"
- pipeline-state.json 已更新，供 Phase 5 读取

## Required Verification
- Command: `python -c "import json; state=json.load(open('test_output/pipeline-state.json')); script=state['script']; assert any(s['duration_source']=='tts_measured' for s in script['shots']); print('TTS-first OK')"`
- Expected: `TTS-first OK`

## Return Report
- Path: `reports/<agent-name>-WP06-result.md`
- Required status for merge: `done`
