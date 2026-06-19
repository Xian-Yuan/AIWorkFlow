# AI Workflow Refactor And Doc Taxonomy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the AI workflow refactor spec into the active workflow and organize current workspace documentation through non-destructive taxonomy indexes and project docs trees.

**Architecture:** Keep existing documents in place during the first pass, add canonical manifests and generated indexes, then migrate files only after references are audited. Active workflow entrypoints point to `spec-living`, `doc-governance`, and mechanical guards; deprecated mechanisms remain compatibility-only.

**Tech Stack:** Markdown workflow docs, Codex skills, Trae/OpenCode task scripts, PowerShell regression checks.

---

## File Structure

- Create: `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`  
  Canonical refactor entrypoint after `AGENTS.md` and `Docs/AI/01-AI-Development-Playbook.md`.
- Move by recreate/delete: `Docs/AI/27-Documentation-Governance-Workflow.md` -> `Docs/AI/28-Documentation-Governance-Workflow.md`  
  Keeps documentation governance active while preserving the original refactor manifest number.
- Modify: `Docs/AI/README.md`  
  Replace stale index with current AI docs index.
- Modify: `Docs/AI/.cache-manifest.md`  
  Classify docs `25` through `28`.
- Modify: `skills/ue-project-router/SKILL.md`  
  Replace active `spec-tracker` examples with `spec-living` and add `doc-governance` evidence.
- Modify: `.trae/scripts/test-workflow-regression.ps1`  
  Add regression checks for spec-living primary routing, Docs/AI index coverage, and doc governance.
- Create: `.trae/scripts/update-docs-tree.ps1`  
  Generate project `DOCS_TREE.md` files from current project docs without moving files.
- Create: `Docs/AI/document-taxonomy-inventory.md`  
  Current workspace document classification inventory and migration notes.
- Modify: `Project/*/Docs/DOCS_TREE.md`  
  Generated per-project document trees.

## Task 1: Manifest And Numbering

- [ ] Create `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` with active, deprecated, experimental, and mechanical workflow components.
- [ ] Move documentation governance to `Docs/AI/28-Documentation-Governance-Workflow.md`.
- [ ] Update `Docs/AI/.cache-manifest.md` so `25`, `26`, `27`, and `28` are volatile.
- [ ] Update `Docs/AI/README.md` to list `01` through `28`.

Verification:

```powershell
Test-Path .\Docs\AI\27-AI-Workflow-Refactor-Manifest.md
Test-Path .\Docs\AI\28-Documentation-Governance-Workflow.md
Select-String .\Docs\AI\README.md -Pattern "27-AI-Workflow-Refactor-Manifest","28-Documentation-Governance-Workflow"
```

Expected: all commands find the new docs.

## Task 2: Active Workflow Integration

- [ ] Update `skills/ue-project-router/SKILL.md` active examples from `spec-tracker.ps1` to `spec-living.ps1`.
- [ ] Add `doc-impact.md` and `doc-governance` to router phase evidence.
- [ ] Keep `spec-tracker` references only in deprecated compatibility contexts.

Verification:

```powershell
rg -n "spec-tracker.ps1" .\skills\ue-project-router\SKILL.md
rg -n "spec-living.ps1|doc-impact|doc-governance" .\skills\ue-project-router\SKILL.md
```

Expected: no active `spec-tracker.ps1` examples remain in router; `spec-living` and doc governance are present.

## Task 3: Workspace Document Inventory

- [ ] Create `.trae/scripts/update-docs-tree.ps1`.
- [ ] Generate `Docs/AI/document-taxonomy-inventory.md`.
- [ ] Regenerate `Project/<ProjectName>/Docs/DOCS_TREE.md` for every project.
- [ ] Keep existing docs in place; record migration candidates instead of moving them.

Verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
Get-ChildItem .\Project -Directory | ForEach-Object { Test-Path (Join-Path $_.FullName "Docs\DOCS_TREE.md") }
```

Expected: check passes and every project reports `True`.

## Task 4: Regression Coverage

- [ ] Extend `.trae/scripts/test-workflow-regression.ps1`.
- [ ] Include checks for doc governance, spec-living primary routing, and Docs/AI index coverage.
- [ ] Run doc guard and workflow regression.

Verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

Expected: both commands exit `0`.

## Self-Review

- Spec coverage: implements manifest, index/cache updates, spec-living migration, document taxonomy inventory, project docs trees, and regression.
- Placeholder scan: no TBD/TODO/fill-later steps.
- Scope safety: first pass is non-destructive for existing docs; it generates indexes and migration notes before any bulk move.

