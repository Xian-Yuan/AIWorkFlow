# Verification Report: Hermes Session Context Stability

Verification Result: pass with noted process/runtime caveats  
Verified at: 2026-06-22 03:50 +08:00  
Verifier: codex  
Verifier role: lead  
Worker model: not-applicable

## Review Basis

- User-reported recurrence: Hermes reply appeared for about 1 second, then disappeared without a persistent response.
- Root cause evidence: latest desktop log showed `Provider: custom`, `Model: glm-5.1`, `Endpoint: https://maas-coding-api.cn-huabei-1.xf-yun.com/v2`, and `PathDomainError: Model Not Found`.
- UI evidence: backend API-server emits terminal failures as `run.failed`, while the desktop stream hook previously only handled `error`.

## Automated Verification

| Command | Result | Evidence |
|---|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-22-hermes-session-context-stability plan` | pass | Plan gate passed after adding desktop UI source/dist to allowed paths. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-state.ps1 can-edit _shared/2026-06-22-hermes-session-context-stability` | pass | `EDIT AUTHORIZED`. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-22-hermes-session-context-stability implement` | pass | Implement gate passed: all tasks checked and doc governance passed. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-22-hermes-session-context-stability implement -Apply` | pass | Transitioned task to `phase: review` and synced spec scenario count to 7/7. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-22-hermes-session-context-stability review` | blocked | `review_result is pass` failed because the packet is now in review with `review_result: pending`. Generic `review-pass` transitions are disabled by issuer-signed workflow rules, and this legacy packet has no issuer identity/seal. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Check` | pass | 2 profiles passed, 0 failures, 0 warnings; new Jinli model/provider sanity check passed. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Apply` | pass | Synced both profile configs, MCP JSON, skill bundles, and guard plugin; preserved existing `.env`. |
| `Select-String` checks on runtime profile configs | pass | Both runtime configs show main `provider: openrouter`, `default: z-ai/glm-5.1`, `context_length: 200000`; auxiliary compression remains custom BigModel endpoint. |
| `npm.cmd run test:ui -- src/app/session/hooks/use-message-stream.test.tsx` | pass | 1 test file passed; 3 tests passed. |
| `npm.cmd run type-check` | pass | `tsc -b` completed successfully. |
| `npx.cmd vite build` | pass | Renderer production build completed; generated updated `dist/assets/index-*.js` and CSS. |
| `.\\venv\\Scripts\\python.exe -m pytest -o addopts='' tests/test_hermes_state.py -q -k "DeleteEmptySessions or CompressionChainProjection"` | pass | 16 passed, 242 deselected. |
| `.\\venv\\Scripts\\python.exe -m pytest -o addopts='' tests/hermes_cli/test_web_server.py -q -k "get_sessions or search_dedupes or branch_specific or EmptySessions"` | pass | 16 passed, 221 deselected. |
| `.\\venv\\Scripts\\python.exe -m pytest -o addopts='' tests/agent/test_context_compressor_summary_continuity.py tests/agent/test_compressor_historical_media.py -q` | pass | 30 passed. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\diagnose-hermes-sessions.ps1` | pass | Completed read-only diagnostics for default, `jinli-implementer`, and `jinli-planner` DBs; no rows modified. |
| `npm.cmd run build` | blocked by local vendored checkout shape | `write-build-stamp.cjs` could not determine a git commit because `.tools/hermes-worker/hermes-agent` is not the expected git checkout. `npx vite build` was used for renderer dist instead. |

Note: Python pytest commands use `-o addopts=''` because the local venv lacks `pytest-timeout`; otherwise pytest rejects the configured timeout options before collecting tests.

## Acceptance Criteria

| ID | Requirement | Result | Evidence |
|---|---|---|---|
| AC01 | Profile overlays use intended model, explicit context length, and consistent conservative compression defaults. | pass | `jinli-planner` and `jinli-implementer` overlays now set main `provider: openrouter`, `default: z-ai/glm-5.1`, and `context_length: 200000`; compression remains conservative with `threshold: 0.85`, `target_ratio: 0.6`, `protect_last_n: 60`, and `abort_on_summary_failure: true`. |
| AC02 | Runtime profile configs match overlays after sync. | pass | `sync-hermes-workflow.ps1 -Apply` passed; runtime profile configs show the same main provider/model/context pairing. |
| AC03 | Compression preserves more recent context and fails closed on summary failure. | pass | Conservative compression settings are present; compressor continuity and historical-media suites passed 30/30. |
| AC04 | Session listing/search avoids true ghost sessions by default and dedupes compression lineages to latest usable tip. | pass | Existing state/web focused suites passed: 16 state tests and 16 web/session tests. |
| AC05 | Non-destructive diagnostics report ghost sessions, multi-child lineages, and severe compression ratios. | pass | Diagnostic script completed in read-only mode and reported current DB anomalies without deleting session rows. |
| AC06 | Focused Hermes tests pass. | pass | UI stream tests 3/3, TypeScript check passed, state/web/compressor focused Python suites passed. |
| AC07 | Desktop stream handling persists terminal run failures as assistant error messages instead of dropping the visible reply. | pass | New Vitest coverage verifies `run.failed` preserves streamed text and error, `response.failed` extracts nested error messages, and `run.cancelled` clears busy state without dropping visible text. |
| AC08 | Verification report maps evidence back to all acceptance criteria and records residual risk. | pass | This report records command evidence, AC mapping, architecture compliance, test evidence, and residual risks. |

## Architecture Compliance

- Selected mature path followed: yes.
- Rejected shortcuts reintroduced: no.
- Project boundaries respected: yes.
- Documentation synchronized: yes.
- Secrets handled safely: no `.env` values were modified; final report does not include secret values.

Implementation followed the layered repair: durable profile overlays, runtime sync, sync-script regression guard, desktop stream failure handling, focused tests, TypeScript check, and renderer dist build. Existing real session history was preserved.

## Test Evidence

- UI stream regression:
  - `run.failed` after `message.delta` keeps `partial reply`, sets assistant error, clears `busy`, clears `awaitingResponse`, and clears `streamId`.
  - `response.failed` extracts nested `response.error.message`.
  - `run.cancelled` finalizes the visible streamed assistant bubble without leaving the session busy.
- Profile sync:
  - `sync-hermes-workflow.ps1 -Check`: 2 passed, 0 failed, 0 warnings.
  - `sync-hermes-workflow.ps1 -Apply`: synced both profiles and preserved `.env`.
- Runtime config:
  - `jinli-implementer` and `jinli-planner` main model now use OpenRouter `z-ai/glm-5.1`.
  - Auxiliary compression still uses custom BigModel `glm-4-flash`.
- Diagnostics:
  - Default DB: 4 sessions, 4 messages, 1 true ghost reported.
  - Implementer DB: 45 sessions, 5637 messages, 2 true ghosts, 6 multi-child parents, 2 severe compression-ratio rows reported.
  - Planner DB: 2 sessions, 161 messages, no true ghosts reported.
- Focused tests:
  - State/session safety subset: 16 passed.
  - Web session/history subset: 16 passed.
  - Compressor continuity/historical media: 30 passed.

## Residual Risk

- Hermes Desktop/profile processes may need a restart or profile reload for the new runtime config and rebuilt renderer `dist` to be loaded by the running app.
- Existing historical DB anomalies remain by design; this task did not delete session rows. Any cleanup should be a separate explicit task and must only delete sessions with both metadata message count 0 and actual messages count 0.
- `npm run build` is blocked in this vendored local layout by the build-stamp script expecting a git checkout at `.tools/hermes-worker/hermes-agent`; renderer dist was successfully rebuilt with `npx vite build`.
- The compression auxiliary key presence differs by profile environment; if a profile lacks `COMPRESSION_API_KEY`, compression summary may still fail closed. That is safer than destructive truncation but may require the user to set the key for best compression quality.
- Formal `task-guard review` / `task-guard verify` acceptance is not completed because the task packet is `legacy_untrusted` without issuer identity/seal; generic review/verify pass transitions are intentionally blocked. The implementation gate passed and all automated evidence above was freshly run.
