# Analysis: Preproduction Workbench zh-CN

## Architecture Context

### System boundaries

- AIDramaProducer owns the workbench.
- `apps/preproduction-workbench/src` owns React UI text, guided intake copy and generated prompt variants.
- Export adapter JSON schemas and backend-compatible artifact names are outside localization scope.

### Dependency map

- `models.ts` supplies workflow labels, tabs, field prompts and selectable option labels.
- `useProjectState.ts` supplies guided intake messages and export progress text.
- `promptGenerator.ts` supplies editable prompt variant labels and template text.
- Components render labels, buttons, status badges and empty states.

### Data and state ownership

- Persisted localStorage state remains owned by `store.ts`.
- Creative brief field keys remain English schema keys for compatibility.
- Chinese text is presentation/prompt content, not schema migration.

### Integration points

- Vite/React frontend.
- Existing Vitest and Playwright tests.
- Existing BAT/PS1 launcher smoke check.

## Mature Solution Evidence

### Project-local evidence

- Current workbench already centralizes many visible labels in `models.ts` and component files.
- Existing tests interact by visible English text, so tests must be updated to localized UI text.

### Official/framework evidence

- React supports Unicode UI text directly; no additional i18n framework is required for a single-language local tool.
- TypeScript string literals can safely contain Simplified Chinese when source files are UTF-8.

### External mature references

- For single-locale internal tools, direct localized copy is a mature path when runtime language switching is not required.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Direct Simplified Chinese copy in existing files | Existing single-language app | Small, maintainable, no runtime overhead | No language switch | Selected |
| Add i18n dictionary framework | i18next-style pattern | Future language switching | Extra abstraction not needed now | Rejected |
| Browser auto-translation | External browser feature | No code change | Poor prompt quality and test instability | Rejected |

### Rejected shortcuts

- Do not translate schema keys or artifact filenames.
- Do not leave core buttons/tests in English while only translating headers.
- Do not add a generic i18n framework before the project needs multiple runtime locales.

### Selected mature path

- Localize all visible UI copy and prompt template products to Simplified Chinese while preserving compatibility boundaries.
- Update Playwright tests to assert the Chinese UI.

## Acceptance Criteria

- AC01: First screen core UI labels are Simplified Chinese.
- AC02: Guided intake questions, options, buttons and completion messages are Simplified Chinese.
- AC03: Prompt Lab tabs, variant labels and generated prompt texts are Simplified Chinese.
- AC04: Export controls and validation display are Simplified Chinese while export artifacts remain valid.
- AC05: Build, unit tests, E2E tests and launcher smoke check pass.

## Automated Verification Plan

- Command: `npm.cmd test -- --run` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: exit 0.
- Command: `npm.cmd run build` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: exit 0.
- Command: `npx.cmd playwright test` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: exit 0.
- Command: `cmd /c Project\AIDramaProducer\start-preproduction-workbench.bat --smoke-test`
- Expected: exits 0 and prints `SMOKE TEST PASSED`.
