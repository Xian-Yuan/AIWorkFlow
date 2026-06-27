# WP08: 管线编排器 (v2.0 — 断点续传 + Pipeline 变体)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/orchestrator.py` (新建)
- `skills/ai-drama-producer/SKILL.md` (更新)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (五层架构 + 三层 Agent)
- `spec.md` (Layer 2 编排层)
- `tasks.md`
- All WP02-WP07 work packages

## Goal
实现管线编排器：五层架构调度、断点续传 (差异化优势)、Pipeline 变体模式、三层 Agent 协调。

## Steps
- [ ] 实现 `orchestrator.py` — 主编排逻辑:
  - 读取 config/default.yaml
  - 按顺序调度 Phase 1→7
  - 每阶段完成后写入 pipeline-state.json (phase/status/timestamp/output_paths)
  - 启动时检查进度文件，跳过已完成阶段 (断点续传)
  - 阶段失败时记录错误日志，支持 --retry-failed
  - 支持 --resume 从断点继续
- [ ] 实现 Pipeline 变体模式 (参考 Pixelle-Video):
  - `StandardPipeline`: 小说→全自动生成 (Phase 1→7)
  - `AssetBasedPipeline`: 用户提供素材→AI 分析→跳过 Phase 3
  - `LinearPipeline`: 固定剧本→跳过 Phase 1+2
- [ ] 实现 CLI 入口 (argparse):
  - `--input`, `--style`, `--duration`, `--mode` (standard|asset|linear)
  - `--resume`, `--retry-failed`, `--output-dir`
  - `--skip-phase` (跳过指定阶段)
- [ ] 实现三层 Agent 协调:
  - 决策层: 风格验证 + 资源配置检查
  - 执行层: 按顺序调用各 Phase Skill
  - 监督层: 每阶段完成后运行对应 Validator
- [ ] 更新 SKILL.md 添加完整使用说明

## Done Definition
- `python orchestrator.py --input story.txt --style 日漫` 跑通全管线
- 中断后 `python orchestrator.py --resume` 从断点继续
- `python orchestrator.py --retry-failed` 仅重试失败阶段
- 三种 Pipeline 变体模式可用

## Required Verification
- Command: `python skills/ai-drama-producer/orchestrator.py --help`
- Expected: 显示所有 CLI 参数 + 三种 Pipeline 模式
- Command: 模拟中断测试: 运行到 Phase 5 后 kill，然后 --resume，验证 Phase 1-4 被跳过
- Expected: 日志显示 "Phase 1-4: skipped (completed)"

## Return Report
- Path: `reports/<agent-name>-WP08-result.md`
- Required status for merge: `done`
