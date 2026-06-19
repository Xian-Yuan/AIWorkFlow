# Mature Solution First Workflow

Date: 2026-06-17
Status: Active
Scope: global AI workflow, plan gate, implementation quality, research evidence

## Purpose

This document makes one rule explicit:

**The default implementation strategy is the mature production-grade path, not the smallest landing path.**

An MVP, prototype, temporary shortcut, reduced-quality implementation, or "do the minimum first" plan is allowed only when the user explicitly asks for it. If the user asks for a normal feature, system, workflow, refactor, or fix, the agent must design and implement the complete mature solution that fits the current project architecture.

## External Basis

This workflow adapts the following Claude/Anthropic engineering patterns:

- Claude Code common workflows: plan before editing, run parallel sessions with worktrees, and delegate research to subagents.
  Source: https://code.claude.com/docs/en/common-workflows
- Claude Code memory and instruction model: project rules guide behavior, but hard enforcement needs hooks or mechanical checks.
  Source: https://code.claude.com/docs/en/memory
- Claude Code subagents: specialized agents should do noisy research in isolated context and return summaries.
  Source: https://code.claude.com/docs/en/sub-agents
- Claude Code hooks: lifecycle hooks can enforce checks automatically.
  Source: https://code.claude.com/docs/en/hooks
- Anthropic agent patterns: use routing, prompt chaining, parallelization, orchestrator-workers, and evaluator-optimizer workflows when task complexity warrants them.
  Source: https://www.anthropic.com/engineering/building-effective-agents

## Non-Negotiable Rules

### Rule 1: Mature path is the default

For every non-trivial task, the plan must start from the best maintainable architecture already implied by:

- existing project design docs
- existing code and assets
- framework-native or engine-native APIs
- mature open-source references
- official documentation
- known project constraints and failure memory

The agent must not propose a deliberately reduced-quality implementation as the default path.

### Rule 2: MVP requires explicit user opt-in

The following phrases are red flags unless the user explicitly requested them:

- "MVP"
- "minimum viable"
- "minimum landing"
- "temporary"
- "placeholder"
- "quick hack"
- "later replace"
- "simplified first"
- "reduced scope"
- "defer the real architecture"

If such a path is proposed, `routing.md` must include:

```markdown
## Quality Exception
- Exception type: MVP / Prototype / Temporary / Reduced Scope
- User approval: explicit quote or decision reference
- Expiration: task/date/condition for replacing it
```

Without this section, the plan is invalid.

### Rule 3: Research before design

Before finalizing a technical design, the agent must gather evidence in this order:

1. Project-local implementation search.
2. Project design/spec/plan search.
3. Official framework or engine documentation.
4. Mature external references, preferably official docs or high-quality open-source projects.
5. Failure memory relevant to the task.

Research output must be summarized in `analysis.md`.

### Rule 4: Compare mature options, do not default to the easiest one

`analysis.md` must include a `## Mature Solution Evidence` section with:

- `Project-local evidence`: existing code/docs/assets that shape the solution.
- `Official/framework evidence`: engine, library, or API references.
- `External mature references`: links or project references if applicable.
- `Options compared`: at least two viable approaches for non-trivial tasks.
- `Rejected shortcuts`: any tempting shortcut and why it is rejected.
- `Selected mature path`: the chosen architecture and why it is maintainable.

Hotfixes may use a shorter section, but still must state why the fix is mature and not a shortcut.

### Rule 5: User confirmation must include quality level

The Plan confirmation prompt must explicitly show:

- selected mature path
- rejected shortcuts
- implementation completeness
- known non-goals
- verification evidence to be produced

The user confirms the mature plan, not just a task list.

### Rule 6: Implementation must follow the selected mature path

During Implement:

- Do not replace the approved mature architecture with a smaller workaround.
- If the mature path becomes impossible, stop and return to Plan.
- If scope must shrink, record it as a Quality Exception and request user confirmation.
- Update `spec.md`, `analysis.md`, and `tasks.md` before continuing.

### Rule 7: Review and Verify judge against maturity, not just passing tests

Review and Verify must check:

- The implementation follows the selected mature path.
- No shortcut from `Rejected shortcuts` was reintroduced.
- Framework-native APIs and project patterns are used where applicable.
- Tests or validation cover the actual behavior, not only compilation.
- Documentation reflects the final architecture.

Passing build/tests is necessary but not sufficient.

## Required Task File Sections

### analysis.md

```markdown
## Mature Solution Evidence

### Project-local evidence
- ...

### Official/framework evidence
- ...

### External mature references
- ...

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|

### Rejected shortcuts
- ...

### Selected mature path
- ...
```

### routing.md

```markdown
## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
```

If MVP/prototype is explicitly requested:

```markdown
## Quality Gate
- Default quality level: User-approved MVP/prototype
- MVP/prototype requested by user: yes
- Quality Exception: present
```

### tasks.md

Every task list must include at least one verification task that checks maturity:

```markdown
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
```

## Mechanical Enforcement

`task-guard.ps1 plan` must fail unless:

- `analysis.md` contains `Mature Solution Evidence`
- `routing.md` contains `Quality Gate`
- `routing.md` declares either `MVP/prototype requested by user: no` or includes `Quality Exception`
- `tasks.md` contains a mature-path verification task

This converts the rule from guidance into a hard phase gate.

## When To Use Subagents

Use research subagents when:

- the codebase search would read many files
- external reference comparison is needed
- the task crosses two or more systems
- the first design attempt is uncertain
- previous attempts drifted toward shortcuts

The main agent must only import the summary into `analysis.md`; noisy raw search results stay out of the main context.

## Workflow Pattern Mapping

| Task shape | Required pattern |
|---|---|
| Clear single-system task | Prompt chaining: understand -> evidence -> design -> implement -> verify |
| Distinct project types or skills | Routing |
| Independent research/code/doc checks | Parallelization |
| Complex multi-file coding | Orchestrator-workers |
| Reviewable quality improvement | Evaluator-optimizer |
| Repeated noisy research | Subagent isolation |

## Anti-Patterns

- Treating "can compile" as "mature".
- Replacing project architecture with a local one-off class.
- Creating placeholder assets or fake adapters when real project assets are required.
- Skipping official docs because a minimal local implementation is faster.
- Calling a design "phase 1" without defining phase boundaries and replacement criteria.
- Asking the user to accept a reduced solution when the user asked for the mature path.

## Relationship To Existing Docs

This document extends:

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`
- `Docs/AI/15-FailSafe-AntiBloat.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/28-Documentation-Governance-Workflow.md`

If there is a conflict, this document wins on quality level selection: mature solution first.
