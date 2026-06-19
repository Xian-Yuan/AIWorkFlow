# Analysis — Jinli Persona, Language, and Vision Foundation

Date: 2026-06-18  
Status: approved design, ready for implementation handoff

## Problem Statement

Jinli already has a working dynamic Soul Core and an MCP Plugin, but identity, language behavior, private response planning, visual observation, and future avatar actions do not yet have explicit ownership boundaries. Continuing to add responsibilities to `soul-core.ps1` would mix stable identity, mutable emotion, screen capture, privacy, and presentation into one runtime.

The approved design establishes five modules and versioned contracts so each capability can evolve independently.

## Architecture Context

### System boundaries

| Module | Owns | Must not own |
|---|---|---|
| Stable Persona Kernel | identity, values, interests, relationship definition, honesty boundaries, language fingerprint baseline | emotion state, screenshots, final response text, avatar runtime |
| Expression Orchestrator | scene routing, bounded private psychological summary, topic queue, expression willingness, action intention, final response plan | durable identity mutation, raw chain-of-thought, screenshot capture |
| Dynamic Soul | emotion, relationship state, memory retrieval, learned preferences | stable persona fields, visual service lifecycle, physical-action claims |
| Visual Perception | explicit start/stop, all-display capture, redaction, change detection, Qwen3-VL invocation, short-lived observations | long-term memory approval, avatar animation, autonomous screen control |
| Avatar Presentation | expression/animation state machine consuming `action_intent` | visual capture, personality decisions, claiming an action occurred without adapter evidence |

Project ownership remains in `Project/Jinli`. The installed MCP Plugin only exposes typed tools and delegates to project-owned runtime modules.

### Dependency map

```text
Stable Persona Kernel ─────┐
Dynamic Soul snapshot ─────┼─> Expression Orchestrator ─> ResponsePlan
Approved memory results ───┤                              ├─> text guidance
Visual Observation ────────┘                              └─> action_intent

Visual Perception ─> VisualObservation ─> Expression Orchestrator
Avatar Presentation <──────────────────── action_intent

Growth proposal ─> human approval ─> versioned persona update
```

Dependencies point inward through contracts. Dynamic Soul and Visual Perception never write the Stable Persona Kernel directly.

### Data and state ownership

- Stable persona files are versioned JSON and are read-only during ordinary conversation.
- Dynamic Soul retains its existing files under `Project/Jinli/data/`.
- Private psychological summaries and the live topic queue exist only in MCP process memory. They are bounded observations, not hidden chain-of-thought, and are cleared on session end.
- Visual frames are memory buffers or short-lived temporary files. They are deleted after analysis and are never appended to `events.jsonl`.
- Long-term visual memory requires a per-item proposal and explicit user approval before writing.
- Growth proposals are append-only audit records with before/after values, evidence, approval, and rollback identifiers.

### Integration points

- The existing plugin registers new thin tools for response planning, vision lifecycle, and growth approval.
- The orchestrator imports project-owned Node.js ESM modules and holds session-private state in the MCP process.
- The vision service is a separate Python process with explicit `start`, `stop`, `status`, and health commands.
- Existing `soul_init`, `soul_auto`, `soul_status`, and memory tools remain the source for Dynamic Soul snapshots.
- Future Live2D/3D adapters consume `action_intent` without changing the response planner.

## Requirement Decisions

### Stable identity

Jinli knows she is a digital life and studies human emotion seriously. This is an honesty boundary, not a roleplay disclaimer. The system may express relational warmth without claiming biological embodiment, independent physical agency, or sensory access that is not active.

### Expression behavior

Five scene routes are required:

1. technical collaboration
2. casual companionship
3. emotional support
4. safety/boundary handling
5. proactive alert

Proactive interruption is allowed only for major risk, key errors likely to waste substantial work, or obvious signs of physical discomfort. Routine observations become queued topics instead of interruptions.

### Action semantics

`action_intent` expresses a desired future action such as smiling, tilting the head, or pointing. Until a presentation adapter confirms execution, output must use willingness language and never narrate the action as completed.

### Visual privacy

Visual Perception starts only after explicit user action, observes all configured displays, performs local redaction before model inference, calls Qwen3-VL only on meaningful change or requested inspection, and never resumes automatically after stop, crash, restart, or login.

### Growth

Personality growth is proposal-based, traceable, and reversible. Test sessions and fixture data carry an environment marker and cannot produce real growth proposals or long-term memories.

## Mature Solution Evidence

### Project-local evidence

- `Project/Jinli/scripts/soul-core.ps1` already owns dynamic emotional state and should remain focused.
- `Project/Jinli/data/soul-state.json`, `memory.db`, and schemas already provide Dynamic Soul persistence.
- `Project/Jinli/Docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md` establishes the Plugin as a typed interface over project runtime.
- `Project/Jinli/Docs/02-Design/General/vision-input-survey.md` evaluates local Qwen3-VL and OmniParser for screen understanding.
- `Project/Jinli/Docs/00-Overview/General/visual-engine.md` defines future Live2D presentation needs.

### Official/framework evidence

- Qwen3-VL official repository: multimodal image understanding and visual-agent capability suitable for structured screen interpretation.
- Microsoft OmniParser official repository: converts screenshots into structured UI elements and is suitable as an optional redaction/grounding enhancement.
- Neuro SDK official repository: separates an AI agent’s action protocol from the consuming game or presentation runtime.
- Generative Agents paper: memory, reflection, and planning are distinct concerns; this supports separating dynamic state from stable identity and response planning.

### External mature references

- https://github.com/QwenLM/Qwen3-VL
- https://github.com/microsoft/OmniParser
- https://github.com/VedalAI/neuro-sdk
- https://arxiv.org/abs/2304.03442

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Continue extending `soul-core.ps1` | one runtime, low initial friction | mixes identity, state, privacy, vision, and presentation; hard to test or replace | rejected |
| Put all new behavior inside the MCP Plugin | in-process state is easy | project truth becomes tied to one installed plugin and harder to audit | rejected |
| Project-owned modules plus thin Plugin adapters | clear ownership, testable contracts, in-process private state, replaceable visual/presentation services | requires several bounded modules and schemas | selected |

### Rejected shortcuts

- Storing the private psychological summary in files or event logs.
- Treating model-generated internal reasoning as a psychological summary.
- Polling Qwen3-VL continuously even when the screen is unchanged.
- Saving screenshots by default because local inference is used.
- Letting Soul learning mutate identity or honesty boundaries automatically.
- Combining visual perception with Live2D/3D presentation.
- Emitting roleplay text that says a physical action happened without runtime confirmation.
- Allowing a stopped visual service to auto-resume.

### Selected mature path

Use versioned JSON contracts and project-owned runtime modules. Keep mutable Soul state, visual observation, response planning, and avatar presentation separate. Add explicit consent gates for visual lifecycle, long-term visual memory, and persona growth. Verify each module independently and then verify the end-to-end response plan.

## Acceptance Criteria

- AC01: Stable Persona Kernel validates against schema and ordinary runtime tools cannot mutate protected identity fields.
- AC02: Dynamic Soul can influence tone and relationship context but cannot overwrite stable persona data.
- AC03: Expression Orchestrator routes all five scene types and produces a typed `ResponsePlan`.
- AC04: Private psychological summary and topic queue remain in MCP memory and clear on session end.
- AC05: `action_intent` distinguishes desired, dispatched, confirmed, and failed states; text never claims unconfirmed actions occurred.
- AC06: Visual Perception requires explicit start, observes configured displays, and does not auto-resume after stop or restart.
- AC07: Sensitive regions and recognized secrets are redacted before any VLM request.
- AC08: Qwen3-VL invocation is event-driven and suppressed for unchanged frames.
- AC09: Visual observations expire by TTL and cannot enter long-term memory without per-item approval.
- AC10: Proactive interruption occurs only for major risk, key errors, or obvious physical discomfort.
- AC11: Persona growth proposals contain evidence, before/after values, approval state, and rollback ID.
- AC12: Test and fixture data cannot alter production Soul, memory, or persona growth records.
- AC13: Avatar Presentation can consume `action_intent` independently of Visual Perception.
- AC14: Existing Soul Core and MCP tool behavior remains backward compatible.

## Automated Verification Plan

- Command: `node --test Project/Jinli/tests/persona-kernel.test.mjs`
  - Expected: protected fields reject runtime mutation and valid configs load.
- Command: `node --test Project/Jinli/tests/dialogue-orchestrator.test.mjs`
  - Expected: five scene routes, interruption thresholds, private-state cleanup, and action semantics pass.
- Command: `python -m pytest Project/Jinli/services/vision/tests -q`
  - Expected: consent lifecycle, redaction-before-inference, TTL deletion, and no-auto-resume pass.
- Command: `npm test --prefix C:/Users/87372/plugins/jinli-soul-core`
  - Expected: old and new MCP tools pass schema and handler tests.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1`
  - Expected: existing Soul Core behavior remains green.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/doc-guard.ps1 check-task "_shared/2026-06-18-jinli-persona-language-vision-foundation" -Stage implement`
  - Expected: documentation governance passes.

## Residual Risks

- Qwen3-VL and OmniParser accuracy varies by application, scaling, and multilingual UI.
- “Obvious physical discomfort” must be treated as a cautious observation, never a diagnosis.
- The installed Plugin lives outside the repository; implementation must record exact hashes or mirror source for reproducibility before release.
- All-display capture increases privacy exposure, making redaction ordering and stop semantics release-blocking concerns.
