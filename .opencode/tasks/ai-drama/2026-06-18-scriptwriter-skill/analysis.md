# Analysis: AI 漫剧编剧 Skill (ai-drama-scriptwriter) v2.0

> 基于生态调研 v1.0 更新
> 调研文档: `Project/AIDramaProducer/docs/early-references/ai-drama-ecosystem-research.md`

## Architecture Context

### 编剧 Skill 在五层架构中的位置

```
Layer 2: 编排层 (Pipeline Orchestrator)
  └─ 决策层 Agent: 风格决策、资源配置、质量标准
      └─ Layer 3: 执行层
          ├── 编剧 Agent (本 Skill) ← 你在这里
          │   └─ 剧本生成、角色提取、场景拆分、分镜设计
          ├── 美术 Agent (Asset + Keyframe Generator)
          └── 配音 Agent (TTS Generator)
              └─ Layer 3: 监督层
                  └─ Validator 套件
```

### 编剧 Skill 与上下游的数据契约

**上游 (Phase 1: Text Preprocessor)**:
- 输入: 章节事件图谱 JSON (长文本场景)
- 用途: 指导 Step 2 场景拆分按章节组织

**下游 (Phase 3: Asset Generator)**:
- 输出: characters[].description + bone_binding_hints
- 用途: 生成角色立绘 + 骨骼绑定数据
- 输出: scenes[].description
- 用途: 生成场景氛围图

**下游 (Phase 4: Keyframe Generator)**:
- 输出: shots[].description + keyframe_prompt_enhancement
- 用途: 生成关键帧图片

**下游 (Phase 6: TTS Generator)**:
- 输出: shots[].dialogue + voice_profile + tts_pace_override + tts_pitch_override
- 用途: 生成配音音频 (TTS-first 策略)
- 输出: tts_duration_estimate_sec
- 用途: 初步时长规划

### v2.0 关键设计变更

| 变更 | v1.0 | v2.0 | 原因 |
|------|------|------|------|
| 角色定义 | description + voice_profile (简单) | + bone_binding_hints + voice_profile (细化到 timbre/pace/pitch) | Toonflow 骨骼绑定 + Pilipili TTS-first 需要精确参数 |
| 时长策略 | 编剧固定 duration_sec | duration_source 标记 (estimated/tts_measured) | TTS-first: 编剧预估 → TTS 实测 → 反馈修正 |
| 长文本 | 不支持 | 章节事件图谱驱动分章处理 | Toonflow 验证: 5万字输入不丢失上下文 |
| 对白 | text + emotion | + tts_pace_override + tts_pitch_override | 对白级 TTS 微调 |
| 关键帧 | description | + keyframe_prompt_enhancement | Pilipili 关键帧锁定策略需要增强提示词 |
| 约束规则 | 13 条 | 15 条 (新增对白时长匹配 + 跳轴检查) | 实际生成中发现的常见问题 |
| 资产复用 | 无 | asset_reuse_id (项目/全局) | Jellyfish 双层资产库 |

### 与 character-designer Skill 的关系 (v2.0 明确)

项目中已有 `character-designer` Skill (71 约束库、17 步设计流程)。编剧 Skill 的角色定义部分:
- **复用**: bone_binding_hints 的字段格式与 character-designer 的视觉约束库对齐
- **差异化**: 编剧关注"角色在故事中的功能"（主角/反派/配角/功能角色），character-designer 关注视觉设计细节
- **协作**: 编剧输出角色概要 + bone_binding_hints → character-designer 可进一步细化为完整视觉设计 + 多角度参考图

### 与 TTS Generator 的数据流 (TTS-first 策略核心)

```
编剧 Skill (Phase 2)
  └─ 输出: shots[].dialogue + voice_profile + duration_sec (estimated)
      └─ TTS Generator (Phase 6)
          └─ 生成所有配音音频
          └─ 测量毫秒级实际时长
          └─ 更新 shots[].duration_source = "tts_measured"
          └─ 更新 shots[].duration_sec = 实际时长
          └─ 反馈给 Video Generator (Phase 5)
              └─ 按实际时长生成视频片段
```

这个数据流是 Pilipili 验证过的"绝对音画同步"方案。编剧 Skill 的职责是提供准确的 `voice_profile` 和 `dialogue`，让 TTS Generator 能精确生成配音。

## Mature Solution Evidence (v2.0 扩展)

### 编剧实现模式对比

| 项目 | 编剧方式 | 关键设计 | 对 AIDramaProducer 的启示 |
|------|---------|---------|--------------------------|
| **Jellyfish** | LLM + 模板填充 | 先分析故事结构（起承转合），再按模板生成分镜 JSON | 分步生成优于一步到位 |
| **Toonflow** | 三层 Agent | 决策层(导演)→执行层(编剧+美术)→监督层(质检) | **三层 Agent 架构** — 编剧 Skill 定位在执行层 |
| **Toonflow** | 章节事件图谱 | 自动提取原著章节事件并结构化存储 | **长文本处理** — Phase 1 的前置步骤 |
| **Toonflow** | Skill 文件化配置 | 核心提示词外化为 Markdown Skill 文件 | **与项目现有 Skill 体系天然契合** |
| **Pixelle-Video** | Storyboard/Frame 数据模型 | 核心中间表示，持有对白、提示词、媒体文件路径 | 分镜 JSON 作为管线"单一真相源" |
| **Pilipili** | TTS-first | 先 TTS 测毫秒级时长，再控制视频 duration | **音画同步** — 编剧输出 voice_profile 供 TTS 精确映射 |
| **Pilipili** | 关键帧锁定 | Nano Banana 生成 4K 关键帧→图生视频 | 编剧输出 keyframe_prompt_enhancement |

### 关键设计决策 (从成熟项目中提取)

1. **分步优于一步**: 所有成熟项目都采用分步生成（角色→场景→镜头），而非一次性输出完整剧本。
2. **角色先于镜头**: 所有项目都在生成镜头前先确定角色列表。
3. **结构化输出是刚需**: JSON Schema 约束 LLM 输出。
4. **视觉可行性过滤器**: BigBanana 和 Jellyfish 都有专门的可行性检查步骤。
5. **TTS-first 音画同步**: Pilipili 验证的策略，编剧输出 voice_profile 供 TTS 精确映射。
6. **章节事件图谱**: Toonflow 验证的长文本处理方案。
7. **骨骼绑定数据**: Toonflow 验证的角色一致性方案，编剧输出 bone_binding_hints。

### Rejected Shortcuts (v2.0 扩展)

| 捷径 | 风险 | 替代方案 | 验证来源 |
|------|------|---------|---------|
| 一次性输出完整剧本 JSON | 角色不一致、场景跳跃 | 分 3 步生成 | Jellyfish/Toonflow |
| 让 LLM 自由发挥镜头语言 | 镜头类型单一 | 提供镜头模板库 + 15 条约束规则 | 本调研 |
| 不检查视觉可行性 | 生成视频时才发现不可行 | 内置可行性规则引擎 | BigBanana/Jellyfish |
| 角色外观每次重新描述 | 外貌不一致 | 角色 ID + 外观只定义一次 | 所有项目共识 |
| 忽略时长约束 | 视频生成成本失控 | 硬约束: 总时长 ≤ target × 1.2 | 成本控制 |
| 不输出 voice_profile 细节 | TTS 音色不匹配角色 | 细化到 timbre/pace/pitch | Pilipili TTS-first |
| 不输出 bone_binding_hints | 视频中面部变形 | 骨骼绑定数据 | Toonflow |
| 长文本一次性处理 | 上下文丢失 | 章节事件图谱→逐章处理 | Toonflow |

## Quality Gate

编剧 Skill 的输出必须通过以下质量门禁：

1. **Schema 校验**: 输出 JSON 通过 script_schema.json 校验
2. **引用完整性**: 所有 character_id 在 characters 数组中存在；所有 scene_id 在 scenes 数组中存在
3. **时长约束**: 总时长 ≤ 目标时长 × 1.2
4. **视觉可行性**: 无标记为 "risky" 的镜头描述
5. **风格一致性**: 所有画面描述使用声明风格的视觉语言
6. **角色一致性**: 每个角色外观描述只出现一次
7. **字段完整性**: bone_binding_hints 和 voice_profile 所有字段非空
8. **对白时长匹配**: 对白文本长度与 duration_sec 匹配 (中文约 3-4 字/秒)
