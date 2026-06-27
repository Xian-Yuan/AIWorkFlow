# WP04: 分镜关键帧生成器 (v2.0 — 关键帧锁定策略)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/keyframe_generator/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (Pilipili 关键帧锁定策略)
- `spec.md` (Phase 4)
- `tasks.md`
- `skills/ai-drama-producer/utils/image_client.py`

## Goal
实现关键帧生成器：采用 Pilipili 验证的关键帧锁定策略 — 用高质量 Image Gen 生成 4K 关键帧，主体不漂移。

## Steps
- [ ] 实现 `modules/keyframe_generator/prompt_builder.py` — 关键帧提示词组装:
  - 镜头 description + keyframe_prompt_enhancement (构图/光影/色彩细节)
  - 角色参考图路径 (img2img 条件输入)
  - 场景参考图路径
  - 风格 shot_keywords
- [ ] 实现 `modules/keyframe_generator/generator.py` — 批量关键帧生成:
  - 优先使用 NanoBanana Pro / FLUX (高质量)
  - 降级: 即梦/豆包
  - 输出分辨率: 4K (3840x2160) 或 1080p 降级
- [ ] 实现单镜头重试 + 关键帧缓存
- [ ] 关键帧路径写入进度文件

## Done Definition
- 输入剧本 JSON + 角色/场景参考图 → 为每个镜头生成 4K 关键帧
- 关键帧包含 keyframe_prompt_enhancement 的构图/光影细节
- 单镜头失败仅重试该镜头

## Required Verification
- Command: `python -c "from pathlib import Path; from PIL import Image; img=Image.open('test_output/keyframes/shot_01.png'); w,h=img.size; assert w>=1920; print(f'keyframe OK: {w}x{h}')"`
- Expected: `keyframe OK: 3840x2160` (或 ≥ 1920x1080)

## Return Report
- Path: `reports/<agent-name>-WP04-result.md`
- Required status for merge: `done`
