# Routing: Generate Docs/AI/SKILL-INVENTORY.md

**Task**: `2026-06-26-skill-inventory`
**Project**: `docs-ai`
**Authored**: 2026-06-26 by 金璃小天才 (Plan)
**Phase**: Plan ✅ + Implement ✅ → Verify ✅ (合并执行, 用户授权)
**Status**: 7/7 AC passed; 73 active + 11 archived 全覆盖; deliverable at `Docs/AI/SKILL-INVENTORY.md` (39.6 KB / 540 lines)

---

## 1. Project Type Detection

| 维度 | 值 | 证据 |
|------|----|----|
| Project 域 | docs-ai (AI 文档治理域) | 交付物在 `Docs/AI/` 目录 |
| Task 类型 | documentation-generation | 单文件 markdown 写作，无代码 |
| 阶段 | Plan | 交付 spec/analysis/routing/tasks，不写 SKILL-INVENTORY.md 本体 |
| Primary skill | `doc-governance` | 文档放置/规范/受影响分析的标准 skill |
| Secondary skills | `find-skills` (辅助发现), `failure-memory` (防重复错误) | 见 §3 |
| 工作量等级 | Medium | 73 skill 卡片 + 6 章节 + 1 架构图，机械写作密集 |
| 风险等级 | Low | 仅新增 1 个 .md，不动现有 skill/junction/source |

**不属于**：
- ❌ UE5 项目 (虽然 skills/ 里含大量 UE5 skill)
- ❌ Web 项目
- ❌ 实际加载/调用任何 skill
- ❌ 创建/修改 junction
- ❌ 修改 capability-baseline.json

## 2. 路由决策树

```
用户任务
  └─ 类型: 文档生成 (Docs/AI/ 下新增 .md)
      └─ 域: docs-ai
          ├─ Primary skill: doc-governance
          │   └─ 必读: Docs/AI/28-Documentation-Governance-Workflow.md
          │   └─ 必跑: .trae/scripts/doc-guard.ps1 (写完后)
          │   └─ 必读: Docs/AI/13-File-Placement-Convention.md
          │
          ├─ Secondary: find-skills
          │   └─ 用途: 辅助定位未在系统 prompt 中列出的 skill 元数据
          │   └─ 输出: 仅摘要注入，不污染主上下文
          │
          └─ Secondary: failure-memory
              └─ 用途: 检查"是否曾因文档重复生成失败"
              └─ 命令: .\.trae\scripts\memory-retrieve.ps1 "skill inventory"
              └─ 预期: 大概率无相关 failure memory (此任务首次)
```

## 3. Skill 加载清单

| 优先级 | Skill | 加载时机 | 用途 |
|--------|-------|---------|------|
| P0 | doc-governance | Implement 阶段入口 | 文档放置/规范/受影响判定 |
| P1 | find-skills | Implement 阶段辅助 | 找未在系统 prompt 暴露的 skill |
| P1 | failure-memory | Plan 收尾 + Implement 收尾 | 失败经验检索 |
| P2 | 13-File-Placement-Convention.md | Plan 阶段已读 | 确认 `Docs/AI/NN-*.md` 命名规则 |
| P2 | 28-Documentation-Governance-Workflow.md | Implement 阶段 | 文档治理主流程 |
| P2 | 35-Workflow-Tooling-Inventory.md | Plan 阶段已读 | 避免与脚本清单重复 (它讲脚本，不讲 skill) |
| P2 | document-taxonomy-inventory.md | Plan 阶段已读 | 避免与文档分类清单重复 (它讲 doc 不讲 skill) |

**不加载**：
- UE5 / Web / AI 漫剧 三大领域 skill — 任务范围是"为 skill 写索引"，不是"用 skill 工作"
- Hermes 适配器 — 任务不涉及 Hermes Profile 切换
- Jinli soul-core 系列 — 任务不涉及情感/记忆/会话管理

## 4. 架构决策记录 (ADR)

### ADR-1: 单一交付物
**决策**: 只生成 `Docs/AI/SKILL-INVENTORY.md` 一个文件。
**理由**: 用户的"交付物结构建议"列的是单文档章节，不是多文件分发。
**不创建**: 不创建 `Docs/AI/SKILL-INVENTORY/` 子目录、不拆 JSON/YAML、不生成 skill-registry.json (那是 `engine/` 域的工程产物，不在 docs 域)。

### ADR-2: 元数据来源 = SKILL.md frontmatter
**决策**: 卡片元数据从每个 skill 的 `SKILL.md` 第一行 frontmatter 的 `name` + `description` 字段抽取。
**理由**: 调研发现 `skills/` 下**没有** `manifest.yaml`（用户原计划假设存在）。capability-baseline.json 的 `metadata_required` 字段也只要求 `SKILL.md`。
**回退**: 若 frontmatter 缺失，fallback 到目录名 + 读 SKILL.md 第一行 H1。

### ADR-3: 不创建 junction、不修改 source
**决策**: 4 目录的 junction 状态保持现状（见 analysis.md §1.2 的实测结果），不在本次任务范围内调整。
**理由**: 用户"不要做"清单 + 已修过的状态工作良好。
**特例**: 实际发现 `.opencode/skills` 是链式 junction (`.opencode/skills` → `.trae/skills` → `skills/`)，这在文档里**如实标注**而不是"修复"成扁平结构。

### ADR-4: 73 + 1 + 11 计数法
**决策**: 总览写"74 个 skill"对应"73 个 active skill 目录 + 1 个 `_archived/` 容器"；`_archived/` 内部 11 个 archived skill 在专门一节列出。
**理由**: 用户口径是 74，但具体看是 73+1；archived 单独标注避免"双计"和"漏计"。

### ADR-5: 分类 = 13 类
**决策**: 按领域 + 用途切 13 类（UE5 / Web / AI 漫剧 / 反降智 / 工作流 / 协作 / Hermes / Jinli 灵魂 / 记忆 / Codex 元 / 工具链 / 效率 / GitHub 搜索 + 已归档）。
**理由**: 满足"至少 5 个分类"硬性要求；13 类覆盖全部 74 项不重不漏。
**验证**: 详见 analysis.md §3 的分类对照表。

## 5. 实施边界声明

| 动作 | 允许 | 理由 |
|------|------|------|
| 读取 `skills/*/SKILL.md` | ✓ | 元数据来源 |
| 读取 `Docs/AI/35-Workflow-Tooling-Inventory.md` | ✓ | 查重 |
| 读取 `Docs/AI/document-taxonomy-inventory.md` | ✓ | 查重 |
| 读取 `AGENTS.md` | ✓ | 仓库规则 |
| 读取 `.codex/capability-baseline.json` | ✓ | 元数据源 |
| 写 `Docs/AI/SKILL-INVENTORY.md` (新文件) | ✓ | 主要交付物 |
| 修改任何 skill 的 `SKILL.md` | ✗ | 用户禁令 |
| 修改 `capability-baseline.json` | ✗ | 用户禁令 |
| 创建/删除 junction | ✗ | 用户禁令 + junction 已修 |
| 执行 `ai-video-creator` 等 skill | ✗ | 用户禁令 + 任务范围外 |
| 编译 UE5 / 跑 Web 应用 | ✗ | 任务不涉及 |

## 6. 风险登记

| 风险 | 等级 | 缓解 |
|------|------|------|
| SKILL.md frontmatter 格式不统一 (部分有、部分无) | Low | 已在 ADR-2 写 fallback |
| 73 个 skill 全部读完耗时长 | Low | 实施时只读 frontmatter + 第一行 H1，不读全文 |
| 与 35-Workflow-Tooling-Inventory 内容混淆 | Low | 35 讲脚本，46 讲 skill；交叉引用而不重复 |
| 中文字符在 PowerShell 输出乱码 (gbk 编码名) | Low | 实施时用 Glob/Read 工具，不依赖 PowerShell 列举 |
| junction 状态描述与用户原话有差异 (链式 vs 扁平) | Info | 在文档里如实标注 + 在 handoff 块中说明 |

## 7. 移交清单

```text
TASK: 2026-06-26-skill-inventory
PROJECT_TYPE: docs
PRIMARY_SKILL: doc-governance
SECONDARY_SKILLS: find-skills, failure-memory
FILES:
  - routing.md    (本文件)
  - analysis.md   (现状分析 + 13 类分组)
  - spec.md       (GIVEN/WHEN/THEN + 7 条 AC)
  - tasks.md      (T1-T11 任务分解)
MATURE_PATH_VERIFIED: yes (capability-baseline.json v1.0.0 + junction 状态实测)
QUALITY_LEVEL: mature (有现成模板可套、有 baseline 可对照)
```
