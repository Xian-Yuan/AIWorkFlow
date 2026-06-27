# Analysis: Preproduction Creative Workbench UI

## Architecture Context

### System boundaries

- AIDramaProducer owns the feature.
- `ai_drama_preproduction_studio` remains the source of truth for creative brief, strategy, story bible, beat sheet, screenplay, director treatment, storyboard, visual bible and editorial review generation.
- The new workbench owns only user interaction, prompt variant editing, local session/project state, running/exporting the text chain and presenting validation results.
- Media generation packages remain downstream consumers and are explicitly out of scope.

### Dependency map

- Frontend workbench -> local UI state -> preproduction API/CLI adapter -> `ai_drama_preproduction_studio` modules -> artifact directory -> `python -m ai_drama_preproduction_studio validate`.
- Prompt Lab -> structured brief/story state -> prompt template compiler -> editable prompt variants -> copy/export.
- Tests -> frontend unit/component checks + Python validation fixtures + Playwright screenshot/interaction checks.

### Data and state ownership

- Workbench session state owns transient UI fields, selected workflow step, chat messages, prompt variants and current artifact directory.
- `creative_brief.json` and generated artifact JSON/Markdown/Fountain files remain owned by the preproduction studio output contract.
- Local saved projects should be browser-local or file-backed in the workbench only; no global provider secrets or account credentials are stored in this task.

### Integration points

- Existing Python package: `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/`
- Existing validation CLI: `python -m ai_drama_preproduction_studio validate <artifact_dir>`
- Existing renderer functions: Markdown/Fountain renderers under `modules/screenwriter/renderers/`
- Existing task/docs governance: `Project/AIDramaProducer/Docs/` and `Project/AIDramaProducer/Docs/DOCS_TREE.md`

## Mature Solution Evidence

### Project-local evidence

- `Project/CharacterDesignTool/interview-engine.js` proves the project already benefits from guided question flow, collected traits, followups and prompt generation.
- `Project/CharacterDesignTool/chat-ui.js` provides a proven pattern for messages, option chips, custom input, prompt bar and persisted prompt variants.
- `Project/CharacterDesignTool/project-store.js` shows local project snapshots, continuing prior work and prompt bundle persistence.
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/__main__.py` already validates the required artifact directory and should remain the output gate.
- `Project/AIDramaProducer/output/preproduction_demo_real_input/` confirms the text-only artifact shape works with real sample input.

### Official/framework evidence

- Prefer a standard Vite + React + TypeScript frontend for a local web workbench because the task needs dense interactive UI, reusable components and Playwright verification.
- Prefer typed local API or CLI adapter boundaries rather than direct browser-side Python calls.
- Prefer automated UI testing with Playwright because frontend layout and interaction quality are part of acceptance.

### External mature references

- Dify: mature workflow app pattern with visual run/export lifecycle.
- Langflow/Flowise: workflow-step visibility and node-level run status, but too generic/heavy for this domain.
- ChainForge/promptfoo: prompt variants and evaluation patterns for comparing output quality.
- Langfuse: prompt management, versions and observability concepts.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Domain-specific guided workbench | CharacterDesignTool + current preproduction contracts | Fast for Ba Ba's actual workflow, fewer concepts, preserves text chain contracts | Less generic than a node canvas | Selected |
| Generic node workflow canvas | Dify/Langflow/Flowise | Flexible and familiar to AI workflow users | Too broad, slower to build, can hide the creative interview flow | Rejected for first delivery |
| CLI-only generator with sample JSON | Current Python modules | Fastest implementation | Does not solve Ba Ba's UI/workflow need | Rejected as insufficient |
| Streamlit quick UI | Python ecosystem | Quick to wire to Python modules | Harder to reach polished desktop-style UX and Prompt Lab interactions | Rejected for product surface |

### Rejected shortcuts

- Do not build only a static mockup with no working input, persistence or export.
- Do not fork CharacterDesignTool wholesale; reuse patterns, not its role-specific code or global `window.*` architecture.
- Do not duplicate story-generation logic in the frontend.
- Do not add media generation controls before the text workflow is usable.
- Do not require users to manually paste Python scripts for normal operation.

### Selected mature path

- Create a focused AIDramaProducer web workbench that uses the approved UI layout and exposes the existing text-first preproduction chain through a clean adapter.
- Implement structured data flow: guided brief intake -> prompt variants -> run/export -> validation -> artifact viewer.
- Keep the backend/domain boundary small and testable so future image/video/TTS stages can consume the exported text artifacts later.

## Acceptance Criteria

- AC01: A local workbench app starts and renders the approved four-zone layout: workflow rail, guided interview, structured creative cards and bottom Prompt Lab.
- AC02: The guided intake captures required brief fields (`platform`, `audience`, `content_type`, `target_duration`) plus optional drama-specific fields without losing state during step navigation.
- AC03: Prompt Lab generates editable/copyable variants for writer, director, storyboard, visual bible, negative constraints and editorial review.
- AC04: The workbench can run or call a local text-chain export for a real brief and writes the required artifact files.
- AC05: Exported artifact directories pass `python -m ai_drama_preproduction_studio validate <dir>`.
- AC06: The UI displays validation/editorial results and file list without claiming media generation is complete.
- AC07: The implementation includes unit/component tests for state, prompt variants and export adapter behavior.
- AC08: The implementation includes Playwright verification screenshots for desktop and mobile-width responsive layouts.

## Automated Verification Plan

- Command: `python -m pytest ai_drama_preproduction_studio/tests -q`
- Expected: All preproduction studio tests pass.
- Command: `python -m ai_drama_preproduction_studio validate tests/fixtures/preproduction_output`
- Expected: JSON output includes `"valid": true`.
- Command: `npm test -- --run` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: frontend unit tests pass.
- Command: `npm run build` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: production build succeeds.
- Command: `npx playwright test` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: workbench layout and export flow tests pass with screenshots recorded.

## Risks And Mitigations

- Risk: A new frontend toolchain adds maintenance overhead. Mitigation: keep the app scoped under `apps/preproduction-workbench` with narrow adapter contracts and local tests.
- Risk: UI claims may drift from Python output truth. Mitigation: validation must use the existing preproduction CLI, and UI status must reflect validation output.
- Risk: Prompt variants become generic boilerplate. Mitigation: generate variants from structured brief/story state and add tests for required prompt sections.
