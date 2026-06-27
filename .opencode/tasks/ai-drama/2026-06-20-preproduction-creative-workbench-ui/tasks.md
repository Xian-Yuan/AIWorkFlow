# Tasks: Preproduction Creative Workbench UI

## Dependency Graph

```
T1 frontend shell
  -> T2 domain state and prompt variants
  -> T3 guided intake UI
  -> T4 creative cards and workflow rail
  -> T5 export adapter and validation display
  -> T6 docs and verification
```

---

## Frontend Shell

- [x] T1.1: Create `Project/AIDramaProducer/apps/preproduction-workbench/` with Vite, React, TypeScript, package scripts, Vitest and Playwright configuration.
- [x] T1.2: Implement the approved four-zone layout with stable responsive dimensions, icon controls and accessible tabs/buttons.
- [x] T1.3: Add desktop and mobile layout tests for AC01 and AC08.

## State And Prompt Contracts

- [x] T2.1: Define typed frontend models for creative brief, workflow step, creative card, prompt variant, export status and artifact file summary.
- [x] T2.2: Implement local project/session persistence for brief answers, prompt variants and active step.
- [x] T2.3: Implement prompt variant generation for writer, director, storyboard, visual bible, negative constraints and editorial review.
- [x] T2.4: Add unit tests for AC02, AC03 and AC07.

## Guided Intake

- [x] T3.1: Implement conversation-style question flow for required brief fields and drama-specific optional fields.
- [x] T3.2: Implement option chips, custom answer input, field completion status and disabled export until required fields are complete.
- [x] T3.3: Add component tests for required-field completion and reload persistence.

## Creative Cards And Prompt Lab

- [x] T4.1: Implement right-side creative cards for creative brief, character continuity, style constraints and content boundaries.
- [x] T4.2: Implement bottom Prompt Lab tabs, copy/edit/compare controls and score/status affordances.
- [x] T4.3: Add tests that prompt edits update the active variant without corrupting generated baseline variants.

## Export And Validation

- [x] T5.1: Add a local export adapter that writes or requests a text-only preproduction artifact directory using existing `ai_drama_preproduction_studio` contracts.
- [x] T5.2: Display progress, output file list, validation result and editorial findings.
- [x] T5.3: Add an integration or Playwright test that runs a real sample brief through export and checks required files.
- [x] T5.4: Run `python -m ai_drama_preproduction_studio validate <artifact_dir>` and show validation truth in the UI.

## Documentation

- [x] T6.1: Create `Project/AIDramaProducer/Docs/01-Planning/CreativeStudio/2026-06-20-preproduction-creative-workbench-ui-plan.md`.
- [x] T6.2: Create `Project/AIDramaProducer/Docs/02-Design/CreativeStudio/2026-06-20-preproduction-creative-workbench-ui-design.md`.
- [x] T6.3: Create or update `Project/AIDramaProducer/Docs/03-Architecture/CreativeStudio/preproduction-workbench-data-flow.md`.
- [x] T6.4: Create implementation and testing notes under `04-Implementation/CreativeStudio/` and `05-Testing/CreativeStudio/`.
- [x] T6.5: Update `Project/AIDramaProducer/Docs/DOCS_TREE.md`.

## Final Verification

- [x] T7.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T7.2: Run automated verification and record command output in `verification-report.md`.
- [x] T7.3: Map implementation result to Acceptance Criteria in `verification-report.md`.
- [x] T7.4: Run `.\\.trae\\scripts\\task-guard.ps1 ai-drama/2026-06-20-preproduction-creative-workbench-ui implement` after verification report is complete, and keep the final verify guard for the Verify phase.
