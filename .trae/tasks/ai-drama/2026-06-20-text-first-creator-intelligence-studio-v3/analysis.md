# Analysis: Text-first Creator Intelligence & Preproduction Studio v3

## Architecture Context

### System boundaries

- `ai_drama_creator_intelligence` owns creator discovery, source evidence, performance normalization, mechanism distillation, trend/meme digests, style packs and inactive Skill bundles.
- `ai_drama_preproduction_studio` owns mandatory creative intake, idea diagnosis, content-type strategy, screenplay, director treatment, storyboard, visual bible and editorial review.
- `ai_drama_viral_analyzer` becomes a compatibility facade and does not remain the architectural source of truth.
- Existing TTS, asset, keyframe, video and compositor packages remain downstream and unchanged in this text-first task.

### Dependency map

```text
platform/content-type registries
        -> source adapters
        -> research snapshot
        -> sample selector and performance normalizer
        -> mechanism distiller
        -> creator style pack / trend digest
        -> creative brief and strategy
        -> screenplay
        -> director treatment
        -> storyboard and visual bible
        -> editorial report
        -> legacy compatibility views
        -> existing media pipeline
```

### Data and state ownership

- Research evidence owns immutable source URLs, retrieval timestamps and public metadata.
- Creator style packs own reusable mechanisms, confidence and prohibited-copy rules.
- Creative briefs own user decisions about platform, audience, type, duration, theme and boundaries.
- Each professional pass owns a separate artifact; downstream passes reference upstream hashes.
- Generated Skill bundles are inactive files and cannot mutate the discovered Skill registry automatically.
- Pipeline state remains owned by Orchestrator.

### Integration points

- Existing Viral Analyzer CLI commands forward through a compatibility adapter.
- Existing Scriptwriter injection files are derived from `creative_strategy.json`.
- Orchestrator adds a `text_first` variant while preserving `standard`.
- Later ComfyUI/remote backends consume visual-bible and storyboard contracts without being implemented here.

## Current-State Findings

- Viral Analyzer has useful concepts but remains in Implement with failed Verify.
- Its channel scanner currently returns empty videos and therefore cannot prove real creator profiling.
- Generic structure blueprints and injection values are partly hard-coded.
- Scriptwriter accepts style injection but does not conduct mandatory platform/audience/type intake.
- Screenwriter, director, storyboard artist and art director responsibilities are not separate professional passes.
- Current style presets are prompt keywords, not a production visual bible.

## Mature Solution Evidence

### Project-local evidence

- `ai_drama_viral_analyzer` already defines video, channel, creator and injection concepts worth preserving behind a compatibility boundary.
- `ai_drama_scriptwriter` already has structured generation, validators and legacy downstream fields.
- `ai_drama_orchestrator` already provides phase handlers and checkpoint state.
- The 2026-06-18 Viral Analysis research identifies anomaly selection, progressive disclosure and structure mirroring as preferred patterns.
- Verification reports prove that real URL/channel analysis is not yet accepted and must not be represented as complete.

### Official/framework evidence

- Platform endpoints and yt-dlp-style adapters are unstable, so source access must be provider-neutral and failure-explicit.
- Python package, argparse and JSON Schema boundaries match the existing project.
- Skills require concise stable instructions and progressive disclosure; creator-specific detail belongs in references/artifacts rather than copied into every active Skill.
- Test-driven development is required for new behavior and Skill changes.

### External mature references

- FilmAgent supports role-separated creative collaboration rather than one prompt performing every film role.
- Professional screenplay conventions separate scene headings, action and dialogue.
- Professional storyboard practice separates composition, camera angle, movement and director intent.
- Short-video retention tools emphasize time-based audience behavior rather than view count alone.

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Patch current Viral Analyzer prompts | Small diff | Keeps hard-coded generic logic and mixed responsibilities | Rejected |
| Auto-create and activate one Skill per creator | Easy discovery | Skill sprawl, stale data, prompt conflicts, weak provenance | Rejected |
| Stable intelligence Skill + versioned style packs + controlled Skill promotion + separate studio | Clear ownership, reusable evidence, safer migration, supports many types | More contracts and tests | Selected |

### Rejected shortcuts

- Do not call raw views “viral proof”.
- Do not profile a creator from one video.
- Do not silently invent inaccessible metadata or transcripts.
- Do not hard-code a 45-second Hook/Problem/Solution/CTA structure for every genre.
- Do not copy full jokes, scripts or signature wording.
- Do not auto-install generated Skill bundles.
- Do not collapse screenwriter, director, storyboard and art direction into one LLM call.
- Do not mark network/provider behavior accepted using fixtures alone.

### Selected mature path

Build a provider-neutral evidence pipeline with creator-relative sampling, versioned style packs and confidence. Route the approved strategy into separate professional preproduction passes. Preserve old interfaces through a compatibility facade and verify offline contracts independently from optional network tests.

## Acceptance Criteria

- AC01: Creative intake blocks strategy generation until platform, audience, content type and duration are resolved.
- AC02: Platform and content type use separate registries and route to distinct strategy rules.
- AC03: Creator research emits source URLs, retrieval timestamps, availability and access issues without fabrication.
- AC04: Creator profiling uses at least five works; fewer samples produce low confidence and block active Skill promotion.
- AC05: Performance selection uses creator-relative normalized metrics when metrics exist and records unavailable metrics otherwise.
- AC06: Style packs contain mechanisms, confidence, provenance, freshness and `do_not_copy`.
- AC07: Trend/meme research is provider-neutral, freshness-aware and stores concepts/links rather than copied compilations.
- AC08: Generated creator Skill bundles are inactive, validate successfully and require explicit promotion.
- AC09: Creative strategy produces idea diagnosis, three distinct routes, a recommendation and an attention-refresh map.
- AC10: Screenwriter emits canonical JSON plus Fountain/Markdown with episode, act, sequence, scene heading, objective, conflict, beats, action and dialogue.
- AC11: Director emits dramatic intent, performance, blocking, rhythm, reveal, sound and edit guidance.
- AC12: Storyboard emits timecodes, shot size, angle, lens intent, camera/subject movement, screen direction, eyeline, transition and audio cues.
- AC13: Visual bible emits character, palette, lighting, material, environment, costume, prop, camera and forbidden-element rules with continuity IDs.
- AC14: Editorial review checks platform fit, retention, genre mechanism, originality, theme, duration, continuity and feasibility.
- AC15: Legacy Viral Analyzer and standard Orchestrator paths remain functional through compatibility tests.
- AC16: Offline tests, documentation governance and final task verification pass with actual command evidence.

## Automated Verification Plan

- Command: `python -m pytest ai_drama_creator_intelligence/tests ai_drama_preproduction_studio/tests -q`
  - Expected: all new unit, contract, golden and pressure tests pass.
- Command: `python -m pytest ai_drama_viral_analyzer/tests ai_drama_scriptwriter/tests ai_drama_orchestrator/tests -q`
  - Expected: compatibility and existing integration suites pass.
- Command: `python -m ai_drama_creator_intelligence validate-style-pack tests/fixtures/style_pack_valid.json`
  - Expected: exit 0 and `valid=true`.
- Command: `python -m ai_drama_preproduction_studio validate tests/fixtures/preproduction_output`
  - Expected: exit 0 and every required artifact validates.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3 -Stage implement`
  - Expected: documentation governance passes.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3 verify`
  - Expected: Verify passes only after all tasks, reports and evidence are complete.

## Residual Risks

- Platform anti-scraping behavior may require manual import or official APIs.
- Public metrics vary across platforms and may not support identical normalization.
- Trend relevance decays rapidly and must never become permanent creator identity.
- LLM quality varies; contract and editorial checks reduce but do not remove creative judgment risk.

