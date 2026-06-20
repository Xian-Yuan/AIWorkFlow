# WP09: Setup, Documentation, And End-To-End Evidence

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
- Read this package, all prior worker reports, task Acceptance Criteria, and the final public interfaces.
- Do not redesign code completed by prior packages.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP09
- This package handles environment scripts, offline end-to-end fixtures, project documentation, and worker-side evidence only.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/scripts/knowledge-env.ps1`
- `Project/Jinli/scripts/knowledge-runtime.ps1`
- `Project/Jinli/scripts/knowledge-tools.ps1`
- `Project/Jinli/services/knowledge/tests/fixtures/e2e/`
- `Project/Jinli/services/knowledge/tests/test_e2e_offline.py`
- `Project/Jinli/Docs/03-Architecture/KnowledgeGraph/runtime-architecture.md`
- `Project/Jinli/Docs/04-Implementation/KnowledgeGraph/video-knowledge-runtime.md`
- `Project/Jinli/Docs/05-Testing/KnowledgeGraph/runtime-test-plan.md`
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/local-runtime-runbook.md`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Forbidden Paths
- `.trae/tasks/`
- Production modules outside the three allowed scripts
- User notes outside `E:\ObsidianVault\JinliKG`
- Global Python or npm environments
- Any credentials

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/doc-impact.md`
- `reports/ds4-WP01-result.md` through `reports/ds4-WP08-result.md`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Goal
- Provide reproducible setup/health commands, deterministic offline end-to-end evidence, accurate project documentation, and a blocked-until-explicit live test path.

## Steps
- [ ] Write failing offline E2E test that ingests a fixture transcript, enriches with a fixture provider, accepts graph candidates, exports Obsidian notes, and returns evidence search results.
- [ ] Implement `knowledge-env.ps1 inspect` and `apply`; `apply` must require an explicit switch and set both `OBSIDIAN_VAULT_PATH` and `KG_VAULT_PATH` to `E:\ObsidianVault`.
- [ ] Extend setup commands to create an isolated knowledge Python environment, install requirements, and install pinned external tools under `E:\Obsidian\tools` without global package changes.
- [ ] Add health reporting for Python packages, FFmpeg, yt-dlp, Ollama endpoint/models, vsummary availability, obra revision, vault path, write access, and free disk space.
- [ ] Add offline and live test commands; live test must require `JINLI_KG_TEST_VIDEO_URL` and must not invent a URL.
- [ ] Write architecture, implementation, testing, and operations documents using only verified behavior.
- [ ] Update `Project/Jinli/docs/DOCS_TREE.md`.
- [ ] Run all worker-side verification commands and return raw evidence; do not mark Review or Verify pass.

## Done Definition
- Offline E2E proves source-to-search without network or a real model.
- Setup is isolated and idempotent.
- Live test refuses to run without explicit URL and reports missing optional dependencies clearly.
- Project docs and docs tree describe actual code and commands.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests -q; npm.cmd test --prefix Project/Jinli; powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.tests.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-runtime.ps1 test-offline; powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-21-knowledge-graph-runtime-implementation -Stage implement`
- Expected: all deterministic tests pass and documentation governance passes; live test remains a separate lead-verification command.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if a prior worker report is missing or blocked.
- Stop if setup would alter a global environment or overwrite an existing external tool checkout.
- Stop if documentation claims live behavior that was not executed.
- Stop if the real vault target is ambiguous.

## Return Report
- Path: `reports/ds4-WP09-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and the smallest reproducible environment or integration blocker.
