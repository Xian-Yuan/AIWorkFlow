# WP07: 合成器 (v2.0 — 剪映草稿导出)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/compositor/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Phase 7 + Layer 5 输出层)
- `tasks.md`

## Goal
实现合成器：FFmpeg 合成最终视频 + 字幕 + 剪映草稿导出 (AI 做 90%，人工微调 10%)。

## Steps
- [ ] 实现 `modules/compositor/ffmpeg_builder.py` — FFmpeg 命令生成器:
  - 视频裁剪到 TTS 实测时长
  - 音频对齐 (基于 TTS duration_metadata.json)
  - 所有镜头拼接
  - 字幕烧录 (可选，默认外挂 .srt)
- [ ] 实现 `modules/compositor/subtitle_gen.py` — 字幕生成:
  - 对白文本 → .srt (时间轴基于 TTS 实测时长)
  - 支持中英文双语字幕
- [ ] 实现 `modules/compositor/compositor.py` — 最终合成
- [ ] 实现 `modules/compositor/jianying_export.py` — 剪映草稿导出:
  - 生成剪映项目文件 (参考 Pilipili 方案)
  - 包含: 视频片段时间轴 + 配音轨道 + 字幕轨道
  - 用户可在剪映中打开进行人工微调
- [ ] 支持可选背景音乐叠加

## Done Definition
- 输入视频片段 + TTS 音频 + 时长元数据 → 输出完整 .mp4 + .srt
- 字幕时间轴与 TTS 实测时长对齐 (偏差 < 200ms)
- 剪映草稿可被剪映桌面版打开
- 视频时长与分镜总时长偏差 < 5%

## Required Verification
- Command: `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 test_output/output/test_drama_final.mp4`
- Expected: 输出正数 (视频时长 > 0)
- Command: `python -c "import json; script=json.load(open('test_output/script.json')); expected=sum(s['duration_sec'] for s in script['shots']); import subprocess; r=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1','test_output/output/test_drama_final.mp4'],capture_output=True,text=True); actual=float(r.stdout.strip()); diff=abs(actual-expected)/expected; assert diff<0.05; print(f'duration OK: expected={expected:.1f}s, actual={actual:.1f}s, diff={diff:.2%}')"`
- Expected: `duration OK`

## Return Report
- Path: `reports/<agent-name>-WP07-result.md`
- Required status for merge: `done`
