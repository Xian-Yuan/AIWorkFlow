# Tasks — Jinli Persona, Language, and Vision Foundation

Date: 2026-06-18  
Execution model: one architecture, five independently verifiable phases

## Dependency Graph

```text
T01 Contracts
 ├─> T02 Stable Persona Kernel
 ├─> T03 Expression Orchestrator
 ├─> T04 Dynamic Soul Integration
 ├─> T05 Visual Perception
 └─> T06 Avatar Presentation

T02 + T03 + T04 + T05 + T06
 └─> T07 Plugin Integration
      └─> T08 Regression, Docs, and Verification
```

## Implementation Checklist

- [x] T01 — Define versioned schemas for Persona, SoulSnapshot, VisualObservation, ResponsePlan, ActionIntent, TopicItem, and GrowthProposal.
- [x] T02 — Implement the Stable Persona Kernel loader, protected-field policy, version migration, and immutable runtime view.
- [x] T03 — Implement the Expression Orchestrator with five scene routes, language fingerprint policy, ephemeral psychological summary, topic queue, interruption policy, and action-intent generation.
- [x] T04 — Integrate existing Dynamic Soul snapshots without granting write access to stable persona fields.
- [x] T05 — Implement the isolated Visual Perception service with explicit lifecycle, all-display capture, local redaction, event-driven Qwen3-VL calls, optional OmniParser enhancement, TTL deletion, and consented memory proposals.
- [x] T06 — Implement the presentation contract and mock state machine so future Live2D/3D bodies can consume `action_intent` independently.
- [x] T07 — Add thin typed MCP tools and handlers for response planning, vision lifecycle, growth approval/rollback, and presentation acknowledgment.
- [x] T08 — Update Jinli architecture, testing, operations, and docs-tree records.
- [x] R01 — Restore Avatar and Dialogue tests so all declared suites execute.
- [x] R02 — Accept UTF-8 BOM in Dynamic Soul JSON without weakening invalid-JSON errors.
- [x] R03 — Implement an explicit cross-process Vision CLI supervisor with stale-PID fail-closed behavior.
- [x] R04 — Deploy the corrected response-plan and Vision CLI adapter to the installed MCP Plugin.
- [x] R05 — Install Python vision dependencies and run the complete pytest suite.
- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in verification-report.md.
- [x] Map implementation result to Acceptance Criteria in verification-report.md.

## Phase Exit Criteria

### Phase 1 — Contracts and Persona

- S01-S03 pass.
- Protected-field writes fail closed.
- Persona config and schema are human-reviewable.

### Phase 2 — Orchestration

- S04-S07 pass.
- Private state is demonstrably non-persistent.
- Routine observations do not interrupt.

### Phase 3 — Soul and Growth

- S08-S09 pass.
- Existing Soul Core remains backward compatible.
- Growth requires approval and supports rollback.

### Phase 4 — Vision

- S10-S12 pass.
- Redaction-before-inference is proven with adapter spies.
- Stop and restart tests prove no automatic resume.

### Phase 5 — Presentation and Release

- S13-S14 pass.
- Mock presentation works without vision.
- Full regression and documentation gates pass.

## Required Evidence

- Unit-test output for each module.
- Integration-test output for Plugin-to-project module calls.
- Privacy lifecycle evidence showing redaction order and TTL cleanup.
- Production-state hashes before and after fixture tests.
- Final acceptance mapping for AC01-AC14.
