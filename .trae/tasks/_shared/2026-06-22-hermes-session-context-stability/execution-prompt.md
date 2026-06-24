# Task Execution Prompt: Hermes Session Context Stability

## Role

Act as the lead Hermes runtime/workflow repair engineer. Preserve user session data and fix the root causes of conversation history instability with evidence-backed changes.

## Goal

Stabilize Jinli Hermes profiles so conversation history, context metadata, and compression behavior are reliable and verifiable.

## Task Packet Truth Sources

1. `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/requirements.md`
2. `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/analysis.md`
3. `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/spec.md`
4. `.trae/tasks/_shared/2026-06-22-hermes-session-context-stability/tasks.md`

## Confirmed Decisions

- Fix conversation history, context length, and violent compression first.
- Treat compression model quality as one contributor, not the sole root cause.
- Make model/context/compression settings explicit in durable profile overlays.
- Preserve real session history and do not edit secrets.
- Add non-destructive diagnostics before any cleanup.

## Accepted Architecture

- Profile overlays are the durable source of truth.
- Runtime profile configs are generated through `sync-hermes-workflow.ps1`.
- Compression remains enabled but uses conservative settings and fail-closed behavior.
- Session list/search behavior follows existing Hermes lineage APIs and avoids presenting true ghost sessions as normal history.
- Diagnostics report current DB anomalies without destructive mutation.
- Desktop stream handling must treat terminal `run.failed` / `response.failed` events as turn-ending errors, preserving any visible streamed delta as a failed assistant bubble.

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
- Real `.env` files and secret stores
- Existing session rows with actual messages
- Other active task packets except read-only inspection
- Unrelated dirty worktree changes
- Git history or remote publication

## Non-Goals

- Do not redesign Hermes wholesale.
- Do not disable compression as the final default unless tests prove no safe compression path exists.
- Do not delete session history in this task.
- Do not create or rotate credentials.
- Do not claim the bug is fixed without focused verification.

## Acceptance Criteria

- AC01: Profile overlays use intended model, explicit context length, and consistent conservative compression defaults.
- AC02: Runtime profile configs match overlays after sync.
- AC03: Compression preserves more recent context and fails closed on summary failure.
- AC04: Session listing/search avoids true ghost sessions by default and dedupes compression lineages to the latest usable tip.
- AC05: Non-destructive diagnostics report ghost sessions, multi-child lineages, and severe compression ratios.
- AC06: Focused Hermes tests pass.
- AC07: Desktop stream handling persists terminal run failures as assistant error messages instead of dropping the visible reply.
- AC08: Verification report maps evidence back to all acceptance criteria and residual risk.

## Verification Commands

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Check` -> expected: profile checks pass without inline secrets.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Apply` -> expected: runtime profile configs sync while `.env` is preserved.
- `python -m pytest tests/hermes_cli/test_web_server.py -q` -> expected: pass.
- `python -m pytest tests/agent/test_context_compressor_summary_continuity.py tests/agent/test_compressor_historical_media.py -q` -> expected: pass.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\diagnose-hermes-sessions.ps1` -> expected: completes without destructive changes.
- `npm run test:ui -- src/app/session/hooks/use-message-stream.test.tsx` from `.tools/hermes-worker/hermes-agent/apps/desktop` -> expected: pass.

## Stop Conditions

- A required gate fails.
- A needed change touches secrets or project application code.
- A cleanup would delete sessions with actual messages.
- Existing unrelated user changes would be overwritten.
- The selected model/context facts cannot be verified from local config/catalog or official provider evidence.
- Verification exposes an architecture issue outside the accepted scope.

## Evidence Rule

Do not claim a file exists, a test passed, a task is done, or an acceptance criterion is satisfied without current-session evidence.
