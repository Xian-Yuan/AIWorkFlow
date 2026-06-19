# WP03: 角色/场景资产生成器 (v2.0 — 双层资产库 + 骨骼绑定)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/`
- Parent task: `2026-06-18-pipeline-architecture`

## Allowed Paths
- `skills/ai-drama-producer/modules/asset_generator/` (新建)
- `skills/ai-drama-producer/utils/image_client.py` (新建)
- `skills/ai-drama-producer/assets/` (资产存储)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (Layer 4 一致性层 + Jellyfish 双层资产库 + Toonflow 骨骼绑定)
- `spec.md` (Phase 3)
- `tasks.md`
- `skills/ai-drama-producer/styles/presets.yaml`

## Goal
实现资产生成器：双层资产库 (项目级 + 全局级)、角色立绘 + 骨骼绑定数据、场景氛围图、资产缓存与跨项目复用。

## Steps
- [ ] 实现 `utils/image_client.py` — Image Gen API 调用抽象层 (NanoBanana/FLUX/即梦/豆包/ComfyUI，统一接口)
- [ ] 实现 `modules/asset_generator/asset_library.py` — 双层资产库:
  - 项目级: `output/{project}/assets/`
  - 全局级: `skills/ai-drama-producer/assets/global/`
  - 资产索引: `asset_index.json` (按角色名/风格/特征 hash 索引)
  - 复用逻辑: 先查全局库 → 再查项目库 → 才调用 API 生成
- [ ] 实现 `modules/asset_generator/character_gen.py` — 角色立绘生成:
  - 提示词 = 角色 description + 风格 character_keywords + "character reference sheet, full body, consistent style"
  - 使用 Global Seed 保证风格一致
  - 输出: `assets/characters/{char_id}.png`
- [ ] 实现 `modules/asset_generator/bone_binding.py` — 骨骼绑定数据生成:
  - 输入: bone_binding_hints (face_shape/eye_style/nose_profile/body_type/height_relative/distinctive_features)
  - 输出: `assets/characters/{char_id}_bone.json` (骨骼约束数据)
  - 用途: 供 Phase 5 (Video Generator) 防止面部变形
  - 参考: Toonflow 骨骼绑定方案
- [ ] 实现 `modules/asset_generator/scene_gen.py` — 场景氛围图生成
- [ ] 实现 `modules/asset_generator/cache.py` — 资产缓存 (基于 hash 去重)
- [ ] 资产路径 + asset_reuse_id 写入 pipeline-state.json

## Done Definition
- 双层资产库可用，跨项目角色复用
- 角色立绘 + 骨骼绑定数据正确生成
- 场景氛围图正确生成
- 缓存命中时跳过 API 调用
- 资产路径写入进度文件

## Required Verification
- Command: `python -c "from pathlib import Path; import json; state=json.load(open('test_output/pipeline-state.json')); assert Path(state['assets']['characters']['char_01']['image']).exists(); assert Path(state['assets']['characters']['char_01']['bone_data']).exists(); print('asset gen v2.0 OK')"`
- Expected: `asset gen v2.0 OK`

## Return Report
- Path: `reports/<agent-name>-WP03-result.md`
- Required status for merge: `done`
