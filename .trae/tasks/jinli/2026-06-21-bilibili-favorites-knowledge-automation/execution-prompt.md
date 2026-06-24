# Task Execution Prompt: Bilibili Favorites Knowledge Automation

## Role

Implement the confirmed orchestration layer through the numbered DS4 work packages. Preserve task-packet authority boundaries and return evidence to the Codex lead.

## Goal

Deliver a restartable pipeline that processes eligible videos from Bilibili folder `ai相关` into classified durable knowledge while storing media on HDD, skipping completed revisions, and deleting only committed disposable media.

## Task Packet Truth Sources

1. `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/requirements.md`
2. `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
3. `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/spec.md`
4. `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/tasks.md`
5. `Project/Jinli/Docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`

## Confirmed Decisions

- Filter strictly below 1,800 seconds before download.
- Default managed media root is `G:\JinliVideoCache`, subject to runtime non-SSD verification and configuration override.
- SQLite owns workflow state; Markdown and canonical records own accepted knowledge.
- Description and pinned comment are optional; important links are retained.
- An unchanged completed revision is skipped even while it remains favorited.
- Cleanup follows atomic export and ledger commit.

## Accepted Architecture

- Extend the Jinli knowledge runtime with adapters for Bilibili, managed media, and vsummary.
- Keep orchestration independent from adapter details and expose one deterministic CLI.
- Share the same runner with an optional Windows scheduled-task installer.
- Degrade graph indexing to a durable queue after Markdown export.

## Allowed Paths

- `Project/Jinli/services/knowledge/`
- `Project/Jinli/tests/knowledge/`
- `Project/Jinli/scripts/knowledge-*.ps1`
- `Project/Jinli/Docs/03-Architecture/KnowledgeGraph/`
- `Project/Jinli/Docs/04-Implementation/KnowledgeGraph/`
- `Project/Jinli/Docs/05-Testing/KnowledgeGraph/`
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/`
- `Project/Jinli/Docs/DOCS_TREE.md`
- The assigned worker package's narrower Allowed Paths

## Forbidden Paths

- `.trae/tasks/`
- vsummary `.env` and provider configuration
- Bilibili cookies and browser profiles
- user notes outside `E:\ObsidianVault\JinliKG`
- files outside the configured managed media root during cleanup
- unrelated Jinli persona, vision, avatar, and UI code

## Non-Goals

- Do not remove Bilibili favorites.
- Do not process videos of 30 minutes or longer.
- Do not build a new graph database or UI.
- Do not implement login, DRM, paywall, or CAPTCHA bypass.
- Do not make comments, graph indexing, or cloud inference mandatory.

## Acceptance Criteria

- AC01: discovery is complete, paginated, read-only, and duration-filtered.
- AC02: existing media is reconciled and new media uses a verified non-SSD root.
- AC03: exported notes preserve identity, optional evidence, important links, classification, and provenance.
- AC04: the ledger provides crash recovery and unchanged-revision skipping.
- AC05: deletion is path-contained and occurs only after durable export commit.
- AC06: graph outage, provider timeout, and missing comments degrade safely.
- AC07: manual run, scheduled run, dry-run, and retry all call one orchestrator.
- AC08: secrets never appear in logs, tests, or reports.

## Verification Commands

- `python -m pytest Project/Jinli/services/knowledge/tests Project/Jinli/tests/knowledge -q` -> expected: all automation tests pass.
- `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-bilibili-favorites.ps1 -DryRun` -> expected: read-only report with no downloads, writes, or deletes.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/detect-duplicates.ps1` -> expected: no introduced duplicate implementation.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/doc-guard.ps1 check-task jinli/2026-06-21-bilibili-favorites-knowledge-automation -Stage verify` -> expected: pass.

## Stop Conditions

- A task truth source or prerequisite knowledge-runtime contract is missing.
- Plan or edit authorization fails.
- A worker needs a path outside its package.
- Physical-disk identity cannot be proven before a download or move.
- Cleanup containment or export durability cannot be proven.
- Required verification fails beyond the DS4 repair loop.

## Evidence Rule

Do not claim discovery counts, disk type, adoption, summary success, export, deletion, skip behavior, or test status without current-session evidence. Never include credentials or cookies in evidence.

