# Analysis: AI Workflow Context Efficiency Patterns

## Architecture Context

### System boundaries

- In scope: three global AI workflow improvements from the 2026-06-20 technical reference:
  - MUSE-style skill-level `.memory.md`;
  - 2-Action Rule for recording findings after repeated search/read actions;
  - CodeGraph usage in Plan phase for dependency and impact analysis.
- In scope: Fable/Claude-Code-style agent operating-system lessons that can be safely translated into local workflow rules:
  - evidence-backed progress claims;
  - long-task checkpoints;
  - explicit thinking-vs-doing boundary;
  - task-packet handoff prompts for worker models.
- In scope: deciding how these patterns should become task-packet-compatible workflow rules.
- Out of scope: implementing all skill memory files, hook automation, or CodeGraph integration in this planning packet.
- Out of scope: Jinli Mentor Mode behavior and KG/video ingestion implementation.

### Dependency map

- Source reference: `Docs/AI/research/2026-06-20-AI-Agent-Ecosystem-Technical-Reference.md`.
- Existing workflow: `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`, `Docs/AI/29-Mature-Solution-First-Workflow.md`, `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`.
- Existing skills: `skills/*/SKILL.md`.
- Existing CodeGraph pattern: `.trae/scripts/codegraph.ps1`, `skills/code-knowledge-graph/SKILL.md`.
- Existing task packets: `.trae/tasks/<project>/<task>/analysis.md`, `tasks.md`, `routing.md`, `doc-impact.md`.
- Existing handoff mechanics: `.trae/scripts/task-handoff.ps1`, work packages, and model-specific prompts supplied by the lead agent.

### Data and state ownership

- Skill-level memory belongs beside each skill as `skills/<skill-name>/.memory.md`.
- Task-local findings belong in task packet files, preferably `analysis.md` or a future `findings.md` when a task needs longer research state.
- CodeGraph output is derived evidence, not source of truth. It should be summarized into `analysis.md`.
- Global workflow docs under `Docs/AI/` own durable operating rules.
- Task handoff prompts belong in task packets or generated handoff outputs. They are derived execution guidance, not replacement for `spec.md` or `tasks.md`.

### Integration points

- Plan phase: use CodeGraph for dependency/impact analysis before reading many files.
- Research loops: after two search/read actions, record findings to task-local evidence before continuing.
- Skill improvement: update a skill's `.memory.md` when repeated successes, failures, or boundary cases are discovered.
- Review/Verify: check that these patterns were used when a task's scope warrants them.
- Task packaging: whenever a lead model gives another model a task packet, include a bounded execution prompt that names read-first files, allowed paths, forbidden paths, gate commands, expected report shape, and stop conditions.
- Progress reporting: any "done" or "ready" claim must be backed by file existence, command output, or explicit verification evidence.

## Mature Solution Evidence

### Project-local evidence

- The repo already uses task packets as persistent context, matching the "filesystem as external memory" pattern.
- The repo already has CodeGraph infrastructure but it is not yet a consistent Plan-stage gate.
- The skills directory is mature enough to support per-skill memory files without changing runtime code.

### Official/framework evidence

- Current workflow docs require `analysis.md` with architecture context, dependency map, acceptance criteria, and automated verification.
- Mature Solution First requires research before design and option comparison.
- Multi-Agent Task Packet Workflow requires bounded worker context and persistent evidence.
- Current DS4 and issuer-worker docs already reject self-verification and broad worker authority; task handoff prompts should make those limits operational for less cautious models.

### External mature references

- The technical reference summarizes MUSE-Autoskill's skill-level memory pattern.
- The same reference highlights planning-with-files and the 2-Action Rule as context-drift prevention.
- It also identifies CodeGraph as a mature code understanding and impact analysis tool.
- The technical reference's System Prompt section and public Fable/Claude-Code prompting discussions are useful as structural references: long tasks need tools, files, checkpoints, explicit boundaries, and evidence-backed claims.
- Public or leaked system prompts must be treated as inspiration for patterns, not as text to copy into local system prompts.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Put these patterns into Mentor Mode | User discussion | Human-facing flow is nearby | Pollutes Mentor Mode with workflow mechanics | Rejected |
| Put these patterns into KG/video | Local worker/token-saving overlap | Related to token efficiency | KG/video would become a global workflow bucket | Rejected |
| Create a separate `_shared` workflow packet | Current analysis | Clean ownership and reusable across projects | More task files | Selected |
| Implement all skills `.memory.md` at once | MUSE inspiration | Comprehensive | Large noisy migration, low reviewability | Rejected |
| Pilot `.memory.md` on high-value skills first | Mature incremental path | Bounded and measurable | Requires later rollout | Selected |
| Make 2-Action fully automatic immediately | planning-with-files | Strong enforcement | Needs hook/tool support and may interrupt flow | Deferred |
| Add CodeGraph as Plan-stage evidence first | Existing local infra | Low risk, immediately useful | Not fully automated yet | Selected |
| Copy Fable/CC system prompt text into local rules | Public prompt collections | Fast | Authenticity/time validity unclear; creates giant prompt instead of local mechanisms | Rejected |
| Extract Fable/CC operating-system patterns into local workflow rules | Fable/CC prompt engineering discussions | Keeps useful structure while preserving local gates | Requires translation into repo-specific docs/templates | Selected |
| Give models task packets without execution prompts | Current ad hoc handoff risk | Less writing | Weaker execution quality, especially for action-biased models | Rejected |
| Require a task-package prompt template with every issued packet | User request + worker lessons | Better model performance and fewer scope errors | More upfront packaging work | Selected |

### Rejected shortcuts

- Do not create empty `.memory.md` files for every skill just to claim adoption.
- Do not make CodeGraph mandatory for tiny single-file tasks.
- Do not let 2-Action Rule become noisy ceremony when no research loop exists.
- Do not store raw search dumps in task packets; record concise findings and source paths.
- Do not replace human/lead architecture judgment with CodeGraph output.
- Do not copy unverified public system-prompt text into the repo as authoritative rules.
- Do not let "progress" or "done" claims stand without evidence.
- Do not issue a task packet to another model without a prompt that explains how to execute it safely.
- Do not let task prompts override task packet files or mechanical gates.

### Selected mature path

- Create a separate `_shared` task packet for these workflow patterns.
- Treat them as global workflow enhancements, not Jinli-specific features.
- First implementation should be a pilot:
  - add `.memory.md` templates to a small set of high-value skills;
  - add task-packet guidance for 2-Action findings recording;
  - add Plan-stage CodeGraph evidence guidance and verification.
- Add a "Task Package Prompt Contract" to the workflow: each task package handed to another model should include a copy-ready prompt with role, read order, allowed/forbidden paths, gates, deliverables, verification commands, report shape, and stop conditions.
- Add "Evidence Before Progress Claims" guidance: progress summaries must cite file paths, commands, or verification output.

## Task Package Prompt Contract

When Ba Ba or the lead model gives another model a task packet, the handoff should include a model-facing prompt. The prompt must not replace the packet. It is an execution wrapper that helps action-biased or lower-context models use the packet correctly.

### Required prompt sections

| Section | Purpose |
|---|---|
| `Task packet path` | Identifies the runtime source of truth |
| `Goal` | Summarizes the bounded outcome |
| `Read first` | Lists exact files to read before action |
| `Before editing` | Lists `task-guard` and `task-state can-edit` commands |
| `Allowed paths` | Limits edit scope |
| `Forbidden paths` | Prevents task state/spec/AC/source drift |
| `Execution rules` | Names phase, worker authority, and stop conditions |
| `Verification commands` | Defines commands and expected result |
| `Report format` | Requires changed files, evidence, AC mapping, and residual risk |

### Evidence rule

Every task prompt should tell the worker:

```text
Do not claim a file exists, a test passed, or a task is done unless you verified it with a command or file read in this session.
```

### Stop conditions

The prompt should make the worker stop when:

- a required file is missing;
- the gate fails;
- an allowed path is insufficient;
- the task appears to require architecture changes;
- verification fails more than the package allows;
- the worker would need to change acceptance criteria or task state.

## Acceptance Criteria

- AC01: The task packet explicitly captures MUSE `.memory.md`, 2-Action Rule, and CodeGraph Plan usage.
- AC02: The packet keeps these patterns separate from Mentor Mode and KG/video tasks.
- AC03: The packet defines state ownership for skill memory, task findings, and CodeGraph evidence.
- AC04: The packet selects a bounded pilot instead of a whole-repo migration.
- AC05: The packet defines future verification commands and expected evidence.
- AC06: The packet defines how Fable/CC-style operating-system lessons are translated into local workflow mechanisms without copying prompt text.
- AC07: The packet defines a Task Package Prompt Contract for future model handoffs.
- AC08: The packet requires evidence-backed progress and completion claims.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task _shared/2026-06-20-ai-workflow-context-efficiency-patterns -Stage plan`
- Expected: Documentation governance passes.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-20-ai-workflow-context-efficiency-patterns plan`
- Expected: The plan gate is ready once Ba Ba confirms the design.
