# Task Package Prompt Template

> Source: `Docs/AI/43-AI-Workflow-Context-Efficiency-Patterns.md` Pattern 4

Copy and fill this template when handing a task packet to another model.

---

## Task Execution Prompt

**Task packet path**: `<task-packet-root>`

**Goal**: <one-sentence bounded outcome>

**Read first**:
1. `<task-packet-root>/execution-prompt.md`
2. `<task-packet-root>/requirements.md` (deep discovery) or `routing.md#Fast-Track-Assessment`
3. `<task-packet-root>/spec.md`
4. `<task-packet-root>/tasks.md`
5. `<task-packet-root>/analysis.md`
6. <other files as needed>

**Requirement gate**:
- Change profile: `<deep|fast>`
- Requirements status: `<confirmed|not_required>`
- Human intent source: `<requirements.md|routing.md#Fast-Track-Assessment>`
- Do not reinterpret the raw user message when it conflicts with the confirmed task packet.

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
- Stop conditions: see below

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

**Stop conditions**:
- A required file is missing
- The gate fails
- An allowed path is insufficient
- The task appears to require architecture changes
- Verification fails more than the package allows
- The worker would need to change acceptance criteria or task state
