# Tasks: AI 漫剧编剧 Skill (ai-drama-scriptwriter) v2.0

## Dependency Graph

```
WP01 (Skill 骨架 + 配置)
  ├── WP02 (风格预设 + 提示词模板) ← v2.0: 新增 bone_binding/voice_profile 模板
  ├── WP03 (剧本 JSON Schema + 验证器) ← v2.0: 新增字段 schema + 3 个新验证器
  ├── WP04 (Step 1: 故事分析 + 角色提取) ← v2.0: 新增 bone_binding_hints + voice_profile 细化
  ├── WP05 (Step 2: 场景拆分) ← v2.0: 新增 chapter_id + estimated_duration
  ├── WP06 (Step 3: 分镜设计 + 15 条约束规则) ← v2.0: 新增 2 条规则 + duration_source
  ├── WP07 (编剧 Skill 主入口 + 交互模式)
  └── WP08 (集成测试 + 验证) ← v2.0: 新增 AC11-AC13
```

---

## WP01: Skill 骨架与配置系统

- [ ] T1.1: 创建 `skills/ai-drama-scriptwriter/` 目录结构
- [ ] T1.2: 创建 `skills/ai-drama-scriptwriter/SKILL.md` (含三层 Agent 架构中的定位说明)
- [ ] T1.3: 创建 `.agents/skills/ai-drama-scriptwriter/SKILL.md` (同步副本)
- [ ] T1.4: 实现 `config/default.yaml` — LLM 后端配置、默认参数
- [ ] T1.5: 实现 `utils/llm_client.py` — LLM 调用抽象层 (支持 Claude/GPT/DeepSeek/GLM)
- [ ] T1.6: 实现 `utils/logger.py` — 日志模块

## WP02: 风格预设与提示词模板 (v2.0 更新)

- [ ] T2.1: 创建 `styles/presets.yaml` — 10 种视觉风格预设，每种含:
  - character_keywords, scene_keywords, shot_keywords, dialogue_style
  - **新增**: bone_style_params (eye_style/body_type 等风格化骨骼参数)
  - **新增**: voice_style_params (timbre/pace/pitch 等风格化声线参数)
- [ ] T2.2: 创建 `prompts/system_prompt.md` — 编剧 Skill 系统提示词 (含三层 Agent 角色定义)
- [ ] T2.3: 创建 `prompts/character_extraction.md` — Step 1 提示词模板 (**新增**: bone_binding_hints + voice_profile 细化字段)
- [ ] T2.4: 创建 `prompts/scene_breakdown.md` — Step 2 提示词模板 (**新增**: chapter_id + estimated_duration)
- [ ] T2.5: 创建 `prompts/shot_design.md` — Step 3 提示词模板 (**新增**: 15 条约束规则 + duration_source + keyframe_prompt_enhancement)

## WP03: 剧本 JSON Schema + 验证器套件 (v2.0 更新)

- [ ] T3.1: 创建 `schemas/script_schema.json` — 完整剧本 JSON Schema (**v2.0 新增字段**)
- [ ] T3.2: 实现 `validators/schema_validator.py` — JSON Schema 校验
- [ ] T3.3: 实现 `validators/reference_checker.py` — 引用完整性检查
- [ ] T3.4: 实现 `validators/duration_checker.py` — 时长约束检查
- [ ] T3.5: 实现 `validators/feasibility_checker.py` — 视觉可行性检查
- [ ] T3.6: 实现 `validators/style_checker.py` — 风格关键词注入检查
- [ ] T3.7: 实现 `validators/duplicate_checker.py` — 角色外观重复描述检查
- [ ] **新增** T3.8: 实现 `validators/field_completeness_checker.py` — bone_binding_hints + voice_profile 字段完整性检查
- [ ] **新增** T3.9: 实现 `validators/dialogue_duration_matcher.py` — 对白时长匹配检查 (中文 3-4 字/秒)
- [ ] **新增** T3.10: 实现 `validators/jump_axis_checker.py` — 跳轴检查 (连续镜头角色位置/朝向连贯性)

## WP04: Step 1 — 故事分析与角色提取 (v2.0 更新)

- [ ] T4.1: 实现 `modules/step1_story_analysis.py` — 故事分析 (**新增**: total_word_count + chapter_count)
- [ ] T4.2: 实现 `modules/step1_character_extraction.py` — 角色提取
  - **新增**: bone_binding_hints 生成 (face_shape/eye_style/nose_profile/body_type/height_relative/distinctive_features)
  - **新增**: voice_profile 细化生成 (gender/age_range/timbre/pace/pitch/quirks)
  - **新增**: asset_reuse_id 全局资产引用
- [ ] T4.3: 实现角色数量验证 (2-6 个)
- [ ] T4.4: 实现角色 description 视觉关键词数量检查 (≥ 3 个)
- [ ] T4.5: 实现 bone_binding_hints 和 voice_profile 字段完整性检查
- [ ] T4.6: 编写单元测试

## WP05: Step 2 — 场景拆分 (v2.0 更新)

- [ ] T5.1: 实现 `modules/step2_scene_breakdown.py` — 场景拆分
  - **新增**: chapter_id 关联 (从章节事件图谱读取)
  - **新增**: estimated_duration_sec 估算
  - **新增**: asset_reuse_id 全局场景资产引用
- [ ] T5.2: 实现场景地点具体性检查
- [ ] T5.3: 实现场景 mood 与 story tone 一致性检查
- [ ] T5.4: 编写单元测试

## WP06: Step 3 — 分镜设计 + 15 条约束规则 (v2.0 更新)

- [ ] T6.1: 实现 `modules/step3_shot_design.py` — 分镜设计主逻辑
  - **新增**: duration_source 标记 (estimated)
  - **新增**: dialogue[].tts_pace_override + tts_pitch_override
  - **新增**: keyframe_prompt_enhancement 生成
  - **新增**: tts_duration_estimate_sec + visual_duration_estimate_sec 分离估算
- [ ] T6.2: 实现 `rules/constraint_engine.py` — 硬约束规则引擎 (**15 条规则**)
  - **新增规则 14**: 对白文本长度与 duration_sec 匹配 (中文 3-4 字/秒)
  - **新增规则 15**: 角色在连续镜头中的位置/朝向保持连贯 (跳轴检查)
- [ ] T6.3: 实现镜头类型变化检测
- [ ] T6.4: 实现首镜头 wide/panorama 检查
- [ ] T6.5: 实现角色首次出场 medium/close-up 检查
- [ ] T6.6: 实现 visual_feasibility 自动标记
- [ ] T6.7: 编写单元测试

## WP07: 编剧 Skill 主入口 + 交互模式

- [ ] T7.1: 实现 `scriptwriter.py` — 主编剧入口 (Quick Mode + Review Mode)
- [ ] T7.2: 实现 CLI 接口 (argparse)
- [ ] T7.3: 实现增量修改
- [ ] T7.4: 实现剧本摘要输出 (script_summary.md)
- [ ] T7.5: 实现可行性报告输出 (feasibility_report.md)
- [ ] **新增** T7.6: 实现 TTS 规划文件输出 (tts_plan.json)
- [ ] T7.7: 更新 SKILL.md 添加完整使用说明

## WP08: 集成测试与验证 (v2.0 更新)

- [ ] T8.1: 准备 3 个测试用例 (短篇: 1000字/2000字/5000字，不同风格)
- [ ] T8.2: 运行 Quick Mode 端到端测试
- [ ] T8.3: 运行 Review Mode 分步测试
- [ ] T8.4: 验证 AC01-AC13 全部通过
  - **新增 AC11**: bone_binding_hints + voice_profile 字段完整性
  - **新增 AC12**: 对白时长匹配
  - **新增 AC13**: 长文本章节事件图谱
- [ ] T8.5: 验证 mature path 被实现，无 rejected shortcut 被引入
- [ ] T8.6: 收集所有验证证据，写入 verification-report.md
- [ ] T8.7: Map implementation result to Acceptance Criteria

## Final Verification

- [ ] T8.5: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T8.6: Run automated verification and record command output in verification-report.md.
- [ ] T8.7: Map implementation result to Acceptance Criteria in verification-report.md.
