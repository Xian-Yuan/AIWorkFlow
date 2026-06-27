# WP06: 创作引擎 (Creator)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/modules/creator/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (结构镜像 + 与 scriptwriter-skill 衔接设计)
- `spec.md` (Module 4-6: StyleCopy + FusionCreate + ScriptInject + 4 个注入文件格式)
- `tasks.md` (WP06 section)
- `../2026-06-18-scriptwriter-skill/spec.md` (编剧 Skill v2.1 注入接口)

## Goal
实现创作引擎：StyleCopy (风格复制) + FusionCreate (融合创作) + ScriptInject (数据注入编剧)。

## Steps
- [ ] 实现 `modules/creator/schemas.py` — 4 个注入文件的 JSON Schema:
  - style_injection.json schema
  - character_archetypes.json schema
  - shot_pacing_reference.json schema
  - voice_style_reference.json schema
- [ ] 实现 `modules/creator/style_copy.py` — StyleCopy:
  - 从分析报告提取风格参数 (hook/结构/情绪/节奏/镜头/文案)
  - 用户主题注入 (套入风格参数框架)
  - 结构镜像生成 (保留结构, 替换内容)
  - 风格一致性校验 (生成内容与参考风格的相似度评分 > 0.7)
- [ ] 实现 `modules/creator/fusion_create.py` — FusionCreate:
  - 多报告优势维度提取 (每个报告在 8 维度上的 top 特征)
  - 冲突检测 (不同来源的风格参数是否冲突)
  - 融合策略 (取最高分/加权平均/用户指定)
  - 融合一致性校验 (> 0.7)
- [ ] 实现 `modules/creator/script_inject.py` — ScriptInject:
  - 分析报告 → 4 个注入文件
  - 格式校验 (符合编剧 Skill 接口规范)
  - 输出到指定目录
- [ ] 编写单元测试

## Done Definition
- StyleCopy: 输入分析报告 + 新主题 → 风格相似度 > 0.7
- FusionCreate: 输入 2+ 报告 → 融合一致性 > 0.7
- ScriptInject: 输出 4 个文件, 通过 Schema 校验
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/test_creator.py -v`
- Expected: all tests pass
- Command: `python -c "import json; from jsonschema import validate; for f in ['style_injection','character_archetypes','shot_pacing_reference','voice_style_reference']: schema=json.load(open(f'skills/ai-drama-viral-analyzer/modules/creator/schemas/{f}.schema.json')); print(f'{f} schema OK')"`
- Expected: 4 行 `xxx schema OK`

## Return Report
- Path: `reports/<agent-name>-WP06-result.md`
- Required status for merge: `done`
