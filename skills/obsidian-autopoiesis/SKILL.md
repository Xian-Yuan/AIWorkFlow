---
name: obsidian-autopoiesis
version: 1.0.0
description: "Self-organizing Obsidian knowledge autopoiesis system. Classifies video summaries into 知识/, extracts compact Gene YAMLs to 进化/genes/, discovers cross-note associations, runs weekly dream-reflection, and self-maintains the vault. Hooked into vsummary post-summarize step."
trigger: user mentions Obsidian 整理、自动分类、视频总结归档、梦境反思、自我进化、Gene 提取、JIPA-SPL、关联发现、knowledge autopoiesis
authority: issuer-worker-v1
related_design_doc: Docs/AI/17-Self-Improving-Framework.md
task_packet: .trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis
---

# Obsidian Knowledge Autopoiesis

## Purpose

Closes the loop between vsummary pipeline and Obsidian vault. Without this system, every new video summary lands in `JinliKG/Sources/Videos/` and never moves — the vault grows stale, GraphView edges stay shallow, and high-value knowledge is never distilled into reusable strategy. This skill turns the vault into a self-organizing second brain:

- **Episodic layer** → `JinliKG/Sources/Videos/` (raw video summaries, existing)
- **Semantic layer** → `知识/{领域}/{子类}/` (classified knowledge, new files only)
- **Procedural layer** → `进化/genes/gene-*.yaml` (compact 300-2000 token strategies, distilled from high-value notes)

## Environment Prerequisites

| Component | Location |
|-----------|----------|
| PowerShell | 5.1 (Windows PowerShell) — no PS7-only syntax |
| Obsidian vault | `E:\ObsidianVault` |
| Classification rules | `E:\ObsidianVault\进化\rules\classification-rules.yaml` |
| Evolution rubric | `E:\ObsidianVault\进化\rules\evolution-rubric.yaml` |
| Scripts root | `.trae/scripts/obsidian-*.ps1` |
| Shared helpers | `.trae/scripts/_shared/ObsidianHelpers.psm1` |
| vsummary post-hook | `skills/vsummary/SKILL.md` (this skill is the integration point) |

No external modules. No Python. No LLM endpoint by default (LLM call is gated by `-UseLLM`).

## Core Workflow

### 1. Classify (WP02)

```powershell
.\.trae\scripts\obsidian-classify.ps1 -DryRun -Source "<file>.md"
.\.trae\scripts\obsidian-classify.ps1 -Batch -DryRun -SourceDir "E:\ObsidianVault\JinliKG\Sources\Videos"
.\.trae\scripts\obsidian-classify.ps1 -Batch -Apply
```

Reads frontmatter `tag` + `domain_path`, looks up `classification-rules.yaml`, moves the file to `知识/{target}/`, leaves a 1-line `[[target-path]]` redirect stub at the old position so Obsidian GraphView edges survive. Idempotent: same `kg_id` already at target = skip. Unclassified files appended to `进化/rules/_unclassified-queue.yaml` (created on demand).

### 2. Evolve (WP03)

```powershell
.\.trae\scripts\obsidian-evolve.ps1 -Analyze -Source "<file>.md"            # 4-dim Pareto score
.\.trae\scripts\obsidian-evolve.ps1 -ExtractGene -Source "<file>.md"         # writes gene-*.yaml if mean >= 0.6
.\.trae\scripts\obsidian-evolve.ps1 -Batch -SourceDir "E:\ObsidianVault\知识"  # bulk
```

Four-dimension scoring (system-enhance / code-quality / automation / self-evolve) driven by `evolution-rubric.yaml` keyword + weight schema. Gene YAML output 300-2000 tokens (SkillOpt empirical bound, D2). Dedup by `gene_id = sha1(domain:trigger)[0..7]`. `-UseLLM` switch enables LLM-driven trigger/strategy generation; off by default to keep cost + determinism.

### 3. Link discover (WP04)

```powershell
.\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun
.\.trae\scripts\obsidian-link-discover.ps1 -Method all -Apply -SourceDir "E:\ObsidianVault\知识"
```

Three layers (D4): tag co-occurrence (Jaccard > 0.6, default), LLM semantic (gated by `-UseLLM`, threshold 0.7), gene-trigger substring match. Apply mode appends `## Related` block at end of file; idempotent on existing `[[]]` links.

### 4. Dream reflect (WP05)

```powershell
.\.trae\scripts\obsidian-dream-reflect.ps1 -QuickScan                       # 1-page Gene usage
.\.trae\scripts\obsidian-dream-reflect.ps1 -FullScan                        # full gap analysis
```

Writes `进化/dreams/dream-report-YYYY-MM-DD.md` with four sections: Gene usage stats, knowledge gap list (system Skill/Doc coverage vs `actionable: true` notes), stale proposals (>30d unapproved), dormant notes (>6m un-referenced), recommended actions. **SUGGESTIONS ONLY** — no auto-archive, no auto-approve.

### 5. Maintain (WP06)

```powershell
.\.trae\scripts\obsidian-maintain.ps1 -DetectDuplicates                    # tag Jaccard + title sim > 0.9
.\.trae\scripts\obsidian-maintain.ps1 -CleanEmptyDirs -DryRun              # 0 files & >7d old
.\.trae\scripts\obsidian-maintain.ps1 -RuleSelfHeal                        # suggest new rules from queue
.\.trae\scripts\obsidian-maintain.ps1 -GeneDecay                           # flag dormant / archive-suggest
```

All destructive actions require explicit `-Apply`; default is `-DryRun` report. Never auto-merges, never auto-archives (SPL safety + user-data safety).

### 6. vsummary post-summarize hook (WP07)

After vsummary finishes a summary, the post-hook chain fires:

```
vsummary  ->  classify (batch on JinliKG/Sources/Videos/)
          ->  evolve  (extract Gene for new classified file)
          ->  link-discover (add Related block)
```

Idempotency: each script checks `kg_id` before re-classifying / re-extracting.

## Safety Guardrails (D1, D3, D7, D8)

| Guard | Implementation |
|-------|----------------|
| D1 zero-destructive | Old files in `JinliKG/`, `虚幻/`, `我的项目/` are NEVER modified or moved. Only new files (post-deploy) follow new rules. |
| D1 redirect stub | Every `Move-Item` writes a 1-line `[[target-path]]` stub at the old position so Obsidian GraphView edges survive. |
| D3 SPL | Gene cannot modify Gene. classification-rules cannot modify itself. Every proposal must pass SPL-Evaluate before SPL-Commit. SPL-Commit requires Ba Ba's `growth_approve`. |
| D3 JIPA | 4-dim Pareto scoring with 0.6 mean threshold. No single-dim shortcut. |
| D7 -Apply | All destructive operations default to `-DryRun`; `-Apply` is explicit opt-in. |
| D8 authority | Workers operate on signed capability `obsidian-autopoiesis-<wp>`. Only the original Issuer signs Review / Verify / Archive. Workers cannot edit task packet / registry / vsummary SKILL.md. |

## Status Auto-Update

Each script writes JSON report to `进化/proposals/<script>-report-YYYYMMDD-HHMMSS.json`. The Skill's `status.yaml` is updated by WP08 final verification step.

## Related Skills

- `vsummary` — upstream producer of source `.md` files; WP07 modifies its SKILL.md to add the post-hook
- `ai-workflow-registry` — discovery + registration system; this workflow is registered at WP08
- `failure-memory` — review/verify failures get recorded as Memory Candidates

## Verification

Run the 8 Acceptance Criteria from `spec.md`. Final gate is `.\.trae\scripts\task-guard.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify` exit 0 + `verification-report.md` listing AC01-AC08 with PASS evidence.

## Pitfall List

| Pitfall | Mitigation |
|---------|-----------|
| Move-Item on same drive OK; cross-drive needs explicit `Move-Item -LiteralPath` | All targets on `E:` drive, no cross-drive concern |
| PowerShell 5.1 `ConvertFrom-Yaml` is not built-in | Custom regex parser in `_shared/ObsidianHelpers.psm1` |
| LLM endpoint not configured | LLM call is opt-in via `-UseLLM`; off by default |
| Re-classification of existing 571 files | D1 forbids it; new files (post-deploy) only |
| Gene pool explosion | 0.6 mean threshold + `gene_id` dedup + SPL-Commit gate |
| Dream report auto-archives anything | Hardcoded SUGGESTIONS-ONLY output; no `Move-Item`, no `Remove-Item` |
| Worker mutates task packet | Authority Profile: issuer-worker-v1 + runtime daemon + Memory Gate block |

## Sub-Skill Activation

This Skill is the entry point. Concrete implementer skills are loaded on demand:
- `ue-engineer` / `web-engineer` — NOT loaded; this task is `jinli` automation, not UE/Web
- `tool-engineer` — for the PowerShell 5.1 + Windows filesystem patterns
- `code-simplifier` — for review-stage cleanup

## Owner

- Skill design: 金璃小天才 (Plan Agent) — WP01
- Scripts: 金璃好帮手 (Implement Agent) — WP02-WP06
- vsummary hook: 金璃小天才 (Plan Agent) — WP07
- Registry + verify: 金璃小天才 (Plan Agent) — WP08
- Final approval: Ba Ba via `growth_approve` (D8)

## Intrinsic Metacognitive Learning Layer

### Purpose
Implements arxiv 2506.05109: "Truly Self-Improving Agents Require Intrinsic Metacognitive Learning"
Key insight from Self-Monitoring paper: metacognition must sit ON the decision pathway, not beside it.

### Script: `obsidian-metacognitive.ps1`
Three components working as a cycle:
1. **Assess** (Metacognitive Knowledge) - Build capability map, generate DYNAMIC evaluation criteria
2. **Plan** (Metacognitive Planning) - Derive learning priorities from gaps + past patterns
3. **Reflect** (Metacognitive Evaluation) - Compare expected vs actual, update lessons-learned

### Integration Point: `dynamic-criteria.yaml`
The SPL cycle reads this file directly. When metacognitive assess adjusts weights/thresholds,
the next SPL cycle automatically uses the new values. This is the "sits on the decision pathway"
design - metacognition directly modifies SPL parameters, not just generates reports.

### Data Files (in `<vault>/metacognitive/`)
| File | Purpose |
|------|---------|
| `capability-map.yaml` | Which capabilities exist, which are gaps |
| `dynamic-criteria.yaml` | Weights + threshold for SPL scoring (the integration point) |
| `learning-plan.yaml` | Focus directions + priorities for self-improve |
| `lessons-learned.yaml` | Persistent lessons from past evolution outcomes |
| `reflection-*.yaml` | Timestamped reflection snapshots |

### Usage
```powershell
# Run full metacognitive cycle (assess + plan + reflect)
.\obsidian-metacognitive.ps1 -FullMeta -Apply

# Run individual component
.\obsidian-metacognitive.ps1 -Assess -Apply
.\obsidian-metacognitive.ps1 -Plan -Apply
.\obsidian-metacognitive.ps1 -Reflect -Apply

# Self-test
.\obsidian-metacognitive.ps1 -SelfTest
```

### Direction Identifiers (ASCII for PS5.1 compatibility)
| Internal ID | Display Name | SPL Use |
|-------------|-------------|---------|
| `intelligence` | intelligence | Knowledge/routing improvement |
| `automation` | automation | Workflow automation |
| `self_evolve` | self_evolve | Self-improvement cycle |
| `memory` | memory | Memory system enhancement |
| `humanize` | humanize | Interaction quality |