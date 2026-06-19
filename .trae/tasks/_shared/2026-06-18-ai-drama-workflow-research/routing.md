# Routing Decision: AI 漫剧/真人剧 工作流调研与 Spec

## Project Detection
- Project type: other
- Project: _shared (跨项目调研，非特定项目代码实现)
- System: AI Drama Pipeline — 从小说到成片的自动化管线
- Task root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research`
- Design authority: GitHub + 网络开源项目分析 (14+ repos)

## Skill Selection
- Primary: none (调研 + spec 编写任务，非代码实现)
- Secondary: `doc-governance` (产出文档需纳入 Docs 体系)
- Collaboration mode: single agent (调研 + spec 产出)

## Quality Gate
- Default quality level: Research-grade (调研报告 + 可执行 spec)
- MVP/prototype requested by user: no — 用户要求写 spec 交给别的模型实现
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: see analysis.md
- Implementation scope: 产出完整的 task packet (spec + tasks + work-packages)，供外部模型直接执行
- Known non-goals: 不在此任务中实现任何代码或 Skill；不修改现有项目文件

## Work Package Policy
- External workers: yes — 本 spec 设计为交给别的模型实现
- Task packet root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes

## Allowed Paths
- 本 task packet 内所有文件
- `Docs/AI/` (如需新增 AI 工作流文档)
- `.agents/skills/` (如需新增 ai-drama-producer Skill)
- `skills/` (如需新增 Skill)

## Forbidden Paths
- `Project/RTS/` (UE5 游戏项目，不相关)
- `Project/CharacterDesignTool/` (Web 应用，不相关)
- `Project/Jinli/` (Soul Core，不相关)

## Release Authority
- 本 task packet 即为交付物
- spec.md 定义完整行为规范
- work-packages/ 定义可分配给外部模型的工作包
