# Routing Decision: Preproduction Creative Workbench UI

## Project Detection

- Project type: web
- Project: AIDramaProducer
- System: CreativeStudio / Preproduction Creative Workbench
- Task root: `.trae/tasks/ai-drama/2026-06-20-preproduction-creative-workbench-ui`
- Primary skill: `web-fullstack`
- Secondary skills: `ui-ux-pro-max`, `test-driven-development`, `doc-governance`, `verification-before-completion`
- Collaboration mode: lead-owned implementation, no external worker packages for the initial focused delivery

## Active Decisions

- Build a dedicated local web workbench for the preproduction text chain rather than adapting a generic Dify/Flowise-style workflow canvas.
- Use the approved UI direction: left workflow rail, center guided conversation, right structured creative cards, persistent bottom Prompt Lab.
- Keep the first delivery text-only: no image generation, video rendering, TTS, ComfyUI execution or provider credential work.
- Reuse existing `ai_drama_preproduction_studio` domain functions and validation contracts instead of duplicating story, director, storyboard or editorial logic in the frontend.
- Add a simple runnable local app surface under AIDramaProducer, with tests and docs, so Ba Ba can operate the workflow without pasting Python snippets.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation includes quality level: yes

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/ai-drama/2026-06-20-preproduction-creative-workbench-ui`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no
- The lead agent owns architecture, implementation, review preparation and verification evidence.

## Allowed Paths

- `Project/AIDramaProducer/apps/preproduction-workbench/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/`
- `Project/AIDramaProducer/skills/tests/fixtures/preproduction_output/`
- `Project/AIDramaProducer/Docs/01-Planning/CreativeStudio/`
- `Project/AIDramaProducer/Docs/02-Design/CreativeStudio/`
- `Project/AIDramaProducer/Docs/03-Architecture/CreativeStudio/`
- `Project/AIDramaProducer/Docs/04-Implementation/CreativeStudio/`
- `Project/AIDramaProducer/Docs/05-Testing/CreativeStudio/`
- `Project/AIDramaProducer/Docs/DOCS_TREE.md`
- This task packet and its verification report

## Forbidden Paths

- `Project/RTS/`
- `Project/CharacterDesignTool/` except read-only reference
- `Project/Jinli/`
- Image, keyframe, TTS, video, compositor and ComfyUI generation implementations
- Provider credentials, cookies, authentication tokens or private account data
- Any generic workflow platform replacement that weakens the existing `ai_drama_preproduction_studio` contracts

## Implementation Order

1. Define frontend project shell and typed preproduction artifact model.
2. Implement guided intake and local project state.
3. Implement structured creative cards and workflow progress rail.
4. Implement Prompt Lab prompt variants for writer, director, storyboard, visual bible, negative constraints and editorial review.
5. Implement export/run integration with the existing text chain and artifact validation.
6. Add automated unit/component tests, Playwright visual checks and project docs.

## Handoff Rule

If the task is delegated later, a worker must receive a bounded work package. Until then, no worker may infer architecture, edit task state or mark review/verify complete.
