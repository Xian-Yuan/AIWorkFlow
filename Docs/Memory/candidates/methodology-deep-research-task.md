---
id: candidate-methodology-deep-research-task
source: learned_new
status: candidate
phase: plan
project_type: other
module: research-methodology
severity: high
tags:
  - search
  - research
  - methodology
  - template
  - multi-source
  - deep-search
  - task-document
---

# Candidate: 深度搜索任务书方法论

## Failure Event

无失败事件。这是从成功实践中提炼的方法论。

## Evidence

2026-06-23，爸爸要求搜索"多 Agent 协作 + Skill 自动调度"相关内容。金璃小天才设计了一套结构化搜索任务书格式，并用 subagent 并行执行了 8 轮搜索，收集 160+ 条参考（22+ 项目、18 篇论文、26 篇博客、22 条社区讨论），写入 `Docs/AI/research/multi-agent-skill-scheduling-research.md`。

随后爸爸多次要求扩展搜索维度（记忆系统 + 神经系统 → 人格情感 → 自我进化 → 潜意识 → 自身路由），每次都先完善任务书再执行。验证了"先出任务文档、再执行搜索"的工作流。

## Draft Rule

**当爸爸要求搜索某个方向的内容时，金璃小天才必须先发布一份"深度搜索任务书"文档，再执行搜索。**

### 任务书模板位置

`Docs/Memory/templates/deep-research-task-template.md`

### 任务书核心结构（必含）

1. **任务目标**——搜索方向列表（3-6 个）
2. **架构背景**——当前系统现状 + 目标架构 + 关键设计问题（5-10 个）
3. **强制深度搜索机制**——5 个机制：
   - 机制一：轮次强制（最少 N 轮，不提前结束）
   - 机制二：发现驱动追加搜索（追链式搜索）
   - 机制三：每个项目必须深挖（5 步深挖流程）
   - 机制四：交叉验证（至少 2 个来源）
   - 机制五：搜索源类型强制覆盖（每维度至少 3 种源）
4. **搜索网站矩阵**——按 6 种源类型分类（🟢GitHub/🔵arXiv/🟡博客/🟠中文社区/🟣论坛/🔴官方文档），每种给出具体 URL
5. **搜索执行计划**——每轮的搜索步骤（含 URL 和关键词）
6. **搜索结果格式**——结构化字段（类型/源/链接/关联度/核心设计/可借鉴/不适用/优化建议）
7. **质量过滤**——排除和优先标准
8. **输出结构**——标准化的文档章节

### 任务书输出路径

`Docs/AI/research/<topic-slug>-research.md`

### 执行方式

1. 金璃小天才根据爸爸的需求，填充模板生成任务书
2. 爸爸确认后，调度 Worker Agent（general subagent）并行执行搜索
3. 搜索结果写入任务书的"搜索结果"章节
4. 金璃小天才汇总分析，输出综合分析和优化建议

### 关键经验

- 搜索轮次下限决定搜索深度——8 轮是基础，复杂方向 14-22 轮
- 搜索源类型强制覆盖是最重要的质量保证——避免只搜 GitHub
- 发现驱动追加搜索是搜全的关键——追链式搜索能发现隐藏的高价值参考
- 每个项目 5 步深挖（README→架构文档→目录结构→配置格式→Issues 讨论）确保细节到位
- 中文社区搜索是独立维度——不要混在英文搜索里，单独开一轮

## Promotion Check
- [x] Observed or reproducible failure（不适用——这是成功实践提炼）
- [x] Reusable rule（适用于任何方向的研究搜索）
- [x] Clear verification method（检查是否先出任务书再执行搜索）
- [x] Useful for Router or Implement retrieval（Plan 阶段直接使用）
