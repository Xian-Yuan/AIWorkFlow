# WP01: Knowledge Runtime Foundation

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
- Read only this package, the task files listed below, and the existing Jinli vision contracts pattern.
- Do not inspect unrelated projects or redesign the service.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP01
- This package handles configuration, versioned contracts, paths, and atomic file utilities only.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/__init__.py`
- `Project/Jinli/services/knowledge/config.py`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/services/knowledge/io_utils.py`
- `Project/Jinli/services/knowledge/requirements.txt`
- `Project/Jinli/services/knowledge/tests/__init__.py`
- `Project/Jinli/services/knowledge/tests/test_config.py`
- `Project/Jinli/services/knowledge/tests/test_contracts.py`
- `Project/Jinli/services/knowledge/tests/test_io_utils.py`
- `Project/Jinli/data/knowledge/schemas/`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/scripts/soul-core.ps1`
- `Project/Jinli/data/memory.db`
- `E:\ObsidianVault`
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/routing.md`
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`
- `Project/Jinli/services/vision/contracts.py`

## Goal
- Create the importable knowledge package, typed configuration, atomic UTF-8/JSONL utilities, and versioned JSON schemas required by later packages.

## Steps
- [ ] Write failing tests for vault precedence, D-drive drift reporting, explicit apply intent, path containment, atomic replacement, JSONL append, and malformed schema payloads.
- [ ] Add configuration fields for project root, data root, vault root, tool root, Ollama endpoint, vsummary revision, obra revision, timeouts, and confidence thresholds.
- [ ] Make `E:\ObsidianVault` the configured default while reporting an existing conflicting `OBSIDIAN_VAULT_PATH`.
- [ ] Implement schemas for video metadata, transcript entry, transcript segment, worker job, worker output envelope, graph candidate, graph node, graph edge, and evidence record.
- [ ] Validate with `jsonschema`; return structured validation errors and never coerce missing provenance.
- [ ] Add atomic write helpers that reject path escape outside their declared root.

## Done Definition
- All WP01 tests pass.
- Schema files are valid Draft 2020-12 JSON Schema.
- Importing the package has no network, database, environment, or vault side effects.
- No environment variable or real vault content is changed.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_config.py Project/Jinli/services/knowledge/tests/test_contracts.py Project/Jinli/services/knowledge/tests/test_io_utils.py -q`
- Expected: all WP01 tests pass.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if the canonical design requires a schema field that cannot be represented without an architecture change.
- Stop if Python dependency installation would modify a shared global environment.
- Return `Status: blocked` with the smallest reproducible blocker.

## Return Report
- Path: `reports/ds4-WP01-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked`.
- Include the failing command, actual output, and smallest lead decision required.

