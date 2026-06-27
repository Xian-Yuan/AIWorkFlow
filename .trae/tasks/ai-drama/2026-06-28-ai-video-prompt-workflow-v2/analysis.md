# Analysis

## Architecture Context

This task lands the v2 prompt-workflow contract for `Project/Jinli/services/ai-video-creator`. It updates project documentation/templates only.

### System boundaries

In scope:
- `Project/Jinli/services/ai-video-creator/docs/prompt-template-universal.md`
- `Project/Jinli/services/ai-video-creator/docs/prompt-spec-checklist.md`
- A new v2 design/contract document under the same docs directory.

Out of scope:
- Runtime Python stage rewrites in `Project/Jinli/services/ai-video-creator/stages/`.
- UI changes.
- Provider/API integration changes.
- Story-specific prompt generation.

### Dependency map

- User requirements -> task packet `requirements.md`
- Task packet `analysis/spec/tasks` -> allowed project docs edits
- `prompt-workflow-v2.md` -> canonical v2 Schema and inheritance contract
- `prompt-template-universal.md` -> user-facing reusable prompt template
- `prompt-spec-checklist.md` -> reviewer/linter checklist for v2 compliance
- Future code integration -> may read these docs, but is not part of this task

### Data and state ownership

- The v2 workflow contract is documentation-owned by the AI video creator service docs.
- No runtime data schema, database, generated asset, or persistent service state changes in this task.
- Task state remains owned by `.trae/tasks/ai-drama/2026-06-28-ai-video-prompt-workflow-v2`.

### Integration points

- Existing stage docs and scripts already reference character, storyboard, video prompt, continuity, and audio concepts.
- The landing updates the docs that future generator stages and prompt authors should follow.

## Mature Solution Evidence

### Project-local evidence

- `Project/Jinli/services/ai-video-creator/docs/prompt-template-universal.md` already contains a broad v1 template with character sheets, prop assets, environment assets, continuity tables, shot cards, storyboard, video prompts, audio, negative prompt layering, lip-sync, and hand protection.
- `Project/Jinli/services/ai-video-creator/docs/prompt-spec-checklist.md` already identifies v2 needs: target platform, color/audio guides, role differentiation, prop scale, environment spatial relations, continuity, per-shot negative/audio/color fields.
- `Project/Jinli/services/ai-video-creator/stages/s4_storyboard.py` and `s5_video_prompts.py` already separate storyboard and video prompt stages, so a documentation-first contract matches the existing stage boundaries.

### Official/framework evidence

- Runway Gen-4 prompt guidance emphasizes clear subject, action, environment, camera, lighting, and reference consistency.
- Google DeepMind Veo prompt guidance emphasizes structured cinematic descriptions, shot type, movement, subject, and style.
- Kling user guidance favors concise but explicit video prompts with camera movement, subject action, environment, and visual style.
- The existing project workflow requires mature solution evidence, task packet gates, confirmed requirements, acceptance criteria, and verification plans before implementation.

### External mature references

- Runway Gen-4 Video Prompting Guide: https://help.runwayml.com/hc/en-us/articles/39789879462419-Gen-4-Video-Prompting-Guide
- Google DeepMind Veo Prompt Guide: https://deepmind.google/models/veo/prompt-guide/
- Kling AI Video 3 Model User Guide: https://kling.ai/quickstart/klingai-video-3-model-user-guide

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Patch only the old universal template | Smallest edit | Schema and inheritance rules remain scattered | Rejected |
| Create a canonical v2 contract doc and update existing template/checklist to point to it | Stable, reviewable, low runtime risk, good future code integration path | Requires a new docs file | Selected |
| Rewrite Python stages immediately | Enforces v2 mechanically sooner | Higher risk before Schema stabilizes; may mix design and implementation | Deferred |

### Rejected shortcuts

- Do not produce another story-specific prompt package as "workflow v2"; it would not solve reusable consistency.
- Do not keep PREVIS as a separate optional note; it must be part of the director storyboard layer.
- Do not put all negative prompts in one global block; v2 needs layered ownership and merge rules.
- Do not edit runtime generation code before the documentation contract is stable.

### Selected mature path

Create a canonical `prompt-workflow-v2.md` that defines Schema, inheritance, conflict resolution, platform adapters, and review gates. Then update `prompt-template-universal.md` and `prompt-spec-checklist.md` so the current project docs route authors and future generators to the v2 contract.

1. **Project internal**: builds on existing `ai-video-creator/docs` templates and stage boundaries.
2. **Official reference**: follows provider prompt guidance around subject/action/camera/setting/style/lighting and reference consistency.
3. **Open source reference**: no new dependency needed.
4. **Design doc**: this task packet plus `prompt-workflow-v2.md`.
5. **Existing implementation**: no runtime code changes; docs prepare future integration.
6. **Risk assessment**: low implementation risk, moderate quality risk if checklist is too vague; mitigated by Schema and explicit required-field review.

## Acceptance Criteria

- AC01: A canonical v2 workflow document exists and defines ProjectManifest, CharacterPrompt, ScenePrompt, PropPrompt, DirectorStoryboardPrompt, VideoGenerationPrompt, NegativePromptLibrary, PlatformAdapter, and ReviewChecklist.
- AC02: The v2 document defines inheritance order, conflict resolution, and negative prompt merge order.
- AC03: The director storyboard template merges PREVIS/storyboard and includes the black-and-white rough-pencil rule plus colored annotation legend.
- AC04: The video generation template includes per-shot timeline, MCSLA fields, first/end frame prompts, audio, color, platform adapter, positive and negative prompt outputs.
- AC05: Existing universal template and checklist reference or embed the v2 contract clearly enough that future prompt generation follows it.
- AC06: No runtime Python files are changed in this task.
- AC07: Repository verification records file presence, required marker checks, and gate results in `verification-report.md`.

## Automated Verification Plan

- Command: `Test-Path .\Project\Jinli\services\ai-video-creator\docs\prompt-workflow-v2.md`
- Expected: `True`
- Command: `Select-String -Path .\Project\Jinli\services\ai-video-creator\docs\prompt-workflow-v2.md -Pattern "ProjectManifest","CharacterPrompt","DirectorStoryboardPrompt","VideoGenerationPrompt","Inheritance Rules","Review Checklist"`
- Expected: all required markers present.
- Command: `Select-String -Path .\Project\Jinli\services\ai-video-creator\docs\prompt-template-universal.md -Pattern "prompt-workflow-v2","PREVIS","DirectorStoryboardPrompt"`
- Expected: all markers present.
- Command: `Select-String -Path .\Project\Jinli\services\ai-video-creator\docs\prompt-spec-checklist.md -Pattern "v2 Schema","Inheritance","Review Checklist"`
- Expected: all markers present.
- Command: `git diff --name-only`
- Expected: only task packet files and allowed docs files are changed.
