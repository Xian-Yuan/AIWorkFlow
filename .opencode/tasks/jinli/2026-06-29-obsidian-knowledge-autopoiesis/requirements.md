# Requirements: Obsidian Knowledge Autopoiesis

> Phase: Plan | Profile: deep | Status: confirmed | Generated: 2026-06-29

## Desired Outcome

Ba Ba's Obsidian vault (E:\ObsidianVault) grows self-organizing: every vsummary-produced video summary is auto-classified into a proper domain folder, every high-value note is auto-distilled into a compact reusable strategy (Gene), every note is auto-linked to its semantically closest peers, and every week a dream report surfaces knowledge gaps and dormant knowledge — so Ba Ba's second brain closes the loop with the AI workflow system instead of being a passive archive.

## Intended User and Context

- **Primary user**: Ba Ba (the user, "爸爸" in our convention). Single user, single vault, single workstation.
- **Usage moment**: After vsummary finishes a video summary (a few times per week), the new `.md` is automatically classified and moved to the right place. The vault never grows stale. When Ba Ba opens Obsidian, GraphView shows richer connections. When Ba Ba wants to find a pattern, dream-report.md points to the right Gene.
- **Scale**: 571 video summaries in `JinliKG/Sources/Videos/`, 1281 total `.md` files, 77 unique frontmatter tags. Target: process all 571 within the first batch run.
- **Trust**: Ba Ba trusts the system not to break existing data. D1 (zero-destructive upgrade) is non-negotiable.

## End-to-End Experience

1. Ba Ba runs vsummary as usual. vsummary writes a new `.md` to `E:\ObsidianVault\JinliKG\Sources\Videos\<title>-<kg_id>.md` with frontmatter `tag: [...]` + `domain_path: ...`.
2. vsummary post-summarize hook fires `obsidian-classify.ps1 -Batch -Apply`.
3. classify reads frontmatter, looks up `classification-rules.yaml`, moves the file to `E:\ObsidianVault\知识\{领域}\{子类}\<title>-<kg_id>.md`, and writes a 1-line redirect stub `[[target-path]]` at the old position so Obsidian GraphView edges are preserved.
4. classify then calls `obsidian-evolve.ps1 -ExtractGene -Source <new path>` which scores the note on 4 Pareto dimensions; if mean >= 0.6, a compact 300-2000 token Gene YAML is written to `进化/genes/gene-YYYYMMDD-NNN.yaml`.
5. classify then calls `obsidian-link-discover.ps1 -Method all -Apply` which adds `## Related` blocks with `[[wikilink]]` to semantically close notes.
6. Once a week (manual or cron), `obsidian-dream-reflect.ps1 -FullScan` produces `进化/dreams/dream-report-YYYY-MM-DD.md` listing dormant Genes, knowledge gaps, stale proposals.
7. Periodically, `obsidian-maintain.ps1 -DetectDuplicates -CleanEmptyDirs -RuleSelfHeal -GeneDecay` produces reports and suggests cleanups (Ba Ba approves manually via `growth_approve`).

## Confirmed Decisions

| ID | Decision | Why |
|----|----------|-----|
| D1 | New files follow new rules; old files untouched | Zero risk; Obsidian GraphView preserved |
| D2 | Gene YAML format, 300-2000 token bound | SkillOpt (Microsoft) empirical evidence |
| D3 | Hybrid JIPA Pareto + SPL safety closed loop | JIPA multi-objective diversity + AGP/SPL safety guardrails |
| D4 | Tag co-occurrence + LLM semantic dual-layer link discovery | Cheap filter + precise LLM, balanced cost/precision |
| D5 | vsummary post-summarize hook triggers classify chain | Keeps vsummary single-responsibility, chain is opt-in |
| D6 | 5 PowerShell scripts (WP02-WP06) + 1 Skill entry point | Standard .trae/scripts/ pattern; PowerShell 5.1 built-in only |
| D7 | All destructive actions require explicit `-Apply`; default `-DryRun` | SPL safety, user-data safety |
| D8 | Authority Profile: issuer-worker-v1; workers operate on signed capability | Ba Ba's growth_approve is the only archive/commit path |
| D9 | Future Soul Core integration deferred (Gene YAML future injection via `soul_learn`) | Out of scope for this task; known not-yet-implemented |

## Implicit Requirements

- PowerShell 5.1 compatibility (no PS7-only syntax; no Python or external modules for runtime).
- All scripts must have `-Help`, `-DryRun`, `-SelfTest` modes for verification without side effects.
- All scripts must output a JSON report on stdout for downstream automation.
- Frontmatter parser must handle both `tag: x` and `tags: [a, b]` forms.
- Idempotency: re-running any script on a stable vault must produce byte-identical state.
- Files moved by classify must leave a redirect stub containing only `[[target-path]]` (1 line, no frontmatter); GraphView edges survive.
- Gene dedup is by `gene_id` (sha1 of `domain + ":" + trigger`); existing Genes are not overwritten.
- Dream reports are suggestions only — no auto-archive, no auto-approve, no auto-merge.
- Maintain report flags duplicates and decays — never auto-merges or auto-archives.
- Workers (WP02-WP06) are gated by `worker-sandbox.ps1` Allowed Paths; cannot edit task packet files, registry, or vsummary SKILL.md.

## Boundaries and Non-Goals

- **In scope**: 5 PowerShell scripts (classify / evolve / link / dream / maintain), 2 YAML rules (classification / rubric), 1 Skill entry, 1 registry entry, 1 vsummary post-hook section, 4 `.gitkeep` placeholders under `E:\ObsidianVault\进化\`.
- **Out of scope**: Soul Core integration (future, not in this task); any change to vsummary core pipeline code (only SKILL.md is modified); any Project/* code; any Docs/AI/ documentation; any user-data file outside `E:\ObsidianVault\进化\` (created files) and the redirect stubs.
- **Non-goal**: full re-classification of existing 571 files. D1 says old files stay. New files (post-deploy) follow new rules. Optional one-time bulk-migration script is NOT in this task scope.
- **Non-goal**: web UI. This is a CLI-only system triggered by vsummary hook + manual cron.

## Success Experience

- Ba Ba opens Obsidian after vsummary finishes; the new summary is already in the right folder.
- Ba Ba opens a knowledge note; the `## Related` block shows 3-5 closely related notes.
- Ba Ba reads dream-report on Sunday; it lists 2-3 dormant Genes to review and 1 knowledge gap (e.g., a topic with many summaries but no Skill).
- Ba Ba reviews a Gene in `进化/genes/`, finds it useful, approves it via `growth_approve`. Soul Core future integration will inject it into context.
- Existing JinliKG files: byte-identical before and after deploy. vsummary core: unchanged. Soul Core: unaffected.

## Open Questions

None. All clarification has been resolved:
- D1-D9 are user-confirmed in `routing.md` (Authority Profile: issuer-worker-v1; `user_confirmed_plan: true`; `clarification_status: answered`; `requirements_status: resolved`).
- 8 Acceptance Criteria are concrete and self-testable.
- 5 PowerShell scripts each have a `-SelfTest` mode and an AC verification command.

## Teach-Back Summary

> "Ba Ba, let me make sure I understood: You want the Obsidian vault to grow its own structure. Every vsummary output gets auto-classified into the right domain folder, old files don't move. High-value notes get distilled into compact 300-2000 token Gene YAMLs. The vault learns links between notes on its own. Once a week a dream report tells you what's dormant and what gaps exist. Nothing breaks: existing files stay put, vsummary still works, and you approve anything destructive with growth_approve. Confirmed?"

## User Confirmation Evidence

- `user_confirmed_plan: true` in `.task.yaml`
- `clarification_status: answered` in `.task.yaml`
- `requirements_status: resolved` in `.task.yaml`
- `router_skill_loaded: true` in `.task.yaml`
- `analysis.md` Mature Solution Evidence: 7 local JinliKG references + 5 external open-source references
- `routing.md` Authority Profile: issuer-worker-v1 with 7-line Authority Policy block
- `routing.md` Quality Gate: mature production-grade, no MVP/prototype exception
- `tasks.md` Final Verification: 5 TF + 4 TA + 10 TM01 sub-checks (mature path verification, no-rejected-shortcut gate)
