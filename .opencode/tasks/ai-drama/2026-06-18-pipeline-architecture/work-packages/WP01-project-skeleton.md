# WP01: 项目骨架与配置系统 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/` (新建)
- `.agents/skills/ai-drama-producer/` (新建)
- `skills/ai-drama-producer/config/`
- `skills/ai-drama-producer/styles/`
- `skills/ai-drama-producer/utils/`

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md` (v2.0: 五层架构 + 8 个子模块索引)
- `analysis.md` (v2.0: 7 项目详析 + 13 维度矩阵)
- `spec.md` (v2.0: 五层架构 + 三层 Agent + TTS-first)
- `tasks.md`

## Goal
创建 AIDramaProducer 项目骨架：目录结构、配置系统、风格预设、进度文件和日志模块。遵循五层架构设计。

## Steps
- [ ] 创建 `skills/ai-drama-producer/` 目录结构 (config/, styles/, utils/, modules/, orchestrator/)
- [ ] 创建 `skills/ai-drama-producer/SKILL.md` — Skill 入口，含五层架构说明 + 三层 Agent 角色定义
- [ ] 实现 `config/default.yaml` — 默认配置:
  - LLM 后端 (Claude/GPT/DeepSeek/GLM) + API keys 占位
  - Image Gen 后端 (NanoBanana/FLUX/即梦/豆包/ComfyUI)
  - Video Gen 后端 (Wan2.2 自部署 + Kling/Seedance API 降级)
  - TTS 后端 (MiniMax + Edge-TTS 降级)
  - 输出路径、默认风格、目标时长
- [ ] 实现 `styles/presets.yaml` — 10 种视觉风格预设，每种含:
  - character_keywords, scene_keywords, shot_keywords, dialogue_style
  - bone_style_params (风格化骨骼参数)
  - voice_style_params (风格化声线参数)
  - color_palette, line_style
- [ ] 实现 `utils/state.py` — 进度文件读写 (pipeline-state.json，支持断点续传)
- [ ] 实现 `utils/logger.py` — 日志模块 (每个 Phase 独立日志)
- [ ] 创建 `.agents/skills/ai-drama-producer/SKILL.md` (同步副本)

## Done Definition
- 目录结构完整
- `config/default.yaml` 含 4 类工具后端配置 + 降级方案
- `styles/presets.yaml` 含 10 种风格 + bone_style_params + voice_style_params
- `utils/state.py` 支持断点续传 (phase/status/timestamp 字段)
- `utils/logger.py` 输出带时间戳的阶段日志

## Required Verification
- Command: `python -c "import yaml; c=yaml.safe_load(open('skills/ai-drama-producer/config/default.yaml')); assert 'video_gen' in c; print('config OK')"`
- Expected: `config OK`
- Command: `python -c "import yaml; d=yaml.safe_load(open('skills/ai-drama-producer/styles/presets.yaml')); assert len(d['presets'])==10; assert 'bone_style_params' in d['presets']['日漫']; print('presets OK')"`
- Expected: `presets OK`

## Return Report
- Path: `reports/<agent-name>-WP01-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
