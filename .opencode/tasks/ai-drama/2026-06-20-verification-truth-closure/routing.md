# Routing Decision: AIDramaProducer Verification Truth Closure

## Project Detection
- Project type: other
- Project: AIDramaProducer
- System: Python Skill pipeline, Scriptwriter/Viral integration, verification governance
- Task root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Primary skill: `codex-project-router`
- Secondary skills: `doc-governance`, `test-driven-development`, `verification-before-completion`
- Collaboration mode: issuer-direct implementation followed by fresh-context independent verification

## Active Decision
- Create a new closure packet instead of rewriting unfinished product requirements as complete.
- Fix only demonstrated defects and integration gaps.
- Keep real AI backends, real media quality metrics, and real URL E2E visibly open in their original packets.
- Mechanical gates and fresh evidence are authoritative; user approval is not a gate override.

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation includes quality level: yes

## Work Package Policy
- External workers: no
- Task packet root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Work packages required: yes
- Claim files required: no
- Worker reports required before merge: no
- Issuer executes the work packages directly and may update packet progress.
- Final verification must use a fresh context that did not implement the changes.

## Authority Policy
- Authority profile: issuer-worker-v1
- Packet mutation authority: issuer only
- Review authority: original issuer only
- Verify authority: original issuer only
- Archive authority: original issuer only
- Verify auto-archive: forbidden

## Allowed Scope
- `Project/AIDramaProducer/skills/pytest.ini`
- `Project/AIDramaProducer/skills/ai_drama_text_preprocessor/`
- `Project/AIDramaProducer/skills/ai_drama_scriptwriter/`
- `Project/AIDramaProducer/skills/ai_drama_viral_analyzer/`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/`
- `Project/AIDramaProducer/Docs/`
- The four active AI-drama task packets under `.trae/tasks/ai-drama/`

## Forbidden Scope
- Do not implement provider credentials or make paid external API calls.
- Do not fabricate SSIM, lip-sync, duration-error, or real-video evidence.
- Do not mark the three original product packets passed or archived while their tasks remain open.
- Do not delete acceptance criteria to make a gate pass.

## Next
Execute WP01 through WP04 in order, reseal the packet after issuer progress updates, then submit the final state to a fresh-context verifier.
