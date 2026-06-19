# WP<NN>: <Work Package Name>

Owner model: unclaimed
Difficulty: simple | medium | hard
Status: unclaimed | claimed | done | blocked
Target model: deepseek-v4-flash | other
Fresh context required: yes | no

## Worker Profile
- Profile: ds4-flash | general
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget
- Read only this package and the files listed under Read First.
- Do not inspect unrelated repository files or reconstruct the full architecture.

## Root Cause Boundary
- Root Cause ID: `<RCxx-or-initial>`
- This package handles exactly one bounded implementation concern.

## Task Packet
- Root: `.trae/tasks/<project>/<task-name>/`
- Parent task: `<task-name>`

## Allowed Paths
- `<exact/path>`

## Forbidden Paths
- `<exact/path-or-pattern>`

## Read First
- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`

## Goal
- `<one concrete goal>`

## Steps
- [ ] `<step 1>`
- [ ] `<step 2>`

## Done Definition
- `<observable completion condition>`

## Required Verification
- Command: `<command>`
- Expected: `<expected result>`

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop when a required change falls outside Allowed Paths.
- Stop after the exact verification command fails for a reason outside this package.
- Return `Status: blocked` with the smallest reproducible blocker.

## Return Report
- Path: `reports/<agent-name>-WP<NN>-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.
- Must include the Worker Authority section from `agent-result-template.md`.

For `authority_profile: issuer-worker-v1`, the Issuer replaces the Markdown return path with the exact signed-capability JSON path:

```text
reports/WP<NN>-A<NNN>/result.json
```

The Worker submits it only through `worker-submit.ps1 result`; it does not edit `tasks.md`, `.task.yaml`, or verification state.

## Failure Reporting
- If blocked, write the same report path with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead agent.
- Do not edit outside Allowed Paths while blocked.

## Publisher Checklist
- [ ] No `<placeholder>` text remains in this work package.
- [ ] Allowed Paths and Forbidden Paths are concrete.
- [ ] Required Verification has a real command and expected result.
- [ ] Return Report path is concrete.
- [ ] DS4 packages have a single Root Cause ID and require a fresh context.
