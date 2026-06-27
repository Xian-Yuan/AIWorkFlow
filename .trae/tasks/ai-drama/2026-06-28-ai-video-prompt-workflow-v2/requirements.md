# Requirement Understanding: AI Video Prompt Workflow v2

## Desired Outcome

Create and land a reusable "AI short-drama prompt workflow v2" that fixes the current prompt-template gap: role, scene, prop, director storyboard, video generation, negative prompts, platform constraints, and review rules must become separate but connected template contracts.

## Underlying Problem

The current workflow can produce useful prompts, but it still mixes several layers together. This makes it easy for generated storyboards or video prompts to drift: characters change, props move to the wrong owner, effects appear in the wrong place, scenes become inconsistent, and the same constraints are repeated or lost between stages.

## Intended User and Context

Ba Ba uses the AI video creator workflow to build short-drama prompts from reference images and story requirements. The workflow must help future projects, not only the "snow temple fight" example, and must be clear enough for another model or stage generator to follow without guessing.

## End-to-End Experience

1. The user defines project context, reference images, role/scene/prop requirements, and target video platform.
2. The workflow generates locked character, scene, and prop prompts with their own negative constraints.
3. The director storyboard template generates PREVIS-style storyboard panels and merges the old "storyboard" and "director storyboard" concepts into one layer.
4. The video generation template inherits the storyboard and asset constraints, then renders platform-specific prompts with audio, camera, motion, continuity, and negative prompt rules.
5. A review checklist catches fight logic, asset ownership, special effects placement, scene continuity, platform limits, and prompt-schema omissions before output is considered ready.

## Confirmed Decisions

- The official workflow must not compress shots by default.
- "Director storyboard" and "storyboard" are the same layer in v2.
- The workflow is generic, not only for the snow-temple project.
- Negative prompts and hard constraints belong in the relevant template layer, then merge downward.
- The video generation template must be more detailed than the storyboard template and include platform adapter fields.
- The PREVIS storyboard instruction must be integrated into the storyboard template: 16:9 storyboard sheet, 12 cinematic panels by default, black-and-white rough pencil artwork, colored annotation system.
- The v2 Schema and inheritance rules must be fixed before editing project files.

## Implicit Requirements

| Requirement inferred by the planner | Status | Reason |
|---|---|---|
| Keep field names stable and machine-readable | Confirmed | Future generators and reviewers need deterministic fields. |
| Separate identity constraints from motion instructions | Confirmed | Prevents video prompts from rewriting characters during action. |
| Add conflict resolution for inherited constraints | Confirmed | Prevents lower layers from overriding hard locks. |
| Include review/linter criteria | Confirmed | Ba Ba explicitly asked to review fight logic, effects, and consistency. |
| Modify runtime Python stages in this task | Deferred | First landing should stabilize docs/templates; code integration can follow after the contract is accepted. |

## Boundaries and Non-Goals

- Do not build a new UI in this task.
- Do not change video provider APIs in this task.
- Do not rewrite the Python generation stages yet.
- Do not create prompts for only one story; examples may be generic, but the workflow must be reusable.
- Do not weaken the project workflow gates.

## Success Experience

The result should feel like a professional prompt-production bible: Ba Ba can hand it to an AI model and reliably get consistent characters, scenes, props, director storyboards, video prompts, negative prompts, and a strict review pass/fail process.

## Open Questions

None.

## Teach-Back Summary

We are landing v2 as a durable workflow/template contract. It defines required Schema for project context, characters, scenes, props, director storyboard panels, video generation prompts, negative prompt layers, platform adapters, and review checks. It keeps PREVIS storyboard inside the storyboard template, uses inheritance to prevent drift, and leaves runtime code changes for a later task after the documentation contract is stable.

## User Confirmation Evidence

- User requested: "下一步直接写一份 《AI短剧提示词工作流 v2 设计稿》，先把 Schema 和继承规则定死，然后再改文件"
- After the design draft, user confirmed: "继续落地小璃"
