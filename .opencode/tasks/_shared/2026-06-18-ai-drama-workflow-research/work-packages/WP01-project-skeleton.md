# WP01: 项目骨架与配置系统

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/` (新建)
- `.agents/skills/ai-drama-producer/` (新建，同步)
- `skills/ai-drama-producer/config/`
- `skills/ai-drama-producer/styles/`
- `skills/ai-drama-producer/utils/`

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `.trae/scripts/`
- `.opencode/agents/`

## Read First
- `routing.md`
- `analysis.md`
- `spec.md` (Module 1)
- `tasks.md` (WP01 section)

## Goal
创建 ai-drama-producer Skill 的项目骨架，包括目录结构、配置系统、风格预设定义、进度文件和日志模块。

## Steps
- [ ] 创建 `skills/ai-drama-producer/` 目录结构
- [ ] 创建 `skills/ai-drama-producer/SKILL.md` (Skill 入口文件)
- [ ] 实现 `config/default.yaml` — 默认配置 (工具后端、API keys 占位、输出路径)
- [ ] 实现 `styles/presets.yaml` — 10 种视觉风格预设 (日漫/韩漫/美漫/写实/国风/像素/水彩/赛博朋克/胶片/极简)，每种含 Image Gen 提示词模板和 Video Gen 提示词模板
- [ ] 实现 `utils/state.py` — 进度文件读写模块 (pipeline-state.json 的读/写/检查)
- [ ] 实现 `utils/logger.py` — 日志模块 (每个阶段独立日志文件)
- [ ] 创建 `.agents/skills/ai-drama-producer/SKILL.md` (同步副本)

## Done Definition
- 目录结构完整，所有文件存在
- `config/default.yaml` 可通过 YAML parser 解析
- `styles/presets.yaml` 包含 10 种风格，每种有 image_prompt_template 和 video_prompt_template
- `utils/state.py` 可正确读写 pipeline-state.json
- `utils/logger.py` 可输出带时间戳的阶段日志

## Required Verification
- Command: `python -c "import yaml; yaml.safe_load(open('skills/ai-drama-producer/config/default.yaml')); print('config OK')"`
- Expected: `config OK`
- Command: `python -c "import yaml; data=yaml.safe_load(open('skills/ai-drama-producer/styles/presets.yaml')); assert len(data['presets'])==10; print('presets OK')"`
- Expected: `presets OK`

## Return Report
- Path: `reports/<agent-name>-WP01-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting
- If blocked, write the same report path with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead agent.
- Do not edit outside Allowed Paths while blocked.

## Publisher Checklist
- [x] No `<placeholder>` text remains in this work package.
- [x] Allowed Paths and Forbidden Paths are concrete.
- [x] Required Verification has a real command and expected result.
- [x] Return Report path is concrete.
