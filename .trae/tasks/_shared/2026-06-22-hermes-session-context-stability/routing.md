# Routing Decision: Hermes Session Context Stability

## Project Detection

- Project type: other
- Project: `_shared`
- System: Hermes Desktop Agent runtime/profile/session workflow
- Primary skills: `codex-project-router`, `hermes-project-router`, `systematic-debugging`
- Secondary skills: `anti-degradation`, `doc-governance`, `failure-memory`, `verification-before-completion`
- Collaboration mode: lead-owned direct implementation; no external workers

## Requirement Discovery Gate

- Change profile: deep
- Requirements status: confirmed
- Requirements document: `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/requirements.md`
- Execution prompt: `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/execution-prompt.md`
- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none

## Architecture Decision

Use a conservative, layered repair:

1. Make profile source overlays explicit and durable for model, context length, and compression.
2. Sync overlays to runtime through the existing Hermes workflow sync script.
3. Add non-destructive session/context diagnostics so existing DB risk is visible.
4. Patch Hermes session list/search behavior only where tests prove duplicate/ghost handling is incomplete.
5. Preserve all existing real conversation data.
6. Handle desktop stream terminal failure events so transient assistant deltas persist as an error message instead of disappearing from the UI.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- User confirmation evidence: Ba Ba explicitly requested repair and named the priority symptoms on 2026-06-22.

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Allowed Paths

- `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/`
- `.trae/hermes/profiles/jinli-planner/config.overlay.yaml`
- `.trae/hermes/profiles/jinli-implementer/config.overlay.yaml`
- `.trae/scripts/sync-hermes-workflow.ps1`
- `.trae/scripts/diagnose-hermes-sessions.ps1`
- `.tools/hermes-worker/profiles/jinli-planner/config.yaml`
- `.tools/hermes-worker/profiles/jinli-implementer/config.yaml`
- `.tools/hermes-worker/hermes-agent/agent/`
- `.tools/hermes-worker/hermes-agent/hermes_cli/`
- `.tools/hermes-worker/hermes-agent/hermes_state.py`
- `.tools/hermes-worker/hermes-agent/tests/`
- `.tools/hermes-worker/hermes-agent/apps/desktop/src/`
- `.tools/hermes-worker/hermes-agent/apps/desktop/dist/`
- `.tools/hermes-worker/hermes-agent/apps/desktop/build/`
- `.tools/hermes-worker/hermes-agent/apps/desktop/package.json`
- `skills/hermes-jinli-implementer/references/hermes-session-diagnosis.md`

## Forbidden Paths

- `Project/`
- Real `.env` files or secret stores
- Existing session rows with actual messages
- Other active task packets except read-only inspection
- Unrelated dirty worktree changes
- Git history or remote publication
