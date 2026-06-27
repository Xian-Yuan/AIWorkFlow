# Routing Decision: Preproduction Workbench BAT Launcher

## Project Detection

- Project type: web
- Project: AIDramaProducer
- System: CreativeStudio / Preproduction Workbench operations
- Task root: `.trae/tasks/ai-drama/2026-06-20-preproduction-workbench-launcher-bat`
- Primary skill: `web-fullstack`
- Secondary skills: `doc-governance`, `verification-before-completion`
- Collaboration mode: lead-owned direct hot path, no external workers

## Active Decisions

- Add a root-level Windows BAT launcher so Ba Ba can double-click to open the preproduction workbench.
- The launcher starts the existing Vite app; it does not change frontend behavior, text export contracts or media generation scope.
- The launcher performs user-friendly checks for Node.js/npm and installs dependencies on first run.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation includes quality level: yes

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/ai-drama/2026-06-20-preproduction-workbench-launcher-bat`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Allowed Paths

- `Project/AIDramaProducer/start-preproduction-workbench.bat`
- `Project/AIDramaProducer/Docs/06-Operations/CreativeStudio/`
- `Project/AIDramaProducer/Docs/DOCS_TREE.md`
- This task packet

## Forbidden Paths

- `Project/RTS/`
- `Project/CharacterDesignTool/`
- Workbench source code under `Project/AIDramaProducer/apps/preproduction-workbench/src/`
- Python preproduction studio implementation
- Provider credentials, environment secrets or private tokens

