# Tasks: Text-first Creator Intelligence & Preproduction Studio v3

## Dependency Graph

```text
WP01 Contracts/Registries
  -> WP02 Source Evidence
  -> WP03 Distillation/Skill Bundle
  -> WP04 Intake/Strategy
  -> WP05 Screenplay
  -> WP06 Director/Storyboard/Visual Bible
  -> WP07 Compatibility/Orchestration
  -> WP08 Documentation/Verification
```

## WP01: Contracts and registries

- [x] T1.1 Write failing contract tests.
- [x] T1.2 Create versioned research, style-pack, creative-brief and strategy schemas.
- [x] T1.3 Create independent platform and content-type registries.
- [x] T1.4 Add schema and registry validation CLI.
- [x] T1.5 Verify AC01-AC02 contract behavior.

## WP02: Source acquisition and evidence

- [x] T2.1 Write failing adapter and partial-access tests.
- [x] T2.2 Implement provider-neutral source adapter protocol.
- [x] T2.3 Implement deterministic manual/fixture adapter.
- [x] T2.4 Implement Bilibili public-metadata adapter with explicit failure states.
- [x] T2.5 Implement creator-relative performance normalization and sample selection.
- [x] T2.6 Verify AC03-AC05.

## WP03: Distillation and controlled Skill publishing

- [x] T3.1 Write failing mechanism, confidence and copyright-safety tests.
- [x] T3.2 Implement multi-work creator mechanism distillation.
- [x] T3.3 Implement provenance, freshness and confidence.
- [x] T3.4 Implement trend/meme digest provider boundary and scoring.
- [x] T3.5 Implement inactive Skill-bundle writer and validator.
- [x] T3.6 Forward-test generated bundles with pressure scenarios.
- [x] T3.7 Verify AC06-AC08.

## WP04: Creative intake and strategy

- [x] T4.1 Write failing mandatory-intake tests.
- [x] T4.2 Implement one-question-at-a-time brief completion.
- [x] T4.3 Implement content-type/platform routing.
- [x] T4.4 Implement idea diagnosis and drop-off risk analysis.
- [x] T4.5 Implement three-route strategy generation and attention-refresh map.
- [x] T4.6 Verify AC09.

## WP05: Professional screenplay

- [x] T5.1 Write failing story-bible, beat-sheet and screenplay tests.
- [x] T5.2 Implement episode/act/sequence/scene canonical model.
- [x] T5.3 Implement objective, conflict, beats, value change, subtext, action and dialogue.
- [x] T5.4 Implement Fountain and Markdown renderers with golden tests.
- [x] T5.5 Implement legacy scene/shot compatibility view.
- [x] T5.6 Verify AC10.

## WP06: Director, storyboard, art direction and editorial

- [x] T6.1 Write failing director-treatment tests.
- [x] T6.2 Write failing storyboard timing, camera and continuity tests.
- [x] T6.3 Write failing visual-bible and editorial tests.
- [x] T6.4 Implement separate director, storyboard and art-direction passes.
- [x] T6.5 Implement editorial review and rewrite findings.
- [x] T6.6 Verify AC11-AC14.

## WP07: Compatibility and orchestration

- [x] T7.1 Write failing legacy CLI compatibility tests.
- [x] T7.2 Write failing `text_first` Orchestrator tests.
- [x] T7.3 Convert Viral Analyzer to a compatibility facade.
- [x] T7.4 Derive the four legacy injection files from the new strategy.
- [x] T7.5 Add Creator Intelligence and Preproduction phases with checkpoints.
- [x] T7.6 Preserve the standard pipeline.
- [x] T7.7 Verify AC15.

## WP08: Documentation and verification

- [x] T8.1 Update same-project architecture, implementation and testing docs.
- [x] T8.2 Update `Project/AIDramaProducer/Docs/DOCS_TREE.md`.
- [x] T8.3 Collect all required worker reports and review scope.
- [x] T8.4 Run full offline test and contract commands.
- [x] T8.5 Run documentation governance.
- [x] T8.6 Write `verification-report.md` with actual command output.
- [x] T8.7 Map all implementation results to Acceptance Criteria.
- [x] T8.8 Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T8.9 Run automated verification and record command output in `verification-report.md`.
- [x] T8.10 Map implementation result to Acceptance Criteria in `verification-report.md`.

## Final Verification

- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in `verification-report.md`.
- [x] Map implementation result to Acceptance Criteria in `verification-report.md`.
