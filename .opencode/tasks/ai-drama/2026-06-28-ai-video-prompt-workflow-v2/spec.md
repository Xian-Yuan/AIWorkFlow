# Living Spec

## Scenario: V2 workflow contract is available

## GIVEN
- The AI video creator docs contain v1 prompt template and v2-draft checklist files.
- Ba Ba has confirmed the v2 Schema and inheritance direction.

## WHEN
- The task lands the v2 prompt workflow documentation.

## THEN
- A canonical v2 contract document defines all prompt-layer schemas.
- Existing template/checklist docs point to the v2 contract.
- Future story prompts can inherit character, scene, prop, storyboard, and video constraints without guessing.

## Scenario: Director storyboard includes PREVIS rules

## GIVEN
- The workflow needs a storyboard layer for professional shot planning.

## WHEN
- A prompt author uses `DirectorStoryboardPrompt`.

## THEN
- PREVIS and storyboard are treated as one layer.
- The storyboard supports 16:9 panels, black-and-white rough pencil drawing, and colored annotation conventions.
- The storyboard records camera, action, composition, lighting, emotion, labels, and continuity anchors.

## Scenario: Video prompts inherit without drift

## GIVEN
- Character, scene, prop, and storyboard constraints exist.

## WHEN
- A `VideoGenerationPrompt` is authored for a shot.

## THEN
- It inherits identity, scene, prop ownership, first/end frames, action beats, and continuity anchors.
- It may adapt language and provider parameters but must not override upstream hard constraints.

## Progress Summary

- Plan: complete.
- Implement: complete.
- Review: pending.
- Verify: pending.

## Decisions

- Documentation/templates first; runtime stage code is deferred.
- No shot compression by default.
- Negative prompts are layered by ownership and merged downward.

## Verification State

- Automated verification evidence recorded in `verification-report.md`.
