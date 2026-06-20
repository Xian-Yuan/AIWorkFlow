# 43 — AI Workflow Context Efficiency Patterns

> **Status**: Pilot — bounded implementation, not whole-repo migration
> **Owner**: _shared global AI workflow
> **Source task**: `.trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns`

## Purpose

This document captures five global workflow patterns that improve context efficiency, reduce drift, and strengthen evidence quality across all AI agent sessions. These patterns are task-packet-compatible and separate from Jinli Mentor Mode or KG/video implementation.

---

## Pattern 1: Skill-Level Memory (`.memory.md`)

### When

A skill repeatedly succeeds, fails, or reveals boundary conditions that are reusable across future tasks.

### What

Record concise lessons in `skills/<skill-name>/.memory.md`, beside the skill's `SKILL.md`.

### Rules

1. `.memory.md` supplements `SKILL.md` — it does **not** replace SKILL.md instructions.
2. Each entry is ≤3 lines: what happened, what was learned, when.
3. Do **not** create empty `.memory.md` files for every skill just to claim adoption.
4. Pilot first on high-value skills; expand after measurable benefit.
5. Entries are append-only during a session; prune only between sessions with explicit reason.

### Template

```markdown
# .memory.md — <skill-name>

## Lessons

### <YYYY-MM-DD> <short-topic>
- What: <concise description of the success/failure/boundary>
- Lesson: <what to do differently or remember>
- Context: <task or scenario reference>
```

### Pilot Skills

| Skill | Reason for inclusion |
|-------|---------------------|
| `金璃好帮手` | Highest-frequency implement agent; accumulates compile/verify lessons |
| `金璃小天才` | Highest-frequency plan agent; accumulates research/routing lessons |
| `failure-memory` | Already has cross-session memory; `.memory.md` complements it |
| `code-knowledge-graph` | Directly related to CodeGraph Plan evidence (Pattern 3) |

---

## Pattern 2: 2-Action Findings Rule

### When

An agent performs two or more search/read actions during Plan-phase research.

### What

After every two search/read actions that produce new useful evidence, record a concise finding in the task packet before continuing.

### Rules

1. Record findings in `analysis.md` (or a dedicated `findings.md` if the task needs longer research state).
2. Each finding: source path, key insight, relevance to current task.
3. Do **not** store raw search dumps — record concise findings and source paths.
4. Do **not** apply this rule when no research loop exists (tiny tasks, single-file changes).
5. The goal is to prevent carrying all findings only in volatile chat context.

### Finding Format

```markdown
### Finding <N>: <short-title>
- **Source**: `<file-path-or-search-query>`
- **Insight**: <1-2 sentence key finding>
- **Relevance**: <how this affects the current task>
```

---

## Pattern 3: CodeGraph Plan Evidence

### When

A Plan task needs dependency or impact analysis across more than three files.

### What

Use CodeGraph (or equivalent code knowledge tool) for the analysis and summarize the evidence in `analysis.md`.

### Rules

1. If CodeGraph is available for the relevant project, the Plan **should** use it.
2. If CodeGraph is not applicable, the Plan must **explicitly explain why** in `analysis.md`.
3. CodeGraph output is **derived evidence**, not source of truth. Summarize into `analysis.md`; do not replace human/lead architecture judgment.
4. Tiny single-file tasks may skip CodeGraph with a one-line note.
5. Do **not** make CodeGraph mandatory for trivial tasks.

### Evidence Format in `analysis.md`

```markdown
### CodeGraph Evidence
- **Query**: <what was searched>
- **Result summary**: <key dependencies/impacts found>
- **Confidence**: <high/medium/low — and why>
- **Alternative**: <if CodeGraph was skipped, why>
```

---

## Pattern 4: Task Package Prompt Contract

### When

Ba Ba or a lead model gives another model a task packet.

### What

The handoff must include a copy-ready execution prompt that helps the receiving model use the packet correctly. The prompt does **not** replace the packet — it is an execution wrapper.

### Required Prompt Sections

| Section | Purpose |
|---------|---------|
| `Task packet path` | Identifies the runtime source of truth |
| `Goal` | Summarizes the bounded outcome |
| `Read first` | Lists exact files to read before action |
| `Before editing` | Lists `task-guard` and `task-state can-edit` commands |
| `Allowed paths` | Limits edit scope |
| `Forbidden paths` | Prevents task state/spec/AC/source drift |
| `Execution rules` | Names phase, worker authority, and stop conditions |
| `Verification commands` | Defines commands and expected result |
| `Report format` | Requires changed files, evidence, AC mapping, and residual risk |

### Evidence Rule (include in every prompt)

```text
Do not claim a file exists, a test passed, or a task is done unless you verified it
with a command or file read in this session.
```

### Stop Conditions (include in every prompt)

The worker must stop when:
- a required file is missing;
- the gate fails;
- an allowed path is insufficient;
- the task appears to require architecture changes;
- verification fails more than the package allows;
- the worker would need to change acceptance criteria or task state.

### Prompt Template

```markdown
## Task Execution Prompt

**Task packet path**: `<task-packet-root>`

**Goal**: <one-sentence bounded outcome>

**Read first**:
1. `<task-packet-root>/spec.md`
2. `<task-packet-root>/tasks.md`
3. `<task-packet-root>/analysis.md`
4. <other files as needed>

**Before editing**:
- `task-guard.ps1 <task-name> <phase>`
- `task-state.ps1 can-edit <task-name>`

**Allowed paths**:
- `<path-1>`
- `<path-2>`

**Forbidden paths**:
- `<task-packet-root>/.task.yaml`
- `<task-packet-root>/spec.md` (unless explicitly allowed)
- `<paths outside task scope>`

**Execution rules**:
- Phase: <plan|implement|review|verify>
- Worker authority: <none|issuer-worker-v1|legacy>
- Stop conditions: see above

**Verification commands**:
- `<command-1>` → expected: `<output>`
- `<command-2>` → expected: `<output>`

**Report format**:
- Changed files (with paths)
- Evidence (file reads, command output, test results)
- AC mapping (AC# → evidence)
- Residual risk (if any)
- Extra scope taken: no

**Evidence rule**: Do not claim a file exists, a test passed, or a task is done
unless you verified it with a command or file read in this session.
```

---

## Pattern 5: Evidence-Backed Claims

### When

An agent claims a task is done, a file exists, or verification passed.

### What

The agent must cite current-session evidence: file reads, command output, or test results. Unsupported progress claims should be rejected during review.

### Rules

1. "Done" requires: at least one verification command output or file existence check from the current session.
2. "File created" requires: a `read_file` or `ls` confirming the file exists at the claimed path.
3. "Test passed" requires: the actual test command output showing the pass.
4. "Verified" requires: the verification command output, not just the agent's assertion.
5. Reviewers should reject claims that lack current-session evidence.

### Acceptable Evidence Types

| Claim type | Required evidence |
|-----------|------------------|
| File exists | `read_file` output showing content, or `ls`/`Test-Path` output |
| Command succeeded | Terminal output with exit code 0 |
| Test passed | Test runner output showing pass |
| Verification done | Verification command output |
| AC satisfied | Mapping from AC# to specific evidence above |

---

## Fable/Claude-Code Lesson Boundary

The patterns above were **inspired by** Fable/Claude-Code-style agent operating-system discussions, but they are **translated into local mechanisms**:

| Fable/CC pattern | Local mechanism |
|-----------------|----------------|
| Long-task checkpoints | Task packet files + 2-Action findings |
| Tools/files as external memory | `.memory.md` + `analysis.md`/`findings.md` |
| Evidence-backed progress | Pattern 5: Evidence-Backed Claims |
| Thinking vs doing boundary | Task packet phases + gate commands |
| Explicit worker prompts | Pattern 4: Task Package Prompt Contract |

**Boundary rule**: Public or leaked system prompt text must **not** be copied into local authoritative rules. Only the structural patterns are absorbed.

---

## Non-Goals

- Do not implement all `.memory.md` files in one migration.
- Do not alter Mentor Mode or KG/video task scope.
- Do not require CodeGraph for trivial single-file tasks.
- Do not build hook automation before the pilot is confirmed.
- Do not copy public/leaked system prompt text into local authoritative rules.
- Do not let task handoff prompts override the task packet or mechanical gates.
