# AI 漫剧编剧 Skill (ai-drama-scriptwriter) v2.0

> 三层 Agent 架构中的**执行层·编剧 Agent**
> 定位: 从故事创意到结构化分镜剧本的自动化编剧引擎
> 数据契约: 上游 Phase 1 (Text Preprocessor) → 下游 Phase 3 (Asset Generator) / Phase 4 (Keyframe Generator) / Phase 6 (TTS Generator)

## Skill Identity

- **名称**: ai-drama-scriptwriter
- **版本**: v2.0
- **角色**: 执行层·编剧 Agent（三层 Agent 架构中的执行层）
- **触发条件**: 用户提供故事文本 + 风格选择 + (可选) 目标时长
- **父模块**: AIDramaProducer Pipeline Phase 2

## 三层 Agent 架构中的定位

```
决策层 (Pipeline Orchestrator)
  └─ 风格决策、资源配置、质量标准
      └─ 执行层
          ├── 编剧 Agent (本 Skill) ← 你在这里
          │   └─ 剧本生成、角色提取、场景拆分、分镜设计
          ├── 美术 Agent (Asset Generator + Keyframe Generator)
          └── 配音 Agent (TTS Generator)
              └─ 监督层 (Validator 套件)
                  └─ Schema校验、引用完整性、可行性检查
```

## 与上下游的数据契约

| 方向 | 模块 | 提供的数据 |
|------|------|-----------|
| 上游 | Phase 1: Text Preprocessor | 章节事件图谱 JSON (长文本场景) |
| 下游 | Phase 3: Asset Generator | characters[].description + bone_binding_hints |
| 下游 | Phase 4: Keyframe Generator | shots[].description + keyframe_prompt_enhancement |
| 下游 | Phase 6: TTS Generator | shots[].dialogue + voice_profile + tts_pace/pitch_override |

## 与 character-designer Skill 的关系

- **复用**: bone_binding_hints 字段格式与 character-designer 的视觉约束库对齐
- **差异化**: 编剧关注角色在故事中的功能（主角/反派/配角），character-designer 关注视觉设计细节
- **协作**: 编剧输出角色概要 + bone_binding_hints → character-designer 可进一步细化为完整视觉设计

## 使用方式

### Quick Mode (一键生成)
```bash
python -m ai_drama_scriptwriter quick \
  --input story.txt \
  --style 日漫 \
  --duration 180
```

### Review Mode (分步审查)
```bash
# Step 1: 角色提取
python -m ai_drama_scriptwriter step1 --input story.txt --style 日漫

# Step 2: 场景拆分
python -m ai_drama_scriptwriter step2 --input story.txt --style 日漫 \
  --characters step1_characters.json

# Step 3: 分镜设计
python -m ai_drama_scriptwriter step3 --input story.txt --style 日漫 \
  --characters step1_characters.json \
  --scenes step2_scenes.json
```

## 3 步生成流程

### Step 1: 故事分析 + 角色提取
- LLM 分析故事结构（类型/基调/叙事结构/核心冲突/目标受众）
- 提取 2-6 个角色（含 bone_binding_hints + 细化 voice_profile + asset_reuse_id）
- 输出: `step1_characters.json`

### Step 2: 场景拆分
- 将故事拆分为 1-8 个场景
- 每个场景关联章节 (chapter_id) + 预估时长 (estimated_duration_sec)
- 输出: `step2_scenes.json`

### Step 3: 分镜设计
- 将每个场景拆分为 2-8 秒的分镜
- 注入 15 条 MUST/SHOULD 约束规则
- 生成 keyframe_prompt_enhancement 供 Phase 4 使用
- 标记 duration_source = "estimated" 供 TTS-first 数据流
- 输出: 完整剧本 JSON (v2.0 schema)

## 15 条硬约束规则

| # | 规则 | 级别 |
|---|------|------|
| 1 | 镜头时长 2-8 秒 | MUST |
| 2 | 总时长 ≤ 目标时长 × 1.2 | MUST |
| 3 | 对话镜头 3-5 秒 | SHOULD |
| 4 | 动作镜头 4-6 秒 | SHOULD |
| 5 | 空镜/转场 2-3 秒 | SHOULD |
| 6 | 每镜头对白 ≤ 2 句 | SHOULD |
| 7 | 连续 3 个以上同类型镜头 → 插入变化 | SHOULD |
| 8 | 每个场景第一个镜头必须是 wide/panorama | SHOULD |
| 9 | 角色首次出场用 medium/close-up | SHOULD |
| 10 | 避免大规模群体场景 (>5人) | MUST |
| 11 | 避免角色外观剧烈变化 (年龄/体型) | MUST |
| 12 | 避免复杂光学 (镜中倒影/水下/强逆光) | SHOULD |
| 13 | 动作描述用具体动词 | MUST |
| 14 | 对白文本长度与 duration_sec 匹配 (中文 3-4 字/秒) | SHOULD |
| 15 | 连续镜头角色位置/朝向保持连贯 (跳轴检查) | SHOULD |

## 输出文件

```
output/{project_name}/
  script.json          # v2.0 完整剧本 JSON
  step1_characters.json
  step2_scenes.json
  step3_shots.json
  script_summary.md
  feasibility_report.md
  tts_plan.json
```

## 风格预设 (10 种)

日漫 / 韩漫 / 美漫 / 写实 / 国风 / 像素 / 水彩 / 赛博朋克 / 胶片 / 极简

## 配置

编辑 `config/default.yaml` 选择 LLM 后端和默认参数。

## 开发

```bash
# 安装依赖
pip install -r requirements.txt

# 运行测试
python -m pytest tests/ -v

# 运行所有验证器
python -m validators.run_all --script output/test/script.json
```
