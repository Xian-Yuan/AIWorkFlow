# Living Spec: Hermes Session Context Stability

## Current Phase

Implement repair complete; verification evidence recorded.

## Goal

Stabilize HermesAgent conversation history, context metadata, and compression behavior for Jinli profiles.

## Scenarios

### S1: Profile model and context are explicit

**Status**: [x]

GIVEN Ba Ba starts a Jinli Hermes profile  
WHEN Hermes reads the profile config  
THEN the main model name is the intended `glm-5.1` profile model and context length is explicit rather than inferred from failed probing.

### S2: Compression is conservative

**Status**: [x]

GIVEN a conversation approaches the context threshold  
WHEN automatic compression is considered  
THEN the threshold, target ratio, and protected recent turns reduce the risk of losing latest user content.

### S3: Compression summary failure fails closed

**Status**: [x]

GIVEN the auxiliary compression provider cannot generate a valid summary  
WHEN compression runs  
THEN Hermes does not replace the conversation with destructive truncation.

### S4: Session history avoids duplicate compression rows

**Status**: [x]

GIVEN one logical conversation has compression parent/child rows  
WHEN the UI/API lists or searches sessions  
THEN the logical chat is represented by the latest usable tip, not repeated similar rows.

### S5: Ghost sessions are not shown as useful history

**Status**: [x]

GIVEN a session row has zero metadata messages and zero actual messages  
WHEN default history is listed  
THEN it does not pollute the normal session picker.

### S6: Diagnostics are non-destructive

**Status**: [x]

GIVEN existing Hermes DBs contain risky lineages and ghost sessions  
WHEN the diagnostic command runs  
THEN it reports findings and safe cleanup candidates without deleting content.

### S7: Terminal stream failure remains visible

**Status**: [x]

GIVEN Hermes has already streamed part of an assistant reply  
WHEN the backend emits `run.failed` or `response.failed` for the same turn  
THEN the desktop UI keeps the assistant bubble visible, marks it failed, clears busy state, and shows the failure reason.

## Progress Summary

- Plan packet created from Ba Ba's explicit repair request.
- Existing diagnosis identifies compression, session branching, ghost sessions, and profile drift as combined root causes.
- Profile overlays and runtime configs now use `glm-5.1`, `context_length: 200000`, conservative compression settings, and `abort_on_summary_failure: true`.
- Session listing keeps active empty handshakes and broken compression roots, hides old true ghosts, preserves metadata-drift sessions that have real messages, and chooses message-bearing compression children over newer ghosts.
- Non-destructive diagnostics script added.
- Reopened after the desktop UI still dropped visible assistant text when a structured terminal failure arrived.
- Jinli main model/provider pairing now uses OpenRouter `z-ai/glm-5.1`, with sync-script sanity checks preventing the previous XF-Coding mismatch.
- Desktop stream handling now persists `run.failed` / `response.failed` as assistant errors and finalizes `run.cancelled` without leaving the session busy.
- Renderer `dist` was rebuilt with `npx vite build` so the local desktop app can load the updated hook after restart.

## Decisions

- Use repository profile overlays as durable source of truth.
- Keep compression enabled but conservative and fail-closed.
- Add diagnostics before any destructive cleanup.
- Preserve all real session history.
- Treat backend terminal failure events as first-class desktop stream errors.

## Verification State

- `sync-hermes-workflow.ps1 -Check`: passed.
- `sync-hermes-workflow.ps1 -Apply`: passed.
- Hermes session/state related tests: passed.
- Compressor continuity/historical media tests: passed.
- Full `test_web_server.py`: unrelated Windows wrapper-alias test remains failing; session/history subset passed.
- Desktop stream failure regression: passed, 3/3.
- Desktop TypeScript type-check: passed.
- Renderer production build: `npx vite build` passed.

## Changelog

- 2026-06-22: Created task packet.
- 2026-06-22: Implemented profile, session history, and diagnostics repair.
- 2026-06-22: Reopened to fix terminal failure event handling and provider/model pairing regression.
- 2026-06-22: Completed recurrence repair for provider/model pairing and terminal stream failure UI persistence.
