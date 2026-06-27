# Tasks: Jinli Self-Evolution Engine v1

## Dependency Graph

```
T1 (evolve-self.ps1 core) → T2 (CLI integration) → T3 (SKILL.md triggers) → T4 (verify + docs)
                                    ↘
                              T2b (knowledge discovery) ────────────↗
```

## T1 — Write evolve-self.ps1 (~380 lines actual)

- [x] T1.1: Write `Project/Jinli/scripts/evolve-self.ps1` with these functions:
  - `Invoke-HabitEvolution`: main pipeline (aggregate → LLM reflect → propose → guard → present)
  - `Get-EventStats`: statistical aggregator (trigger frequencies, emotion trends, co-occurrence)
  - `Invoke-PatternExtraction`: LLM prompt for pattern discovery from event data
  - `Test-AdjustmentValidity`: Verification Guard (value range, conflict, frequency, schema)
  - `Invoke-KnowledgeDiscovery`: arXiv/GitHub search → LLM analysis → report
  - `Write-EvolutionResult`: confirmed changes → atomic write to style-profile.json
- [x] T1.2: Statistical aggregator reads events.jsonl, outputs structured summary (frequencies, trends)
- [x] T1.3: LLM prompt template for pattern extraction (includes Jinli context, event data, output format)
- [x] T1.4: Verification Guard with value clamp (0.05-1.0), conflict detection, daily limit (≤2/param)
- [x] T1.5: Knowledge Discovery: search arXiv + GitHub, LLM analysis, report generation

## T2 — CLI Integration

- [x] T2.1: Add `evolve` command to soul-core.ps1 CLI: triggers Invoke-HabitEvolution
- [x] T2.2: Add `discover` command to soul-core.ps1 CLI: triggers Invoke-KnowledgeDiscovery
- [x] T2.3: Add session-end auto-prompt placeholder in Invoke-SessionEnd (after N sessions, suggest evolve)
- [x] T2.4: Run `soul-core.ps1 -Command evolve` — verify pipeline executes
- [x] T2.5: Run `soul-core.ps1 -Command discover` — verify search + report generated

## T3 — SKILL.md Triggers

- [x] T3.1: Add knowledge discovery trigger phrases to daughter-companion SKILL.md:
  - "去看看"/"学习一下"/"有什么新项目"/"有什么新论文"/"看看最近"
- [x] T3.2: Verify agent can trigger knowledge discovery from natural language

## T4 — Verify and Document

- [x] T4.1: Run evolve-self.ps1 on today's events.jsonl — verify LLM extracts at least 1 pattern
- [x] T4.2: Test Verification Guard with invalid adjustment — verify rejection
- [x] T4.3: Test Ba Ba Gate — verify no changes applied without confirmation
- [x] T4.4: Run all 18 Pester tests — verify no regression
- [x] T4.5: Run soul-core-safety-assert.ps1 — verify ALL SCRIPTS SAFE
- [x] T4.6: Compare production hashes — verify static files unchanged
- [x] T4.7: Create `Project/Jinli/Docs/04-Implementation/General/soul-core-self-evolution.md`
- [x] T4.8: Update `Project/Jinli/Docs/DOCS_TREE.md`
- [x] T4.9: Run doc-governance
- [x] T4.10: Run automated verification: `soul-core-safety-assert.ps1` (must pass) + Pester suite (18/18) + production hash comparison
- [x] T4.11: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T4.12: Map implementation result to Acceptance Criteria and record in verification-report.md

## Phase Exit

1. `task-guard.ps1 2026-06-18-jinli-self-evolution-engine implement -Apply` → Review
2. Independent review, record `review_result=pass`
3. `task-guard.ps1 2026-06-18-jinli-self-evolution-engine review -Apply` → Verify
4. Record `verify_result=pass`, `verification_report`
5. `task-guard.ps1 verify -Apply` → Archive
