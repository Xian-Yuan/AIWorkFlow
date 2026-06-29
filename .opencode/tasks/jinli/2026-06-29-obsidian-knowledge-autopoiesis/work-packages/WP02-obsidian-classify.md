# WP02: obsidian-classify.ps1 �?自动分类归档

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

- Root Cause ID: RC01-no-classification-pipeline
- This package handles the auto-classify + wikilink-redirect script.
- Scope: read frontmatter, look up classification-rules.yaml, Move-Item + create redirect stub.
- Out of scope: rule YAML authoring (WP01), Gene extraction (WP03), link discovery (WP04), maintain (WP06).

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/`
- Parent task: `2026-06-29-obsidian-knowledge-autopoiesis`
- Spec reference: `spec.md` �?AC01, AC02
- Tasks reference: `tasks.md` �?T02.1-T02.8

## Allowed Paths

- `.trae/scripts/obsidian-classify.ps1` (new)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (new �?shared frontmatter/yaml helpers; create if not exists, otherwise append)

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/.task.yaml`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/routing.md`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/analysis.md`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/spec.md`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/tasks.md`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/doc-impact.md`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/work-packages/**`
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/reports/**`
- `E:\ObsidianVault\JinliKG\**` (read OK, NEVER modify)
- `E:\ObsidianVault\知识\**` (read OK, write only via -Apply on -Batch)
- `E:\ObsidianVault\虚幻\**` (read OK, NEVER modify)
- `E:\ObsidianVault\我的项目\**` (read OK, NEVER modify)
- `skills/obsidian-autopoiesis/**` (WP01 only)
- `skills/vsummary/**` (WP07 only)
- `skills/ai-workflow-registry/**` (WP08 only)
- `Docs/AI/**`
- `Docs/Memory/**`
- `Project/**`

## Read First

- `routing.md`
- `analysis.md` (sections: Architecture Context, Mature Solution Evidence, Key Design Decisions)
- `spec.md` (GIVEN / WHEN / THEN / AC01 / AC02)
- `tasks.md` (WP02)
- `E:\ObsidianVault\进化\rules\classification-rules.yaml` (created by WP01; if missing, fail with clear message �?do NOT invent rules)

## Goal

Implement `obsidian-classify.ps1` that:
1. Reads frontmatter `tag` + `domain_path` from a markdown file.
2. Looks up the target directory in `classification-rules.yaml`.
3. On `-Apply`: `Move-Item` the file to target; create redirect stub at old position containing only `[[target-path]]`.
4. On `-DryRun`: prints `[DRY] `source` -> `target`` and exits without modifying files.
5. Supports `-Batch -SourceDir `dir`` to scan an entire directory.
6. Idempotency: if a file with the same `kg_id` already exists at the target, skip (no error).
7. On un-classified file: append entry to `E:\ObsidianVault\进化\rules\_unclassified-queue.yaml` (created on demand).
8. Outputs a JSON report: `{moved, redirected, skipped, unclassified, errors}`.

## Steps

- [ ] T02.1: Create `.trae/scripts/obsidian-classify.ps1` with parameter block: `-Source `path``, `-SourceDir `dir``, `-Apply`, `-DryRun`, `-RulesPath `yaml``, `-VaultPath `path`` (default `E:\ObsidianVault`), `-Help`.
- [ ] T02.2: Implement frontmatter parser: read up to first `---` block, parse key:value pairs and `tags: [a, b]` or `tag: a` (PowerShell 5.1, no external modules required; fall back to regex if ConvertFrom-Yaml not available).
- [ ] T02.3: Implement rules loader: parse `classification-rules.yaml` line-by-line (regex on `^tag:\s*(\S+)\s*$` + `^target:\s*(.+?)\s*$` per block). Cache in script-scope hashtable.
- [ ] T02.4: Implement classifier: pick first matching tag's `target`; if no match, queue to `_unclassified-queue.yaml`.
- [ ] T02.5: Implement Move-Item + redirect stub writer: stub file at old position is `1 line` with `[[target-path]]` so Obsidian GraphView edge is preserved.
- [ ] T02.6: Idempotency check: read target dir for existing file with same `kg_id`; if found, skip.
- [ ] T02.7: Batch mode: iterate `-SourceDir` (default `E:\ObsidianVault\JinliKG\Sources\Videos`), call single-file classifier for each.
- [ ] T02.8: Self-test mode: `-SelfTest` runs against a fixture file in `%TEMP%\obsidian-classify-selftest\` and exits 0/1.
- [ ] T02.9: JSON report at end of run on stdout AND in `E:\ObsidianVault\进化\proposals\classify-report-YYYYMMDD-HHMMSS.json`.
- [ ] T02.10: Verify AC01 and AC02 �?see Required Verification.

## Done Definition

- `.\.trae\scripts\obsidian-classify.ps1 -DryRun -Source "`existing .md in Sources/Videos with tag+domain_path`"` prints target path and exits 0.
- After `-Apply`, original position file contains only `[[target-path]]` (1 line, no frontmatter).
- `.\.trae\scripts\obsidian-classify.ps1 -Batch -DryRun -SourceDir "`small test dir with 3 files`"` returns valid JSON report.
- `.\.trae\scripts\obsidian-classify.ps1 -SelfTest` exits 0.
- No file under `E:\ObsidianVault\JinliKG\` is modified (D1).

## Required Verification

| Step | Command | Expected |
|------|---------|----------|
| 1 | `.\.trae\scripts\obsidian-classify.ps1 -Help` | Help text shown, exit 0 |
| 2 | `.\.trae\scripts\obsidian-classify.ps1 -DryRun -Source "E:\ObsidianVault\JinliKG\Sources\Videos\`any one .md file with frontmatter`"` | prints `[DRY] ... -> ...` line, JSON report, exit 0 |
| 3 | `.\.trae\scripts\obsidian-classify.ps1 -SelfTest` | exits 0 |
| 4 | diff on `E:\ObsidianVault\JinliKG\**` before/after `-SelfTest` | empty diff |
| 5 | AC01 evidence in `reports/obsidian-classify-WP02-AC01.log` (path printed to target) | file exists, contains `[[target-path]]` for AC02 |

## Do Not Game The Gate

- Do not move old files to satisfy D1 violation.
- Do not delete source content silently �?always leave the redirect stub.
- Do not write to target without creating the redirect at the old position.
- Do not silently swallow unclassified files �?must append to queue.
- Do not require Python or external modules �?PowerShell 5.1 + built-in only.

## Stop Conditions

- Stop if `classification-rules.yaml` does not exist (WP01 must complete first; do not invent rules).
- Stop if a required path is outside Allowed Paths.
- Stop if `-Apply` is invoked but the source file has no `kg_id` in frontmatter (idempotency is impossible without it).
- Stop if Move-Item would cross drive boundaries without `Move-Item -LiteralPath` and explicit ` -Force` review.

## Return Report

- Path: `reports/obsidian-classify-WP02-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, AC01/AC02 evidence, scope control, unresolved risks, and `Extra scope taken: no`.
