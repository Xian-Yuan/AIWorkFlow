# Analysis: Obsidian Knowledge Autopoiesis

> Phase: Plan | Authority Profile: issuer-worker-v1 | Generated: 2026-06-29

## Architecture Context

### System boundaries

- **Inbound**: vsummary post-summarize hook (existing pipeline), manual `obsidian-*.ps1` calls, weekly cron for `dream-reflect`
- **Outbound**: Obsidian vault file system (E:\ObsidianVault), ai-workflow-registry status, Soul Core future integration (soul_learn / soul_memory) — read-only via Gene YAML, no MCP write
- **Trust boundary**: Workers (DS4-Flash) operate on a signed capability `obsidian-autopoiesis-<wp>`; only the original Issuer signs Review, explicit Archive, and growth_approve
- **Mutation boundary**: Gene, classification-rules, evolution-rubric, registry entry — all Issuer-only mutations; workers may only read+propose via `worker-submit.ps1`
- **SPL guardrails (from Autogenesis AGP/SPL, BV1W27R63EmC)**:
  - Gene cannot modify Gene (no self-reference mutation)
  - classification-rules cannot modify classification-rules
  - Every proposal must pass `SPL-Evaluate` (parse + dryrun + AC mock) before `SPL-Commit`
  - SPL-Commit requires `growth_approve` from Ba Ba
- **Vault safety**: D1 (zero-destructive upgrade) — only new files follow new rules; existing files untouched; old positions get `[[wikilink]]` redirect stubs preserving GraphView connectivity

### Dependency map

```
                 ┌──────────────────────────────────────┐
                 │  vsummary pipeline (existing)        │
                 │  skills/vsummary/SKILL.md            │
                 └────────────────┬─────────────────────┘
                                  │ post-summarize hook (WP07)
                                  ▼
   ┌─────────────────────────────────────────────────────────┐
   │  WP01: Skill + classification-rules.yaml + rubric      │
   │  skills/obsidian-autopoiesis/SKILL.md                  │
   │  E:\ObsidianVault\进化\rules\classification-rules.yaml │
   │  E:\ObsidianVault\进化\rules\evolution-rubric.yaml     │
   └──────────────────────────┬──────────────────────────────┘
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
       ▼                      ▼                      ▼
   ┌─────────┐          ┌──────────┐          ┌──────────┐
   │ WP02    │          │ WP03     │          │ WP04     │
   │ classify│─────────▶│ evolve   │          │ link-    │
   │ .ps1    │          │ .ps1     │          │ discover │
   └────┬────┘          └─────┬────┘          └────┬─────┘
        │                     │                    │
        │                     ▼                    │
        │              ┌──────────┐                │
        │              │ 进化/    │                │
        │              │ genes/   │                │
        │              │ gene-*.yaml               │
        │              └──────────┘                │
        ▼                                        ▼
   ┌─────────┐                            ┌──────────┐
   │ WP06    │◀───────────────────────────│ WP05     │
   │ maintain│                            │ dream-   │
   │ .ps1    │                            │ reflect  │
   └─────────┘                            └──────────┘
                              │
                              ▼
                ┌─────────────────────────┐
                │ WP08: registry + verify │
                │ skills/ai-workflow-     │
                │   registry/registry.yaml│
                └─────────────────────────┘
```

### Acceptance Criteria

All 8 AC are defined in `spec.md` and mapped to tasks in `tasks.md`:

| AC# | Source Task | Verification |
|-----|------------|--------------|
| AC01 | T02.8 | `obsidian-classify.ps1 -DryRun` outputs target path without moving |
| AC02 | T02.8 | Original position contains `[[wikilink]]` redirect |
| AC03 | T03.6 | `obsidian-evolve.ps1 -Analyze` outputs 4-dim JSON |
| AC04 | T03.6 | `obsidian-evolve.ps1 -ExtractGene` writes gene-*.yaml under 进化/genes/ |
| AC05 | T04.7 | `obsidian-link-discover.ps1 -Method tag-cooccurrence` outputs pairs |
| AC06 | T05.7 | `obsidian-dream-reflect.ps1 -FullScan` writes dream-report-*.md |
| AC07 | T06.6 | `obsidian-maintain.ps1 -DetectDuplicates` outputs duplicate pairs |
| AC08 | T07.4 | vsummary post-hook triggers classify chain |

### Automated Verification Plan

| Stage | Command | Expected |
|-------|---------|----------|
| WP01 | `Test-Path skills\obsidian-autopoiesis\SKILL.md` | True |
| WP01 | `python -c "import yaml; yaml.safe_load(open(r'E:\ObsidianVault\进化\rules\classification-rules.yaml'))"` | exit 0 |
| WP02 | `.\.trae\scripts\obsidian-classify.ps1 -DryRun -Source "<test.md>"` | prints target path, no move |
| WP03 | `.\.trae\scripts\obsidian-evolve.ps1 -Analyze -Source "<test.md>"` | prints JSON with 4 keys |
| WP04 | `.\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun` | prints pairs |
| WP05 | `.\.trae\scripts\obsidian-dream-reflect.ps1 -QuickScan` | writes dream-report |
| WP06 | `.\.trae\scripts\obsidian-maintain.ps1 -DetectDuplicates` | prints pairs |
| WP07 | review `skills\vsummary\SKILL.md` post-summarize section | contains hook call |
| WP08 | `python .trae\scripts\sync-workflow-registry.py` | exit 0 |
| WP08 | `.\.trae\scripts\task-guard.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify` | all checks pass |

### Work package policy

- **External workers**: yes (DS4-Flash subagent for script-implementation tasks, with signed capability)
- **Worker scope**: WP02-WP06 implementation files; Worker may NOT modify routing.md / spec.md / analysis.md / .task.yaml / registry.yaml
- **Issuer-only operations**: WP01 (Skill + rules YAMLs), WP07 (vsummary SKILL.md modification), WP08 (registry + final verify)
- **No skipped WPs**: each WP must be self-contained complete solution, not progressive stubs
- **No downgraded quality**: mature production-grade default, no MVP placeholder

## Mature Solution Evidence

### Project-local evidence

- **JIPA (Pareto Prompt Evolution)** — JinliKG video `BV1c6LV67EvA`. Multi-objective Pareto optimization + 6-step pipeline (sampling / scoring / crossover / mutation / selection / commit). Provides the algorithmic skeleton for `obsidian-evolve.ps1` Pareto 4-dim scoring (system-enhance / code-quality / automation / self-evolve).
- **Autogenesis AGP/SPL** — JinliKG `BV1W27R63EmC`. Five-class resource registry + SPL 5-step closed loop (Reflect / Select / Improve / Evaluate / Commit). Provides safety guardrails: Gene cannot modify Gene, proposals must pass Evaluate before Commit, Commit requires human approval. Mapped 1:1 to our `Gene → SPL-Reflect → SPL-Select → SPL-Improve → SPL-Evaluate → SPL-Commit` workflow.
- **SkillOpt (Microsoft, 2024)** — JinliKG `BV1mKEg69Evn`. Treats skill docs as trainable parameters; 5-step iteration; empirically validated that **compact Gene YAML (300-2000 tokens) outperforms verbose markdown** for downstream LLM retrieval. Decision D2 directly uses this finding.
- **Self-Harness** — JinliKG `BV1B8Ju6gGEqT`. Three-stage loop (weak-mining → minimal-modify → verify). Provides the minimal-modification principle applied in WP03 Gene extraction (no source mutation, only distillation).
- **Hermes four-layer memory** — JinliKG `BV17KoFBBEqM`. Episodic / Semantic / Procedural + trajectory / Provider. Direct mapping to our three-tier: Sources/ (episodic) → 知识/ (semantic) → 进化/genes/ (procedural).
- **Hermes + LLM-Wiki + Obsidian pipeline** — JinliKG `BV16hZFB5ERM`. Document → AI consolidation → Wiki generation → bidirectional linking. The canonical reference for vsummary→classify→evolve→link-discover linear chain.
- **自进化知识库 (Self-Evolving KB)** — JinliKG `BV1iJEK6bE7h`. Five-layer directory + avatar mechanism. Direct inspiration for the `进化/` directory structure (rules / genes / proposals / dreams / enacted).

### Official/framework evidence

- **PowerShell 5.1 (Windows PowerShell)** — `.trae/scripts/` standard. All scripts use parameter splatting, `Get-Content -Raw`, `ConvertFrom-Yaml` (from powershell-yaml module if available, fallback to simple key:value regex parse), and Pester-compatible assertions for self-test mode.
- **Obsidian `[[wikilink]]` + GraphView** — First-class. Redirects use stub `.md` files containing only `[[target-path]]` so GraphView edges are preserved.
- **Soul Core (jinli-soul-core MCP)** — Existing toolset (`soul_learn`, `soul_memory`, `soul_turn`). Future integration will inject Gene YAMLs via `soul_learn` — not part of this task scope, recorded as known-not-yet-implemented.
- **ai-workflow-registry (`skills/ai-workflow-registry/registry.yaml`)** — Existing registry schema; new workflow registers with name / description / status / skill_path / trigger_keywords.
- **Docs/AI/17-Self-Improving-Framework.md** — Authoritative design doc. Defines 4 engines (Memory / Evolution / Skill / Subconscious). This task closes the loop for Memory + Evolution engines via Obsidian vault.

### Options compared

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **A. Auto-classify via LLM call per file** | Most flexible | Slow (1-3s/file × 571 = 30+ min), expensive, non-deterministic | **Rejected** — uses classification-rules.yaml lookup + LLM only for unclassified queue |
| **B. Manual folder reorganization** | Zero risk | Doesn't scale, doesn't run automatically | **Rejected** — violates D1 automation principle |
| **C. Pure JIPA evolution** | Strong Pareto selection | No safety guardrails, no SPL commit gate | **Rejected** — must combine with SPL safety |
| **D. Pure Autogenesis SPL** | Strong safety | Single-objective selection, no Pareto diversity | **Rejected** — must combine with JIPA multi-objective |
| **E. Hybrid JIPA-SPL** (this task) | Pareto diversity + SPL safety + human approval | More moving parts | **Selected** — best of both, used in 进化/genes/ lifecycle |
| **F. SkillOpt-style long-form markdown Genes** | Easier to author | Empirically worse retrieval; 10-50k tokens each | **Rejected** — D2 mandates 300-2000 token Gene YAML |
| **G. Tag-only link discovery (no LLM)** | Cheap | Misses semantic connections, low recall | **Rejected** as sole method — D4 keeps LLM for semantic layer |
| **H. LLM-only link discovery** | High recall | Expensive, noisy, slow | **Rejected** as sole method — D4 keeps tag co-occurrence as cheap filter |
| **I. Tag co-occurrence + LLM semantic** (this task) | Cheap filter + precise LLM | Two-stage complexity | **Selected** — best precision/cost ratio |
| **J. Sync Obsidian via Symlinks** | OS-level single source | Breaks Obsidian on Windows, fragile | **Rejected** — use explicit `[[]]` redirect files |

### Rejected shortcuts

- **"Just use GPT to classify everything"** — slow, expensive, non-idempotent, no audit trail. Rejected because classification-rules.yaml provides deterministic, auditable mapping.
- **"Skip Gene extraction threshold, extract everything"** — Gene pool explodes, signal-to-noise collapses. Rejected because Pareto ≥ 0.6 threshold (4-dim) is the proven quality gate from JIPA.
- **"Move old files too"** — violates D1 (zero-destructive upgrade), breaks existing wikilinks, GraphView regressions, user data loss risk. Rejected.
- **"Skip maintain.ps1, manual cleanup"** — Gene decay is mathematical, manual tracking impossible at scale. Rejected because dream-report + maintain.ps1 automate this.
- **"Just modify vsummary directly without hook"** — tight coupling, breaks vsummary single-responsibility, harder to test. Rejected because post-summarize hook preserves vsummary pipeline integrity.
- **"Use `Move-Item` without redirect stub"** — breaks Obsidian GraphView, breaks existing `[[]]` links. Rejected.
- **"Inline Gene as markdown frontmatter in source notes"** — Gene pool invisible, not version-controllable, no Gene-to-Gene dedup. Rejected in favor of separate `进化/genes/gene-*.yaml`.
- **"Skip SPF/Authority Profile check"** — workers would mutate routing.md, registry.yaml, .task.yaml — breaks issuer-worker-v1 invariant. Rejected.

### Selected mature path

The chosen path is **hybrid JIPA-SPL evolution + Tag+LLM hybrid link discovery + zero-destructive D1 classification + SkillOpt 300-2000 token Gene format**, integrated as 5 PowerShell scripts under `.trae/scripts/` plus 1 Skill entry point under `skills/obsidian-autopoiesis/`, registered in `skills/ai-workflow-registry/registry.yaml`, and hooked into vsummary post-summarize step.

This path is selected because:
1. **Mature evidence stack**: 7 local JinliKG references + 5 external open-source references (EvoMap / COG / llm-wiki-skills / obsidian-agent-memory-skills / arxiv 2603.24639 ERL) all converge on the same architectural shape.
2. **SPL safety proven**: AGP/SPL is the only known evolution framework that prevents self-modification loops.
3. **SkillOpt format proven**: 300-2000 token Genes empirically outperform long markdown.
4. **D1 zero-destructive is a hard constraint** from user requirement (Obsidian GraphView preservation), not a shortcut.
5. **Authority Profile compatibility**: WS-worker + Issuer separation maps 1:1 to AGP/SPL Reflect→Commit boundary.

## 1. 问题诊断

### 1.1 现状
- Obsidian vault (E:\ObsidianVault) 含 1281 个 md 文件，571 个视频总结
- JinliKG/Sources/Videos/ 下 571 个文件全部平铺在一个目录
- 知识/ 和 虚幻/ 两套分类体系有内容重叠 (如 Niagara 在两处都有)
- vsummary 总结后文件留在 Sources/Videos/ 无后续归档
- 77 个 frontmatter tag 已存在但未反向驱动文件夹分类
- 附件组 2536 个文件无类型子分
- Docs/AI/17 Self-Improving Framework 有框架但未与 Obsidian 闭环

### 1.2 根因
1. **没有自动分类管线**: vsummary 输出后无 hook 触发归档
2. **分类规则未文件化**: tag->目录映射只存在于 LLM 上下文中，无持久化规则
3. **知识没有价值评估**: 所有知识平等存储，未区分哪些对系统进化有帮助
4. **没有经验蒸馏**: 视频总结停留在"原始笔记"层面，未提取可迁移策略
5. **没有关联发现**: 笔记间隐含关联依赖手动 [[]] 链接

## 2. 成熟方案分析

### 2.1 本地知识库已有方案
| 方案 | 来源 | 核心机制 | 可借鉴点 |
|------|------|---------|---------|
| JIPA (Pareto Prompt Evolution) | JinliKG BV1c6LV67EvA | 多目标Pareto优化 + 六步流程 | 进化引擎算法骨架 |
| Autogenesis AGP/SPL | JinliKG BV1W27R63EmC | 五类资源注册 + SPL五步闭环 | 安全护栏 (资源不能自改自) |
| Self-Harness | JinliKG BV1B8Ju6gGEqT | 三阶段循环 (弱挖掘→最小修改→验证) | 最小化修改策略 |
| SkillOpt | JinliKG BV1mKEg69Evn | 技能文档当可训练参数 + 五步迭代 | Gene 格式 (300-2000 token) |
| Hermes 四层记忆 | JinliKG BV17KoFBBEqM | 工作→长期→轨迹→外部Provider | 三层记忆映射 |
| Hermes+LLM-Wiki+Obsidian | JinliKG BV16hZFB5ERM | 文档→AI整理→Wiki生成→双向链接 | vsummary→classify→evolve管线 |
| 自进化知识库 | JinliKG BV1iJEK6bE7h | 五层目录 + 画象机制 | 目录结构 + 个性化进化 |

### 2.2 外部开源方案
| 方案 | Stars | 核心机制 | 可借鉴点 |
|------|-------|---------|---------|
| EvoMap Evolver | 8.8k | GEP协议 + Gene/Capsule/Event + Proxy Mailbox | Gene概念 + Memory Graph + Narrative Memory |
| COG Second Brain | 567 | 17 Skills + knowledge-consolidation | 分类体系 + 知识合并 |
| llm-wiki-skills | 41 | 6 Skill (ingest/crystallize/integrate/lint/query/config) | 流水线设计 + 知识结晶概念 |
| obsidian-agent-memory-skills | 40 | 双向关系 + graph traversal + session orientation | Obsidian 原生集成 |
| arxiv 2603.24639 (ERL) | - | Experiential Reflective Learning + heuristic extraction | Heuristic > few-shot, selective retrieval |

## 3. 架构设计

### 3.1 三层记忆映射
`
Episodic (情景)  → JinliKG/Sources/     — 原始视频总结 (现有)
Semantic (语义)   → 知识/{领域}/{子类}/   — 分类后的知识 (升级)
Procedural (程序) → 进化/genes/           — 紧凑策略 Gene (新增)
`

### 3.2 JIPA-SPL 混合引擎
`
知识摄入 → 分类归档 → Pareto价值评估 → Gene提取(SPL-Reflect)
    → 候选筛选(SPL-Select) → 改进生成(SPL-Improve,最小化修改)
    → 验证(SPL-Evaluate,地域级测试) → 提交/回滚(SPL-Commit)
`

### 3.3 SPL 安全护栏
- Gene 不能修改 Gene
- 分类规则不能修改分类规则
- 进化提案不能直接执行，必须 Evaluate→Commit
- Commit 必须人工审批 (Ba Ba 的 growth_approve)

## 4. 文件变更清单

### 4.1 新增文件
| 文件 | 类型 | 说明 |
|------|------|------|
| skills/obsidian-autopoiesis/SKILL.md | Skill | 系统入口 |
| skills/obsidian-autopoiesis/status.yaml | Status | 工作流状态 |
| E:\ObsidianVault\进化\rules\classification-rules.yaml | Rules | 分类映射规则 |
| E:\ObsidianVault\进化\rules\evolution-rubric.yaml | Rules | 进化评分规则 |
| .trae/scripts/obsidian-classify.ps1 | Script | 自动分类归档 |
| .trae/scripts/obsidian-evolve.ps1 | Script | 知识价值分析 + Gene提取 |
| .trae/scripts/obsidian-link-discover.ps1 | Script | 关联发现 |
| .trae/scripts/obsidian-dream-reflect.ps1 | Script | 梦境反思 |
| .trae/scripts/obsidian-maintain.ps1 | Script | 自动维护 |

### 4.2 修改文件
| 文件 | 改动 | 说明 |
|------|------|------|
| skills/vsummary/SKILL.md | MODIFY | 添加 post-summarize hook 步骤 |
| skills/ai-workflow-registry/registry.yaml | MODIFY | 注册 obsidian-autopoiesis |

### 4.3 不变文件
- 所有 JinliKG/ 现有文件
- 知识/ 和 虚幻/ 现有文件
- vsummary 核心 pipeline 代码
- Docs/AI/ 文档
- Soul Core MCP 配置
- 现有 40+ Skill

## 5. 风险分析

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 分类规则覆盖不全 | 中 | 低 | 自修复机制 + 待分类队列 |
| LLM 评分不稳定 | 中 | 低 | Pareto 多目标 + 阈值 0.6 滤波 |
| Gene 提取质量低 | 低 | 中 | 人工审批 + SPL-Commit |
| 关联发现噪声高 | 中 | 低 | DryRun 默认 + 阈值调优 |
| vsummary hook 阻塞主流程 | 低 | 高 | 异步调用 + 超时保护 |

## 6. 实现顺序

WP01 (基础设施) → WP02 (分类) → WP07 (vsummary集成) → WP03 (进化) → WP04 (关联) → WP05 (梦境) → WP06 (维护) → WP08 (注册验证)
