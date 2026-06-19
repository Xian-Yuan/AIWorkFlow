# WP07: 编剧 Skill 主入口 + 交互模式 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/scriptwriter.py` (新建)
- `skills/ai-drama-scriptwriter/SKILL.md` (更新)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (交互模式 + 输出文件结构 v2.0)
- `tasks.md` (WP07 section)
- WP04/WP05/WP06 的模块接口

## Goal
实现编剧 Skill 主入口 v2.0：Quick Mode + Review Mode + TTS 规划文件输出。

## Steps
- [ ] 实现 `scriptwriter.py` — 主编剧入口:
  - Quick Mode: Step 1→2→3 自动连续执行
  - Review Mode: 单独执行指定 Step
  - 读取 config/default.yaml 和 styles/presets.yaml
  - 调用 WP04/WP05/WP06 模块
  - 调用 WP03 的 8 个验证器
  - 输出文件到 `output/{project_name}/`
- [ ] 实现 CLI 接口 (argparse)
- [ ] 实现增量修改
- [ ] 实现剧本摘要输出 (script_summary.md)
- [ ] 实现可行性报告输出 (feasibility_report.md)
- [ ] **v2.0 新增**: 实现 TTS 规划文件输出 (tts_plan.json):
  - 所有对白列表 (按 shot 组织)
  - 每条对白的 voice_profile 参数
  - 每条对白的 tts_pace_override + tts_pitch_override
  - 预估时长
  - 供 Phase 6 (TTS Generator) 直接读取
- [ ] 更新 SKILL.md 添加 v2.0 使用说明

## Done Definition
- Quick Mode 和 Review Mode 均可正常运行
- tts_plan.json 正确生成，含所有对白 + voice_profile 参数
- 增量修改功能可用
- script_summary.md 和 feasibility_report.md 正确生成

## Required Verification
- Command: `python skills/ai-drama-scriptwriter/scriptwriter.py --help`
- Expected: 显示所有 CLI 参数
- Command: `python skills/ai-drama-scriptwriter/scriptwriter.py --input tests/fixtures/short_story_01.txt --style 日漫 --mode quick --output-dir test_output/`
- Expected: 输出完整剧本 JSON + summary + feasibility + tts_plan.json，exit code 0

## Return Report
- Path: `reports/<agent-name>-WP07-result.md`
- Required status for merge: `done`
