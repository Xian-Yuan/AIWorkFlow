# WP05: 视频生成器 (Video Generator)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/video_generator/` (新建)
- `skills/ai-drama-producer/utils/video_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (逐镜头处理 + Rejected Shortcuts: 禁止一次性批量生成)
- `spec.md` (Module 5)
- `tasks.md` (WP05 section)

## Goal
实现视频生成器：从关键帧图片生成视频片段，支持异步提交、轮询状态、并发生成、失败重试。

## Steps
- [ ] 实现 `utils/video_client.py` — Video Gen API 调用抽象层 (支持 Seedance/Kling/Veo/Vidu/Sora，统一接口: submit + poll + download)
- [ ] 实现 `modules/video_generator/generator.py` — 图生视频 (关键帧 → 视频片段)
- [ ] 实现异步任务提交 + 轮询状态 (支持 timeout 配置)
- [ ] 实现并发生成 (多镜头同时提交，使用 asyncio 或线程池)
- [ ] 实现失败重试 + 视频缓存
- [ ] 视频路径写入进度文件

## Done Definition
- `video_client.py` 支持至少 2 种 Video Gen 后端
- 输入关键帧 + 镜头描述 + 时长 → 输出 `videos/{shot_id}.mp4`
- 支持并发提交 (至少 3 个镜头同时处理)
- 单镜头失败自动重试 (最多 3 次)
- 缓存命中时跳过已生成的视频

## Required Verification
- Command: `python -c "from pathlib import Path; assert Path('test_output/videos/shot_01.mp4').exists(); print('video OK')"`
- Expected: `video OK`

## Return Report
- Path: `reports/<agent-name>-WP05-result.md`
- Required status for merge: `done`
