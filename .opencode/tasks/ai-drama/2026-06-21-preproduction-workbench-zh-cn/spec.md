# Spec: Preproduction Workbench zh-CN

## GIVEN

Ba Ba wants the preproduction workbench to be Chinese-first for daily creative prompt workflow.

## WHEN

The user opens the local preproduction workbench.

## THEN

The interface, guided interview, prompt lab products and export status are shown in Simplified Chinese while the text production/export chain stays compatible.

### S01 Chinese First Screen

**Status**: [x]

The workflow rail, creative brief header, card titles, tabs and primary buttons use Simplified Chinese.

### S02 Chinese Guided Intake

**Status**: [x]

The onboarding message, required-field questions, option chips, custom input placeholder and completion actions use Simplified Chinese.

### S03 Chinese Prompt Products

**Status**: [x]

Prompt Lab tab names, variant labels and generated prompt text are Chinese and suitable for writer/director/storyboard use.

### S04 Chinese Export Surface

**Status**: [x]

Export button, progress, validation title, artifact summary and editorial findings label use Chinese while generated artifact JSON remains valid.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Visible UI labels are Chinese | `npx.cmd playwright test tests/workbench-layout.spec.ts` | layout tests pass with Chinese selectors |
| AC02 | Guided intake and prompt generation work in Chinese | `npx.cmd playwright test tests/export-flow.spec.ts` | flow tests pass with Chinese selectors |
| AC03 | Unit behavior remains compatible | `npm.cmd test -- --run` | exit 0 |
| AC04 | Production build succeeds | `npm.cmd run build` | exit 0 |
| AC05 | Launcher still opens reachable workbench | `cmd /c Project\AIDramaProducer\start-preproduction-workbench.bat --smoke-test` | `SMOKE TEST PASSED` |

## Non-Goals

- Runtime language switching.
- Translating JSON schema keys or artifact filenames.
- Changing export artifact content contracts beyond editable prompt text copy.
