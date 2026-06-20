# Spec: Text-first Creator Intelligence & Preproduction Studio v3

## GIVEN

- The user has a rough short-video idea.
- The current project contains Viral Analyzer, Scriptwriter and Orchestrator packages.
- The user wants platform-aware creator research, creative strengthening and professional preproduction.
- Network sources may be unavailable, rate-limited or incomplete.

## WHEN

The user starts the text-first creative workflow, optionally naming reference creators or works.

## THEN

### S01 Creative brief intake

GIVEN one or more of platform, audience, content type or duration is missing  
WHEN intake validation runs  
THEN strategy generation stops and returns one next question plus `missing_fields`.

### S02 Platform and content-type routing

GIVEN a complete brief for a 20-second Douyin comedy  
WHEN the router runs  
THEN it combines the Douyin platform profile with the comedy mechanism profile without using a generic global template.

### S03 Creator candidate research

GIVEN a content type, platform and optional reference creator  
WHEN a research plan is generated  
THEN it lists candidate creators/works, selection reasons, source adapters and required sample counts.

### S04 Partial source access

GIVEN a source cannot be fetched  
WHEN research executes  
THEN the snapshot records the source, failure and fallback options and does not fabricate transcript or metrics.

### S05 Creator profile confidence

GIVEN fewer than five usable works  
WHEN distillation runs  
THEN the style pack is low confidence and cannot be promoted as an active Skill.

### S06 Mechanism-level distillation

GIVEN sufficient creator samples  
WHEN style distillation runs  
THEN it extracts hooks, narrative, humor, performance, editing, visual, audio and series mechanisms plus `do_not_copy`, provenance and freshness.

### S07 Trend and meme fusion

GIVEN a theme and current trend candidates  
WHEN the strategist evaluates them  
THEN it scores fit, comprehension, freshness, visualizability, reversal, transformation and safety and excludes stale or unsafe candidates.

### S08 Creative strategy alternatives

GIVEN a complete brief and one or more style packs  
WHEN strategy generation runs  
THEN it returns an idea diagnosis, three distinct routes, one recommendation, attention-refresh timing and originality notes.

### S09 Professional screenplay

GIVEN an approved strategy  
WHEN the screenwriter pass runs  
THEN it creates canonical JSON and human-readable Fountain/Markdown with professional structural fields.

### S10 Director and storyboard

GIVEN a valid screenplay  
WHEN director and storyboard passes run  
THEN they create separate artifacts for dramatic intent, performance, blocking, camera, movement, timecode, continuity, audio and transitions.

### S11 Visual bible and editorial review

GIVEN screenplay, director and storyboard artifacts  
WHEN art direction and editorial review run  
THEN they produce reusable visual rules, continuity IDs and explicit pass/fail findings for platform, retention, originality, duration and feasibility.

### S12 Compatibility

GIVEN an existing Viral Analyzer or standard Orchestrator call  
WHEN the migration adapters are enabled  
THEN the old command remains executable and receives a compatible derived view without automatic network claims or media-generation changes.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Mandatory brief fields gate strategy | `pytest ai_drama_preproduction_studio/tests/test_intake.py -q` | pass |
| AC02 | Platform/type registries remain separate | `pytest ai_drama_creator_intelligence/tests/test_contracts.py -q` | pass |
| AC03 | Source provenance and access issues are explicit | `pytest ai_drama_creator_intelligence/tests/test_source_adapters.py -q` | pass |
| AC04 | Sample/confidence gate enforced | `pytest ai_drama_creator_intelligence/tests/test_distillation.py -q` | pass |
| AC05 | Relative performance normalization works | `pytest ai_drama_creator_intelligence/tests/test_sample_selector.py -q` | pass |
| AC06 | Complete style-pack contract | `pytest ai_drama_creator_intelligence/tests/test_style_pack.py -q` | pass |
| AC07 | Trend/meme freshness and safety | `pytest ai_drama_creator_intelligence/tests/test_trend_digest.py -q` | pass |
| AC08 | Inactive Skill-bundle validation | `pytest ai_drama_creator_intelligence/tests/test_skill_bundle.py -q` | pass |
| AC09 | Three strategy routes and attention map | `pytest ai_drama_preproduction_studio/tests/test_strategy.py -q` | pass |
| AC10 | Professional screenplay and renderers | `pytest ai_drama_preproduction_studio/tests/test_screenwriter.py ai_drama_preproduction_studio/tests/test_fountain_renderer.py -q` | pass |
| AC11 | Director treatment fields | `pytest ai_drama_preproduction_studio/tests/test_director_storyboard.py -q` | pass |
| AC12 | Storyboard timing/camera/continuity | `pytest ai_drama_preproduction_studio/tests/test_director_storyboard.py -q` | pass |
| AC13 | Visual bible fields and IDs | `pytest ai_drama_preproduction_studio/tests/test_visual_bible.py -q` | pass |
| AC14 | Editorial checks | `pytest ai_drama_preproduction_studio/tests/test_editorial.py -q` | pass |
| AC15 | Legacy compatibility | `pytest ai_drama_viral_analyzer/tests ai_drama_orchestrator/tests -q` | pass |
| AC16 | Full offline verification and docs | full command set in `analysis.md` | all pass |

## Quality Checklist

### Completeness
- [x] [OK] Creator research, strategy and professional preproduction are covered.
- [x] [OK] Every scenario has explicit input and output.
- [x] [OK] Acceptance criteria cover all scenarios.

### Clarity
- [x] [OK] Critical fields and confidence thresholds are explicit.
- [x] [OK] External source access is marked as fallible.
- [x] [OK] Generated Skill activation is explicitly excluded.

### Consistency
- [x] [OK] New packages preserve existing Python package conventions.
- [x] [OK] Documentation paths follow project taxonomy.
- [x] [OK] Compatibility preserves existing callers.

### Scenario Coverage
- [x] [OK] Happy paths are covered.
- [x] [OK] Low-sample and missing-field edge cases are covered.
- [x] [OK] Network/source failure paths are covered.

### Edge Case Coverage
- [x] [OK] Empty/missing values are covered.
- [x] [OK] Source timeouts and partial data are covered.
- [x] [OK] Stale trends and conflicting style packs are covered by design.
- [x] [OK] Cancellation and checkpoint behavior are owned by Orchestrator integration.

## Progress Summary

| Phase | Status | Key Decision |
|---|---|---|
| Plan | In progress | Stable intelligence Skill + style packs + controlled promotion |
| Implement | Pending | Test-first work packages |
| Review | Pending | Lead checks mature-path and copyright-safety boundaries |
| Verify | Pending | Independent evidence required |

## Non-Goals

- ComfyUI execution or media generation.
- Social-platform publishing.
- Guaranteed virality.
- Automatic Skill activation.
- Credentials, cookies or private account scraping.
- Verbatim copying of creator scripts or jokes.

