# Routing Decision: AI 漫剧编剧 Skill (ai-drama-scriptwriter) v2.1

## Project Detection
- Project type: other
- Project: ai-drama (AIDramaProducer)
- System: Scriptwriter Skill — 从故事创意到结构化分镜剧本
- Task root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill`
- Design authority:
  - `Project/AIDramaProducer/docs/early-references/ai-drama-ecosystem-research.md`
  - `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`

## Skill Selection
- Primary: `writing-skills`
- Secondary: `doc-governance`
- Collaboration mode: single agent

## Quality Gate
- Default quality level: Mature production-grade
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: 12 条
- Implementation scope: 产出完整 task packet
- Known non-goals: 不实现 Skill 代码；不实现爆款分析功能本身

## Work Package Policy
- External workers: yes
- Task packet root: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes

## 上下游依赖 (v2.1)

| 方向 | 模块 | 数据契约 |
|------|------|---------|
| 上游 | Phase 0: ViralAnalysis | style_injection.json + character_archetypes.json + shot_pacing_reference.json + voice_style_reference.json |
| 上游 | Phase 1: Text Preprocessor | 章节事件图谱 JSON |
| 下游 | Phase 3: Asset Generator | characters[].description + bone_binding_hints |
| 下游 | Phase 4: Keyframe Generator | shots[].description + keyframe_prompt_enhancement |
| 下游 | Phase 6: TTS Generator | shots[].dialogue + voice_profile + tts_pace/pitch_override |
