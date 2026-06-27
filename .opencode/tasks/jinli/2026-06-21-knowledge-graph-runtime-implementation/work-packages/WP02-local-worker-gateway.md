# WP02: Local Worker Gateway

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
- Read this package, WP01 results, task files, and the existing vision Ollama adapter.
- Do not inspect or edit unrelated lifecycle code.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP02
- This package handles provider calls, durable jobs, validation, retry, and cancellation only.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/providers/`
- `Project/Jinli/services/knowledge/worker_gateway.py`
- `Project/Jinli/services/knowledge/tests/test_providers.py`
- `Project/Jinli/services/knowledge/tests/test_worker_gateway.py`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/services/vision/`
- `Project/Jinli/scripts/`
- Real provider credentials
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/services/knowledge/config.py`
- `Project/Jinli/services/vision/inference.py`

## Goal
- Implement a provider-neutral, durable, schema-validating Local Worker Gateway with Ollama default behavior and explicit unavailable-provider degradation.

## Steps
- [ ] Write failing tests using an injected HTTP transport and temporary job directory.
- [ ] Define provider protocol methods for health and structured generation.
- [ ] Implement Ollama `/api/chat` structured-output calls with timeout, model name, low temperature, non-streaming response, and token metadata capture.
- [ ] Implement an external-provider interface that remains disabled until explicit configuration; do not embed credentials or make live calls.
- [ ] Implement queued, running, completed, failed, cancelled, and schema-validation-failed job transitions with atomic updates.
- [ ] Verify input hashes before invocation and output schema after invocation.
- [ ] Implement one bounded normalization retry and reject endless retries.
- [ ] Preserve raw provider output for diagnosis without admitting it into canonical records.

## Done Definition
- Deterministic tests cover success, timeout, unreachable provider, missing model, malformed JSON, schema failure, normalization retry, cancellation, and input-hash mismatch.
- A validated envelope is the only successful return type.
- Worker jobs never write outside `data/knowledge/jobs`.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_providers.py Project/Jinli/services/knowledge/tests/test_worker_gateway.py -q`
- Expected: all WP02 tests pass with no live provider required.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if WP01 contracts are missing or incompatible.
- Stop if implementation requires a provider-specific canonical schema.
- Stop after one failed normalization retry in a test scenario.

## Return Report
- Path: `reports/ds4-WP02-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and exact failing evidence.

