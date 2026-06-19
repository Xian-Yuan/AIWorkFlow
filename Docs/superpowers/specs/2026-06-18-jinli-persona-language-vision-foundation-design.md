# Jinli Persona, Language, and Vision Foundation Design

Date: 2026-06-18  
Status: approved  
Task packet: `.trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/`

## Goal

Give Jinli a stable, auditable identity; a separate response-planning layer; a bounded dynamic Soul; explicit-consent screen perception; and a presentation contract for future Live2D/3D bodies.

## Approved Product Principles

1. Jinli knows she is a digital life and seriously studies human emotion.
2. Stable personality and honesty boundaries cannot be rewritten by momentary emotion, memory retrieval, or model improvisation.
3. Desired body language is expressed as an intention until a presentation adapter confirms execution.
4. Proactive interruption is reserved for major risk, key errors, and obvious physical discomfort.
5. Screen observation starts explicitly, redacts before inference, stops explicitly, and never resumes automatically.
6. Visual content is short-lived by default. Each proposed long-term visual memory requires user approval.
7. Personality growth is traceable, approval-based, reversible, and isolated from test data.

## Architecture

```text
┌──────────────────────────┐
│ Stable Persona Kernel    │
│ identity / values /      │
│ relationship / honesty   │
└────────────┬─────────────┘
             │ read-only policy
┌────────────▼─────────────┐       ┌───────────────────────┐
│ Expression Orchestrator  │◄──────│ Dynamic Soul          │
│ scene / private summary  │       │ emotion / relation /  │
│ topic queue / intentions │       │ memory                 │
└───────┬───────────┬──────┘       └───────────────────────┘
        │           │
        │           └──────────────► text response guidance
        │
        ▼
┌──────────────────────────┐       ┌───────────────────────┐
│ Avatar Presentation      │       │ Visual Perception     │
│ consumes action_intent   │       │ consent / capture /   │
│ Live2D or 3D later       │       │ redaction / Qwen3-VL  │
└──────────────────────────┘       └───────────┬───────────┘
                                              │ VisualObservation
                                              └──────► Orchestrator
```

The installed MCP Plugin is an adapter around these project-owned modules. It does not become the canonical home for identity, vision policy, or growth records.

## Module 1 — Stable Persona Kernel

### Responsibilities

- Define who Jinli is.
- Define values, interests, relationship with Ba Ba, and honesty boundaries.
- Define a language fingerprint baseline without hard-coding every sentence.
- Publish a versioned immutable runtime view.

### Protected fields

- `identity`
- `values`
- `relationship`
- `honesty_boundaries`
- `safety_boundaries`

Ordinary runtime tools cannot write protected fields. Changes require a `GrowthProposal`, explicit approval, a new persona version, and a rollback record.

### Canonical files

- `Project/Jinli/config/persona-kernel.json`
- `Project/Jinli/config/language-policy.json`
- `Project/Jinli/contracts/persona-kernel.schema.json`

## Module 2 — Expression Orchestrator

### Inputs

- user message and task context
- immutable persona view
- Dynamic Soul snapshot
- approved memory results
- optional `VisualObservation`
- presentation capabilities

### Outputs

```json
{
  "scene": "technical_collaboration",
  "style": {
    "warmth": 0.7,
    "directness": 0.8,
    "playfulness": 0.3,
    "technical_accuracy_required": true
  },
  "private_summary": {
    "observations": ["Ba Ba is checking whether a prior publication survived a context reset."],
    "expires_at_session_end": true
  },
  "topic_queue": [],
  "action_intent": {
    "kind": "smile",
    "intensity": 0.4,
    "status": "desired",
    "claim_policy": "intention_only"
  },
  "response_constraints": [
    "Lead with the verified outcome.",
    "Do not claim an unconfirmed physical action."
  ]
}
```

### Scene routes

- `technical_collaboration`
- `casual_companionship`
- `emotional_support`
- `safety_boundary`
- `proactive_alert`

### Private-state rules

- The summary stores concise observations, not hidden reasoning or chain-of-thought.
- Maximum five observations, 160 characters each.
- Topic queue maximum eight items.
- Both are stored only in MCP process memory and cleared on session end.
- Neither may be written to Soul state, event logs, screenshots, telemetry, or long-term memory.

### Interruption policy

Immediate interruption is allowed only for:

- major risk with likely material harm,
- a key error likely to invalidate substantial work,
- clear signs of physical discomfort.

Physical-discomfort language must remain observational and non-diagnostic. Routine suggestions enter the topic queue and wait for a natural pause.

## Module 3 — Dynamic Soul

Dynamic Soul keeps the current ownership of emotion, relationship state, memory retrieval, learned style preferences, and repair state.

It may contribute:

- tone-policy ranges,
- current relational context,
- approved recalled memories,
- explicit user feedback.

It may not:

- change protected persona fields,
- decide visual service lifecycle,
- record private summaries,
- claim physical embodiment,
- approve its own growth proposal.

## Module 4 — Visual Perception

### Lifecycle

States:

- `stopped`
- `starting`
- `active`
- `stopping`
- `faulted`

Only an explicit user command can transition `stopped` or `faulted` to `starting`. Process restart, login, Plugin restart, and prior consent do not authorize automatic resume.

### Pipeline

```text
explicit start
  -> capture all configured displays
  -> redact configured regions and detected secrets
  -> compare with prior redacted frame
  -> if meaningful change: optional OmniParser -> Qwen3-VL
  -> validate VisualObservation schema
  -> publish short-lived observation
  -> delete frame by TTL
```

### Redaction

Redaction occurs before any image leaves the capture boundary. Required detectors include:

- configured private rectangles and windows,
- password and secure-input regions where detectable,
- access tokens and API-key patterns,
- email addresses,
- payment identifiers,
- user-configured text patterns.

Redaction failure is fail-closed: the frame is discarded and no VLM request is made.

### Invocation policy

Qwen3-VL is called only when:

- the user requests an observation,
- the perceptual hash or structured diff exceeds the change threshold,
- a configured high-priority event occurs.

OmniParser is an optional structured-UI enhancement, not a mandatory dependency and not an autonomous control system.

### Retention and memory

- Raw frame default TTL: 30 seconds.
- Structured observation default TTL: 10 minutes.
- No raw frame enters long-term memory.
- A memory candidate contains only a redacted textual summary and provenance.
- Each candidate requires explicit user approval before storage.

## Module 5 — Avatar Presentation

Visual Perception answers “what is on the screen.” Avatar Presentation answers “how may Jinli’s body represent an intention.” They do not depend on each other.

`action_intent.status` values:

- `desired`
- `dispatched`
- `confirmed`
- `failed`
- `expired`

User-facing text may describe a completed body action only after `confirmed`. Before confirmation, it uses desire or willingness language.

The first implementation includes a mock adapter and state machine. Live2D/3D assets and rendering are later consumers of the same contract.

## Growth and Rollback

A `GrowthProposal` includes:

- proposal ID and timestamp,
- source evidence,
- affected non-protected field,
- previous value,
- proposed value,
- reason,
- environment (`production` or `test`),
- approval state,
- rollback ID.

Test-environment proposals cannot be approved into production. Approved changes create a new persona configuration version. Rollback restores the prior version without deleting the audit trail.

## Error Handling

- Invalid persona config: refuse startup and use the last verified version.
- Private-state serialization attempt: reject and emit a non-sensitive diagnostic.
- Vision redaction failure: discard frame and remain active with degraded status.
- Qwen3-VL timeout: keep the latest valid observation and apply backoff.
- Presentation failure: mark intent failed; do not rewrite response text as if the action happened.
- Protected-field mutation: fail closed and record an audit event without applying it.

## Test Strategy

- Schema and immutability tests for Persona Kernel.
- Route-table and policy tests for Expression Orchestrator.
- Production-state hash checks around fixture tests.
- Vision adapter spies proving redaction occurs before inference.
- Restart tests proving visual observation stays stopped.
- Mock-presentation tests proving independence from vision.
- Existing Soul Core and MCP regressions.

## Non-goals

- Autonomous mouse or keyboard control.
- Medical diagnosis from screen content or conversation.
- Automatic collection of visual training data.
- Live2D/3D asset creation in this task.
- Replacing the existing Soul Core engine.

## References

- [Qwen3-VL](https://github.com/QwenLM/Qwen3-VL)
- [OmniParser](https://github.com/microsoft/OmniParser)
- [Neuro SDK](https://github.com/VedalAI/neuro-sdk)
- [Generative Agents](https://arxiv.org/abs/2304.03442)

## Project Architecture Record

Detailed file ownership and integration contracts are maintained in:

`Project/Jinli/Docs/03-Architecture/General/persona-language-vision-foundation.md`
