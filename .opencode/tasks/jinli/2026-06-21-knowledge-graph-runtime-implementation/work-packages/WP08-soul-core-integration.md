# WP08: Knowledge CLI And Soul Core Integration

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
- Read this package, knowledge service public API, and only the Soul Core command-routing sections needed for integration.
- Do not alter persona, emotion, response planning, or unrelated lifecycle code.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP08
- This package handles the knowledge CLI, PowerShell bridge, and bounded Soul Core command integration.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/cli.py`
- `Project/Jinli/services/knowledge/service.py`
- `Project/Jinli/services/knowledge/tests/test_cli.py`
- `Project/Jinli/services/knowledge/tests/test_service.py`
- `Project/Jinli/scripts/knowledge-runtime.ps1`
- `Project/Jinli/scripts/soul-core.ps1`
- `Project/Jinli/scripts/soul-core.tests.ps1`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/config/persona.json`
- `Project/Jinli/runtime/`
- `Project/Jinli/services/vision/`
- Existing memory database schema
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/config.py`
- `Project/Jinli/services/knowledge/evidence_search.py`
- `Project/Jinli/services/knowledge/obsidian_export.py`
- `Project/Jinli/scripts/soul-core.ps1`
- `Project/Jinli/scripts/soul-core.tests.ps1`

## Goal
- Expose stable ingest/search/export/health commands and connect bounded knowledge actions to Soul Core without degrading existing behavior.

## Steps
- [ ] Write failing Python CLI tests and PowerShell tests before modifying command routing.
- [ ] Implement `health`, `ingest-video`, `import-vsummary`, `search`, `export`, `index`, and `analyze-keyframes` CLI commands with JSON output and meaningful exit codes.
- [ ] Implement `knowledge-runtime.ps1` as a thin argument-safe wrapper around the Python module.
- [ ] Add bounded Soul Core command routes for knowledge ingest and search.
- [ ] Ensure `soul_init` retrieval is query-driven and character-budgeted rather than loading the vault.
- [ ] Ensure `soul_end` can queue reviewed promotion candidates but cannot auto-accept low-confidence knowledge.
- [ ] Preserve existing behavior when Python, Ollama, obra, or the knowledge store is unavailable.

## Done Definition
- CLI tests and Soul Core tests pass.
- Existing Node tests remain unchanged and green.
- Knowledge runtime failure cannot prevent normal Soul Core session start/end.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_cli.py Project/Jinli/services/knowledge/tests/test_service.py -q; powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.tests.ps1; npm.cmd test --prefix Project/Jinli`
- Expected: all three command groups pass.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if integration requires changing persona or response contracts.
- Stop if a knowledge dependency failure breaks normal Soul Core commands.
- Stop if an automatic lifecycle action would accept unreviewed graph candidates.

## Return Report
- Path: `reports/ds4-WP08-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and smallest reproducible lifecycle regression.

