# WP<NN>: <Work Package Name>

Owner model: unclaimed
Difficulty: simple | medium | hard
Status: unclaimed | claimed | done | blocked

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

## Return Report
- Path: `reports/<agent-name>-WP<NN>-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting
- If blocked, write the same report path with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead agent.
- Do not edit outside Allowed Paths while blocked.

## Publisher Checklist
- [ ] No `<placeholder>` text remains in this work package.
- [ ] Allowed Paths and Forbidden Paths are concrete.
- [ ] Required Verification has a real command and expected result.
- [ ] Return Report path is concrete.
