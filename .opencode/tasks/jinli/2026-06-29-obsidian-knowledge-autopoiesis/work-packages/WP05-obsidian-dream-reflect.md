# WP05: obsidian-dream-reflect.ps1 �?梦境反�?
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

- Root Cause ID: RC04-no-knowledge-gap-discovery
- This package handles the weekly dream-reflection report.
- Scope: scan Genes for usage, find knowledge gaps, decay proposals, output markdown report.
- Out of scope: classify (WP02), evolve (WP03), link (WP04), maintain (WP06).

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/`
- Parent task: `2026-06-29-obsidian-knowledge-autopoiesis`
- Spec reference: `spec.md` �?AC06
- Tasks reference: `tasks.md` �?T05.1-T05.7

## Allowed Paths

- `.trae/scripts/obsidian-dream-reflect.ps1` (new)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (append or read)
- `E:\ObsidianVault\进化\**` (read + write; only `proposals/` and `dreams/` write)

## Forbidden Paths

- All task packet files (`.task.yaml`, `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md`, `work-packages/**`, `reports/**`)
- `E:\ObsidianVault\JinliKG\**`, `E:\ObsidianVault\知识\**`, `E:\ObsidianVault\虚幻\**`, `E:\ObsidianVault\我的项目\**` (read OK, NEVER modify)
- `E:\ObsidianVault\进化\genes\**` (read OK, NEVER auto-write)
- `skills/obsidian-autopoiesis/**` (WP01)
- `skills/vsummary/**` (WP07)
- `skills/ai-workflow-registry/**` (WP08)
- `Docs/AI/**`, `Docs/Memory/**`
- `Project/**`

## Read First

- `routing.md` (D3 SPL safety)
- `analysis.md` (Hermes memory layer, T7 dreamer reference)
- `spec.md` (GIVEN / WHEN �?梦境反�? AC06)
- `tasks.md` (WP05)
- `Docs/AI/17-Self-Improving-Framework.md` (Subconscious engine section)

## Goal

Implement `obsidian-dream-reflect.ps1` that:
1. `-QuickScan`: scans `进化/genes/*.yaml` only, outputs 1-page summary.
2. `-FullScan`: scans all knowledge files + Genes + proposals, outputs full dream-report.
3. Identifies: unused Genes (`use_count=0` past threshold), knowledge gaps (system Skill/Docs/Memory coverage vs `actionable: True` notes), stale proposals (>30d unapproved), dormant notes (>6m un-referenced).
4. Writes `E:\ObsidianVault\进化\dreams\dream-report-YYYY-MM-DD.md` with sections: Gene usage stats, Knowledge gap list, Stale proposal list, Dormant notes list, Recommended actions (suggestion only, not auto-execute).
5. Does NOT auto-archive or auto-approve anything �?only suggests (SPL safety).
6. Idempotent: re-running same day overwrites the same dated report (no duplicate).

## Steps

- [ ] T05.1: Create `.trae/scripts/obsidian-dream-reflect.ps1` with param block: `-FullScan`, `-QuickScan`, `-OutputPath `path`` (default `E:\ObsidianVault\进化\dreams\`), `-Help`.
- [ ] T05.2: Gene usage scanner: parse all `进化/genes/*.yaml` for `last_used`, `use_count`; flag `use_count=0` AND `last_used ` today - 90d` as dormant-suggest.
- [ ] T05.3: Knowledge gap finder: walk `skills/`, `Docs/AI/`, `.trae/scripts/`; collect file paths; walk `E:\ObsidianVault\知识/**/*.md` for `actionable: true` in frontmatter; cross-reference: notes with `actionable: true` whose domain has no corresponding Skill/Doc �?gap.
- [ ] T05.4: Stale proposal scanner: list `进化/proposals/*.yaml` older than 30d where `status` is not `approved`; mark stale.
- [ ] T05.5: Dormant notes scanner: walk vault `.md` files; for each, find `## Related` block; if file has no inbound `[[]]` from any other file, AND file mtime ` 180d, mark dormant.
- [ ] T05.6: Generate report markdown with the 4 sections + recommendations (suggestion only).
- [ ] T05.7: Self-test mode: `-SelfTest` runs against a tiny fixture vault, asserts report is generated.
- [ ] T05.8: Verify AC06.

## Done Definition

- `.\.trae\scripts\obsidian-dream-reflect.ps1 -QuickScan` writes `dream-report-YYYY-MM-DD.md` to `进化/dreams/`, exit 0.
- `.\.trae\scripts\obsidian-dream-reflect.ps1 -FullScan` writes a more detailed version with all 4 sections, exit 0.
- Report contains no auto-execute directives �?only `[SUGGEST]` markers.
- `.\.trae\scripts\obsidian-dream-reflect.ps1 -SelfTest` exits 0.
- No file outside `进化/dreams/` and `进化/proposals/` is modified.

## Required Verification

| Step | Command | Expected |
|------|---------|----------|
| 1 | `.\.trae\scripts\obsidian-dream-reflect.ps1 -Help` | Help text, exit 0 |
| 2 | `.\.trae\scripts\obsidian-dream-reflect.ps1 -QuickScan` | dream-report-*.md created, exit 0 |
| 3 | `.\.trae\scripts\obsidian-dream-reflect.ps1 -FullScan` | dream-report-*.md with all 4 sections, exit 0 |
| 4 | `.\.trae\scripts\obsidian-dream-reflect.ps1 -SelfTest` | exit 0 |
| 5 | AC06 evidence in `reports/obsidian-dream-reflect-WP05-AC06.log` | file exists with required content |

## Do Not Game The Gate

- Do not auto-archive or auto-approve �?only suggest (SPL safety).
- Do not write to Genes �?only read.
- Do not silently skip stale items �?must list them.
- Do not call external services (LLM, network) without explicit switch.
- Do not modify JinliKG/知识/虚幻/我的项目 files.

## Stop Conditions

- Stop if a required path is outside Allowed Paths.
- Stop if `进化/dreams/` directory does not exist �?create it (within Allowed Paths).

## Return Report

- Path: `reports/obsidian-dream-reflect-WP05-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, sample dream-report excerpt, AC06 evidence, scope control, unresolved risks, and `Extra scope taken: no`.
