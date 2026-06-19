# WP07: 合成器 (Compositor)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/compositor/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Module 7)
- `tasks.md` (WP07 section)

## Goal
实现合成器：使用 FFmpeg 将视频片段、配音音频、字幕合成为最终 .mp4 文件。

## Steps
- [ ] 实现 `modules/compositor/ffmpeg_builder.py` — FFmpeg 命令生成器 (视频裁剪、音频对齐、拼接、字幕叠加)
- [ ] 实现 `modules/compositor/subtitle_gen.py` — 字幕生成 (对白文本 → .srt 文件，时间轴对齐)
- [ ] 实现 `modules/compositor/compositor.py` — 最终合成 (逐镜头处理 → 拼接 → 输出)
- [ ] 支持可选背景音乐叠加 (指定音频文件路径 + 音量)
- [ ] 输出最终视频 `output/{title}_final.mp4`

## Done Definition
- 输入视频片段 + 配音音频 + 时长元数据 → 输出完整 .mp4
- 字幕 .srt 文件与对白一致
- 视频时长与分镜总时长偏差 < 5%
- 背景音乐可选叠加

## Required Verification
- Command: `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 test_output/output/test_drama_final.mp4`
- Expected: 输出正数 (视频时长 > 0)
- Command: `python -c "import json; script=json.load(open('test_output/script.json')); expected=sum(s['duration_sec'] for s in script['shots']); import subprocess; result=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1','test_output/output/test_drama_final.mp4'],capture_output=True,text=True); actual=float(result.stdout.strip()); diff=abs(actual-expected)/expected; assert diff<0.05; print(f'duration OK: expected={expected}s, actual={actual}s, diff={diff:.2%}')"`
- Expected: `duration OK: expected=Xs, actual=Ys, diff=Z%`

## Return Report
- Path: `reports/<agent-name>-WP07-result.md`
- Required status for merge: `done`
