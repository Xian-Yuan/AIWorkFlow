# Routing Decision - jinli/2026-06-29-obsidian-knowledge-autopoiesis

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> Related design docs: Docs/AI/17-Self-Improving-Framework.md, Docs/AI/12-MultiAgent-Workflow.md
> Related task packages: T7 (Dreamer), T8 (Evolution), vsummary workflow
> Authority Profile: issuer-worker-v1

## Authority Policy

- Authority profile: issuer-worker-v1
- Packet mutation authority: issuer only
- Review authority: original issuer only
- Verify authority: original issuer only
- Archive authority: original issuer only
- Verify auto-archive: forbidden

> **Enforcement**: Only the original Issuer SID/key may sign Review, Verify-publish, Repair-publish, and explicit Archive. Workers (DS4-Flash or any subagent) operate on a signed capability `obsidian-autopoiesis-<wp>` and may only call `worker-submit.ps1`. Workers must NOT edit routing.md / spec.md / analysis.md / .task.yaml / registry.yaml. The runtime daemon + Memory Gate block unauthorized transitions. See `Docs/AI/41-Issuer-Worker-Authority-Separation.md` for the full contract.

## Work Package Policy

- External workers: yes
- Worker-eligible WPs: WP02, WP03, WP04, WP05, WP06 (script implementation + self-test)
- Issuer-only WPs: WP01 (Skill + rules YAMLs — design artifacts), WP07 (vsummary SKILL.md modification — coupled to other workflows), WP08 (registry + final verify — system-wide impact)
- Self-contained completeness: each WP must be a complete deliverable. No progressive stubs ("Phase A 止血 + Phase B 加固" pattern is forbidden). If a WP cannot be fully implemented in one pass, it must be re-scoped, not downgraded.
- Quality level: mature production-grade. MVP/prototype requested by user: no. No Quality Exception.

## Project Detection

| Signal | Value |
|--------|-------|
| User mention keywords | Obsidian 整理、自动分类、视频总结归档、梦境反思、自我进化、Gene格式、JIPA-SPL、关联发现 |
| File path prefix | E:\ObsidianVault\ + skills\vsummary\ + skills\obsidian-autopoiesis\ + .trae\scripts\ |
| Primary skill involved | 金璃好帮手 (Implement 阶段)；Plan 阶段由 金璃小天才 完成 |
| project_type | **other** (Obsidian vault + PowerShell scripts, 非 UE5 / Web) |
| Mature-solution category | **Mature** — JIPA (ICLR 2026 ORAL), Autogenesis AGP/SPL, SkillOpt (微软), EvoMap Evolver (8.8k stars) 均有生产验证 |

## Primary Skill Selection

| Decision | Rationale |
|----------|-----------|
| **Primary Skill** | 金璃好帮手 — Implement 阶段全权负责编码、测试、重复检测、spec 自检 |
| **Plan Skill** | 金璃小天才 — 需求澄清、设计文档索引、隐性需求推导、任务拆分和 spec 生成 |
| **Companion Skill** | web-engineer — YAML 规则文件 + PowerShell 脚本实现 |
| **Reference Reading** | daughter-companion — 此任务改变 Obsidian 知识库结构，需注意 Ba Ba 的使用体验 |
| **NOT Loaded** | UE5 / Mobile skill（与本任务无关） |

## Architecture Decision

**Single-agent (Plan) -> Sequential-WP (Implement)**

```
WP01 Skill+Rules ─┬─> WP02 classify ─┬─> WP07 vsummary hook
                   │                  ├─> WP03 evolve
                   │                  ├─> WP04 link-discover
                   │                  ├─> WP05 dream-reflect
                   │                  └─> WP06 maintain
                   └─> WP08 registry + verification
```

**改动面**: 新增 6 文件 (scripts) + 1 Skill + 2 YAML rules + 1 registry entry + 1 vsummary Skill 修改

**不变面**: 所有现有 JinliKG 文件、知识/虚幻/我的项目 目录内容、vsummary 核心代码、Docs/AI/ 文档

## Key Design Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | 新文件按统一规则归档，旧文件不动 | 零风险升级，Obsidian [[]] 链接保持有效 |
| D2 | Gene YAML 格式 (300-2000 token) | SkillOpt 论文验证：紧凑策略 > 长 markdown |
| D3 | JIPA-SPL 混合进化引擎 | JIPA 多目标 Pareto + SPL 安全闭环 |
| D4 | Tag共现 + LLM 语义关联发现 | 轻量级 + 精准度平衡 |

## Quality Gate

- **Quality level default**: mature production-grade
- **MVP/prototype requested by user**: no
- **Quality Exception**: none
- **Minimum acceptance per WP**:
  - All scripted commands must be self-testable (each script has at least one `-SelfTest` or dry-run path)
  - All AC (AC01-AC08) must be reproducible via documented command
  - No TODOs / placeholder logic in shipped scripts
  - Gene YAML output must be valid YAML and within 300-2000 token size constraint
  - Zero file destruction: existing JinliKG / 知识 / 虚幻 / 我的项目 content must be byte-identical post-run
  - vsummary post-hook must be idempotent (same kg_id processed twice = same state)
- **Verification gate**: `.\.trae\scripts\task-guard.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify` must exit 0; `verification-report.md` must list all 8 ACs with PASS/FAIL evidence
- **Mature path verification**: tasks.md contains explicit "Verify selected mature path was implemented and no rejected shortcut was introduced" task (see T08.4-T08.5)
