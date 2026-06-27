# WP02: 知识库初始化

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/knowledge/` (新建)
- `skills/ai-drama-viral-analyzer/modules/knowledge_base.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (知识库积累 — 数据飞轮)
- `spec.md` (Module 7: KnowledgeBase + 4 个知识库文件格式)
- `tasks.md` (WP02 section)

## Goal
初始化 4 个知识库模板文件 + 实现知识库读写模块（增量追加 + 去重 + 检索）。

## Steps
- [ ] 创建 `knowledge/hook-patterns.md` — 钩子模式库模板:
  - 6 种基础钩子类型: question_shock, statistic_bomb, story_hook, controversy_hook, fear_hook, curiosity_gap
  - 每种含: 模板(填空式)、适用场景、案例、有效性评分、来源
- [ ] 创建 `knowledge/emotional-curves.md` — 情绪曲线模式库模板:
  - 4 种基础曲线: high_energy_curiosity_spike, tension_release_cycle, emotional_rollercoaster, slow_burn_build
  - 每种含: 情绪序列模式、适用场景、来源
- [ ] 创建 `knowledge/narrative-structures.md` — 叙事结构库模板:
  - 5 种基础结构: problem_solution, three_act, hero_journey, listicle, scqa
  - 每种含: 分段模板(起止比例+功能)、适用场景、来源
- [ ] 创建 `knowledge/creator-styles.md` — 博主风格库模板:
  - 字段: 签名钩子、偏好结构、情绪签名、视觉美学、音频风格、受众关系
- [ ] 实现 `modules/knowledge_base.py`:
  - `append_entry(kb_name, entry)` — 增量追加 (不覆盖已有条目)
  - `deduplicate(kb_name)` — 基于相似度去重
  - `search(kb_name, query)` — 关键词检索
  - `get_all(kb_name)` — 获取全部条目
  - `export_for_injection(kb_name)` — 导出为注入数据格式

## Done Definition
- 4 个知识库模板文件存在，每种类型有 ≥ 2 个预置条目
- `knowledge_base.py` 支持增量追加 + 去重 + 检索
- 单元测试通过

## Required Verification
- Command: `python -c "from pathlib import Path; for f in ['hook-patterns','emotional-curves','narrative-structures','creator-styles']: assert Path(f'skills/ai-drama-viral-analyzer/knowledge/{f}.md').exists(); print(f'{f} OK')"`
- Expected: 4 行 `xxx OK`
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/test_knowledge_base.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP02-result.md`
- Required status for merge: `done`
