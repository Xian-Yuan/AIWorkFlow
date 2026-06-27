# WP05: Step 2 — 场景拆分 (v2.0)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
- Parent task: `2026-06-18-scriptwriter-skill`

## Allowed Paths
- `skills/ai-drama-scriptwriter/modules/step2_scene_breakdown.py` (新建)
- `skills/ai-drama-scriptwriter/tests/test_step2.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `spec.md` (Step 2 v2.0: chapter_id + estimated_duration_sec + asset_reuse_id)
- `analysis.md`
- `tasks.md` (WP05 section)
- `skills/ai-drama-scriptwriter/prompts/scene_breakdown.md`

## Goal
实现 Step 2 v2.0：场景拆分，关联章节事件图谱，估算场景时长。

## Steps
- [ ] 实现 `modules/step2_scene_breakdown.py` — 场景拆分:
  - 调用 LLM 拆分场景 (location/time/weather/description/mood/characters_present/shot_count_estimate)
  - **v2.0 新增**: chapter_id 关联 (从章节事件图谱读取，长文本场景)
  - **v2.0 新增**: estimated_duration_sec 估算 (基于 shot_count_estimate × 平均镜头时长)
  - **v2.0 新增**: asset_reuse_id 全局场景资产引用
  - 场景地点具体性检查
  - 场景 mood 与 story tone 一致性检查
  - 场景数量: 1-8 个
  - 每个场景至少 1 个角色
- [ ] 编写单元测试 (3 个用例)

## Done Definition
- 输入故事文本 + 角色列表 → 输出 scenes JSON (v2.0 schema)
- chapter_id 正确关联 (长文本)
- estimated_duration_sec 合理
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-scriptwriter/tests/test_step2.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP05-result.md`
- Required status for merge: `done`
