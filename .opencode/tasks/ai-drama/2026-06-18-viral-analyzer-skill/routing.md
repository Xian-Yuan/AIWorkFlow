# Routing Decision: AI 爆款分析与融合创作 Skill (ai-drama-viral-analyzer)

## Project Detection
- Project type: other
- Project: ai-drama (AIDramaProducer)
- System: ViralAnalysis Skill — 爆款视频/小说分析 + 风格复制 + 融合创作 + 数据注入编剧
- Task root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill`
- Design authority: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md` (12 开源 + 6 SaaS + 8 AI 小说工具 + 2 论文 + 6 方法论)

## Skill Selection
- Primary: `writing-skills` (Skill 创建流程)
- Secondary: `doc-governance`
- Collaboration mode: single agent (spec 产出，后续交给别的模型实现)

## Quality Gate
- Default quality level: Mature production-grade
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence` (Level 1-4 进化路径 + 6 种架构模式)
- Rejected shortcuts reviewed: 7 条
- Implementation scope: 产出完整 task packet，定义 ai-drama-viral-analyzer Skill 的全部行为规范
- Known non-goals: 不实现自动发布、实时监控、TRIBE v2、视频渲染

## Work Package Policy
- External workers: yes
- Task packet root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes

## Allowed Paths
- 本 task packet 内所有文件
- `skills/ai-drama-viral-analyzer/` (新建)
- `.agents/skills/ai-drama-viral-analyzer/` (新建，同步)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- `skills/ai-drama-scriptwriter/` (只读引用，不修改)
- `skills/ai-drama-producer/` (只读引用，不修改)

## 上下游依赖

| 方向 | 模块 | 数据契约 |
|------|------|---------|
| 上游 | 用户输入 | 视频 URL / 小说文本 / 博主主页 URL |
| 下游 | Phase 2: Scriptwriter Skill | style_injection.json + character_archetypes.json + shot_pacing_reference.json + voice_style_reference.json |
| 知识库 | 自维护 | hook-patterns.md + emotional-curves.md + narrative-structures.md + creator-styles.md |
