# Spec: Preproduction Creative Workbench UI

## GIVEN

Ba Ba needs a more automatic, workflow-style interface for AI drama preproduction creative and prompt work. The current text chain can already produce preproduction artifacts, but normal use still requires direct Python/module operation or manual scripts.

## WHEN

A user opens the local preproduction workbench, answers guided creative questions, reviews prompt variants and runs the text export workflow.

## THEN

The workbench presents a usable creative-production surface, keeps the workflow text-only, exports validated preproduction artifacts and gives the user editable prompt products for writer/director/storyboard usage.

### S01 Workbench Layout

**Status**: [x]

The first screen is the working app, not a landing page. It shows a left workflow rail, center guided interview, right creative cards and bottom Prompt Lab. It uses the approved quiet professional style and avoids generic marketing layout.

### S02 Guided Brief Intake

**Status**: [x]

The user can enter required brief fields and drama-specific optional details through conversation-style questions, option chips and custom text input. Required fields are visibly complete before export is enabled.

### S03 Structured Creative Cards

**Status**: [x]

The right panel summarizes creative brief, character continuity, style constraints and content boundaries using compact editable fields and status badges.

### S04 Prompt Lab

**Status**: [x]

The Prompt Lab exposes tabs for writer, director, storyboard, visual bible, negative constraints and editorial review. Each tab shows multiple editable prompt variants with copy/edit/compare controls.

### S05 Text Chain Export

**Status**: [x]

The user can run the front-end export action for a real brief and receive a complete artifact directory containing the required JSON artifacts and human-readable screenplay files.

### S06 Validation And Review Display

**Status**: [x]

The UI runs or consumes artifact validation and displays valid/missing/invalid state, editorial findings and output file list.

### S07 Persistence

**Status**: [x]

The current project state, brief answers and prompt variants survive page reload using local persistence or a local file-backed store.

### S08 Responsive Verification

**Status**: [x]

The app remains usable at desktop and mobile-width viewports. Text does not overlap, fixed controls do not shift unexpectedly and Prompt Lab remains reachable.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Four-zone workbench layout renders | `npx playwright test tests/workbench-layout.spec.ts` | desktop screenshot shows rail, interview, creative cards and Prompt Lab |
| AC02 | Guided intake captures required brief fields | `npm test -- --run` | brief state tests pass |
| AC03 | Prompt Lab generates editable/copyable prompt variants | `npm test -- --run` | prompt variant tests pass |
| AC04 | Text export creates required artifacts | `npx playwright test tests/export-flow.spec.ts` | export flow test passes |
| AC05 | Export output validates against existing CLI | `python -m ai_drama_preproduction_studio validate tests/fixtures/preproduction_output` | `"valid": true` |
| AC06 | UI displays validation/editorial status truthfully | `npx playwright test tests/export-flow.spec.ts` | validation status and file list assertions pass |
| AC07 | Frontend production build succeeds | `npm run build` | build exits 0 |
| AC08 | Existing preproduction tests remain green | `python -m pytest ai_drama_preproduction_studio/tests -q` | all tests pass |

## Quality Checklist

### Completeness
- [x] [OK] All requested first-phase text workflow needs are covered.
- [x] [OK] Each scenario has a concrete input condition and expected output.
- [x] [OK] Acceptance Criteria cover all scenarios.

### Clarity
- [x] [OK] The UI scope is defined as local preproduction workbench.
- [x] [OK] Media generation is explicitly excluded.
- [x] [OK] Third-party references are design references, not dependencies.

### Consistency
- [x] [OK] Terms match existing AIDramaProducer CreativeStudio docs.
- [x] [OK] File placement follows project docs taxonomy and `apps/preproduction-workbench` app boundary.
- [x] [OK] Existing preproduction studio contracts remain authoritative.

### Scenario Coverage
- [x] [OK] Main path is guided intake through validated export.
- [x] [OK] Edge cases include incomplete brief and responsive layout.
- [x] [OK] Error path includes validation failure display.

### Edge Case Coverage
- [x] [OK] Empty/missing required brief fields are covered.
- [x] [OK] Reload persistence is covered.
- [x] [OK] Export validation failure is covered.
- [x] [OK] Long-running export has progress/status display requirements.

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Domain-specific guided workbench selected |
| Implement | Complete | All tasks done, 61 unit tests + 8 e2e tests pass |
| Review | Pending | Independent review required |
| Verify | Pending | Automated UI and Python validation required |

## Non-Goals

- Image generation, video generation, keyframe generation, TTS, compositor or ComfyUI execution.
- Public multi-user SaaS deployment.
- Generic node-based workflow builder.
- Provider credential management beyond existing local model/API settings if already present.
