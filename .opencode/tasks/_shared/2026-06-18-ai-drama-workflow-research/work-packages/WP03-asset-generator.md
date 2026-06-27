# WP03: 角色/场景资产生成器 (Asset Generator)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/asset_generator/` (新建)
- `skills/ai-drama-producer/utils/image_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (角色一致性设计决策 + Rejected Shortcuts)
- `spec.md` (Module 3)
- `tasks.md` (WP03 section)
- `skills/ai-drama-producer/styles/presets.yaml` (风格预设)

## Goal
实现角色/场景资产生成器：从剧本 JSON 提取角色和场景，调用 Image Gen API 生成参考图，并缓存已生成资产。

## Steps
- [ ] 实现 `utils/image_client.py` — Image Gen API 调用抽象层 (支持 NanoBanana/Imagen/即梦/豆包/ComfyUI，统一接口)
- [ ] 实现 `modules/asset_generator/character_gen.py` — 角色立绘生成 (提示词模板 + 风格注入 + img2img 条件输入)
- [ ] 实现 `modules/asset_generator/scene_gen.py` — 场景氛围图生成
- [ ] 实现 `modules/asset_generator/cache.py` — 资产缓存 (已生成的角色/场景不重复生成，基于 hash)
- [ ] 确保角色参考图保存路径写入进度文件，供后续阶段读取

## Done Definition
- `image_client.py` 支持至少 2 种 Image Gen 后端
- 输入剧本 JSON → 为每个角色生成 `assets/characters/{char_id}.png`
- 输入剧本 JSON → 为每个场景生成 `assets/scenes/{scene_id}.png`
- 重复调用时缓存命中，不重复调用 API
- 角色参考图路径写入 pipeline-state.json

## Required Verification
- Command: `python -c "from pathlib import Path; import json; state=json.load(open('test_output/pipeline-state.json')); assert Path(state['assets']['characters']['char_01']).exists(); print('asset gen OK')"`
- Expected: `asset gen OK`

## Return Report
- Path: `reports/<agent-name>-WP03-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.
