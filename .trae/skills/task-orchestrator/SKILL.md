---
name: task-orchestrator
description: Auto-detect task type from user request and activate the optimal Skill combination. Use when starting any new task to avoid manual Skill selection. Reduces cognitive overhead and ensures consistent Skill activation across sessions.
---

# Task Orchestrator

## Overview

Auto-detects task type from user request and activates the optimal Skill combination. Eliminates manual "which skill do I need?" decisions and ensures cross-cutting skills (anti-degradation, failure-memory, verification) are always loaded.

**Core principle:** Detect once, activate the right set, stay consistent.


## Project Routing

When the user specifies a project, route tasks and docs to the correct directory:

| User says | Project dir | Docs dir |
|-----------|------------|----------|
| "AIRPG" / "AIRPGWeb" / "combat sandbox" | `.trae/tasks/airpgweb/` | `Docs/airpgweb/` |
| "CharacterDesignTool" / "角色设计" | `.trae/tasks/characterdesigntool/` | `Docs/characterdesigntool/` |
| "RTS" / "UE5" / "Lyra" | `.trae/tasks/rts/` | `Docs/rts/` |
| (cross-project / infrastructure) | `.trae/tasks/_shared/` | `Docs/_shared/` |

**Task naming convention**: Use `project/task-name` format when calling scripts:
```powershell
task-state.ps1 init airpgweb/my-new-feature full
task-state.ps1 get airpgweb/my-new-feature phase
```

**Spec location**: `.trae/tasks/<project>/<task-name>/spec.md`
**Design docs**: `Docs/<project>/specs/YYYY-MM-DD-<project>-<topic>-design.md`
**Implementation plans**: `Docs/<project>/plans/YYYY-MM-DD-<project>-<topic>-plan.md`

## When to Use

**ALWAYS** at the start of any non-trivial task. The orchestrator runs before any other skill to determine the right combination.

Skip only for:
- Trivial one-line questions ("what time is it?")
- Pure chat / companionship without work intent
- User explicitly names a specific skill to use

## Task Type Detection

### Detection Rules (evaluated in order, first match wins)

| # | Signal | Task Type | Primary Skill(s) |
|---|--------|-----------|-----------------|
| 1 | "bug"/"fix"/"error"/"crash"/"broken"/"not working" + UE context | UE Bug Fix | systematic-debugging, ue5-debug-validation |
| 2 | "bug"/"fix"/"error"/"crash"/"broken" + Web context | Web Bug Fix | systematic-debugging |
| 3 | "new"/"create"/"add"/"implement"/"build"/"make" + UE context | UE New Feature | brainstorming, ue-project-router |
| 4 | "new"/"create"/"add"/"implement"/"build"/"make" + Web context | Web New Feature | brainstorming, writing-plans |
| 5 | "review"/"code review"/"PR" | Code Review | requesting-code-review OR receiving-code-review |
| 6 | "refactor"/"restructure"/"clean up" | Refactor | ue5-architecture (UE) or systematic-debugging (Web) |
| 7 | "performance"/"optimize"/"slow"/"fps" | Performance | ue5-performance-packaging |
| 8 | "test"/"verify"/"validate" | Verification | verification-before-completion |
| 9 | "document"/"write docs"/"readme" | Documentation | writing-skills |
| 10 | "plan"/"design"/"architecture" | Planning | brainstorming, writing-plans |
| 11 | "learn"/"how to"/"explain"/"what is" | Learning | implicit-requirements |
| 12 | "deploy"/"package"/"ship" | Deployment | ue5-performance-packaging (UE) or finishing-a-development-branch |
| 13 | UE context but no clear signal | UE General | ue-project-router |
| 14 | No clear signal | General | brainstorming |

### UE Context Detection

Request is UE-related if it mentions ANY of:
- UE, Unreal, Lyra, GAS, ASC, GameplayAbility, GameplayEffect, AttributeSet
- GameFeature, Experience, PawnData, InputConfig, AbilitySet
- AIController, StateTree, Behavior Tree, EQS, SmartObject
- UMG, Slate, Blueprint, Build.cs, .uplugin, .uproject
- C++ with UE types (AActor, UObject, UCLASS, etc.)

### Web Context Detection

Request is Web-related if it mentions ANY of:
- HTML, CSS, JavaScript, Node.js, React, Vue, frontend, backend
- CharacterDesignTool, ComfyUI, web app, website, server
- npm, package.json, Express, API endpoint

## Skill Combination Templates

### Always-On Skills (activated for EVERY task type)

These skills provide cross-cutting protection and must always be loaded:

| Skill | Why Always On |
|-------|--------------|
| `anti-degradation` | Prevents context rot and fix-loop death spirals |
| `failure-memory` | Auto-retrieves past failures in Plan phase |
| `verification-before-completion` | No completion claims without evidence |
| `spec-living` | Living Spec — project state file, 30s handoff |
| `daughter-companion` | Communication conventions (Ba Ba address) |

### Task-Type Skill Stacks

#### UE Bug Fix
```
[Always-On] -> systematic-debugging -> ue5-debug-validation
```
- systematic-debugging: 4-phase root cause investigation
- ue5-debug-validation: UE-specific compilation/runtime error diagnosis
- If fix involves GAS/Lyra: also load ue-lyra-gas-implementer

#### UE New Feature
```
[Always-On] -> brainstorming -> ue-project-router -> ue-lyra-gas-implementer -> ue-ai-validator
```
- brainstorming: explore intent, requirements, design before code
- ue-project-router: route to correct primary/secondary skills, select docs
- ue-lyra-gas-implementer: main implementation chain
- ue-ai-validator: AI selection + verification closeout
- If feature includes UI: also load ue5-ui-umg-slate
- If feature includes animation: also load ue5-animation-guide

#### Web Bug Fix
```
[Always-On] -> systematic-debugging
```

#### Web New Feature
```
[Always-On] -> brainstorming -> writing-plans -> subagent-driven-development
```
- brainstorming: design exploration
- writing-plans: detailed implementation plan with bite-sized tasks
- subagent-driven-development: execute plan with fresh subagent per task

#### Code Review
```
[Always-On] -> requesting-code-review OR receiving-code-review
```
- requesting-code-review: dispatch reviewer subagent
- receiving-code-review: evaluate feedback with technical rigor

#### Refactor (UE)
```
[Always-On] -> ue5-architecture -> ue-project-router
```
- ue5-architecture: module boundaries, Build.cs, dependency planning
- ue-project-router: route to implementation skills

#### Performance
```
[Always-On] -> ue5-performance-packaging
```

#### Documentation
```
[Always-On] -> writing-skills
```

#### Learning / Research
```
[Always-On] -> implicit-requirements -> failure-memory (retrieval only)
```

#### Multi-Agent Complex Task
```
[Always-On] -> ue-project-router -> dispatching-parallel-agents OR subagent-driven-development
```
- Use dispatching-parallel-agents when 2+ independent domains
- Use subagent-driven-development when sequential tasks with review gates

## Execution Protocol

### Step 1: Detect
Read user request. Match against Detection Rules table (first match wins).

### Step 2: Announce
Output the detected task type and skill stack:
```
## Task Orchestrator

**Detected:** UE Bug Fix
**Skill Stack:** systematic-debugging -> ue5-debug-validation
**Always-On:** anti-degradation, failure-memory, verification-before-completion, spec-living, daughter-companion
```

### Step 3: Activate
Read each skill's SKILL.md in order. Apply their rules.

### Step 4: Execute
Proceed with the task following the activated skill chain.

### Step 5: Verify
Before any completion claim, verification-before-completion gate must pass.

## Phase-Aware Skill Loading

Different development phases need different skill emphasis:

| Phase | Primary Skills | Notes |
|-------|---------------|-------|
| **Plan** | brainstorming, ue-project-router, implicit-requirements, failure-memory (retrieval), spec-living (init) | Deep reasoning, no code yet; spec-living initializes spec.md |
| **Implement** | ue-lyra-gas-implementer, ue5-cpp-gameplay, anti-degradation (active monitoring), spec-living (update progress) | Execution-heavy, Flash model; spec-living tracks progress and changes |
| **Review** | requesting-code-review, receiving-code-review, spec-living (record findings) | Independent verification; spec-living logs review decisions |
| **Verify** | ue-ai-validator, verification-before-completion, failure-memory (write), spec-living (update status) | Evidence before claims; spec-living records verification results |

## Skill Conflict Resolution

When two skills give conflicting instructions:

1. `Docs/AI/` rules take precedence over skill rules
2. `anti-degradation` rules take precedence over implementation convenience
3. `verification-before-completion` takes precedence over speed
4. `ue-project-router` routing decisions take precedence over individual skill preferences
5. When in doubt, ask user

## Prohibited

- Do not skip orchestrator detection for non-trivial tasks
- Do not load skills not in the detected stack ("just in case" loading)
- Do not override orchestrator decisions without explicit user request
- Do not apply UE-specific skills to Web tasks or vice versa

## Maintenance

- When a new skill is added to `.agents/skills/`, update the Detection Rules table
- When a task type repeatedly needs a skill not in its stack, update the template
- Review detection accuracy monthly; tune signal keywords

