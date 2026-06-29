# WP04: obsidian-link-discover.ps1 �?关联发现

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

- Root Cause ID: RC03-no-association-discovery
- This package handles tag co-occurrence + LLM semantic association discovery.
- Scope: suggest wikilinks, optionally write to `## Related` section.
- Out of scope: classify (WP02), evolve (WP03), dream reflect (WP05), maintain (WP06).

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/`
- Parent task: `2026-06-29-obsidian-knowledge-autopoiesis`
- Spec reference: `spec.md` �?AC05
- Tasks reference: `tasks.md` �?T04.1-T04.7

## Allowed Paths

- `.trae/scripts/obsidian-link-discover.ps1` (new)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (append or read)
- `E:\ObsidianVault\**` (read OK; write OK ONLY to `## Related` block of files in `知识/` and `进化/proposals/`, never to `JinliKG/`)

## Forbidden Paths

- All task packet files (`.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md`, `work-packages/**`, `reports/**`)
- `E:\ObsidianVault\JinliKG\**` (D1 �?never modify)
- `E:\ObsidianVault\虚幻\**`, `E:\ObsidianVault\我的项目\**` (D1 �?never modify)
- `E:\ObsidianVault\进化\genes\**` (read OK; never auto-write)
- `skills/obsidian-autopoiesis/**` (WP01)
- `skills/vsummary/**` (WP07)
- `skills/ai-workflow-registry/**` (WP08)
- `Docs/AI/**`, `Docs/Memory/**`
- `Project/**`

## Read First

- `routing.md` (D4)
- `analysis.md` (Mature Solution Evidence: Hermes+LLM-Wiki+Obsidian BV16hZFB5ERM)
- `spec.md` (GIVEN / WHEN �?关联发现; AC05)
- `tasks.md` (WP04)

## Goal

Implement `obsidian-link-discover.ps1` that:
1. `-Method tag-cooccurrence`: reads frontmatter `tag` from all `.md` files in vault, computes Jaccard similarity; pairs with Jaccard > 0.6 are suggested.
2. `-Method semantic`: optional LLM-based similarity (gated by `-UseLLM`); on same domain, sample 100-200 char summary, call LLM to rate 0-1; pairs > 0.7 are suggested.
3. `-Method gene-trigger`: scan `进化/genes/*.yaml` `trigger` field, match against note title + first paragraph; pairs with substring match are suggested.
4. `-DryRun`: prints `[SUGGEST] `source` -> `target`` lines + JSON report, no writes.
5. `-Apply`: appends `[[target]]` wikilinks under a new `## Related` section at end of each source file (or updates existing `## Related` block).
6. Idempotency: if `[[target]]` already in source's `## Related`, do not add again.
7. Default: tag-cooccurrence only; LLM off; D4 mandates dual layer but cheap-first.

## Steps

- [ ] T04.1: Create `.trae/scripts/obsidian-link-discover.ps1` with param block: `-Method `tag-cooccurrence|semantic|gene-trigger|all``, `-SourceDir `dir``, `-DryRun`, `-Apply`, `-UseLLM`, `-Threshold `0-1``, `-Help`.
- [ ] T04.2: Tag scanner: walk vault, parse frontmatter `tag` arrays into hashtable `path -> set(tag)`.
- [ ] T04.3: Jaccard calculator: for each pair (A, B), `|A �?B| / |A �?B|`; if > 0.6, add to suggestions.
- [ ] T04.4: LLM semantic layer (gated by `-UseLLM`): for each pair in same `domain_path` folder, sample first 200 chars after frontmatter; call LLM endpoint; parse 0-1 score; threshold 0.7.
- [ ] T04.5: Gene-trigger matcher: load `进化/genes/*.yaml`, extract `trigger` strings; scan note titles + first paragraphs; substring match (case-insensitive); add to suggestions with `source: gene-`filename`` marker.
- [ ] T04.6: Output suggestions as JSON + human-readable text on stdout; also `进化/proposals/link-suggest-YYYYMMDD-HHMMSS.json`.
- [ ] T04.7: Apply mode: for each suggestion, open target file, check if `[[source]]` already in `## Related`; if not, append under `## Related` heading (create if missing, at end of file).
- [ ] T04.8: Self-test mode: `-SelfTest` runs against a 3-file fixture, asserts at least 1 tag-cooccurrence pair is found.
- [ ] T04.9: Verify AC05.

## Done Definition

- `.\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun -SourceDir "`small test dir`"` prints suggested pairs + JSON, exit 0.
- `.\.trae\scripts\obsidian-link-discover.ps1 -Method all -Apply -SourceDir "`test`"` adds `## Related` blocks to source files, exit 0.
- Re-running `-Apply` is idempotent (no duplicate `[[]]`).
- `.\.trae\scripts\obsidian-link-discover.ps1 -SelfTest` exits 0.
- No file under `E:\ObsidianVault\JinliKG\**` is modified.

## Required Verification

| Step | Command | Expected |
|------|---------|----------|
| 1 | `.\.trae\scripts\obsidian-link-discover.ps1 -Help` | Help text, exit 0 |
| 2 | `.\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun -SourceDir "`test dir with 3 files sharing tags`"` | suggested pairs printed, exit 0 |
| 3 | `.\.trae\scripts\obsidian-link-discover.ps1 -SelfTest` | exit 0 |
| 4 | After `-Apply`, source file has `## Related` block with `[[target]]` links | grep verification |
| 5 | AC05 evidence in `reports/obsidian-link-discover-WP04-AC05.log` | file exists with required content |

## Do Not Game The Gate

- Do not suggest links to non-existent targets (must verify file exists first).
- Do not use semantic LLM by default �?must require `-UseLLM` explicit switch.
- Do not add duplicate `[[]]` to `## Related` �?must check first.
- Do not modify `JinliKG/` files (D1).
- Do not break existing frontmatter �?append only, do not parse-and-rewrite.

## Stop Conditions

- Stop if a required path is outside Allowed Paths.
- Stop if LLM call requested but no endpoint configured.

## Return Report

- Path: `reports/obsidian-link-discover-WP04-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, sample suggestions, AC05 evidence, scope control, unresolved risks, and `Extra scope taken: no`.
