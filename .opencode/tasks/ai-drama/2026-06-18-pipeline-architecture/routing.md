# Routing Decision: AIDramaProducer 管线总架构 (v2.1)

## Project Detection
- Project type: other
- Project: ai-drama (AIDramaProducer)
- System: Pipeline Architecture — 六层架构 + 8 阶段管线
- Task root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture`
- Design authority:
  - `Project/AIDramaProducer/docs/early-references/ai-drama-ecosystem-research.md` (14+ 项目 + 8 论文)
  - `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md` (12 开源 + 6 SaaS + 8 AI 小说工具)

## Skill Selection
- Primary: none (架构设计 + spec 编写)
- Secondary: `doc-governance`
- Collaboration mode: single agent

## Quality Gate
- Default quality level: Research-grade → Production-grade
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence` (v2.1: 双调研报告支撑)
- Rejected shortcuts reviewed: 12 条 (v2.1 扩展)
- Known non-goals: 不实现代码；各模块由独立 task packet 实现

## Work Package Policy
- External workers: yes
- Task packet root: `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes

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
