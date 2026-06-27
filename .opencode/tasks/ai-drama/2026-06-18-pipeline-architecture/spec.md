# Spec: AIDramaProducer 管线总架构 (v2.1)

> v2.1 更新: 整合 ViralAnalysis 爆款分析层作为可选 Phase 0
> 调研文档: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`

## GIVEN
- 用户有一篇小说原文或创意大纲 (文本格式，支持 500-50000 字)
- 用户选择了一种视觉风格 (预设: 日漫/韩漫/美漫/写实/国风/像素/水彩/赛博朋克/胶片/极简)
- (可选) 用户提供了爆款参考视频/小说 URL，用于风格分析和数据注入
- 系统可访问至少一个 LLM API、一个 Image Gen API、一个 Video Gen API、一个 TTS API
- 系统有 FFmpeg 可用
- 系统支持 Docker Compose 一键部署

## WHEN
用户触发管线执行:
1. 提供输入文本 + 风格选择 + 工具后端配置
2. (可选) 提供爆款参考 URL → Phase 0 分析 → 注入风格数据
3. 管线自动执行，产出最终视频 + 字幕 + (可选) 剪映草稿

## THEN

### 六层架构总览 (v2.1)

```
┌─────────────────────────────────────────────────┐
│  Layer 0: 创意研究层 (新增，可选)                 │
│  ViralAnalysis Skill                            │
│  - 爆款视频/小说分析 → style_injection.json       │
│  - 角色原型分析 → character_archetypes.json       │
│  - 分镜节奏参考 → shot_pacing_reference.json      │
│  参考: viral-video-analyzer + ViralMint          │
├─────────────────────────────────────────────────┤
│  Layer 1-5: 同 v2.0                             │
│  输入层 → 编排层 → 执行层 → 一致性层 → 输出层     │
└─────────────────────────────────────────────────┘
```

### Phase 0: 创意研究 (新增，可选)

**独立 Skill**: `ai-drama-viral-analyzer` (task packet 待创建)
**参考项目**: viral-video-analyzer (39★), ViralMint (18★), hook-lab (9★), videoanalyzer (5★), viral-ops (5★)

**输入**: 爆款参考 URL (视频/小说/博主主页)
**处理流程** (渐进披露模式):
1. 批量扫描 → Z-score 筛选异常值
2. 异常值深度分析 (8 维度)
3. 模式聚类提取共性
4. 输出结构化注入数据

**输出**:
- `style_injection.json` — 风格参数注入 (覆盖/增强 styles/presets.yaml)
- `character_archetypes.json` — 角色原型参考 (Big Five 人格模型)
- `shot_pacing_reference.json` — 分镜节奏参考 (镜头类型分布、时长分布)
- `voice_style_reference.json` — 配音风格参考 (voice_profile 建议)

**8 个分析维度** (按优先级):
1. 钩子分析 (前 3 秒策略) — 100% 项目覆盖
2. 叙事结构 (三幕剧/SCQA 等) — 92%
3. 情绪曲线 (观众情绪随时间变化) — 83%
4. 剪辑节奏 (切镜频率、高潮分布) — 75%
5. 镜头语言 (景别/运镜/构图) — 67%
6. CTA 分析 (引导行为设计) — 58%
7. 文案/金句 (口播文案提取) — 58%
8. 评论区洞察 (受众偏好) — 42%

**关键设计原则**:
- **异常值驱动**: 不分析所有参考内容，只分析 Z-score > 2x 的超常表现
- **结构镜像**: 提取结构模式（叙事逻辑、情绪曲线、镜头节奏），而非具体内容
- **渐进披露**: 批量扫描→筛选→深度分析，控制 Token 成本

### Phase 1-7: 同 v2.0

(Phase 1: 长文本预处理 → Phase 2: 剧本生成 → Phase 3: 资产生成 → Phase 4: 关键帧 → Phase 5: 视频生成 → Phase 6: TTS 配音 → Phase 7: 合成导出)

### 数据注入接口 (v2.1 新增)

编剧 Skill (Phase 2) 新增可选输入参数:

```
scriptwriter.py --input story.txt --style 日漫 \
    --style-injection style_injection.json \
    --character-archetypes character_archetypes.json \
    --shot-pacing shot_pacing_reference.json \
    --voice-style voice_style_reference.json
```

注入数据优先级: `style_injection.json` > `styles/presets.yaml` 默认值。注入数据为可选，不影响编剧 Skill 独立运行。

## 子模块索引 (v2.1)

| 阶段 | Task Packet | 形态 | 优先级 | 参考项目 |
|------|-----------|------|:---:|---------|
| **Phase 0: 创意研究** | `ai-drama/2026-06-18-viral-analyzer-skill` | Skill | P1 | viral-video-analyzer + ViralMint |
| Phase 1: 长文本预处理 | `ai-drama/2026-06-18-text-preprocessor-skill` | Skill | P1 | Toonflow |
| Phase 2: 剧本生成 | `ai-drama/2026-06-18-scriptwriter-skill` | Skill | **P0** | Jellyfish + Toonflow |
| Phase 3: 资产生成 | `ai-drama/2026-06-18-asset-generator-skill` | Skill | P0 | Jellyfish |
| Phase 4: 关键帧 | `ai-drama/2026-06-18-keyframe-generator-skill` | Skill | P0 | Pilipili |
| Phase 5: 视频生成 | `ai-drama/2026-06-18-video-generator-skill` | Skill | P0 | Wan2.2 + Kling |
| Phase 6: TTS 配音 | `ai-drama/2026-06-18-tts-generator-skill` | Skill | P0 | Pilipili TTS-first |
| Phase 7: 合成导出 | `ai-drama/2026-06-18-compositor-skill` | Skill | P0 | Pilipili |
| 管线编排 | `ai-drama/2026-06-18-orchestrator-skill` | Skill | P1 | Pixelle + ViralMint |

## Acceptance Criteria (v2.1 新增 AC12)

| AC# | Description |
|-----|-------------|
| AC01-AC11 | 同 v2.0 |
| **AC12** | **新增**: 提供爆款参考 URL → Phase 0 分析 → 风格数据注入编剧 Skill → 剧本风格与参考一致 |

## Non-Goals

- 同 v2.0
- 不实现自动发布功能 (那是 ViralMint 的全链路闭环，非本阶段)
- 不实现实时趋势监控
- 不实现 TRIBE v2 脑反应预测 (非商业许可)

## Implementation Status (2026-06-18)

| Phase | Status | Detail |
|-------|--------|--------|
| Plan | ✅ Completed v2.1 | 六层架构 + 8 Phase + 12 AC |
| Implement | 🚧 In Progress | 包结构与单元测试已落地；真实小说→成片链路仍未完成 |
| Verify | ❌ Failed | 真实运行生成 0 镜头且无 final.mp4 |

## Current Progress Audit (2026-06-19)

- **Current Phase**: Implement
- **Verified AC**: 3/12（断点状态基础、单镜头重试基础、SRT 多对白时长匹配）。
- **Automated tests**: 93/93 在联网环境通过。
- **Runtime blocker**: Orchestrator Phase 2 生成空剧本骨架，真实运行得到 0 角色、0 镜头且无 `final.mp4`。
- **Integration blocker**: Video 结果包装对象未规范化后再传给 Compositor。
- **Asset blocker**: 全局资产命中仍引用原项目路径，默认图片/视频/音频仍可能是占位字节。
- **Next Step**: 完成真实 Scriptwriter handler、资产复制与媒体有效性验证，再重跑 AC01–AC12。
