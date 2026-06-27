# Living Spec

## Scenario: Root AI workflow commit is bounded

## GIVEN
- The root repository owns shared AI workflow, docs, skills, task packets, and IDE adapters.

## WHEN
- A worker stages the root commit.

## THEN
- `Project/` is not staged in the root repository.
- Staged files are audited before commit.
- Secret scan runs before commit.

## Scenario: Jinli system commit is independent

## GIVEN
- `Project/Jinli` has no `.git` directory and is ignored by root Git.

## WHEN
- A worker submits the Jinli system.

## THEN
- The worker initializes or uses an independent Git repository inside `Project/Jinli`.
- `.gitignore` excludes secrets, runtime state, node modules, caches, generated outputs, and temp test folders.
- The Jinli baseline is committed separately from the root workflow commit.

## Scenario: Submission evidence is recorded

## GIVEN
- Both commit streams are attempted.

## WHEN
- The worker finishes or blocks.

## THEN
- A report records commit hashes or blocker details, staged scope, exclusions, secret scan results, and verification output.

## Progress Summary

- Plan: complete.
- Implement: delegated to another model.
- Review: pending worker report.
- Verify: pending worker report.

## Decisions

- Use two repositories.
- Do not force-add `Project/Jinli` into root.
- Exclude runtime and secret-bearing content.

## Verification State

- Pending worker execution.

