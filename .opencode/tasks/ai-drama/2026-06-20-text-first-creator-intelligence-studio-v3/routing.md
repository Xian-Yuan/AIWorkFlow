# Routing Decision: Text-first Creator Intelligence & Preproduction Studio v3

## Project Detection

- Project type: other
- Project: AIDramaProducer
- System: creator research, style distillation, creative strategy and professional text preproduction
- Task root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Primary skill: `writing-skills`
- Secondary skills: `web-fullstack`, `test-driven-development`, `doc-governance`, `verification-before-completion`
- Collaboration mode: bounded work packages with lead-owned architecture and final verification

## Active Decisions

- Keep one stable `ai_drama_creator_intelligence` Skill instead of auto-registering one Skill per creator.
- Generate versioned `creator_style_pack` artifacts for normal runtime use.
- Allow optional inactive Skill-bundle generation only after sufficient samples and provenance checks.
- Create `ai_drama_preproduction_studio` for intake, strategy, screenwriter, director, storyboard, art direction and editorial review.
- Keep `ai_drama_viral_analyzer` as a compatibility facade until downstream consumers migrate.
- Prioritize text artifacts; ComfyUI and media generation remain outside this task.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation includes quality level: yes

## Work Package Policy

- External workers: yes
- Task packet root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes
- Workers may implement only their assigned package.
- Architecture decisions, task mutation, Review and Verify remain with the lead.

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/`
- `Project/AIDramaProducer/skills/ai_drama_viral_analyzer/`
- `Project/AIDramaProducer/skills/ai_drama_scriptwriter/`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/`
- `Project/AIDramaProducer/data/creator_style_packs/`
- `Project/AIDramaProducer/Docs/`
- This task packet and its reports

## Forbidden Paths

- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`
- Image, keyframe, TTS, video and compositor implementation packages except read-only contract inspection
- Provider credentials, cookies, authentication tokens or private account data
- Automatic activation of generated creator Skills
- Copying complete scripts, joke compilations or signature dialogue from source creators

## Implementation Order

1. WP01 contracts and registries.
2. WP02 source acquisition and evidence.
3. WP03 distillation and inactive Skill bundles.
4. WP04 creative intake and strategy.
5. WP05 professional screenplay.
6. WP06 director, storyboard, visual bible and editorial.
7. WP07 compatibility and orchestration.
8. WP08 documentation and independent verification.

## Handoff Rule

Another model may execute a work package after reading that package and its listed files. It must not infer missing architecture or edit task state. If a package requires a decision outside its boundary, it returns `Status: blocked`.

