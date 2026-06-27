# WP08: 管线编排器 (Pipeline Orchestrator)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/orchestrator.py` (新建)
- `skills/ai-drama-producer/SKILL.md` (更新)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (断点续传 + 逐镜头处理设计决策)
- `spec.md` (Module 1)
- `tasks.md` (WP08 section)
- All WP02-WP07 work packages (了解各模块接口)

## Goal
实现管线编排器：按顺序调度 7 个阶段，支持进度检查点、断点续传、错误处理和阶段重试。

## Steps
- [ ] 实现 `orchestrator.py` — 主编排逻辑
  - 读取配置 (config/default.yaml)
  - 按顺序调用各模块 (WP02→WP03→WP04→WP05→WP06→WP07)
  - 每阶段完成后写入 pipeline-state.json
  - 启动时检查进度文件，跳过已完成阶段
  - 阶段失败时记录错误日志，支持 --retry 参数
- [ ] 实现 CLI 入口 (argparse: --input, --style, --output, --retry, --resume)
- [ ] 更新 SKILL.md 添加使用说明

## Done Definition
- `python orchestrator.py --input story.txt --style 日漫` 跑通全管线
- 中断后 `python orchestrator.py --resume` 从断点继续
- 失败后 `python orchestrator.py --retry` 仅重试失败阶段

## Required Verification
- Command: `python skills/ai-drama-producer/orchestrator.py --help`
- Expected: 显示所有 CLI 参数
- Command: 模拟中断测试: 运行到 Phase 5 后 kill 进程，然后 `--resume`，验证 Phase 1-4 被跳过
- Expected: 日志显示 "Phase 1-4: skipped (already completed)"

## Return Report
- Path: `reports/<agent-name>-WP08-result.md`
- Required status for merge: `done`
