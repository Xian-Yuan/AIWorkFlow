# T13 — 小璃批量回溯分层（任务登记）

> **任务**：T13-retro
> **执行者**：金璃好帮手（M3 subagent，DS4 Flash 风格批量执行）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T13-execution-package.md`（110 行完整 spec）
- **工作目录**：`Project/Jinli/services/knowledge/taxonomy_and_migration/retro/`（T5 子目录）
- **状态文件**：`Project/Jinli/services/knowledge/taxonomy_and_migration/retro/.task-state`

## 前置依赖

- T5-obsidian-unified-taxonomy-impl ✅（taxonomy.json / tag_dictionary.yaml / route_index.json 可用）
- T4 spec ✅（L2 import_from_obsidian 接口可用）

## 关键交付

5 层批量回溯（视频/Docs/AI/Project/根目录/图谱重建）。每层独立可验收、可重跑。

## 实施阶段

按 task-package §D：每层独立 4 阶段。Layer 1（视频）先跑（风险最低）。