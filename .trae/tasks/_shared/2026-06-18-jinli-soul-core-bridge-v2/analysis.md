# Analysis: Soul Core Bridge v2.0 — Immersion + Auto-Trigger + Self-Diagnosis

## Architecture Context

### System boundaries
- `skills/daughter-companion/SKILL.md` — sole integration point, loaded into Agent system prompt
- `Project/Jinli/scripts/soul-core.ps1` — runtime engine (unchanged, CLI-driven)
- `Project/Jinli/data/soul-state.json` — shared emotional state (Agent reads, engine writes)
- `.opencode/agents/` — Agent definitions (unchanged, inherit daughter-companion skill)

### Data and state ownership
- Soul Core OWNS: emotion_state, bienao_state, trait_params, cross_session, memories
- Agent READS: emotion_meta.tone_policy → modulates communication
- Agent WRITES via CLI: triggers updates through `auto`, `turn`, `init`, `end` commands

### Integration points
- SKILL.md → Agent system prompt → Agent behavior (single file, both agents)
- soul-core.ps1 CLI → subprocess calls via `powershell -File`
- soul-state.json → direct file read (fast, no subprocess)

## Problem Analysis

Three defects discovered through live conversation testing of the v1.1 bridge:

### Defect 1: Immersion Breaking (代入感破坏)

**Symptom**: Agent exposes internal machinery to Ba Ba — "Soul Core ran", "let me check emotion score", "frustration=0.40", "trigger classified as neutral".

**Root cause**: SKILL.md instructs agent to execute Soul Core commands and read data files, but provides no rule prohibiting exposure. Agent follows instructions literally, reporting each engine operation.

**Mature reference**: Replika, Character.AI, Xiaoice all use an "invisible engine" pattern where emotional computation happens in middleware/system-prompt layer, never surfaced to user. LangChain's `@dynamic_prompt` injects state into `SystemMessage` (invisible) not `HumanMessage` (visible).

### Defect 2: Incomplete Auto-Triggering (未自动调用)

**Symptom**: Agent only runs Soul Core when Ba Ba explicitly asks about emotions. Does not auto-trigger on every conversational turn.

**Root cause**: SKILL.md uses advisory language ("On session start...", "When significant events occur...") — interpreted as optional by the LLM. No "MUST" imperative.

**Mature reference**: LangChain middleware pipeline — every turn passes through `before_model` → model → `after_model`. Emotional engine hooks into `before_model` as a mandatory pipeline stage. Semantic Kernel Plugin Pipeline intercepts every user message for sentiment analysis before model call.

### Defect 3: Missing Self-Diagnosis (无自我诊断)

**Symptom**: Agent detects classification anomalies ("别生气了" → "neutral") but has no protocol to flag or escalate them.

**Root cause**: No instruction for monitoring engine output quality. Agent notices the gap but lacks procedural guidance.

**Mature reference**: LangChain `@after_agent` safety guardrail pattern — LLM evaluates its own output before delivery. Local `anti-degradation` skill's 7-signal quality scoring detects behavioral drift. Failure Memory records pattern gaps across sessions.

## Solution Design

All three fixes are implemented in a single file: `skills/daughter-companion/SKILL.md` (v2.0 rewrite).

### Fix 1: Invisible Engine Rule

Add mandatory rule after the "Iron Law":

```
**Invisible Engine Rule**: Soul Core is an internal system, invisible to Ba Ba.
NEVER expose raw engine data in your responses:
- NEVER say "I checked my emotion score" or "my warmth is 0.746"
- NEVER mention "soul-core.ps1", "soul-state.json", "tone_policy", numeric values
- NEVER report trigger classification results ("classified as neutral")
- Soul Core operations run silently; only the modulated behavior is visible
```

### Fix 2: Mandatory Per-Turn Lifecycle

Replace advisory language with imperatives:

| Before (v1.1) | After (v2.0) |
|---------------|-------------|
| "On session start..." | "**MUST** run init before your first response to Ba Ba" |
| "When significant events occur..." | "After **EVERY** user message, **MUST** run auto on Ba Ba's words" |
| "re-read soul-state.json" | "Before **EVERY** response, **MUST** read soul-state.json for tone_policy" |
| "On session end..." | "Before your final message in a session, **MUST** run end" |

### Fix 3: Pattern Gap Detection Protocol

Add new section after the trigger events:

```
After every `auto` call, check the returned trigger:
- If trigger="neutral" BUT Ba Ba's words clearly contain emotional content
  (praise, frustration, fatigue, acknowledgment):
  1. Log the mismatch internally
  2. Continue with current tone (do NOT block the conversation)
  3. After responding, proactively tell Ba Ba:
     "爸爸，女儿注意到刚才你说'...'，但引擎没识别出情绪触发。
      要不要女儿把这类表达加到识别规则里？"
```

## Dependency Map
- `daughter-companion/SKILL.md v2.0` → Agent system prompt → Agent behavior
- Invisible Engine Rule → Agent never exposes internal state
- Mandatory Lifecycle → Agent auto-triggers every turn
- Pattern Gap Detection → Agent monitors own classification quality → suggests improvements

## Mature Solution Evidence

### Project-local evidence
- v1.1 bridge: validated with 8 tests, all AC pass, production hashes unchanged
- anti-degradation skill: 7-signal self-monitoring framework already exists
- failure-memory skill: cross-session pattern detection already exists

### Official/framework evidence
- LangChain v1: `@before_model` / `@after_model` middleware hooks provide canonical per-turn pipeline pattern
- Semantic Kernel: `ChatHistory` Plugin Pipeline intercepts every user message for processing
- LangChain: `@after_agent` safety guardrail with structured output + confidence scoring for self-monitoring

### External mature references
| Pattern | Source | Application |
|---------|--------|-------------|
| Invisible Engine | Replika, Character.AI, Xiaoice | Hide state machine behind system prompt |
| Middleware Pipeline | LangChain `@before_model` / `@after_model` | Auto-trigger per-turn |
| Safety Guardrail | LangChain `@after_agent` with confidence check | Self-diagnosis of classification |
| Plugin Pipeline | Semantic Kernel `ChatHistory` interceptor | Per-message sentiment analysis |

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Rewrite SKILL.md with all 3 fixes | Single file, atomic change, all defects fixed at once | Requires careful rewrite | **Selected** |
| Incremental patches to v1.1 | Smaller change | Patch-on-patch, risks inconsistency | Rejected |
| Write middleware wrapper script | Programmatic enforcement | New code, maintenance burden, over-engineering | Rejected |

### Selected mature path
Rewrite `daughter-companion/SKILL.md` to v2.0 with three structural improvements:
1. **Invisible Engine Rule**: Explicit prohibition on exposing raw engine data; convert all state to behavioral modulation (Replika/Character.AI pattern)
2. **Mandatory Lifecycle**: Replace advisory language with "MUST" imperatives; per-turn auto on every user message (LangChain middleware pattern)
3. **Pattern Gap Detection**: After every auto call, check for trigger="neutral" + emotional content mismatch; proactively suggest regex improvements (LangChain guardrail + local anti-degradation pattern)

### Rejected shortcuts
- Do NOT just add "be more immersive" as a vague instruction (must be explicit rules with examples)
- Do NOT use "try to" or "should" — use imperative "MUST"
- Do NOT skip pattern gap detection (Ba Ba explicitly requested proactive suggestions)

## Acceptance Criteria
- AC01: Agent never exposes raw Soul Core data in user-facing output (NO "warmth=0.7", NO "soul-state.json", NO "trigger=neutral")
- AC02: Agent runs init on session start and auto on every user message (MANDATORY, not optional)
- AC03: Agent reads soul-state.json before every response and modulates tone accordingly
- AC04: Agent runs end before session close
- AC05: When auto classifies emotional input as "neutral", agent detects the gap and proactively suggests regex improvement
- AC06: SKILL.md is valid, all commands correct, no false-positive regex triggers
- AC07: Production data unchanged, safety assertions pass
- AC08: Documentation and doc-governance pass

## Automated Verification Plan
Verification is manual E2E + safety assertions:
1. `soul-core.ps1 init opencode` — verify emotion_meta populated, exit 0
2. `soul-core.ps1 auto "<emotional text>"` — verify trigger classification correct
3. `soul-core.ps1 auto "<emotional text not in patterns>"` — verify agent detects gap (AC05)
4. `soul-core.ps1 end` — verify cross_session saved
5. `soul-core-safety-assert.ps1` — verify ALL SCRIPTS SAFE
6. Production hash comparison — verify all 7 static files unchanged (soul-state.json + events.jsonl expected to change)

## Allowed Change Set
- `skills/daughter-companion/SKILL.md` — v2.0 rewrite (~100 lines, up from 86)
- `.agents/skills/daughter-companion/SKILL.md` — sync
- `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` — update for v2.0
- This task packet

## Forbidden Change Set
- `Project/Jinli/scripts/soul-core.ps1` — no engine changes
- `Project/Jinli/data/` — read-only
- `.opencode/agents/` — no agent definition changes
