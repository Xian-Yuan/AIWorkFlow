# Tasks: Obsidian Knowledge Autopoiesis

## Dependency Graph

`
WP01 (Skill+Rules) ──┬──> WP02 (classify) ──┬──> WP07 (vsummary hook)
                       │                      ├──> WP03 (evolve)
                       │                      ├──> WP04 (link-discover)
                       │                      ├──> WP05 (dream-reflect)
                       │                      └──> WP06 (maintain)
                       └──> WP08 (registry + verify)
`

---

## WP01: Skill + Classification Rules + Evolution Rubric

- [ ] T01.1: 创建 skills/obsidian-autopoiesis/SKILL.md，定义整个系统的入口、触发条件、环境前提、核心工作流
- [ ] T01.2: 创建 E:\ObsidianVault\进化\rules\classification-rules.yaml，定义 tag -> 目标目录映射规则
- [ ] T01.3: 创建 E:\ObsidianVault\进化\rules\evolution-rubric.yaml，定义 Pareto 四维评分标准和 Gene 提取阈值
- [ ] T01.4: 创建 E:\ObsidianVault\进化\genes\.gitkeep
- [ ] T01.5: 创建 E:\ObsidianVault\进化\proposals\.gitkeep
- [ ] T01.6: 创建 E:\ObsidianVault\进化\dreams\.gitkeep
- [ ] T01.7: 创建 E:\ObsidianVault\进化\enacted\.gitkeep
- [ ] T01.8: 验证 classification-rules.yaml 覆盖当前 77 个 tag 中的 top 20 (覆盖 90%+ 文件)

## WP02: obsidian-classify.ps1 (自动分类归档)

- [ ] T02.1: 创建 .trae/scripts/obsidian-classify.ps1，支持参数: -Source, -DryRun, -RulesPath, -VaultPath
- [ ] T02.2: 实现分类逻辑: 读取 frontmatter tag + domain_path -> 查 classification-rules.yaml -> 确定目标路径
- [ ] T02.3: 实现移动逻辑: Move-Item + 在原位置创建 wikilink 重定向文件
- [ ] T02.4: 实现 kg_id 去重: 如果目标位置已存在同 kg_id 的文件，跳过 (幂等)
- [ ] T02.5: 支持批量模式: -Batch 参数扫描整个 Sources/Videos/ 目录
- [ ] T02.6: 输出分类报告: 移动了多少、跳过了多少、无法分类的有多少
- [ ] T02.7: 无法分类的文件加入 进化/rules/_unclassified-queue.yaml 供后续规则补充
- [ ] T02.8: 验证 AC01, AC02

## WP03: obsidian-evolve.ps1 (知识价值分析 + Gene 提取)

- [ ] T03.1: 创建 .trae/scripts/obsidian-evolve.ps1，支持参数: -Analyze, -ExtractGene, -Source, -DryRun
- [ ] T03.2: 实现 Pareto 四维评分 (system-enhance, code-quality, automation, self-evolve)
  - 评分基于 LLM 分析内容 + 已有系统文档对比 (Docs/AI/, skills/, .trae/scripts/)
  - 输出 JSON: {system-enhance: 0.8, code-quality: 0.3, automation: 0.7, self-evolve: 0.9}
- [ ] T03.3: 实现 Gene 提取: Pareto 均分 >0.6 时进入提取
  - 提取 trigger, strategy, evidence, pareto_scores
  - Gene 大小约束 300-2000 token
  - 写入 进化/genes/gene-YYYY-MMDD-NNN.yaml
- [ ] T03.4: 实现 Gene 去重: 检查已有 Gene 的 trigger + domain 是否重复
- [ ] T03.5: 实现批量模式: -Batch 扫描整个 知识/ 目录
- [ ] T03.6: 验证 AC03, AC04

## WP04: obsidian-link-discover.ps1 (关联发现)

- [ ] T04.1: 创建 .trae/scripts/obsidian-link-discover.ps1，支持参数: -Method, -DryRun, -VaultPath
- [ ] T04.2: 实现 Tag 共现关联: 读取所有 md 的 frontmatter tag，计算 Jaccard 相似度 >0.6 的笔记对
- [ ] T04.3: 实现 LLM 语义关联: 对同 domain 下笔记做内容摘要对比 (批量调用，可配置 LLM provider)
- [ ] T04.4: 实现进化关联: 扫描 Gene trigger 关键词匹配笔记标题/内容
- [ ] T04.5: 输出关联建议列表，-DryRun 只输出不写入；非 DryRun 模式在笔记末尾 ## Related 区块添加 [[]]
- [ ] T04.6: 关联去重: 不重复添加已有的 [[]] 链接
- [ ] T04.7: 验证 AC05

## WP05: obsidian-dream-reflect.ps1 (梦境反思)

- [ ] T05.1: 创建 .trae/scripts/obsidian-dream-reflect.ps1，支持参数: -FullScan, -QuickScan, -OutputPath
- [ ] T05.2: 实现 Gene 使用率扫描: 读取所有 Gene 的 last_used 和 use_count
- [ ] T05.3: 实现知识缺口发现: 对比系统目录 (skills/, Docs/AI/, .trae/scripts/) 的覆盖 vs JinliKG 中标记为 ctionable: True 的知识
- [ ] T05.4: 实现过期提案清理: 30天未审批降级为"参考"
- [ ] T05.5: 实现衰减标记: 6个月未引用标记 dormant，1年建议归档
- [ ] T05.6: 生成 进化/dreams/dream-report-YYYY-MM-DD.md，格式: 缺口列表 + 未使用 Gene + 衰减建议 + 联网搜索建议
- [ ] T05.7: 验证 AC06

## WP06: obsidian-maintain.ps1 (自动维护)

- [ ] T06.1: 创建 .trae/scripts/obsidian-maintain.ps1，支持参数: -DetectDuplicates, -CleanEmptyDirs, -RuleSelfHeal, -GeneDecay
- [ ] T06.2: 实现重复检测: tag 集合 + 标题相似度 >90% 的笔记对
- [ ] T06.3: 实现空文件夹清理: 0 文件超 7 天的目录删除
- [ ] T06.4: 实现分类规则自修复: 读取 _unclassified-queue.yaml，连续 5 次同类文件匹配不到规则 -> 生成候选规则
- [ ] T06.5: 实现 Gene 衰减: use_count=0 超 90 天标记 dormant; 180 天建议归档
- [ ] T06.6: 验证 AC07

## WP07: vsummary Post-Summarize Hook 集成

- [ ] T07.1: 修改 skills/vsummary/SKILL.md，在总结完成后增加调用 obsidian-classify.ps1 -Batch 的步骤
- [ ] T07.2: 在 vsummary 工作流末尾添加: classify -> evolve -> link-discover 链式调用
- [ ] T07.3: 确保 hook 幂等: 同一 kg_id 不重复分类
- [ ] T07.4: 验证 AC08

## WP08: ai-workflow-registry 注册 + 验证

- [ ] T08.1: 创建 skills/obsidian-autopoiesis/status.yaml，记录工作流状态
- [ ] T08.2: 在 skills/ai-workflow-registry/registry.yaml 注册 obsidian-autopoiesis 工作流
- [ ] T08.3: 运行 python .trae/scripts/sync-workflow-registry.py 同步
- [ ] T08.4: 端到端验证: 运行完整流水线 classify -> evolve -> link-discover -> dream-reflect -> maintain
- [ ] T08.5: 运行 .\.trae\scripts\verify.ps1 并记录输出到 erification-report.md

## Final Verification

### Acceptance Criteria mapping
- [ ] TF01: AC01-AC08 all PASS — 映射见 spec.md 与 analysis.md "Acceptance Criteria" 表
- [ ] TF02: Verify 现有 JinliKG 文件未被修改或删除 (零破坏性, D1)
- [ ] TF03: Verify vsummary 现有功能不受影响 (post-hook 幂等)
- [ ] TF04: Verify Soul Core soul_learn/soul_memory 不受影响
- [ ] TF05: Run .\.trae\scripts\task-guard.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify 通过

### Automated verification
- [ ] TA01: 每 WP 完成后跑该 WP 的 dry-run/self-test 命令,记录到 verification-report.md
- [ ] TA02: WP08 端到端流水线测试: classify -> evolve -> link-discover -> dream-reflect -> maintain
- [ ] TA03: `python .trae/scripts/sync-workflow-registry.py` 退出 0
- [ ] TA04: `contract-verify.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify -Strict` 退出 0

### Mature path verification
- [ ] TM01: Verify selected mature path was implemented and no rejected shortcut was introduced — 对照 analysis.md "Selected mature path" 和 "Rejected shortcuts" 列表,逐项确认
  - [ ] TM01a: classification-rules.yaml 已创建(D2 evidence: SkillOpt)
  - [ ] TM01b: evolution-rubric.yaml 含 Pareto 4 维 + threshold 0.6(D3 evidence: JIPA)
  - [ ] TM01c: SPL 护栏在 scripts 中显式实现(D3 evidence: AGP/SPL)
  - [ ] TM01d: Gene YAML 输出 300-2000 token 校验(D2)
  - [ ] TM01e: 旧文件未移动、未修改(D1)
  - [ ] TM01f: 原位置有 wikilink 重定向(避免 GraphView 断裂)
  - [ ] TM01g: vsummary post-hook 幂等(同 kg_id 不重复分类)
  - [ ] TM01h: 未使用"GPT 全量分类"捷径 — 用 classification-rules.yaml 查表
  - [ ] TM01i: 未使用"长 markdown Gene"捷径 — 用 300-2000 token YAML
  - [ ] TM01j: 未使用"tag-only"或"LLM-only"单一关联 — 双层混合(D4)

## Phase 4: Intrinsic Metacognitive Learning Layer (COMPLETED 2026-06-30)

- [x] obsidian-metacognitive.ps1 - Three-component intrinsic metacognition
  - [x] Assess: capability map + dynamic evaluation criteria (not fixed Pareto)
  - [x] Plan: learning priorities from gaps + past success patterns
  - [x] Reflect: expected vs actual outcomes, persistent lessons-learned
  - [x] Self-test passes (PS5.1 compatible, all ASCII identifiers)
  - [x] Real vault execution: 12/12 capabilities, 6 past outcomes, dynamic criteria generated
- [x] Integration: dynamic-criteria.yaml sits ON the SPL decision pathway
  - [x] Run-SPLReflect reads dynamic criteria for direction scoring
  - [x] Run-SPLSelect uses dynamic weights instead of fixed 0.2/0.3
  - [x] Run-SPLImprove uses ASCII direction aliases (intelligence, automation, self_evolve, etc.)
- [x] Integration: learning-plan.yaml feeds into obsidian-self-improve.ps1
  - [x] Read-LearningPlan function added
  - [x] Direction alignment with learning plan focus logged
- [x] End-to-end verified: metacognitive -> SPL cycle -> self-improve all pass

### Key Architecture Decision (Self-Monitoring Paper Insight)
Metacognition sits ON the decision pathway, not beside it.
dynamic-criteria.yaml is the integration point - SPL reads it and uses
the weights/thresholds directly. No "side module that generates reports
nobody reads."

### Data Files Generated
- `E:\ObsidianVault\metacognitive\capability-map.yaml` - 12 capabilities, 0 gaps
- `E:\ObsidianVault\metacognitive\dynamic-criteria.yaml` - weights + threshold (adapted from 6 outcomes)
- `E:\ObsidianVault\metacognitive\learning-plan.yaml` - focus directions + priorities
- `E:\ObsidianVault\metacognitive\lessons-learned.yaml` - persistent lessons
- `E:\ObsidianVault\metacognitive\reflection-*.yaml` - timestamped reflection snapshots