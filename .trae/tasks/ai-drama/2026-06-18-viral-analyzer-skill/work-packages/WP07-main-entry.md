# WP07: Skill 主入口 + CLI + 交互模式

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/viral_analyzer.py` (新建)
- `skills/ai-drama-viral-analyzer/SKILL.md` (更新)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (4 种交互模式 + 输出文件结构)
- `tasks.md` (WP07 section)
- WP03/WP04/WP05/WP06 的模块接口

## Goal
实现 Skill 主入口：4 种交互模式路由 + CLI 接口 + 分析报告输出 + 知识库自动追加。

## Steps
- [ ] 实现 `viral_analyzer.py` — 主入口:
  - 模式路由: Quick Analyze / Batch Scan / Style Inject / Fusion
  - 自动检测输入类型 (URL→视频分析, 文本→小说分析, 博主主页→频道分析)
  - 调用 WP03/WP04/WP05/WP06 模块
  - 输出分析报告 (JSON + Markdown)
  - 自动追加到知识库
- [ ] 实现 CLI 接口 (argparse):
  - `--input`: 视频 URL / 小说文件 / 博主主页 URL
  - `--mode`: analyze | scan | inject | fusion
  - `--sources`: 多源分析 ID 列表 (fusion 模式)
  - `--topic`: 用户主题 (style_copy / fusion 模式)
  - `--output-dir`: 输出目录
  - `--zscore-threshold`: Z-score 阈值 (默认 2.0)
  - `--max-frames`: 最大抽帧数 (默认 180)
- [ ] 实现分析报告输出:
  - JSON: `output/viral_analysis/{id}/analysis_report.json`
  - Markdown: `output/viral_analysis/{id}/replication_playbook.md`
- [ ] 实现知识库自动追加 (每次分析后更新对应 .md 文件)
- [ ] 更新 SKILL.md 添加完整使用说明 + 示例

## Done Definition
- 4 种交互模式均可正常运行
- 自动检测输入类型正确
- 分析报告 JSON + Markdown 正确生成
- 知识库自动追加正确
- SKILL.md 含完整使用说明

## Required Verification
- Command: `python skills/ai-drama-viral-analyzer/viral_analyzer.py --help`
- Expected: 显示所有 CLI 参数 + 4 种模式说明
- Command: `python skills/ai-drama-viral-analyzer/viral_analyzer.py --input tests/fixtures/test_video_url.txt --mode analyze --output-dir test_output/`
- Expected: 输出分析报告, exit code 0

## Return Report
- Path: `reports/<agent-name>-WP07-result.md`
- Required status for merge: `done`
