# Tasks: AI Workflow Ecosystem Upgrade

## Dependency Graph

```
M1 (spec-template) ──┐
M2 (plan-agent)    ──┼── M5 (verification)
M3 (handoff)       ──┤
M4 (agent-reach)   ──┘
```

All modules are independent; M5 runs after all others complete.

## Task List

### M1: spec-template.md — Quality Checklist Section

| ID | Task | File | Scenario |
|----|------|------|----------|
| T1.1 | Read current spec-template.md and spec-kit checklist philosophy | `.trae/tasks/_shared/templates/spec-template.md` | AC01, AC02 |
| T1.2 | Design Quality Checklist section with 5 categories | (design) | AC02 |
| T1.3 | Add `## Quality Checklist` section to spec-template.md | `.trae/tasks/_shared/templates/spec-template.md` | AC01 |
| T1.4 | Add inline guidance comments so AI knows how to fill checklist | `.trae/tasks/_shared/templates/spec-template.md` | AC02 |
| T1.5 | Verify: Select-String confirms section exists, manual review confirms no implementation-testing items | `.trae/tasks/_shared/templates/spec-template.md` | AC01, AC02 |

### M2: Plan Agent SKILL.md — Multi-Platform Search

| ID | Task | File | Scenario |
|----|------|------|----------|
| T2.1 | Read current Step 1e in Plan Agent SKILL.md | `skills/金璃小天才/SKILL.md` | AC03 |
| T2.2 | Design multi-platform search strategy (GitHub + web + Agent-Reach fallback) | (design) | AC03 |
| T2.3 | Update Step 1e with multi-platform search instructions | `skills/金璃小天才/SKILL.md` | AC03 |
| T2.4 | Add standardized search result format | `skills/金璃小天才/SKILL.md` | AC03 |
| T2.5 | Verify: Select-String confirms multi-platform references exist | `skills/金璃小天才/SKILL.md` | AC03 |

### M3: Handoff Template — Structured Context

| ID | Task | File | Scenario |
|----|------|------|----------|
| T3.1 | Read current handoff template | `Docs/AI/09-Agent-Handoff-Templates.md` | AC04 |
| T3.2 | Design Context Snapshot section (decisions, questions, constraints, files) | (design) | AC04 |
| T3.3 | Add `## Context Snapshot` section to handoff template | `Docs/AI/09-Agent-Handoff-Templates.md` | AC04 |
| T3.4 | Add usage guidance: when to fill each subsection | `Docs/AI/09-Agent-Handoff-Templates.md` | AC04 |
| T3.5 | Verify: Select-String confirms Context Snapshot exists | `Docs/AI/09-Agent-Handoff-Templates.md` | AC04 |

### M4: Agent-Reach — Documented Integration Path

| ID | Task | File | Scenario |
|----|------|------|----------|
| T4.1 | Create integration doc with value proposition and install steps | `Docs/AI/37-Agent-Reach-Integration.md` | AC05 |
| T4.2 | Document network restriction and workarounds (offline install, mirror, manual clone) | `Docs/AI/37-Agent-Reach-Integration.md` | AC05 |
| T4.3 | Add to Docs/AI/README.md index | `Docs/AI/README.md` | AC05 |
| T4.4 | Verify: Test-Path confirms doc exists | `Docs/AI/37-Agent-Reach-Integration.md` | AC05 |

### M5: Verification & Regression

| ID | Task | File | Scenario |
|----|------|------|----------|
| T5.1 | Run workflow regression tests S17-S20 | `.trae/scripts/test-workflow-regression.ps1` | AC06 |
| T5.2 | Diff review of all changed files | All M1-M4 files | AC07 |
| T5.3 | Manual: create test task with new spec-template, verify all sections render | (manual) | AC07 |
| T5.4 | Update doc-impact.md with final file change list | `.trae/tasks/_shared/2026-06-18-workflow-ecosystem-upgrade/doc-impact.md` | AC07 |
| T5.5 | Generate verification-report.md | `.trae/tasks/_shared/2026-06-18-workflow-ecosystem-upgrade/verification-report.md` | AC06, AC07 |

## Mature Path Verification

- [ ] T-V1: Verify Quality Checklist section follows spec-kit philosophy (not implementation-testing)
- [ ] T-V2: Verify multi-platform search does not break existing single-platform fallback
- [ ] T-V3: Verify handoff Context Snapshot integrates with existing template structure
- [ ] T-V4: Verify Agent-Reach doc clearly states "blocked, ready when network available"
