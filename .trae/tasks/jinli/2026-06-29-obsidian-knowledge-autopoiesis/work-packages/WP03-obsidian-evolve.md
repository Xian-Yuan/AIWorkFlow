# WP03: obsidian-evolve.ps1 �?知识价值分�?+ Gene 提取

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile

- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget

Read only this package and the files listed under Read First.

## Root Cause Boundary

- Root Cause ID: RC02-no-value-evaluation-no-gene-extraction
- This package handles the Pareto 4-dim scoring + Gene YAML distillation.
- Scope: score notes, extract Genes, write to `进化/genes/`.
- Out of scope: classify (WP02), link discover (WP04), dream reflect (WP05), maintain (WP06).

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/`
- Parent task: `2026-06-29-obsidian-knowledge-autopoiesis`
- Spec reference: `spec.md` �?AC03, AC04
- Tasks reference: `tasks.md` �?T03.1-T03.6

## Allowed Paths

- `.trae/scripts/obsidian-evolve.ps1` (new)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (append if not present; read OK)

## Forbidden Paths

- All task packet files (`.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md`, `work-packages/**`, `reports/**`)
- `E:\ObsidianVault\JinliKG\**` (read OK, NEVER modify)
- `E:\ObsidianVault\虚幻\**`, `E:\ObsidianVault\我的项目\**` (read OK, NEVER modify)
- `E:\ObsidianVault\知识\**` (read OK; Gene write OK to `进化/genes/`)
- `skills/obsidian-autopoiesis/**` (WP01)
- `skills/vsummary/**` (WP07)
- `skills/ai-workflow-registry/**` (WP08)
- `Docs/AI/**`, `Docs/Memory/**`
- `Project/**`

## Read First

- `routing.md` (D2, D3)
- `analysis.md` (Mature Solution Evidence: JIPA / SPL / SkillOpt)
- `spec.md` (GIVEN / WHEN �?Gene Extraction; AC03, AC04)
- `tasks.md` (WP03)
- `E:\ObsidianVault\进化\rules\evolution-rubric.yaml` (created by WP01; if missing, fail with clear message)

## Goal

Implement `obsidian-evolve.ps1` that:
1. `-Analyze -Source `file``: scores a single note on 4 dimensions (system-enhance / code-quality / automation / self-evolve), each 0-1, outputs JSON.
2. `-ExtractGene -Source `file``: when mean(Pareto) >= 0.6, extracts Gene YAML (300-2000 token bound) to `E:\ObsidianVault\进化\genes\gene-YYYYMMDD-NNN.yaml`.
3. `-Batch -SourceDir `dir``: iterates and produces `proposals/evolve-report-YYYYMMDD-HHMMSS.json`.
4. `-DryRun`: prints plan only, no writes.
5. Scoring rules driven by `evolution-rubric.yaml` (regex-keyword + length + tag presence signals); LLM call is OPTIONAL and behind `-UseLLM` switch.
6. Gene dedup: by `gene_id` hash of `(domain, trigger)`. Already-existing Gene with same id is skipped, not overwritten.
7. SPL-Reflect: each Gene is logged in `进化/proposals/` with timestamp + source path before write.

## Steps

- [ ] T03.1: Create `.trae/scripts/obsidian-evolve.ps1` with param block: `-Source `path``, `-SourceDir `dir``, `-Analyze`, `-ExtractGene`, `-Apply`, `-DryRun`, `-UseLLM`, `-Help`.
- [ ] T03.2: Implement rubric loader: parse `evolution-rubric.yaml` (4-dim block: `system-enhance:`, `code-quality:`, etc. each with `keywords:` and `weight:`).
- [ ] T03.3: Implement 4-dim scoring: for each dim, count keyword matches, normalize to 0-1 via sigmoid-or-linear (rubric-configurable). Output JSON: `{system-enhance: 0.X, code-quality: 0.X, automation: 0.X, self-evolve: 0.X, mean: 0.X, eligible: bool}`.
- [ ] T03.4: Implement Gene extraction: if `mean >= 0.6`, extract `gene_id` (sha1 of `domain + ":" + trigger` first 8 chars), `domain` (from frontmatter `domain_path` or classified dir), `trigger` (LLM-free: first H1 + first paragraph sentence; LLM path: structured call), `strategy` (1-3 sentences), `evidence` (list of source paths), `pareto_scores` (the JSON above), `origin` (`{source: `path`, ts: `iso`, agent: obsidian-evolve.ps1}`), `size_tokens` (computed).
- [ ] T03.5: Token-size check: `gene.size_tokens` must be 300-2000. If outside, log warning and adjust `strategy` truncation; if cannot fit, skip and log to `proposals/`.
- [ ] T03.6: Write Gene YAML to `E:\ObsidianVault\进化\genes\gene-YYYYMMDD-NNN.yaml` (NNN is 3-digit zero-padded sequence for that day).
- [ ] T03.7: Dedup check: scan existing `进化/genes/*.yaml`, parse `gene_id`, skip if duplicate.
- [ ] T03.8: SPL-Reflect: write `proposals/reflect-YYYYMMDD-HHMMSS.yaml` listing considered notes + scores + decisions.
- [ ] T03.9: Self-test mode: `-SelfTest` runs against a fixture file with known keywords, asserts Pareto scores fall in expected ranges.
- [ ] T03.10: Verify AC03 and AC04.

## Done Definition

- `.\.trae\scripts\obsidian-evolve.ps1 -Analyze -Source "`test.md`"` prints valid JSON with 4 keys + `mean` + `eligible`, exits 0.
- `.\.trae\scripts\obsidian-evolve.ps1 -ExtractGene -Source "`high-value.md`"` writes a YAML file under `进化/genes/`, exits 0.
- `.\.trae\scripts\obsidian-evolve.ps1 -ExtractGene -Source "`low-value.md`"` (mean < 0.6) prints "skip: not eligible" and exits 0 without writing.
- All generated Gene YAMLs are valid YAML and 300-2000 tokens.
- `.\.trae\scripts\obsidian-evolve.ps1 -SelfTest` exits 0.
- No file outside Allowed Paths is modified.

## Required Verification

| Step | Command | Expected |
|------|---------|----------|
| 1 | `.\.trae\scripts\obsidian-evolve.ps1 -Help` | Help text, exit 0 |
| 2 | `.\.trae\scripts\obsidian-evolve.ps1 -Analyze -Source "`test fixture`"` | JSON with 6 keys, exit 0 |
| 3 | `.\.trae\scripts\obsidian-evolve.ps1 -ExtractGene -Source "`high-value test fixture`"` | gene-*.yaml written, size 300-2000 tokens, exit 0 |
| 4 | `python -c "import yaml; yaml.safe_load(open(r'`created gene`.yaml'))"` | exit 0 |
| 5 | `.\.trae\scripts\obsidian-evolve.ps1 -SelfTest` | exit 0 |
| 6 | AC03/AC04 evidence in `reports/obsidian-evolve-WP03-AC03-AC04.log` | files exist with required content |

## Do Not Game The Gate

- Do not skip the 300-2000 token bound by padding with filler.
- Do not lower the 0.6 threshold to make everything eligible.
- Do not use LLM by default �?must be explicit `-UseLLM` switch.
- Do not silently drop ineligible notes �?must log to `proposals/`.
- Do not allow Gene to overwrite an existing Gene with same `gene_id` �?must skip + log.

## Stop Conditions

- Stop if `evolution-rubric.yaml` does not exist (WP01 must complete first).
- Stop if a required path is outside Allowed Paths.
- Stop if LLM call is requested but no LLM endpoint configured �?fail with clear error.

## Return Report

- Path: `reports/obsidian-evolve-WP03-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, sample Gene YAML printed, AC03/AC04 evidence, scope control, unresolved risks, and `Extra scope taken: no`.
