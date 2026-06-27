# Spec: AI Workflow Ecosystem Upgrade

## GIVEN
- AI workflow infrastructure is mature (task packets, mechanical gates, model tiering, 57 skills)
- Ecosystem survey (Docs/AI/research/2026-06-AI-Agent-Ecosystem-Survey.md) identified 4 high-value integrations
- Current spec-template.md lacks structured quality checklist section
- Plan phase search is single-platform (webfetch/websearch only)
- Agent handoff templates lack structured context sections
- Agent-Reach cannot be pip-installed due to GitHub network restrictions

## WHEN
Apply the 3 feasible P0/P1 upgrades from the ecosystem survey:
1. Upgrade spec-template.md with Quality Checklist section (spec-kit philosophy)
2. Upgrade Plan Agent SKILL.md Step 1e with multi-platform search strategy
3. Upgrade handoff templates with structured context sections
4. Document Agent-Reach integration path (blocked by network, with workaround)

## THEN

### M1: spec-template.md Quality Checklist Section
- New `## Quality Checklist` section after Acceptance Criteria
- Items follow "Unit Tests for Requirements" philosophy
- Categories: Completeness, Clarity, Consistency, Scenario Coverage, Edge Case Coverage
- Each item references spec section or uses [Gap]/[Ambiguity] markers

### M2: Plan Agent Multi-Platform Search
- Step 1e enhanced with multi-platform strategy
- Primary: GitHub code search; Secondary: web search Reddit/HN; Tertiary: Agent-Reach
- Standardized result format: platform, relevance, finding, link
- Graceful fallback to single-platform when multi unavailable

### M3: Handoff Template Structured Context
- New `## Context Snapshot` section: active decisions, open questions, constraints, file summary
- "What the next agent needs to know in 60 seconds"
- Integrated with existing Docs/AI/09-Agent-Handoff-Templates.md

### M4: Agent-Reach Documented Integration Path
- New doc: what it provides, why valuable, install steps, network workaround
- Status: blocked by GitHub access, ready when resolved

### M5: Verification
- Diff review of all changed files
- Workflow regression tests S17-S20
- Manual: create test task with new templates

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output | Actual Result |
|-----|-------------|---------------------|-----------------|---------------|
| AC01 | spec-template.md has Quality Checklist section | Select-String check | Match found | ✅ Line 22 |
| AC02 | Checklist items use requirement-quality language | Manual review | No implementation-testing items | ✅ 5 categories, all spec-quality |
| AC03 | Plan Agent SKILL.md Step 1e has multi-platform search | Select-String check | Match found | ✅ Lines 105-131 (4 tiers) |
| AC04 | Handoff template has Context Snapshot section | Select-String check | Match found | ✅ Lines 148-197 (6 fields) |
| AC05 | Agent-Reach integration doc exists | Test-Path check | True | ✅ File exists |
| AC06 | Workflow regression tests pass | Run test script | All PASS | ✅ 20/20 all green |
| AC07 | No existing template behavior broken | Manual review | All sections present | ✅ 0 lines deleted; additive only |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Done | 3 modules selected; Agent-Reach deferred to doc-only |
| Implement | Completed (2026-06-18) | All 4 modules (M1-M4) implemented additively; 5 files touched |
| Review | Ready | Implementer self-verified 7/7 ACs + 20/20 regression tests |
| Verify | Pending | - |

## Non-Goals

- Installing Agent-Reach (blocked by network; documented only)
- Integrating Graphify (P1 - needs UE5 C++ macro validation first)
- Changing task-guard.ps1 or task-state.ps1 behavior
- Modifying .task.yaml schema
- Adding new npm/pip dependencies
