# WP06: Obsidian Index And MCP Bridge

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
- Read this package, obra README, and exported fixture note format.
- Do not implement graph algorithms or a custom MCP server.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP06
- This package handles pinned installation commands, process invocation, JSON result normalization, health checks, and fixture indexing.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/obra_bridge.py`
- `Project/Jinli/services/knowledge/tests/fixtures/obsidian_vault/`
- `Project/Jinli/services/knowledge/tests/test_obra_bridge.py`
- `Project/Jinli/scripts/knowledge-tools.ps1`

## Forbidden Paths
- `.trae/tasks/`
- obra/knowledge-graph source code
- Global npm configuration
- Real vault writes during tests
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/analysis.md`
- `Project/Jinli/services/knowledge/obsidian_export.py`
- obra README at `https://github.com/obra/knowledge-graph`

## Goal
- Reuse pinned obra/knowledge-graph for indexing, search, path, neighbors, node lookup, and MCP startup through a safe Jinli wrapper.

## Steps
- [ ] Write failing tests with an injected process runner for missing tool, wrong revision, index success, JSON parse failure, timeout, search result normalization, and path traversal.
- [ ] Implement a wrapper configuration pinned to revision `1d2481ece87807f2f695b8853a790b8c8aa62b29`.
- [ ] Add PowerShell inspect/install/update/index/search/mcp commands that use `npm.cmd` and never change global npm state.
- [ ] Require `KG_VAULT_PATH` to resolve to the configured vault and reject path mismatch.
- [ ] Normalize CLI JSON into compact records with node ID, title, path, score, links, and evidence excerpt.
- [ ] Add a fixture vault with at least one source note, three concept notes, and internal links.
- [ ] Keep install/network actions explicit; focused tests use a fake process runner.

## Done Definition
- Fixture-vault wrapper tests pass without network.
- Live wrapper can prove the pinned revision before indexing.
- MCP startup command is exposed but not automatically launched.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_obra_bridge.py -q`
- Expected: all WP06 tests pass offline.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if the installed obra revision differs and cannot be safely pinned.
- Stop if a command would install global npm packages.
- Stop if wrapper output cannot preserve note/evidence paths.

## Return Report
- Path: `reports/ds4-WP06-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and exact process output.

