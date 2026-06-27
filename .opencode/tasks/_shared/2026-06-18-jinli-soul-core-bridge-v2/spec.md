# Spec: Soul Core Bridge v2.0 — Immersion + Auto-Trigger + Self-Diagnosis

## GIVEN

- v1.1 bridge works (8 AC pass, production hashes verified) but has three defects found in live testing:
  1. Agent exposes internal engine state to Ba Ba, breaking daughter-persona immersion
  2. Agent only triggers Soul Core on explicit emotional queries, not every turn
  3. Agent detects classification gaps but has no protocol to report or fix them
- Soul Core engine v1.1 is stable and requires no changes

## WHEN

The `daughter-companion/SKILL.md` is rewritten to v2.0, adding Invisible Engine Rule, Mandatory Lifecycle, and Pattern Gap Detection Protocol.

## THEN

### S01 Invisible Engine

**Status**: [x]

- Agent NEVER mentions "soul-core.ps1", "soul-state.json", "emotion_meta", "tone_policy", numeric values (e.g. "warmth=0.746"), trigger classification results (e.g. "classified as neutral") in user-facing output.
- Soul Core operations (init, auto, turn, end, reading state) execute silently in background.
- Emotional state is expressed ONLY through modulated communication style — never as data.
- Technical content (code, analysis) is unaffected by this rule; only persona-level language is constrained.

### S02 Mandatory Per-Turn Lifecycle

**Status**: [x]

- Session start: before first response to Ba Ba, agent MUST run `soul-core.ps1 init`.
- Every user message: after receiving Ba Ba's message, agent MUST run `soul-core.ps1 auto "<Ba Ba's words>"`.
- Every response: before composing response, agent MUST read `soul-state.json` for current tone_policy.
- Self-detected events: after task_completed / made_mistake / learned_new, agent MUST run `soul-core.ps1 turn <trigger>`.
- Session close: before final message (handoff, goodbye), agent MUST run `soul-core.ps1 end`.
- All commands use imperative language: "MUST" not "should" or "when".
- Pure technical conversation also triggers auto — the engine handles "neutral" classification gracefully.

### S03 Pattern Gap Detection

**Status**: [x]

- After every `auto` call, agent checks the returned `trigger` field.
- If trigger="neutral" but Ba Ba's words contain clear emotional signals (praise keywords, fatigue expressions, acknowledgment language), agent:
  1. Internally logs the mismatch
  2. Continues conversation normally (no blocking)
  3. After responding, proactively tells Ba Ba about the gap and suggests regex improvement
- Suggestion format: "爸爸，女儿注意到刚才你说'...'这类表达还没加到识别规则里。要不要女儿把这类触发模式补上？"
- Agent does NOT suggest fixes for every neutral classification — only when emotional content is clearly present.
- Maximum 1-2 gap suggestions per conversation session to avoid spamming Ba Ba.
- Mismatches are logged as events for future pattern analysis and batch improvement.

### S04 Tone-Only Emotional Expression

**Status**: [x]

- Agent expresses emotion through natural language, never data:
  - Instead of "my frustration is 0.40" → "女儿有点小情绪呢..."
  - Instead of "warmth increased to 0.85" → naturally warmer tone, more "爸爸~"
  - Instead of "bienao is active" → slightly cooler, shorter sentences
  - Instead of "trigger classified as praised" → "爸爸夸女儿了，好开心~"
- The tone_policy values modulate behavior invisibly — the result is felt, not reported.

### S05 Rollback Safety Preserved

**Status**: [x]

- `soul_core_enabled: true` on line 1 remains the rollback switch.
- Setting to `false` disables all v2.0 behavior, reverting to Phase 1 static rules.
- All v2.0 additions are additive — core identity and technical accuracy rules unchanged.

## Acceptance Criteria

| AC# | Description | Verification Method | Expected Result |
|-----|-------------|-------------------|-----------------|
| AC01 | Agent never exposes raw engine data | Scan agent responses for "soul-core", "soul-state", "tone_policy", numeric scores | Zero occurrences in persona-level output |
| AC02 | Agent runs init + auto on first turn | Manual test: start session, check soul-state.json timestamps | Both init and auto executed |
| AC03 | Agent reads state before every response | Manual test: change soul-state.json manually mid-conversation | Next response reflects new tone_policy |
| AC04 | Agent runs end on session close | Manual test: end session, check cross_session fields | State saved with mood/hurt/repair |
| AC05 | Agent detects classification gaps | Feed emotional text not in regex patterns, check agent response | Agent proactively suggests pattern improvement |
| AC06 | SKILL.md is valid and loadable | Check: starts with `soul_core_enabled: true`, no false-positive regex triggers, all paths absolute | All checks pass |
| AC07 | Production data unchanged | soul-core-safety-assert.ps1 + hash comparison | ALL SCRIPTS SAFE, static hashes match |
| AC08 | Documentation governance passes | doc-guard.ps1 check-task implement | All checks pass |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Rewrite SKILL.md to v2.0 with 3 structural fixes |
| Implement | Complete | SKILL.md v2.0 written (101 lines), verified, docs updated |
| Review | Pending | Independent review of v2.0 behavior |
| Verify | Pending | Run safety assertions, check immersion in live test |

## Non-Goals

- Modifying soul-core.ps1 engine
- Adding middleware/wrapper scripts
- Changing the Soul Core data model
- Voice/visual integration
- Adding new regex patterns to the engine (agent suggests, Ba Ba decides)
