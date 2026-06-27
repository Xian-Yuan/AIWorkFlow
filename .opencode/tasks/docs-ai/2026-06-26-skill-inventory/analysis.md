# Analysis: Generate Docs/AI/SKILL-INVENTORY.md

**Task**: `2026-06-26-skill-inventory`
**Date**: 2026-06-26
**Authored by**: 金璃小天才 (Plan Agent)

---

## 1. 现状实测 (Ground Truth)

### 1.1 文件系统事实

| 项 | 值 | 验证命令 / 证据 |
|---|---|---|
| `Docs/AI/SKILL-INVENTORY.md` | 不存在 | `Test-Path` 返回 False |
| `skills/` 顶层目录数 | 74 | `Get-ChildItem -Directory \| Measure-Object` |
| `skills/` 内 `_archived/` 容器 | 存在 | 列名第 1 项 |
| `skills/_archived/` 内部 skill 数 | 11 | `Get-ChildItem` |
| `skills/` 顶层 active skill 数 | 73 | 74 − 1 (`_archived`) |
| `manifest.yaml` 存在性 | 不存在 | `Get-ChildItem -Recurse -Filter manifest.yaml` 0 命中 |
| SKILL.md frontmatter 普遍性 | 普遍 | 抽 `ue5-cpp-gameplay` 和 `hermes-jinli-planner` 都有 `name` + `description` |

**关键修正**：用户原任务说"74 个 skill"对应 `skills/` 顶层 74 个目录。精确拆分：
- 73 个 active skill 目录
- 1 个 `_archived/` 容器（内含 11 个 archived skill）

**这意味着 SKILL.md 总数 = 73 + 11 = 84 份**，但 74 是目录计数。

### 1.2 Junction 架构实测

| 路径 | 类型 | Target | 状态 |
|------|------|--------|------|
| `E:\UEGameDevelopment\skills` | **真实目录（源）** | — | ✓ 内容 |
| `E:\UEGameDevelopment\.codex\skills` | junction | `E:\UEGameDevelopment\skills` | ✓ 直连 |
| `E:\UEGameDevelopment\.trae\skills` | junction | `E:\UEGameDevelopment\skills` | ✓ 直连 (2026-06-26 修复) |
| `E:\UEGameDevelopment\.opencode\skills` | junction | `E:\UEGameDevelopment\.trae\skills` | ⚠ **链式** (transitive) |

**修正用户描述**：用户原话是"`.opencode\skills` (junction → source)"，实测是"`.opencode\skills` → `.trae\skills` → `skills/`" 的两跳链式 junction。

- **功能上等价**：三跳链式与单跳扁平都能正确解析出同一份内容，OS 会自动跟进 reparse point。
- **文档里如实标注**：在 §5 同步状态章节写明"链式 junction"以避免后续维护者疑惑。
- **不修复**：用户"不要做"清单明确禁止创建/修改 junction。链式是历史结果，文档化即可。

### 1.3 capability-baseline.json 关键字段

| 字段 | 值 | 用途 |
|------|----|----|
| `version` | `1.0.0` | 版本基线锚定 |
| `project_skill.canonical_source` | `E:\UEGameDevelopment\skills` | 文档 §1 引用 |
| `project_skill.adapter_type` | `junction` | 文档 §5 引用 |
| `project_skill.validation_required` | `true` | 文档 §6 验证脚本引用 |
| `project_skill.archived_excluded` | `true` | 文档 §4 archived 标注引用 |
| `project_skill.metadata_required` | `["SKILL.md"]` | 文档 §3 卡片元数据来源声明 |
| `merge_policy` | `allowlist` | 文档 §5 sync 行为说明 |
| `generated_at` | `2026-06-18` | 时效声明 (注：当前 2026-06-26，相隔 8 天，建议在文档里标注 baseline 日期) |
| `validation.required_checks` | 10 项 | 文档 §6 引用 |

## 2. 元数据格式分析 (SKILL.md frontmatter)

### 2.1 典型样本

**样本 A** (ue5-cpp-gameplay) — 完整 frontmatter：
```yaml
---
name: ue5-cpp-gameplay
description: UE5.6/UE5.7 gameplay C++ implementation for Actors, Components, DataAssets...
---
```

**样本 B** (hermes-jinli-planner) — 完整 frontmatter：
```yaml
---
name: hermes-jinli-planner
description: Hermes 适配器 — 金璃小天才 Plan Agent 语义层...
---
```

**样本 C** (ai-video-creator) — **无 frontmatter**，用 H1 标题：
```markdown
# AI Video Creator Pipeline Skill (ai-video-creator) v1.0
> **版本**: v1.0
> **触发条件**: 用户说"做视频"/"创作视频"/"AI视频"...
```

**含义**：
- 多数 skill 有 YAML frontmatter（`name` + `description`）
- 部分 skill（特别是 AI 漫剧系列）用 H1 标题包含版本和触发关键词
- **必须 fallback 机制**：抽不到 frontmatter 时用目录名 + 读 SKILL.md 第 1 行 H1 + grep 触发关键词

### 2.2 卡片字段设计

每个 skill 卡片至少包含：

| 字段 | 来源 | 必填 | 备注 |
|------|------|------|------|
| 名称 | frontmatter.name 或 目录名 | ✓ | 目录名为权威 |
| 触发关键词 | frontmatter.description 第 1 句 | ✓ | 用户原计划"manifest.yaml.routing_keywords"不存在；改用 description 摘要 |
| 一句话用途 | frontmatter.description | ✓ | |
| code_root | `skills/<name>/` | ✓ | 4 目录 junction 统一可访问 |
| 上下游关系 | 手动标注（参考 jinli-agent-soul ↔ daughter-companion 那种明显成对关系） | 可选 | 不强行展开，避免编造 |
| 版本 | frontmatter 缺失时 fallback 到 H1 中的 `vX.Y` | 可选 | 多数 skill 未声明版本，留空 |
| 分类 | 13 类硬编码映射（见 §3） | ✓ | |

## 3. 13 类分组映射表

按"领域 + 用途"切 13 类，覆盖全部 74 个目录（73 active + 1 archived 容器）：

| # | 分类 | skill 数量 | 包含 skill |
|---|------|-----------|------------|
| 1 | **UE5 引擎** | 18 | `ue5-animation-guide` `ue5-architecture` `ue5-auto-assistant` `ue5-blueprint-workflow` `ue5-cpp-gameplay` `ue5-debug-validation` `ue5-mass-entity` `ue5-module-router` `ue5-pcg-building` `ue5-performance-packaging` `ue5-save-load-replication` `ue5-ui-umg-slate` `ue5-world-interaction` `ue-engineer` `ue-project-router` `ue-ai-validator` `ue-lyra-gas-implementer` `xg-uecpp-course` |
| 2 | **Web 开发** | 5 | `web-engineer` `web-fullstack` `web-implementer` `webapp-testing` `ui-ux-pro-max` |
| 3 | **AI 漫剧 (AIDramaProducer 管线)** | 6 | `ai-video-creator` `ai-drama-scriptwriter` `ai-video-director` `ai-drama-viral-analyzer` `bilibili-crawler` `character-designer` |
| 4 | **反降智 / 质量保证** | 6 | `anti-degradation` `anti-duplication` `code-quality-reviewer` `code-verifier` `code-simplifier` `verification-before-completion` |
| 5 | **工作流 / 规划** | 8 | `brainstorming` `writing-plans` `executing-plans` `subagent-driven-development` `dispatching-parallel-agents` `systematic-debugging` `test-driven-development` `task-orchestrator` |
| 6 | **协作 / 交付** | 5 | `receiving-code-review` `requesting-code-review` `finishing-a-development-branch` `using-git-worktrees` `doc-governance` |
| 7 | **Hermes 适配器** | 4 | `hermes-project-router` `hermes-jinli-planner` `hermes-jinli-implementer` `hermes-jinli-verifier` |
| 8 | **Jinli 灵魂 / 角色** | 2 | `jinli-agent-soul` `daughter-companion` |
| 9 | **记忆 / 经验** | 4 | `failure-memory` `memory-keeper` `agent-memory-bench` `code-knowledge-graph` |
| 10 | **Codex / 元工具** | 6 | `codex-project-router` `find-skills` `writing-skills` `implicit-requirements` `smart-requirements` `spec-living` |
| 11 | **工具链 / 桌面操控** | 2 | `tool-engineer` `windows-desktop-control` |
| 12 | **效率 / 压缩** | 2 | `token-guardian` `output-compressor` |
| 13 | **GitHub / 方案搜索** | 1 | `github-project-search` |
| 14 | **杂项 / 跨域** | 4 | `enhanced-subagent` `prompt-compressor` `spec-tracker (deprecated)` `using-git-worktrees (重复见 #6)` ⚠ 待复核 |
| - | **`_archived/` 容器** | 1 | `_archived/` (内含 11 个 archived skill：bmad-auto, character-designer(archived 版本), lyra-gas-dev, personal-branding, planning-with-files, prompt-compressor, rag-hallucination-guard, spec-tracker, token-optimizer, ue57-lyra-gas-ai-singleplayer, using-superpowers) |

**待复核点** (实施时校验)：
- `spec-tracker` 在 active 和 _archived 都有副本 → 文档化时 active 标记"已被 spec-living 取代"
- `using-git-worktrees` 是否真的既在 #6 也在 #14 → 实际只在 #6
- `prompt-compressor` 是否真的在 active 也在 _archived → 调研显示 _archived 里有，active 列表里也出现（重名），需在实施时用 Glob 复核
- `character-designer` 同上 (active + archived)

**净计数校验**：18 + 5 + 6 + 6 + 8 + 5 + 4 + 2 + 4 + 6 + 2 + 2 + 1 + 1 (`_archived`) = **70**

**差 3** → 来自 active 列表的：
- `金璃好帮手` (金璃好帮手 — Plan 描述错，应是 Implement)
- `金璃小天才` (金璃小天才 — Plan)
- `enhanced-subagent`

修正分组：

| 修正 | skill | 正确分类 |
|------|-------|----------|
| 加 #7 末 | `enhanced-subagent` | 工作流 / 规划 增强 (归到 #5 或单列) |
| 加 #8 后 | `金璃好帮手` (Implement Agent) | Jinli 灵魂 → 拆出"双 Agent 架构"小节 |
| 加 #8 后 | `金璃小天才` (Plan Agent) | Jinli 灵魂 → 拆出"双 Agent 架构"小节 |

**最终 13 类** (调整后)：

| # | 分类 | 数量 | 含调整 |
|---|------|------|--------|
| 1 | UE5 引擎 | 18 | — |
| 2 | Web 开发 | 5 | — |
| 3 | AI 漫剧 | 6 | — |
| 4 | 反降智 / 质量 | 6 | — |
| 5 | 工作流 / 规划 | 9 | + `enhanced-subagent` |
| 6 | 协作 / 交付 | 5 | — |
| 7 | Hermes 适配器 | 4 | — |
| 8 | Jinli 灵魂 / 双 Agent | 4 | + `金璃小天才` + `金璃好帮手` (原 #8 拆并) |
| 9 | 记忆 / 经验 | 4 | — |
| 10 | Codex / 元工具 | 6 | — |
| 11 | 工具链 | 2 | — |
| 12 | 效率 | 2 | — |
| 13 | GitHub 搜索 | 1 | — |
| - | `_archived/` 容器 | 1 | — |
| **合计** | | **73** | ✓ 与 74 顶层目录 - 1 archived 容器 = 73 active 匹配 |

## 4. AI 漫剧入口标注

用户在交付物结构建议里点名要标注的 skill：

| skill | 角色 | 入口标注 |
|-------|------|----------|
| `ai-video-creator` | **管线编排入口** | 顶层入口，6 阶段流水线 (S0-S5) |
| `ai-drama-scriptwriter` | 子阶段 S2 实施 | 剧本大纲生成 |
| `ai-video-director` | 子阶段 S4 实施 | 分镜/导演提示词 |
| `ai-drama-viral-analyzer` | 横向支持 | 爆款分析 (style_injection) |
| `bilibili-crawler` | 数据源 | 灵感采集 (S0) |
| `character-designer` | 跨阶段支持 | 角色提示词 (S3) |

**AIDramaProducer 入口** = `ai-video-creator` (本任务范围内仅文档化，**不执行**)

## 5. Jinli 入口标注

| skill / agent | 角色 | 入口标注 |
|---------------|------|----------|
| `金璃小天才` (skills/金璃小天才/SKILL.md) | **Plan 阶段入口** | 需求澄清、任务拆解、spec 生成 |
| `金璃好帮手` (skills/金璃好帮手/SKILL.md) | **Implement 阶段入口** | 按 spec 实现、编译验证、self-check |
| `jinli-agent-soul` | 共享基础设施 | Soul Core 集成合同（两 Agent 都引用） |
| `daughter-companion` | Soul Core 引擎参考 | 情感/记忆/会话管理（**不直接执行**） |
| `hermes-jinli-planner` | Hermes 适配器 | 在 Hermes Profile 下激活小天才 |
| `hermes-jinli-implementer` | Hermes 适配器 | 在 Hermes Profile 下激活好帮手 |

**Jinli 双管线入口** = `金璃小天才` + `金璃好帮手` (本任务范围内仅文档化)

## 6. 风险与约束推导

### 6.1 任务内在约束

1. **不创建重复内容**：必须先查 `Docs/AI/` 现有 50+ 个 .md 文件确认无重复（已查 `35-Workflow-Tooling-Inventory.md` 和 `document-taxonomy-inventory.md` 都不重复）
2. **不动 source**：4 目录 junction 架构和 `capability-baseline.json` 都不修改
3. **不执行 skill**：所有 skill 仅作为元数据来源被列举
4. **74 项全覆盖**：必须遍历所有 73 active + 1 archived 容器，不能漏

### 6.2 实施期约束

- 写作时统一用 ASCII 表格 + 中文描述混排
- 关键词不超过 8 个 / skill（避免卡片过长）
- 不展开 skill 内容，只做导航
- 不写教程、不写 review、不写 changelog
- 标记 Jinli 双 Agent 入口和 AIDramaProducer 入口的"管道起点"

### 6.3 验证期约束

实施完成后必须验证：
- [ ] 73 active skill 全部出现在分类表中
- [ ] 11 archived skill 全部出现在 `_archived/` 子节中
- [ ] 4 目录 junction 关系图与实测一致（链式结构如实标注）
- [ ] 至少 5 个分类（实际 13 个）
- [ ] Jinli 入口和 AIDramaProducer 入口都标注
- [ ] `capability-baseline.json` 关键字段被引用
- [ ] `.trae/scripts/validate-codex-capabilities.ps1` 等脚本被引用

## 7. 依赖图

```text
[能力基线确认]
  capability-baseline.json v1.0.0
  junction 实测 (3 直 + 0 链? → 实际 2 直 + 1 链)
  SKILL.md frontmatter 普遍性确认
  ↓
[分类映射固化] → 13 类
  ↓
[写章节 1] 总览 + junction 图
  ↓
[写章节 2] 分类索引 (13 类 × skill 列表)
  ↓
[写章节 3] skill 卡片 (73 个)
  ↓
[写章节 4] AI 漫剧专区 (6 个)
  ↓
[写章节 5] 同步状态 (链式 junction 实测)
  ↓
[写章节 6] 验证脚本引用
  ↓
[自检] 7 条 AC + 防重复
  ↓
[交付]
```

---

## 附录 A：原始 skill 列表 (74 项)

抽自 `Get-ChildItem -Directory` 实际输出，按字母序：

```
_archived, agent-memory-bench, ai-drama-scriptwriter, ai-drama-viral-analyzer,
ai-video-creator, ai-video-director, anti-degradation, anti-duplication,
bilibili-crawler, brainstorming, character-designer, code-knowledge-graph,
code-quality-reviewer, code-simplifier, code-verifier, codex-project-router,
daughter-companion, dispatching-parallel-agents, doc-governance,
enhanced-subagent, executing-plans, failure-memory, find-skills,
finishing-a-development-branch, github-project-search, hermes-jinli-implementer,
hermes-jinli-planner, hermes-jinli-verifier, hermes-project-router,
implicit-requirements, jinli-agent-soul, memory-keeper, output-compressor,
prompt-compressor, receiving-code-review, requesting-code-review,
smart-requirements, spec-living, subagent-driven-development,
systematic-debugging, task-orchestrator, test-driven-development,
token-guardian, tool-engineer, ue5-animation-guide, ue5-architecture,
ue5-auto-assistant, ue5-blueprint-workflow, ue5-cpp-gameplay,
ue5-debug-validation, ue5-mass-entity, ue5-module-router, ue5-pcg-building,
ue5-performance-packaging, ue5-save-load-replication, ue5-ui-umg-slate,
ue5-world-interaction, ue-ai-validator, ue-engineer, ue-lyra-gas-implementer,
ue-project-router, ui-ux-pro-max, using-git-worktrees,
verification-before-completion, webapp-testing, web-engineer, web-fullstack,
web-implementer, windows-desktop-control, writing-plans, writing-skills,
xg-uecpp-course, 金璃好帮手, 金璃小天才
```

**注意**：最后两项是中文目录名（中文字符），在 PowerShell 5.1 下显示乱码属正常，实施时用 Read/Glob 工具直接按真实名访问即可。

## 附录 B：_archived/ 内 11 个 skill

```
bmad-auto, character-designer, lyra-gas-dev, personal-branding,
planning-with-files, prompt-compressor, rag-hallucination-guard,
spec-tracker, token-optimizer, ue57-lyra-gas-ai-singleplayer, using-superpowers
```

实施时如发现 active 列表与 _archived 列表有重名（如 character-designer、prompt-compressor、spec-tracker），文档需在两个位置都标注并解释"archived 版本 vs active 版本"。
