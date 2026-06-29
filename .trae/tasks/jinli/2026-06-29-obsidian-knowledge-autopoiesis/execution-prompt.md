# Execution Prompt: Obsidian Knowledge Autopoiesis

> For: 金璃好帮手 (Implement Agent) and downstream workers
> Issued by: 金璃小天才 (Plan Agent) | 2026-06-29
> Task: jinli/2026-06-29-obsidian-knowledge-autopoiesis
> Authority Profile: issuer-worker-v1

## Role

You are 金璃好帮手 (Implement Agent) executing the Implement phase of the Obsidian Knowledge Autopoiesis task. You write code, run tests, and self-verify against spec.md scenarios. You do NOT modify task packet files (routing.md / analysis.md / spec.md / tasks.md / doc-impact.md / .task.yaml) — those are Issuer-only mutations.

## Goal

Deliver a complete, mature, self-organizing Obsidian knowledge autopoiesis system per the spec:

1. 5 PowerShell scripts under `.trae/scripts/` (classify / evolve / link-discover / dream-reflect / maintain).
2. 2 YAML rule files under `E:\ObsidianVault\进化\rules\` (classification-rules.yaml + evolution-rubric.yaml) — these are created by WP01 Issuer-only WP.
3. 1 Skill entry `skills/obsidian-autopoiesis/SKILL.md` + `status.yaml`.
4. 4 `.gitkeep` placeholders under `E:\ObsidianVault\进化\genes/, proposals/, dreams/, enacted/`.
5. Modify `skills/vsummary/SKILL.md` to add a post-summarize hook step.
6. Register the new workflow in `skills/ai-workflow-registry/registry.yaml`.

All 8 Acceptance Criteria (AC01-AC08) must pass automated verification.

## Task Packet Truth Sources

The task packet is the single source of truth. Read in this order:

1. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/requirements.md` — what we are building (Ba Ba-readable).
2. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/spec.md` — GIVEN/WHEN/THEN behavior + 8 ACs.
3. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/analysis.md` — architecture, mature solution evidence, risk analysis, rejected shortcuts.
4. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/routing.md` — routing decisions + Authority Policy + Quality Gate + Work Package Policy.
5. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/tasks.md` — 8 WPs / 38 sub-tasks / Final Verification.
6. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/work-packages/WP0X-*.md` — the per-WP work package you are executing.
7. `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/doc-impact.md` — code/doc change scope.

Do not trust the chat history; trust only the task packet.

## Confirmed Decisions

- D1: New files follow new rules; old files untouched. Old position gets 1-line `[[wikilink]]` redirect stub.
- D2: Gene YAML, 300-2000 token bound.
- D3: Hybrid JIPA Pareto + SPL safety.
- D4: Tag co-occurrence + LLM semantic dual-layer.
- D5: vsummary post-summarize hook triggers classify chain.
- D6: 5 PowerShell scripts (WP02-WP06) + 1 Skill entry (WP01) + 1 registry (WP08) + 1 vsummary hook (WP07).
- D7: All destructive actions require explicit `-Apply`; default `-DryRun`.
- D8: Authority Profile: issuer-worker-v1; workers operate on signed capability; only Issuer signs Review / Verify / Archive.
- D9: Soul Core integration deferred (future `soul_learn` injection).

## Accepted Architecture

```
vsummary post-hook (WP07, issuer-only)
        ↓
WP02 classify (worker)  ─┐
WP03 evolve (worker)     │  sequential in vsummary hook
WP04 link-discover (worker)
        ↓
WP05 dream-reflect (worker, weekly)
WP06 maintain (worker, periodic)
        ↓
WP08 registry + verify (issuer-only)
```

Sequential-WP Implement by Plan → 1 issuer (Plan) → 5 workers (Implement) → 1 issuer (Review) → 1 issuer (Verify) → 1 issuer (Archive).

## Allowed Paths

Per the per-WP work package Allowed Paths section. Common:
- `.trae/scripts/obsidian-*.ps1` (worker)
- `.trae/scripts/_shared/ObsidianHelpers.psm1` (worker)
- `skills/obsidian-autopoiesis/**` (issuer-only WP01)
- `skills/vsummary/SKILL.md` (issuer-only WP07)
- `skills/ai-workflow-registry/**` (issuer-only WP08)
- `E:\ObsidianVault\进化\**` (workers for `genes/`, `proposals/`, `dreams/`, `enacted/`)
- `E:\ObsidianVault\知识\**` (worker, but only via `-Apply` on classify)
- `E:\ObsidianVault\JinliKG\**` (READ-ONLY; D1 prohibits any write)

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/.task.yaml` (Issuer-only)
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/{routing,analysis,spec,tasks,doc-impact,requirements,execution-prompt}.md` (Issuer-only)
- `.trae/tasks/jinli/2026-06-29-obsidian-knowledge-autopoiesis/work-packages/**` (worker can read own WP, never edit)
- `E:\ObsidianVault\JinliKG\**` (D1, read-only)
- `E:\ObsidianVault\虚幻\**`, `E:\ObsidianVault\我的项目\**` (D1, read-only)
- `E:\ObsidianVault\进化\genes\**` (read OK; only `obsidian-evolve.ps1 -ExtractGene -Apply` can write)
- `Docs/AI/**`, `Docs/Memory/**` (no edits)
- `Project/**` (no edits)
- `.codex/capability-baseline.json` (no edits)

## Non-Goals

- Full re-classification of existing 571 files (D1 says old files stay).
- Soul Core integration (D9 deferred).
- Web UI (CLI-only system).
- Modifying vsummary core pipeline code (only SKILL.md is modified, by Issuer).
- MVP / prototype shortcuts (Quality Gate: mature production-grade).
- Auto-merge / auto-archive of duplicates or dormant Genes (SPL safety).

## Acceptance Criteria

| AC# | Description | Verification |
|-----|-------------|--------------|
| AC01 | `obsidian-classify.ps1 -DryRun -Source <file>` prints target path without moving | command in `verification-report.md` |
| AC02 | Original position file contains `[[wikilink]]` redirect stub after `-Apply` | grep evidence in report |
| AC03 | `obsidian-evolve.ps1 -Analyze -Source <file>` outputs 4-dim JSON | JSON in report |
| AC04 | `obsidian-evolve.ps1 -ExtractGene -Source <file>` writes `gene-*.yaml` under `进化/genes/`, 300-2000 tokens | file + token count in report |
| AC05 | `obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun` outputs pairs | list in report |
| AC06 | `obsidian-dream-reflect.ps1 -FullScan` writes `dream-report-*.md` | file in report |
| AC07 | `obsidian-maintain.ps1 -DetectDuplicates` outputs duplicate pairs | list in report |
| AC08 | vsummary post-hook triggers classify chain end-to-end | simulated run in report |

## Verification Commands

Per-WP Required Verification is documented in each `work-packages/WP0X-*.md` file. Final Verification:

```
.\.trae\scripts\task-guard.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify
.\.trae\scripts\contract-verify.ps1 jinli/2026-06-29-obsidian-knowledge-autopoiesis verify -Strict
python .trae/scripts/sync-workflow-registry.py
```

All three must exit 0 and the `verification-report.md` must enumerate all 8 ACs with PASS evidence.

## Stop Conditions

- Stop if `classification-rules.yaml` or `evolution-rubric.yaml` does not exist (WP01 must complete first).
- Stop if a required path is outside the WP's Allowed Paths.
- Stop if `-Apply` is invoked on a non-empty dir (maintain.ps1 safety guard).
- Stop if a Worker result is not `implementation_done` (authority gate will block Review).
- Stop on any of: missing frontmatter kg_id, kg_id conflict, missing target dir.
- Stop if an existing JinliKG file would be modified (D1 violation — escalate to Issuer immediately).
- If a context-rot signal appears (re-reading modified files, repeating concepts, proposing already-rejected shortcuts), stop and call `/clear` then resume from this prompt.

## Evidence Rule

- Every AC requires concrete evidence in `verification-report.md`: command + exit code + relevant excerpt (file path, JSON key, wikilink text, YAML token count, etc.).
- "Tests pass" is not evidence; show the actual output.
- "I think it works" is not evidence; show the diff.
- Compiled clean is not evidence; show no-error compile log.
- A worker report at `reports/<wp>-result.md` is required for every Worker-eligible WP. Status must be `done`. Must include: Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Unresolved Risks, `Extra scope taken: no`.
- Only after all 5 worker reports are `done` and the 8 ACs are evidenced, may the Issuer sign Review.

---

**Workflow**:
1. Issuer (Plan) signs task packet.
2. Workers claim `work-packages/WP0X-*.md`, get signed capability, do their WP, write `reports/<wp>-result.md`.
3. Issuer verifies all worker reports + runs final verification.
4. Issuer signs Verify-publish.
5. Issuer explicit-archives.

If you are reading this prompt as a worker, you should ONLY have a signed capability for one WP. Stay within that WP's Allowed Paths. Do not touch other WPs, the task packet, the registry, or vsummary SKILL.md.
