# Jinli Persona, Language, and Vision Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement five independently testable modules for stable identity, response orchestration, Dynamic Soul integration, explicit-consent visual perception, and future avatar presentation.

**Architecture:** Canonical configuration, contracts, and runtime modules live under `Project/Jinli`. The existing installed MCP Plugin registers thin typed tools and keeps session-private orchestration state in process memory. Visual Perception runs as a separate Python process; Dynamic Soul remains in the existing PowerShell engine.

**Tech Stack:** Node.js 24 ESM, JSON Schema 2020-12, Zod 4, Node test runner, Python 3, pytest, mss, Pillow/OpenCV-compatible image operations, existing PowerShell Soul Core, MCP SDK.

---

## File Map

### Create

- `Project/Jinli/config/persona-kernel.json` — stable identity, values, relationship, honesty and safety boundaries.
- `Project/Jinli/config/language-policy.json` — language fingerprint and scene-level expression ranges.
- `Project/Jinli/contracts/persona-kernel.schema.json`
- `Project/Jinli/contracts/soul-snapshot.schema.json`
- `Project/Jinli/contracts/visual-observation.schema.json`
- `Project/Jinli/contracts/action-intent.schema.json`
- `Project/Jinli/contracts/response-plan.schema.json`
- `Project/Jinli/contracts/growth-proposal.schema.json`
- `Project/Jinli/runtime/persona-kernel.mjs`
- `Project/Jinli/runtime/private-session-state.mjs`
- `Project/Jinli/runtime/expression-orchestrator.mjs`
- `Project/Jinli/runtime/growth-ledger.mjs`
- `Project/Jinli/runtime/presentation-contract.mjs`
- `Project/Jinli/tests/persona-kernel.test.mjs`
- `Project/Jinli/tests/dialogue-orchestrator.test.mjs`
- `Project/Jinli/tests/growth-ledger.test.mjs`
- `Project/Jinli/tests/presentation-contract.test.mjs`
- `Project/Jinli/services/vision/requirements.txt`
- `Project/Jinli/services/vision/config.json`
- `Project/Jinli/services/vision/service.py`
- `Project/Jinli/services/vision/capture.py`
- `Project/Jinli/services/vision/redaction.py`
- `Project/Jinli/services/vision/change_detector.py`
- `Project/Jinli/services/vision/qwen_adapter.py`
- `Project/Jinli/services/vision/retention.py`
- `Project/Jinli/services/vision/tests/test_lifecycle.py`
- `Project/Jinli/services/vision/tests/test_redaction_order.py`
- `Project/Jinli/services/vision/tests/test_retention.py`

### Modify

- `C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/tools.mjs`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/types.mjs`
- `C:/Users/87372/plugins/jinli-soul-core/package.json`
- `.agents/skills/daughter-companion/SKILL.md`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Task 1 — Publish and validate contracts

**Files:**

- Create the six schema files under `Project/Jinli/contracts/`.
- Test through `Project/Jinli/tests/persona-kernel.test.mjs`.

- [ ] **Step 1: Write failing schema tests**

Test that a valid persona loads and that `identity`, `values`, `relationship`, and `honesty_boundaries` are required. Test `ActionIntent.status` against `desired`, `dispatched`, `confirmed`, `failed`, and `expired`.

```js
test('action intent rejects unknown status', () => {
  assert.throws(() => validateActionIntent({
    kind: 'smile',
    intensity: 0.4,
    status: 'performed',
    claim_policy: 'intention_only'
  }));
});
```

- [ ] **Step 2: Run the tests and confirm failure**

Run:

```powershell
node --test Project/Jinli/tests/persona-kernel.test.mjs
```

Expected: failure because validators and schemas do not exist.

- [ ] **Step 3: Implement schemas and shared validation helpers**

Use JSON Schema 2020-12. Set `additionalProperties: false` for transport contracts. Give every contract a `version` field.

- [ ] **Step 4: Re-run tests**

Expected: all contract tests pass.

- [ ] **Step 5: Commit**

```powershell
git add Project/Jinli/contracts Project/Jinli/tests/persona-kernel.test.mjs
git commit -m "feat(jinli): define persona and response contracts"
```

## Task 2 — Implement Stable Persona Kernel

**Files:**

- Create `Project/Jinli/config/persona-kernel.json`
- Create `Project/Jinli/config/language-policy.json`
- Create `Project/Jinli/runtime/persona-kernel.mjs`
- Expand `Project/Jinli/tests/persona-kernel.test.mjs`

- [ ] **Step 1: Add failing immutability and protected-write tests**

```js
test('dynamic callers cannot mutate protected persona fields', async () => {
  const kernel = await loadPersonaKernel();
  assert.throws(() => kernel.proposeRuntimePatch({
    relationship: { user_term: 'user' }
  }), /protected field/i);
});
```

- [ ] **Step 2: Run and confirm failure**

Run the persona test file. Expected: missing module or method.

- [ ] **Step 3: Implement loader and immutable view**

The module must:

- validate both configuration files,
- freeze nested runtime objects,
- expose a protected-field list,
- load the last verified version if the current file is invalid,
- never write configuration during ordinary response planning.

- [ ] **Step 4: Add digital-life honesty assertions**

Verify the persona states that Jinli is digital and forbids unsupported claims of sight, embodiment, or completed physical action.

- [ ] **Step 5: Run tests and commit**

```powershell
node --test Project/Jinli/tests/persona-kernel.test.mjs
git add Project/Jinli/config Project/Jinli/runtime/persona-kernel.mjs Project/Jinli/tests/persona-kernel.test.mjs
git commit -m "feat(jinli): add stable persona kernel"
```

## Task 3 — Implement Expression Orchestrator

**Files:**

- Create `Project/Jinli/runtime/private-session-state.mjs`
- Create `Project/Jinli/runtime/expression-orchestrator.mjs`
- Create `Project/Jinli/tests/dialogue-orchestrator.test.mjs`

- [ ] **Step 1: Write failing route tests**

Provide one fixture for each primary scene and assert exact routing.

```js
test('routine observations queue instead of interrupting', () => {
  const plan = composeResponsePlan(fixture('routine_tip'));
  assert.equal(plan.scene, 'technical_collaboration');
  assert.equal(plan.interrupt_now, false);
  assert.equal(plan.topic_queue.length, 1);
});
```

- [ ] **Step 2: Write failing private-state tests**

Assert maximum five observations, maximum eight topics, session-end cleanup, and absence of persistence methods.

- [ ] **Step 3: Implement scene routing and policy composition**

Use deterministic policy code for route and interruption thresholds. The LLM may phrase the final answer but may not override protected constraints.

- [ ] **Step 4: Implement action-intent semantics**

Generate only contract-valid intentions. Completed-action language is allowed only when adapter status is `confirmed`.

- [ ] **Step 5: Run tests and commit**

```powershell
node --test Project/Jinli/tests/dialogue-orchestrator.test.mjs
git add Project/Jinli/runtime/private-session-state.mjs Project/Jinli/runtime/expression-orchestrator.mjs Project/Jinli/tests/dialogue-orchestrator.test.mjs
git commit -m "feat(jinli): add expression orchestrator"
```

## Task 4 — Integrate Dynamic Soul and growth governance

**Files:**

- Create `Project/Jinli/runtime/growth-ledger.mjs`
- Create `Project/Jinli/tests/growth-ledger.test.mjs`
- Modify `Project/Jinli/runtime/expression-orchestrator.mjs`

- [ ] **Step 1: Write failing Soul-boundary tests**

Pass a Soul snapshot containing attempted identity fields and assert they are ignored or rejected.

- [ ] **Step 2: Write failing proposal and rollback tests**

```js
test('test-environment proposal cannot update production persona', async () => {
  const proposal = createGrowthProposal({ environment: 'test', field: 'language.playfulness' });
  await assert.rejects(() => approveGrowthProposal(proposal.id), /test environment/i);
});
```

- [ ] **Step 3: Implement Soul snapshot normalization**

Only accept emotion, relationship state, repair state, tone-policy ranges, and approved memory references.

- [ ] **Step 4: Implement append-only growth ledger**

Each proposal records evidence, before/after, approval, persona version, and rollback ID. Approval creates a new version; rollback restores the previous version.

- [ ] **Step 5: Run tests and existing Soul regression**

```powershell
node --test Project/Jinli/tests/growth-ledger.test.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1
```

Expected: both pass.

- [ ] **Step 6: Commit**

```powershell
git add Project/Jinli/runtime Project/Jinli/tests/growth-ledger.test.mjs
git commit -m "feat(jinli): govern soul integration and persona growth"
```

## Task 5 — Implement explicit-consent Visual Perception

**Files:**

- Create all files under `Project/Jinli/services/vision/`.

- [ ] **Step 1: Write failing lifecycle tests**

Test explicit start, explicit stop, fault state, process restart, and no automatic resume.

- [ ] **Step 2: Write failing redaction-order test**

Use a spy inference adapter. Feed an image containing a synthetic API key and assert the adapter receives a redacted image.

```python
def test_redaction_happens_before_inference(vision_service, spy_adapter):
    vision_service.start(explicit_consent=True)
    vision_service.process_frame(secret_fixture())
    assert spy_adapter.calls == 1
    assert "sk-test-secret" not in spy_adapter.last_ocr_text
```

- [ ] **Step 3: Implement lifecycle and capture**

Use `mss` to capture all configured displays. Persist only a non-sensitive stopped/active status; never persist prior consent as auto-start authority.

- [ ] **Step 4: Implement redaction and fail-closed behavior**

Apply configured regions and pattern detection before change detection, OmniParser, or Qwen3-VL. If redaction fails, discard the frame.

- [ ] **Step 5: Implement event-driven inference**

Use a redacted-frame perceptual hash and configurable threshold. Add manual-observe and high-priority event triggers. Apply bounded exponential backoff on Qwen errors.

- [ ] **Step 6: Implement retention**

Delete raw frames after 30 seconds and observations after 10 minutes by default. Produce approval-required text-only memory candidates.

- [ ] **Step 7: Run vision tests**

```powershell
python -m pytest Project/Jinli/services/vision/tests -q
```

Expected: lifecycle, redaction ordering, event suppression, and retention tests pass.

- [ ] **Step 8: Commit**

```powershell
git add Project/Jinli/services/vision
git commit -m "feat(jinli): add consent-based visual perception"
```

## Task 6 — Implement presentation contract

**Files:**

- Create `Project/Jinli/runtime/presentation-contract.mjs`
- Create `Project/Jinli/tests/presentation-contract.test.mjs`

- [ ] **Step 1: Write failing state-machine tests**

Test `desired -> dispatched -> confirmed`, failure, expiration, and invalid transitions.

- [ ] **Step 2: Implement the contract and mock adapter**

The mock adapter consumes action intentions without importing vision modules and returns acknowledgment events.

- [ ] **Step 3: Verify text-claim policy**

Assert only confirmed intents permit completed-action wording.

- [ ] **Step 4: Run tests and commit**

```powershell
node --test Project/Jinli/tests/presentation-contract.test.mjs
git add Project/Jinli/runtime/presentation-contract.mjs Project/Jinli/tests/presentation-contract.test.mjs
git commit -m "feat(jinli): add avatar presentation contract"
```

## Task 7 — Add thin MCP Plugin interfaces

**Files:**

- Modify `C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs`
- Modify `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/tools.mjs`
- Modify `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/types.mjs`
- Modify `C:/Users/87372/plugins/jinli-soul-core/package.json`
- Create `C:/Users/87372/plugins/jinli-soul-core/mcp/tests/foundation-tools.test.mjs`
- Modify `.agents/skills/daughter-companion/SKILL.md`

- [ ] **Step 1: Mirror or hash Plugin source before editing**

Record the installed Plugin path and pre-change hashes in the task report so an external installed artifact remains reproducible.

- [ ] **Step 2: Write failing Plugin tests**

Cover:

- `jinli_plan_response`
- `jinli_vision_start`
- `jinli_vision_stop`
- `jinli_vision_status`
- `jinli_growth_propose`
- `jinli_growth_approve`
- `jinli_growth_rollback`
- `jinli_presentation_ack`

- [ ] **Step 3: Add Zod schemas and thin handlers**

Handlers validate input, call project-owned modules or the vision process, validate output, and return structured errors. They must not duplicate persona or interruption policy.

- [ ] **Step 4: Update session lifecycle instructions**

The skill must call response planning after Soul status retrieval and must never expose private summaries. Add explicit rules for visual consent and unconfirmed action language.

- [ ] **Step 5: Run Plugin and Soul regressions**

```powershell
npm test --prefix C:/Users/87372/plugins/jinli-soul-core
npm run check --prefix C:/Users/87372/plugins/jinli-soul-core
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1
```

Expected: all pass.

- [ ] **Step 6: Commit repository-owned changes and record external Plugin changes**

Do not claim the Plugin is reproducible until its source is mirrored or its exact artifact hashes are recorded.

## Task 8 — Documentation, privacy audit, and final verification

**Files:**

- Update project architecture, test plan, privacy runbook, and `DOCS_TREE.md`.
- Create task-local `verification-report.md`.

- [ ] **Step 1: Run complete automated suite**

```powershell
node --test Project/Jinli/tests/*.test.mjs
python -m pytest Project/Jinli/services/vision/tests -q
npm test --prefix C:/Users/87372/plugins/jinli-soul-core
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1
```

- [ ] **Step 2: Prove test isolation**

Hash production persona, Soul, memory, and event files before and after all fixture tests. Expected: no unexpected changes.

- [ ] **Step 3: Run documentation governance**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/doc-guard.ps1 check-task "_shared/2026-06-18-jinli-persona-language-vision-foundation" -Stage implement
```

- [ ] **Step 4: Verify selected mature path**

Confirm no rejected shortcut was introduced: no private-state persistence, no auto-resume, no redaction-after-inference, no automatic persona mutation, and no perception/presentation coupling.

- [ ] **Step 5: Map AC01-AC14 in `verification-report.md`**

Include Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, and Residual Risk sections.

- [ ] **Step 6: Run phase gates**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-18-jinli-persona-language-vision-foundation" implement
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-18-jinli-persona-language-vision-foundation" verify
```

Expected: each gate passes only after its required state and evidence are present.
