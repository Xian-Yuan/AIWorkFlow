# Routing Decision: AIDramaProducer 验收阻断修复

## Project Detection
- Project type: other
- Project: ai-drama (AIDramaProducer)
- System: 全管线 — 9 Skill / 3 Task Packet
- Task root: `.trae/tasks/ai-drama/2026-06-19-fix-verification-blockers`
- Design authority:
  - `Project/AIDramaProducer/docs/early-references/ai-drama-ecosystem-research.md`
  - `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`
  - `.trae/tasks/ai-drama/2026-06-18-pipeline-architecture/` (原始 Plan + verification-report)
  - `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/`
  - `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`

## Root Cause
Implement 阶段生成了 91 个文件的结构但仍存在以下系统性问题:
1. 包命名违反 Python 规范（连字符目录名）
2. Orchestrator 未集成任何真实 Skill（空占位）
3. 7/9 模块无测试覆盖
4. 任务清单未勾选，Verification 全自检无证据

## Skill Selection
- Primary: `web-fullstack` (Python 全栈修复)
- Secondary: none
- Collaboration mode: single agent（串行修复 5 步）

## Quality Gate
- Default quality level: **Fix to pass verification**（不求完美重构，只求验收通过）
- MVP/prototype requested by user: no
- Quality Exception: 本任务为修复，默认质量目标为"通过验收门禁"，非生产级重构
- P0 must pass: 包结构 / orchestrator 集成 / 核心逻辑 bug 修复 / 测试覆盖 / 任务勾选 + verify 门禁
- P1 should pass: 资产复制 / 占位替换
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: `analysis.md#拒绝的捷径`
- Selected mature path: `analysis.md#Selected-mature-path`

## Dependencies
- 必须先修包结构（Step 1），再修 orchestrator 集成（Step 2）
- 核心逻辑 bug 修复（Step 2）与包结构并行度有限：包结构改完 import 路径后需同步调整
- 测试（Step 3）依赖核心逻辑修复
- 验收文档（Step 4）依赖全部修复完成

## Work Package Policy
- External workers: no（本任务包由 Implement Agent 单 agent 串行完成）
- Task packet root: `.trae/tasks/ai-drama/2026-06-19-fix-verification-blockers`
- Work packages required: yes（5 个 WP）
| WP | 名称 | 依赖 |
|----|------|:----:|
| WP01 | 包结构修复 + import 路径调整 | — |
| WP02 | 核心逻辑 bug 修复 | WP01 |
| WP03 | 测试修复 + 补充 | WP02 |
| WP04 | 任务勾选 + 验收文档 + Verify 门禁 | WP01-03 |
| WP05 | P1 修复（资产复制/占位替换） | WP01 |

## Related Task Packets
| Task Packet | Phase | Action |
|-------------|:-----:|--------|
| `ai-drama/2026-06-18-pipeline-architecture` | implement | 修复后更新 review_result, verify_result |
| `ai-drama/2026-06-18-scriptwriter-skill` | implement | 修复后更新 review_result, verify_result |
| `ai-drama/2026-06-18-viral-analyzer-skill` | implement | 修复后更新 review_result, verify_result |
