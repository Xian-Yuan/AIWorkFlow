# WP05: 视频生成器 (v2.0 — 双引擎 + TTS-first 时长反馈)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/video_generator/` (新建)
- `skills/ai-drama-producer/utils/video_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (双引擎策略 + TTS-first 数据流)
- `spec.md` (Phase 5)
- `tasks.md`

## Goal
实现视频生成器：Wan2.2 自部署 (主力) + Kling/Seedance API (降级) 双引擎，接收 TTS-first 反馈的实际时长。

## Steps
- [ ] 实现 `utils/video_client.py` — Video Gen API 调用抽象层:
  - Wan2.2 自部署 (Apache-2.0, 14B, 16GB+ VRAM)
  - Kling 3.0 API (中文场景最佳)
  - Seedance 1.5 API (与 GPT Image 2 配合)
  - LTX-Video (8GB VRAM 低配降级)
  - 统一接口: submit(prompt, keyframe_image, duration_sec) + poll + download
- [ ] 实现 `modules/video_generator/generator.py` — 图生视频:
  - 输入: 关键帧 + 镜头描述 + duration_sec
  - **TTS-first 反馈**: 读取 shots[].duration_source，若为 "tts_measured" 则使用 TTS 实测时长
  - 骨骼绑定数据注入 (防止面部变形)
- [ ] 实现异步提交 + 轮询 + 并发 (asyncio)
- [ ] 实现失败重试 (最多 3 次) + 视频缓存
- [ ] 视频路径写入进度文件

## Done Definition
- 双引擎可用，Wan2.2 自部署 + Kling API 降级
- 正确读取 TTS 实测时长 (duration_source=tts_measured)
- 骨骼绑定数据注入视频生成
- 并发 ≥ 3 镜头 + 失败自动重试

## Required Verification
- Command: `python -c "from pathlib import Path; import subprocess; p=Path('test_output/videos/shot_01.mp4'); assert p.exists(); r=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1',str(p)],capture_output=True,text=True); print(f'video OK: {float(r.stdout.strip()):.1f}s')"`
- Expected: `video OK: X.Xs`

## Return Report
- Path: `reports/<agent-name>-WP05-result.md`
- Required status for merge: `done`
