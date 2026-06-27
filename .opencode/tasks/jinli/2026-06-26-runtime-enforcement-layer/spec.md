# Living Spec: Jinli Runtime Enforcement Layer

## Scope

Create a runtime layer that forces meaningful Jinli work through the full system: memory, skill routing, multi-agent evidence, response gate, after-turn commit, file route maintenance, and workflow route maintenance.

## Scenarios

### Scenario 1: Standard technical answer uses required evidence

Given Ba Ba asks for a non-trivial technical answer
When the runtime classifies the turn as Standard
Then the runtime must gather memory, skill routing, file route, workflow route, and verifier-lite evidence
And the final answer must include no unsupported claim that a skipped system was used.

### Scenario 2: Strict project work cannot bypass multi-agent structure

Given Ba Ba asks for project workflow or code changes
When the runtime classifies the turn as Strict
Then the lead must use task-packet gates and bounded worker/verifier evidence
And a worker must not update review, verify, archive, or task authority files.

### Scenario 3: Missing memory evidence blocks the answer

Given the mode requires memory context
When memory retrieval fails without an allowed degradation reason
Then `ResponseGate` must block final output and request repair or declare blocked evidence.

### Scenario 4: Weak model skips steps

Given a simulated worker returns an answer without required evidence
When the response gate validates the turn manifest
Then the gate must fail and produce a machine-readable failure reason.

### Scenario 5: File route index tells models where files belong

Given a new model enters the project
When it reads the generated file route index
Then it can identify canonical locations for workflow docs, task packets, Jinli services, runtime data, skills, scripts, and project source files.

### Scenario 6: Workflow route index tells models which process to follow

Given a task request enters Jinli
When the route index is checked
Then the model can map request type to Lite, Standard, Strict, or Critical mode and required gates.

### Scenario 7: After-turn commit records follow-up signals

Given a turn produces useful learning, memory, proactive, dream, or evolution signals
When the answer is accepted
Then the after-turn commit must write structured pending signals through approved paths.

### Scenario 8: Existing service entrypoints are not mistaken for turn enforcement

Given `JinliService` or `JinliDaemon` can start some background services
When a user turn is processed
Then the runtime must still prove per-turn memory/persona/skill/route/gate evidence through a turn manifest
And it must not treat "service was available" as "service was used this turn".

### Scenario 9: JS response planning bridges to Python runtime evidence

Given the visible response path uses the JS expression orchestrator
When Standard or higher mode is selected
Then a bridge must provide Python runtime evidence or a declared degradation record
And missing bridge evidence must block claims that Python memory/persona/proactive/dreamer/evolution participated.

### Scenario 10: Strict/Critical manifests include authority evidence

Given a Strict or Critical project task uses workers
When a final answer or completion claim is prepared
Then the manifest must reference worker reports or issuer-worker artifacts
And missing packet seal, capability, worker result, issuer review, or archive evidence must be visible as blocking or degraded evidence.

### Scenario 11: Weak contract checks are not treated as sufficient

Given `contract-verify.ps1` performs a broad pattern check
When `task-guard.ps1` has stricter semantics
Then the runtime must prefer the stricter gate or add an all-required-sections check before accepting verification evidence.

## Decisions

- Use a per-turn manifest as the central evidence record.
- Use a response gate to block missing required evidence.
- Keep task-packet scripts as project edit authority.
- Add route indexes instead of relying on prompt memory for file placement.
- Use explicit degradation records instead of silent fallback.
- Name the cross-model contract MIRP: Model-Independent Runtime Protocol.
- Treat service availability and per-turn service usage as separate facts.
- Treat signed issuer-worker evidence as stronger than plain Markdown worker reports.
- Treat `task-guard.ps1` as the stricter phase authority when it conflicts with `contract-verify.ps1`.

## Changelog

- 2026-06-26: Initial Plan spec created.

## Verification State

- Plan artifacts: in progress.
- Implementation: not started.
- Verification: not run.
