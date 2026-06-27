# Task Execution Prompt: Submit Jinli System And AI Workflows

## Role

Git submission worker operating under strict repository-boundary and secret-safety rules.

## Goal

Create safe commits for the shared AI workflow root repository and the independent `Project/Jinli` system repository, then write a report.

## Task Packet Truth Sources

1. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/requirements.md`
2. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/analysis.md`
3. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/spec.md`
4. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/work-packages/WP01-root-ai-workflow-commit.md`
5. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/work-packages/WP02-jinli-system-repo-commit.md`
6. `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/work-packages/WP03-final-submit-report.md`

## Confirmed Decisions

- Root repository and `Project/Jinli` are separate commit streams.
- Do not force-add `Project/Jinli` into the root repository.
- Do not push to any remote.
- Do not commit `.env`, runtime data, output folders, node modules, caches, temp test directories, or captured command output files.

## Accepted Architecture

- Commit root AI workflow in the root repository.
- Initialize or use an independent Git repository in `Project/Jinli`.
- Write a report with commit hashes and safety evidence.

## Allowed Paths

- Root commit: `AGENTS.md`, `Docs/AI/**`, `Docs/Memory/**`, `Docs/superpowers/**`, `skills/**`, `.trae/**`, `.opencode/**`, `.vscode/**`.
- Jinli commit: `Project/Jinli/**` from inside the independent `Project/Jinli` repository, excluding ignored runtime/temp/secret paths.
- Report: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/reports/submit-report.md`.

## Forbidden Paths

- Root commit must not stage `Project/**`.
- Do not stage `.env`, `.env.*`, `node_modules/**`, `data/**`, `runtime/**`, `output/**`, `.pytest_cache/**`, `jinli_evo_test_*/**`, `jinli_mem_test_*/**`, `p2_wechat_test_*/**`, `pytest-of-*/**`, `*_out.txt`, `*_err.txt`.
- Do not delete, reset, or revert user changes.

## Non-Goals

- No remote push.
- No cleanup or deletion of generated folders.
- No implementation changes beyond optional `Project/Jinli/.gitignore` hardening.

## Acceptance Criteria

- AC01: Root AI workflow commit exists and excludes `Project/`.
- AC02: Jinli system commit exists in an independent `Project/Jinli` repository.
- AC03: Staged-path audits and secret scans were run before each commit.
- AC04: `.env`, runtime state, output, node modules, caches, and temp test folders were excluded.
- AC05: Final report records commit hashes or blocker details.

## Verification Commands

- `git diff --cached --name-only -- Project` in root -> expected: no output.
- `git log -1 --oneline` in root -> expected: root workflow commit hash.
- `git log -1 --oneline` in `Project/Jinli` -> expected: Jinli baseline commit hash.
- Secret scan commands from work packages -> expected: no real credentials.

## Stop Conditions

- Existing staged files are present before work begins.
- A real secret appears in staged content.
- Root staging includes `Project/`.
- Jinli staging includes `.env`, runtime state, output, node modules, caches, or temp test folders.
- `Project/Jinli/.git` already exists but has unexpected remote/history that changes the plan.
- Any command would require deleting or reverting user changes.

## Evidence Rule

Do not claim a commit exists, a path was excluded, a scan passed, or a test ran without including current-session command output in the final report.

