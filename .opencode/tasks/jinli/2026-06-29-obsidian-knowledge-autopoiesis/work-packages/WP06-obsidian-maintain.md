# WP06: obsidian-maintain.ps1 �?自动维护

Owner model: unclaimed
Difficulty: medium
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

- Root Cause ID: RC05-no-auto-maintenance
- This package handles duplicate detection, empty-dir cleanup, rule self-heal, Gene decay.
- Scope: detect and report / soft-clean; no auto-destructive operations.
- Out of scope: classify (WP02), evolve (WP03), link (WP04), dream (WP05).

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/`
- Parent task: `2026-06-29-obsidian-knowledge-autopoiesis`
- Spec reference: `spec.md` �?AC07
- Tasks reference: `tasks.md` �?T06.1-T06.6

## Allowed Paths

- `.trae/scripts/obsidian-maintain.ps1` (new)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (append or read)
- `E:\ObsidianVault\**` (read + write to `进化/proposals/` only; non-destructive cleanup restricted to empty dirs under `知识/`)

## Forbidden Paths

- All task packet files (`.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md`, `work-packages/**`, `reports/**`)
- `E:\ObsidianVault\JinliKG\**` (D1 �?never modify or delete)
- `E:\ObsidianVault\虚幻\**`, `E:\ObsidianVault\我的项目\**` (D1 �?never modify or delete)
- `E:\ObsidianVault\知识\**` (read OK; soft-clean empty dirs OK; never auto-merge duplicates �?only report)
- `E:\ObsidianVault\进化\genes\**` (read OK, NEVER auto-delete �?only flag)
- `skills/obsidian-autopoiesis/**` (WP01)
- `skills/vsummary/**` (WP07)
- `skills/ai-workflow-registry/**` (WP08)
- `Docs/AI/**`, `Docs/Memory/**`
- `Project/**`

## Read First

- `routing.md` (D1, D3)
- `analysis.md` (5.1 风险分析, Self-Harness minimal-modify principle)
- `spec.md` (GIVEN / WHEN �?自动维护; AC07)
- `tasks.md` (WP06)

## Goal

Implement `obsidian-maintain.ps1` that:
1. `-DetectDuplicates`: scans `知识/**/*.md`; pairs with tag-set Jaccard > 0.9 AND title similarity > 0.9 are flagged as duplicate candidates. Output: `进化/proposals/duplicates-YYYYMMDD-HHMMSS.json` with pairs. **NEVER auto-merge** (SPL safety + user-data safety).
2. `-CleanEmptyDirs`: walks `知识/` recursively; deletes directories with 0 files AND mtime older than 7d. **Default `-DryRun`**; only deletes with `-Apply`.
3. `-RuleSelfHeal`: reads `进化/rules/_unclassified-queue.yaml`; if 5+ files share the same `primary_tag` and no rule exists, suggest a new rule (printed, not auto-added).
4. `-GeneDecay`: scans `进化/genes/*.yaml`; flags `use_count=0` AND `last_used < today - 90d` as dormant; flags `use_count=0` AND `last_used < today - 180d` as archive-suggest. NEVER auto-archive.
5. All destructive actions require `-Apply`; default is `-DryRun` report.

## Steps

- [ ] T06.1: Create `.trae/scripts/obsidian-maintain.ps1` with param block: `-DetectDuplicates`, `-CleanEmptyDirs`, `-RuleSelfHeal`, `-GeneDecay`, `-All`, `-Apply`, `-DryRun`, `-VaultPath `path``, `-Help`.
- [ ] T06.2: Duplicate detector: for each pair (A, B) in `知识/**/*.md`, compute `jaccard(tags(A), tags(B))` and `title_similarity(A.title, B.title)` (normalized Levenshtein ratio); if both > 0.9, add to pairs.
- [ ] T06.3: Empty dir scanner: walk `知识/`; for each leaf dir, check `(Get-ChildItem -Recurse -File).Count == 0` AND `LastWriteTime ` (Get-Date).AddDays(-7)`; list for cleanup.
- [ ] T06.4: Rule self-heal: read `_unclassified-queue.yaml`; group by `primary_tag`; if group size `= 5, emit suggested rule `tag: `X`` with `target:` inferred from majority file paths.
- [ ] T06.5: Gene decay scanner: read all Gene YAMLs; compute today minus `last_used` (default to `created_at` if `last_used` missing); flag with tier (dormant / archive-suggest).
- [ ] T06.6: Output JSON report(s) to `进化/proposals/`.
- [ ] T06.7: Self-test mode: `-SelfTest` runs against a tiny fixture, asserts at least 1 duplicate pair is found.
- [ ] T06.8: Verify AC07.

## Done Definition

- `.\.trae\scripts\obsidian-maintain.ps1 -DetectDuplicates` writes `proposals/duplicates-*.json` listing pairs, exit 0.
- `.\.trae\scripts\obsidian-maintain.ps1 -CleanEmptyDirs -DryRun` lists empty dirs without deleting, exit 0.
- `.\.trae\scripts\obsidian-maintain.ps1 -CleanEmptyDirs -Apply` deletes only old+empty dirs.
- `.\.trae\scripts\obsidian-maintain.ps1 -RuleSelfHeal` outputs suggested rules without writing to `classification-rules.yaml`.
- `.\.trae\scripts\obsidian-maintain.ps1 -GeneDecay` outputs Gene decay report.
- `.\.trae\scripts\obsidian-maintain.ps1 -SelfTest` exits 0.
- No file under `E:\ObsidianVault\JinliKG\**` is modified or deleted.

## Required Verification

| Step | Command | Expected |
|------|---------|----------|
| 1 | `.\.trae\scripts\obsidian-maintain.ps1 -Help` | Help text, exit 0 |
| 2 | `.\.trae\scripts\obsidian-maintain.ps1 -DetectDuplicates` | duplicates-*.json created, exit 0 |
| 3 | `.\.trae\scripts\obsidian-maintain.ps1 -CleanEmptyDirs -DryRun` | list of empty dirs, exit 0 (no delete) |
| 4 | `.\.trae\scripts\obsidian-maintain.ps1 -SelfTest` | exit 0 |
| 5 | AC07 evidence in `reports/obsidian-maintain-WP06-AC07.log` | file exists with required content |

## Do Not Game The Gate

- Do not auto-merge duplicates �?only report.
- Do not auto-archive Genes �?only flag.
- Do not auto-write `classification-rules.yaml` �?only suggest.
- Do not clean dirs without `-Apply`.
- Do not modify `JinliKG/` or `虚幻/` or `我的项目/`.

## Stop Conditions

- Stop if a required path is outside Allowed Paths.
- Stop if `-Apply` is requested on a non-empty dir (safety guard).

## Return Report

- Path: `reports/obsidian-maintain-WP06-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, sample reports, AC07 evidence, scope control, unresolved risks, and `Extra scope taken: no`.
