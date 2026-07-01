# Knowledge Index — UEGameDevelopment

> 主入口：[AGENTS.md](../../AGENTS.md) · 路径：`Docs/AI/AGENTS-Knowledge-Index.md`

## Agent 规则（AI 读取）

| 文档 | Trae | OpenCode |
|------|------|----------|
| 全局项目规则 + Harness Engineering + GDD 文档体系 | `.trae/rules/project_rules.md` | `.opencode/rules/project_rules.md` |
| 路由入口：项目识别 + 路由 + 调度文档索引 + 任务状态机 | `.trae/skills/ue-project-router/SKILL.md` | `.opencode/agents/ue-project-router.md` |
| 开发总览：角色判定 + 调度规则 + 资源索引 | `Docs/AI/01-AI-Development-Playbook.md` | 共享 |

## UE5 专题 → `Docs/AI/`

| 编号 | 文档 | 用途 |
|------|------|------|
| 03 | `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS 开发规则 |
| 04 | `04-Asset-Checklists.md` | 资产检查清单 |
| 05 | `05-StateTree-BT-EQS-SmartObject.md` | AI 行为选择 |
| 06 | `06-GameplayTag-Registry.md` | GameplayTag 注册表 |
| 07 | `07-Test-Checklists.md` | 测试清单 |
| 08 | `08-AntiPatterns.md` | 反模式教训 |
| 13 | `13-File-Placement-Convention.md` | 文件放置约定 |
| 14 | `14-Coding-Standards.md` | UE5 C++ 编码规范 |
| 18 | `18-Validation-Checklist.md` | 验证清单 |
| 19 | `19-Unreal-Conventions.md` | 通用约定 |

## 协作规则 → `Docs/AI/`

| 编号 | 文档 | 用途 |
|------|------|------|
| 09 | `09-Agent-Handoff-Templates.md` | Agent 交接模板 |
| 10 | `10-Execution-Examples.md` | 执行范例 |
| 11 | `11-Skill-Routing-Workflow.md` | Skill 路由规则 |
| 12 | `12-MultiAgent-Workflow.md` | 多 Agent 协作 + 反馈协议 + Memory Candidate |
| 15 | `15-FailSafe-AntiBloat.md` | 失败安全与反臃肿 |
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro 工作流硬约束 profile |
| 17 | `17-Self-Improving-Framework.md` | 自改进框架 |
| 24 | `24-Pro-Flash-Model-Tiering.md` | Pro + Flash 模型分层工作流 |

## Memory 层

- `Docs/AI/` 依然是公共知识的主要来源
- `Docs/Memory/` 是失败经验的补充层，不替代 `Docs/AI/`
- Codex Skill `failure-memory` 提供跨会话失败经验记忆
- 第二阶段才引入 `Mem0`，文件仍然是主要来源，`Mem0` 只做语义增强

### Memory 路径索引 → `Docs/Memory/`

| 路径 | 用途 |
|------|------|
| `Docs/Memory/README.md` | Basic Memory 第一阶段工作准则、触发条件与预期 |
| `Docs/Memory/indexes/memory-index.md` | failure memory 索引与检索 |
| `Docs/Memory/failures/` | 已转化的 failure memory |
| `Docs/Memory/candidates/` | 待转化的 memory candidate |
| `Docs/Memory/templates/` | failure memory 和 candidate 模板 |

## Codex Skills → `.agents/skills/`

| Skill | 用途 |
|-------|------|
| `failure-memory` | 跨会话失败经验记忆与检索，Review/Verify 失败时记录，Plan 阶段自动检索 |
| `anti-degradation` | 上下文腐烂检测 + 修复循环中断 + 假阳性防御 |
| `anti-duplication` | AI 多次修改/重构导致的代码冗余检测与预防 |
| `金璃小天才` | Plan 阶段专责 —— 需求澄清、设计文档检索、隐性需求推导、依赖链推导、成熟方案搜索、任务拆分 |
| `金璃好帮手` | 实现阶段专责 —— 按 spec 编码、编译验证、重复检测、对照 spec 自检 |
| `implicit-requirements` | 隐性需求化归与需求补全 |
