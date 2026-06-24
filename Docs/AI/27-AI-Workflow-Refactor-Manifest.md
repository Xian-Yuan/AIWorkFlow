---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-27-ai-workflow-refactor-manifest-985d
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.27-ai-workflow-refactor-manifest.985d

---

# AI Workflow Refactor Manifest

Date: 2026-06-17
Status: Active
Scope: global AI workflow, task state, skills, scripts, docs taxonomy, memory, regression

## Purpose

This manifest is the short current entrypoint for the AI workflow refactor. It does not replace the detailed playbook. It tells agents which mechanisms are active, which are deprecated, which are experimental, and where documents belong.

Read order for workflow work:

1. `AGENTS.md`
2. `Docs/AI/01-AI-Development-Playbook.md`
3. This manifest
4. `Docs/AI/29-Mature-Solution-First-Workflow.md`
5. `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
6. `Docs/AI/45-Conversational-Requirements-Discovery-Workflow.md`
7. Task-specific `requirements.md`, `execution-prompt.md`, `routing.md`, `spec.md`, `tasks.md`, `analysis.md`, and `doc-impact.md`

## Active Workflow Components

| Component | Location | Role |
|---|---|---|
| Project router | `skills/ue-project-router/SKILL.md`, `.opencode/agents/ue-project-router.md` | Single workflow entrypoint |
| Task state | `.trae/scripts/task-state.ps1`, `.opencode/scripts/task-state.ps1` | Phase state and Can-Edit checks |
| Task guard | `.trae/scripts/task-guard.ps1` | Phase exit gate |
| Handoff | `.trae/scripts/task-handoff.ps1` | Phase handoff template |
| Living Spec | `skills/spec-living/SKILL.md`, `.trae/scripts/spec-living.ps1` | Runtime `spec.md` state |
| Doc governance | `skills/doc-governance/SKILL.md`, `.trae/scripts/doc-guard.ps1` | Project docs sync gate |
| Failure memory | `skills/failure-memory/SKILL.md`, `Docs/Memory/` | Cross-session failure lessons |
| Mature solution first | `Docs/AI/29-Mature-Solution-First-Workflow.md`, `.trae/scripts/task-guard.ps1` | Blocks MVP/reduced-quality plans unless explicitly approved |
| Multi-agent task packets | `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`, `.trae/scripts/work-package-template.md`, `.trae/scripts/agent-result-template.md` | Lets multiple models find bounded work and return evidence |
| DS4 Flash worker repair loop | `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`, `.trae/scripts/worker-repair-loop.ps1` | Repackages independent verification failures into narrower, bounded Flash work and trips architecture review after three same-root failures |
| Issuer-worker authority | `Docs/AI/41-Issuer-Worker-Authority-Separation.md`, `.trae/scripts/authority-core.psm1`, `.trae/scripts/issuer-*.ps1` | Proves publisher/reviewer/archive authority using Windows SID, non-exportable CNG signatures, and bound hashes |
| GitHub SSH publication | `Docs/AI/42-GitHub-SSH-Publish-Workflow.md` | Publishes reviewed root-workflow commits through the protected-origin/writable-gh remote model with worktree isolation and remote SHA verification |
| Codex workflow adapter | `skills/codex-project-router/SKILL.md` | Makes Codex use shared task packets, architecture evidence, and gates |
| Conversational requirements gate | `Docs/AI/45-Conversational-Requirements-Discovery-Workflow.md`, `skills/smart-requirements/SKILL.md` | Separates deep discovery from fast fixes and requires confirmed intent plus an agent-authored execution prompt |
| Workflow regression | `.trae/scripts/test-workflow-regression.ps1` | Mechanical regression checks |

## Deprecated Compatibility Components

| Component | Location | Replacement | Rule |
|---|---|---|---|
| spec-tracker | `skills/spec-tracker/SKILL.md`, `.trae/scripts/spec-tracker.ps1` | `spec-living` | Keep only for historical tasks and compatibility references |
| archived skills | `skills/_archived/` | active `skills/` entries | Do not route to archived skills unless explicitly requested |
| old shared mirrors | `Docs/_shared/specs/`, `Docs/_shared/plans/` | canonical `Docs/superpowers/` specs/plans | Treat as optional mirror or history until cleaned |

## Experimental / Health-Checked Components

| Component | Location | Health Rule |
|---|---|---|
| code-knowledge-graph | `skills/code-knowledge-graph/SKILL.md`, `.trae/scripts/codegraph.ps1` | Must report clear project errors and avoid treating directories as source files |
| agent-memory-bench | `skills/agent-memory-bench/SKILL.md`, `.trae/scripts/memory-benchmark.ps1` | Insufficient data is a health state, not an ambiguous crash |
| output-compressor | `skills/output-compressor/SKILL.md` | Must preserve decisions, risks, commands, and verification evidence |
| enhanced-subagent | `skills/enhanced-subagent/SKILL.md` | Must return evidence, touched paths, and unresolved risks |

## Document Taxonomy

| Class | Canonical Location | Notes |
|---|---|---|
| Global AI workflow docs | `Docs/AI/NN-*.md` | Numbered, indexed in `Docs/AI/README.md`, classified in `.cache-manifest.md` |
| Formal design specs | `Docs/superpowers/specs/YYYY-MM-DD-*-design.md` | Primary design spec location |
| Implementation plans | `Docs/superpowers/plans/YYYY-MM-DD-*-plan.md` | Must link or refer to design spec |
| Shared mirrors | `Docs/_shared/specs/`, `Docs/_shared/plans/` | Mirror only when cross-tool sharing is required |
| Runtime task docs | `.trae/tasks/<scope>/<task>/`, `.opencode/tasks/<scope>/<task>/` | Runtime truth for a task |
| Project docs | `Project/<ProjectName>/Docs/` | Project-specific docs; must have `DOCS_TREE.md` |
| Memory docs | `Docs/Memory/` | Failure memory and memory candidates |

## Runtime Task Required Files

Each active task should contain:

| File | Required By |
|---|---|
| `.task.yaml` | task state |
| `routing.md` | router decision |
| `spec.md` | Living Spec |
| `tasks.md` | implementation checklist |
| `analysis.md` | analysis and constraints |
| `doc-impact.md` | documentation governance |
| `requirements.md` | confirmed human-readable intent for version-1 deep tasks |
| `execution-prompt.md` | planner-authored execution contract for version-1 deep and fast tasks |

## Phase Gates

| Transition | Required Evidence |
|---|---|
| plan -> implement | routing, tasks, Living Spec, analysis, doc-impact, mature solution evidence, architecture context, acceptance criteria, automated verification plan, work package policy, quality gate, requirement profile, confirmed requirement evidence or fast-track assessment, execution prompt, clarification resolved, user plan confirmation, router proof |
| implement -> review | tasks complete, edit auth still valid, project checks, doc governance, Living Spec progress |
| review -> verify | review pass and evidence |
| verify -> archive | verification report, tasks complete, verification pass |

## Refactor Decisions

1. `spec-living` is the primary runtime spec mechanism.
2. `spec-tracker` is compatibility-only.
3. `Docs/superpowers/specs/` is canonical for formal design specs.
4. `Docs/_shared/specs/` is not canonical by default.
5. Project-specific docs must live in `Project/<ProjectName>/Docs/`.
6. Project document trees are required and generated by `.trae/scripts/update-docs-tree.ps1`.
7. Bulk document moves require a migration plan and link audit first.
8. Mature production-grade implementation is the default; MVP/prototype/reduced-quality plans require explicit user opt-in and a recorded Quality Exception.
9. Multi-model collaboration must go through task packets and work packages; worker models do not own architecture or final verification.
10. Codex must use `skills/codex-project-router/SKILL.md` for project work until a native `.codex/tasks` adapter exists.
11. Worker models may append progress and submit one result only; task mutation, Review, Verify, repair publication, and Archive are original-Issuer capabilities.
12. New version-1 task packets must classify the change as deep or fast. Deep tasks require confirmed `requirements.md`; both profiles require `execution-prompt.md`.

## Verification Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
```



## Current Authoritative Runtime (2026-06-17)

**Hard rule**: The current authoritative mechanical workflow is .trae/scripts. engine/ is a refactor candidate until explicitly promoted. Do NOT use engine/phase-machine.ps1 or .agents/engine/phase-machine.ps1 as phase gates — both are disabled.

| Layer | Authoritative Source | Status |
|-------|---------------------|--------|
| Task state management | .trae/scripts/task-state.ps1 | Active authoritative |
| Phase gate enforcement | .trae/scripts/task-guard.ps1 | Active authoritative |
| Document governance | .trae/scripts/doc-guard.ps1 | Active authoritative |
| Spec lifecycle | .trae/scripts/spec-living.ps1 | Active authoritative |
| Memory retrieval | .trae/scripts/memory-retrieve.ps1 | Active authoritative |
| Verification | .trae/scripts/verify.ps1 | Active authoritative |
| DS4 repair orchestration | .trae/scripts/worker-repair-loop.ps1 | Active authoritative for tasks with worker_profile=ds4-flash |
| Issuer identity and signatures | .trae/scripts/authority-core.psm1 + issuer-identity.ps1 | Active authoritative |
| Packet/capability authority | task-packet-seal.ps1 + worker-capability.ps1 + worker-submit.ps1 | Active authoritative |
| Review and archive authority | issuer-review.ps1 + issuer-archive.ps1 | Active authoritative |
| Regression testing | .trae/scripts/test-workflow-regression.ps1 | Active authoritative |
| Rule registry | engine/rule-registry.json + engine/rule-enforcer.ps1 | Active authoritative |
| Phase machine | engine/phase-machine.ps1 | DISABLED — parse errors |
| Phase machine (legacy) | .agents/engine/phase-machine.ps1 | DISABLED — parse errors |
| Experimental scripts | engine/_experimental/ | Non-blocking experiments |

**Safe operating rule**: Use .trae/scripts as mechanical authority. Use .trae/tasks as shared runtime task root. Treat engine/ as refactor candidate. Codex must load skills/codex-project-router before project work.

See: Docs/AI/34-AI-Workflow-Current-Audit.md for full audit details.
