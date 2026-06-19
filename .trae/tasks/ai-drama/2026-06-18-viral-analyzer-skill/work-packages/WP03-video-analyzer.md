# WP03: 视频分析引擎 (VideoAnalyzer)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/modules/video_analyzer/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (Level 1-3 视频分析项目详析)
- `spec.md` (Module 1: VideoAnalyzer + 8 维度 + 输出 JSON Schema)
- `tasks.md` (WP03 section)

## Goal
实现视频分析引擎：下载→抽帧→ASR→视觉分析→8 维度爆款分析→Replication Playbook 生成。

## Steps
- [ ] 实现 `modules/video_analyzer/downloader.py` — 视频下载 (yt-dlp, 多平台, 降级策略: 直接下载→页面JSON→WebFetch→手动粘贴)
- [ ] 实现 `modules/video_analyzer/frame_extractor.py` — 关键帧提取:
  - FFmpeg 每秒 1 帧, 最长 180 帧
  - 场景切换检测 (scene detect filter)
  - 标记切镜点时间戳
- [ ] 实现 `modules/video_analyzer/transcriber.py` — ASR 转录:
  - Whisper 本地 (优先) + Groq/OpenAI API (降级)
  - 输出词级时间戳 [{word, start_sec, end_sec}]
- [ ] 实现 `modules/video_analyzer/visual_analyzer.py` — 视觉分析:
  - LLM Vision 逐场景分析: 景别/运镜/构图/文字叠加/情绪
  - 并发处理 (多帧同时提交)
- [ ] 实现 `modules/video_analyzer/viral_analyzer.py` — 8 维度爆款分析:
  - 钩子/叙事结构/情绪曲线/剪辑节奏/镜头语言/CTA/文案金句/评论区
  - LLM 结构化输出 (JSON Schema 约束)
- [ ] 实现 `modules/video_analyzer/playbook_generator.py` — Replication Playbook:
  - hook_formula + structure_blueprint + visual_style + audio_style
- [ ] 实现 `modules/video_analyzer/pipeline.py` — 主编排 (Step 1-7 串联, 进度回调)
- [ ] 编写单元测试 (3 个测试视频)

## Done Definition
- 输入视频 URL → 输出完整 8 维度分析报告 + Replication Playbook
- 支持 TikTok/YouTube/Instagram/抖音/B站
- 分析耗时 < 5 分钟/视频
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/test_video_analyzer.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP03-result.md`
- Required status for merge: `done`
