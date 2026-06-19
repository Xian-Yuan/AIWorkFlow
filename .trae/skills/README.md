# Skills 索引

> 根目录 .trae/skills/ 是项目 skill 真相源。\n> 共 28 个 Skill。

## 路由速查（按需求类型）

| 需求类型 | Skill |
|---------|-------|
| Lyra + GAS + AI + 单机玩法 | `ue57-lyra-gas-ai-singleplayer` |
| Lyra/GAS 全栈开发 | `lyra-gas-dev` |
| 通用 UE 需求（描述模糊） | `ue5-auto-assistant` |
| 纯 C++ gameplay | `ue5-cpp-gameplay` |
| 蓝图节点/接线 | `ue5-blueprint-workflow` |
| UMG / Slate / UI | `ue5-ui-umg-slate` |
| 模块边界 / Build.cs | `ue5-architecture` |
| 大规模实体（100+） | `ue5-mass-entity` |
| 动画蓝图 / 状态机 | `ue5-animation-guide` |
| 编译/运行时验证 | `ue5-debug-validation` |
| 世界交互（拾取/生成） | `ue5-world-interaction` |
| PCG 建筑生成 | `ue5-pcg-building` |
| 存档/读档 | `ue5-save-load-replication` |
| 性能/打包 | `ue5-performance-packaging` |
| 模块路由 | `ue5-module-router` |
| UE C++ 课程参考 | `xg-uecpp-course` |
| 网页全栈开发（非UE项目） | `web-fullstack` |
| 复杂任务文件化规划 | `planning-with-files` |
| 代码简化（不含行为变更） | `code-simplifier` |
| Web应用测试（Playwright） | `webapp-testing` |
| UI/UX 设计指导 | `ui-ux-pro-max` |
| RAG + 幻觉预防 | `rag-hallucination-guard` |
| GitHub 方案搜索 | `github-project-search` |

## Agent Skill

| Agent | Skill |
|-------|-------|
| `ue-project-router` | 需求路由分流 |
| `ue-lyra-gas-implementer` | Lyra/GAS 主链路实现 |
| `ue-ai-validator` | AI 选型 + 编译/运行时/资产验证 |

## 通用 Skill（UE + 后端均可使用）

| Skill | 用途 |
|-------|------|
| `brainstorming` | 需求分析、方案设计 |
| `test-driven-development` | TDD 测试驱动开发 |
| `systematic-debugging` | 系统化调试 |
| `writing-plans` | 计划编写 |
| `executing-plans` | 计划执行 |
| `verification-before-completion` | 完成前验证 |
| `requesting-code-review` | 代码审查 |
| `receiving-code-review` | 接收代码审查反馈 |
| `web-fullstack` | 网页全栈开发（前后端 + 数据库） |
| `planning-with-files` | 文件化规划（task_plan/findings/progress 三文件模式） |
| `code-simplifier` | 代码简化（保持行为不变，降低复杂度） |
| `webapp-testing` | Web 应用自动化测试（Playwright） |
| `ui-ux-pro-max` | UI/UX 设计指导 |
| `rag-hallucination-guard` | RAG + 幻觉预防（CoVe自验证 + 检索增强） |
| `token-optimizer` | Token 优化与上下文效率 |
| `github-project-search` | GitHub 多维度方案搜索 |

> Agent 定义在 `.opencode/agents/`，Skill 文件在 `.trae/skills/`。
> Agent 控制行为约束，Skill 提供领域知识。
