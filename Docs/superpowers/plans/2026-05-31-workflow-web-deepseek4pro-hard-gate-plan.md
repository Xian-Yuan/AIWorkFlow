# Workflow Web DeepSeek4Pro Hard Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the workspace workflow so Web tasks use the same hard edit gate as UE tasks, while adding a shared DeepSeek4Pro profile that improves workflow compliance across router, implementers, and review.

**Architecture:** Keep `ue-project-router` as the only workflow entry. Add a dedicated `web-implementer` agent for Web `Implement`, wire Web skills to the same `task-state.ps1 can-edit` gate already used by UE, and add one reusable DeepSeek4Pro profile document so critical constraints are referenced from a single truth source instead of duplicated ad hoc.

**Tech Stack:** Markdown agent/skill definitions, PowerShell workflow scripts, workspace Docs

---

## File Map

### Create

- `g:\UEGameDevelopment\.opencode\agents\web-implementer.md`
  - Web implementer agent aligned with the existing phase machine
- `g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md`
  - Shared DeepSeek4Pro prompt/profile truth source

### Modify

- `g:\UEGameDevelopment\.opencode\agents\ue-project-router.md`
  - Route Web implement phase through `web-implementer`
  - Reference the DeepSeek4Pro profile and fixed action order
- `g:\UEGameDevelopment\.opencode\agents\code-quality-reviewer.md`
  - Add the same fixed preflight/output contract for DeepSeek4Pro
- `g:\UEGameDevelopment\CLAUDE.md`
  - Index the new Web agent and profile doc
- `g:\UEGameDevelopment\.trae\rules\project_rules.md`
  - Update cross-project workflow wording for Web implementer and profile
- `g:\UEGameDevelopment\Docs\AI\11-Skill-Routing-Workflow.md`
  - Reflect Web implementer routing and profile reference
- `g:\UEGameDevelopment\Docs\AI\12-MultiAgent-Workflow.md`
  - Replace old Web placeholder wording with the concrete Web implementer role
- `g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md`
  - Require Web implement phase to go through `web-implementer`
  - Reference DeepSeek4Pro fixed execution order
- `g:\UEGameDevelopment\.trae\skills\web-fullstack\SKILL.md`
  - Add `can-edit` gate and fixed execution order
- `g:\UEGameDevelopment\.trae\skills\ui-ux-pro-max\SKILL.md`
  - Add `can-edit` gate and fixed execution order
- `g:\UEGameDevelopment\.trae\skills\webapp-testing\SKILL.md`
  - Add gate-aware verify behavior and structured output contract

### Verification

- `g:\UEGameDevelopment\.trae\scripts\task-state.ps1`
  - Reuse existing `can-edit` behavior without modification
- Markdown diagnostics for all changed `.md` files
- PowerShell parse check for touched scripts (if any script changes occur)

## Task 1: Add The Shared DeepSeek4Pro Workflow Profile

**Files:**
- Create: `g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md`
- Modify: `g:\UEGameDevelopment\CLAUDE.md`
- Modify: `g:\UEGameDevelopment\.trae\rules\project_rules.md`

- [ ] **Step 1: Write the new profile doc with short hard constraints**

Create `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md` with:

```md
# DeepSeek4Pro Workflow Profile

## Goal
- Make DeepSeek4Pro follow the workspace workflow mechanically.

## Highest-Priority Rules
- Read phase from `.task.yaml`; never trust chat history alone.
- No confirmation -> no edit.
- No `can-edit` pass -> no write.
- No real skill/tool call -> no pretend execution.
- If blocked, only ask, read, search, or report the blocker.

## Fixed Action Order
1. Read state
2. Check phase
3. Run `can-edit` if implementation is requested
4. Load required skill
5. Read `routing.md`, `analysis.md`, `spec.md`, `tasks.md`
6. Only then edit

## Required Status Block
```text
PHASE: <plan|implement|review|verify>
AUTH: <blocked|allowed>
NEXT: <ask|search|read|edit|verify>
BLOCKER: <none|...>
```
```

- [ ] **Step 2: Add the profile to the truth-source index**

Update `CLAUDE.md` to include:

```md
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro workflow hard-gate profile |
```

- [ ] **Step 3: Reference the profile from project rules**

Add a short rule block in `project_rules.md` that points implementers and reviewers to `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md` as the shared prompt profile for DeepSeek4Pro sessions.

- [ ] **Step 4: Review the new profile for duplicated or conflicting rules**

Check:
- no contradiction with existing `can-edit` gate
- no Web/UE specific wording in the shared profile unless marked as examples

- [ ] **Step 5: Commit the profile foundation**

```bash
git add Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md CLAUDE.md .trae/rules/project_rules.md
git commit -m "docs: add DeepSeek4Pro workflow profile"
```

## Task 2: Add Web Implementer And Route Web Implement Through It

**Files:**
- Create: `g:\UEGameDevelopment\.opencode\agents\web-implementer.md`
- Modify: `g:\UEGameDevelopment\.opencode\agents\ue-project-router.md`
- Modify: `g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\12-MultiAgent-Workflow.md`

- [ ] **Step 1: Create `web-implementer.md`**

Create an agent with:

```md
description: Web implementation agent — executes Web implement phase only
mode: subagent
```

Core rules:
- must run `task-state.ps1 check <task-name> implement`
- must run `task-state.ps1 can-edit <task-name>` before any `edit/write/apply_patch`
- must load the main Web skill from `routing.md`
- if blocked, must stop and report `STATUS: NEED_USER_CONFIRMATION`

- [ ] **Step 2: Route Web implement phase to the new agent**

Update `ue-project-router.md` and `ue-project-router/SKILL.md` so Web implement phase references `web-implementer` first, then the concrete Web skill.

- [ ] **Step 3: Update the multi-agent doc**

Replace the generic “web-fullstack 等” wording in `Docs/AI/12-MultiAgent-Workflow.md` with the explicit chain:

```text
router -> web-implementer -> web skill -> code-quality-reviewer
```

- [ ] **Step 4: Align wording with the existing UE implement chain**

Check that Web and UE now share:
- one router
- one phase model
- one edit gate
- one review agent

- [ ] **Step 5: Commit the Web implementer layer**

```bash
git add .opencode/agents/web-implementer.md .opencode/agents/ue-project-router.md .trae/skills/ue-project-router/SKILL.md Docs/AI/12-MultiAgent-Workflow.md
git commit -m "feat: add web implementer workflow layer"
```

## Task 3: Add Hard Edit Gates To Web Skills

**Files:**
- Modify: `g:\UEGameDevelopment\.trae\skills\web-fullstack\SKILL.md`
- Modify: `g:\UEGameDevelopment\.trae\skills\ui-ux-pro-max\SKILL.md`
- Modify: `g:\UEGameDevelopment\.trae\skills\webapp-testing\SKILL.md`

- [ ] **Step 1: Add a shared preflight block to `web-fullstack`**

Insert:

```md
## Implement Gate
- Before any edit/write/apply_patch, run:
```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
& $TASK_STATE can-edit <task-name>
```
- If `can-edit` fails, only ask/read/search. Do not write code.
```

- [ ] **Step 2: Add the same gate to `ui-ux-pro-max`**

Tailor the wording so design suggestions remain allowed, but actual code changes still require `can-edit`.

- [ ] **Step 3: Make `webapp-testing` gate-aware**

Add rules:
- test scripts may be proposed or updated only after `can-edit` if they are part of implementation
- read-only investigation remains allowed without `can-edit`
- verification output must use the shared status block

- [ ] **Step 4: Add the fixed DeepSeek4Pro execution order to all three Web skills**

Add the same six-step order from the profile doc and reference the profile path rather than duplicating long explanations.

- [ ] **Step 5: Commit the Web skill gate updates**

```bash
git add .trae/skills/web-fullstack/SKILL.md .trae/skills/ui-ux-pro-max/SKILL.md .trae/skills/webapp-testing/SKILL.md
git commit -m "feat: enforce can-edit in web skills"
```

## Task 4: Align Router, Reviewer, And Routing Docs With DeepSeek4Pro

**Files:**
- Modify: `g:\UEGameDevelopment\Docs\AI\11-Skill-Routing-Workflow.md`
- Modify: `g:\UEGameDevelopment\.opencode\agents\code-quality-reviewer.md`

- [ ] **Step 1: Update the routing doc**

Add Web-side routing language that names `web-implementer` as the Web implement-phase agent and points to the DeepSeek4Pro profile as a shared compliance reference.

- [ ] **Step 2: Add DeepSeek4Pro status/output contract to the reviewer**

Add:

```md
Before review, output:
PHASE: review|verify
AUTH: allowed
NEXT: verify
BLOCKER: none
```

And add a fail-closed reminder that blocked or incomplete evidence must never be re-labeled as PASS.

- [ ] **Step 3: Reconcile with existing independence checks**

Ensure the new reviewer wording does not weaken:
- independent context requirement
- evidence requirement
- fail-closed behavior

- [ ] **Step 4: Run a placeholder/consistency scan on the changed docs**

Search changed docs for:
- `TODO`
- `TBD`
- conflicting references to old Web flow wording

- [ ] **Step 5: Commit the routing/reviewer alignment**

```bash
git add Docs/AI/11-Skill-Routing-Workflow.md .opencode/agents/code-quality-reviewer.md
git commit -m "docs: align routing and review with DeepSeek4Pro profile"
```

## Task 5: Validate Documentation And Workflow Integrity

**Files:**
- Verify: `g:\UEGameDevelopment\.opencode\agents\web-implementer.md`
- Verify: `g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md`
- Verify: all changed `.md` files

- [ ] **Step 1: Run markdown diagnostics on every changed file**

Use editor diagnostics to confirm no malformed markdown or workspace warnings were introduced.

- [ ] **Step 2: Parse-check PowerShell scripts only if touched**

Run:

```powershell
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('g:\UEGameDevelopment\.trae\scripts\task-state.ps1', [ref]$tokens, [ref]$errors)
$errors
```

Expected:

```text
No parse errors
```

- [ ] **Step 3: Spot-check the new workflow references**

Verify these chains are now consistent:
- `project_rules.md`
- `CLAUDE.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`
- `ue-project-router` agent and skill

- [ ] **Step 4: Capture the resulting workflow summary**

Record:
- Web implement path now exists
- Web skills now require `can-edit`
- DeepSeek4Pro has one shared profile source

- [ ] **Step 5: Commit the validation-safe final state**

```bash
git add .
git commit -m "chore: finalize web workflow hard-gate alignment"
```
