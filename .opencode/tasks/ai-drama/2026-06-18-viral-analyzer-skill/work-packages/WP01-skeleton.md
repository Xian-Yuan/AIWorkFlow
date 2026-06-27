# WP01: Skill 骨架与工具依赖

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/` (新建)
- `.agents/skills/ai-drama-viral-analyzer/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-scriptwriter/`
- `skills/ai-drama-producer/`

## Read First
- `routing.md`
- `analysis.md` (Level 1-4 进化路径 + 6 种架构模式)
- `spec.md` (双引擎架构 + 8 维度 + 4 种交互模式)
- `tasks.md` (WP01 section)

## Goal
创建 ai-drama-viral-analyzer Skill 骨架：目录结构、SKILL.md、配置系统、LLM 客户端（含 Vision）、媒体工具封装、日志模块。

## Steps
- [ ] 创建目录结构 (config/, knowledge/, modules/video_analyzer/, modules/novel_analyzer/, modules/channel_analyzer/, modules/creator/, utils/, tests/)
- [ ] 创建 SKILL.md — 含六层架构定位 + 双引擎说明 + 4 种交互模式概述
- [ ] 创建 `.agents/skills/ai-drama-viral-analyzer/SKILL.md` (同步)
- [ ] 实现 `config/default.yaml` — LLM 后端 + Vision API + 分析参数 (Z-score 阈值=2.0, 抽帧率=1fps, 最大帧数=180)
- [ ] 实现 `utils/llm_client.py` — LLM 调用抽象层 (Claude/GPT/DeepSeek/GLM + Vision API 支持)
- [ ] 实现 `utils/media_utils.py` — 媒体工具封装:
  - yt-dlp 下载 (多平台, 降级: 直接下载→页面JSON→WebFetch→手动粘贴)
  - FFmpeg 抽帧 (每秒1帧, 场景切换检测, 音频分离)
  - Whisper ASR (本地 + Groq/OpenAI API 降级, 词级时间戳)
- [ ] 实现 `utils/logger.py` — 日志模块

## Done Definition
- 目录结构完整
- SKILL.md 含六层架构定位 + 双引擎说明
- `config/default.yaml` 可解析
- `media_utils.py` 可下载视频 + 抽帧 + ASR 转录
- `llm_client.py` 支持 Vision API

## Required Verification
- Command: `python -c "import yaml; yaml.safe_load(open('skills/ai-drama-viral-analyzer/config/default.yaml')); print('config OK')"`
- Expected: `config OK`
- Command: `python -c "from skills.ai_drama_viral_analyzer.utils.media_utils import check_dependencies; check_dependencies(); print('deps OK')"`
- Expected: `deps OK`

## Return Report
- Path: `reports/<agent-name>-WP01-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
