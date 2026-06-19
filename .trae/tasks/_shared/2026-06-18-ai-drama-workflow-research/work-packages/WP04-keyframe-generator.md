# WP04: 分镜关键帧生成器 (Keyframe Generator)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/keyframe_generator/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (分镜驱动设计决策)
- `spec.md` (Module 4)
- `tasks.md` (WP04 section)
- `skills/ai-drama-producer/utils/image_client.py` (复用 WP03 的 Image Gen 客户端)

## Goal
实现分镜关键帧生成器：为每个镜头生成关键帧图片，将角色参考图和场景参考图作为 img2img 条件输入以保证视觉一致性。

## Steps
- [ ] 实现 `modules/keyframe_generator/prompt_builder.py` — 关键帧提示词组装 (镜头描述 + 角色参考图路径 + 场景参考图路径 + 风格预设)
- [ ] 实现 `modules/keyframe_generator/generator.py` — 批量关键帧生成 (遍历所有镜头，调用 image_client)
- [ ] 实现单镜头重试逻辑 (失败镜头单独重试，不影响已完成镜头)
- [ ] 实现关键帧缓存 (基于镜头 hash 去重)
- [ ] 关键帧路径写入进度文件

## Done Definition
- 输入剧本 JSON + 角色/场景参考图 → 为每个镜头生成 `keyframes/{shot_id}.png`
- 单镜头失败时仅重试该镜头
- 缓存命中时跳过已生成的关键帧

## Required Verification
- Command: `python -c "from pathlib import Path; assert Path('test_output/keyframes/shot_01.png').exists(); print('keyframe OK')"`
- Expected: `keyframe OK`

## Return Report
- Path: `reports/<agent-name>-WP04-result.md`
- Required status for merge: `done`
