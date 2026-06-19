# WP01: Skill 骨架与配置系统 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/` (新建)
- `.agents/skills/ai-drama-scriptwriter/` (新建，同步)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-producer/`

## Read First
- `routing.md` (v2.0: 三层 Agent 定位 + 上下游数据契约)
- `analysis.md` (v2.0: 7 项目编剧实现对比 + TTS-first 数据流)
- `spec.md` (v2.0: 15 条约束规则 + bone_binding_hints + voice_profile 细化)
- `tasks.md` (v2.0)

## Goal
创建 ai-drama-scriptwriter Skill 骨架：目录结构、SKILL.md（含三层 Agent 定位）、LLM 客户端、日志模块。

## Steps
- [ ] 创建 `skills/ai-drama-scriptwriter/` 目录结构 (config/, prompts/, schemas/, modules/, validators/, rules/, utils/, styles/, tests/)
- [ ] 创建 `skills/ai-drama-scriptwriter/SKILL.md` — Skill 入口:
  - 角色定义: 三层 Agent 架构中的执行层·编剧 Agent
  - 触发条件: 用户提供故事文本 + 风格选择
  - 3 步流程概述
  - 与上下游的数据契约 (Phase 1 Text Preprocessor → Phase 3 Asset Generator / Phase 6 TTS Generator)
  - 与 character-designer Skill 的关系
- [ ] 创建 `.agents/skills/ai-drama-scriptwriter/SKILL.md` (同步副本)
- [ ] 实现 `config/default.yaml` — LLM 后端配置 + 默认参数
- [ ] 实现 `utils/llm_client.py` — LLM 调用抽象层 (Claude/GPT/DeepSeek/GLM)
- [ ] 实现 `utils/logger.py` — 日志模块

## Done Definition
- 目录结构完整
- SKILL.md 含三层 Agent 定位 + 上下游数据契约
- `config/default.yaml` 可通过 YAML parser 解析
- `llm_client.py` 支持 Claude + 至少 1 种其他后端

## Required Verification
- Command: `python -c "import yaml; yaml.safe_load(open('skills/ai-drama-scriptwriter/config/default.yaml')); print('config OK')"`
- Expected: `config OK`
- Command: `python -c "from pathlib import Path; sk=Path('skills/ai-drama-scriptwriter/SKILL.md').read_text(); assert '三层 Agent' in sk or '执行层' in sk; print('SKILL.md v2.0 OK')"`
- Expected: `SKILL.md v2.0 OK`

## Return Report
- Path: `reports/<agent-name>-WP01-result.md`
- Required status for merge: `done`
- Must declare `Extra scope taken: no`.
