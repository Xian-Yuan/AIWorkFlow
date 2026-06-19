# CharacterDesignTool Prompt Workflow V2 Design

Date: 2026-05-20
Status: Draft approved for review
Project: `Project/CharacterDesignTool`
Topic: Prompt workflow redesign for preserving character design information while generating model-ready prompts

## 1. Goal

Redesign the prompt workflow in `CharacterDesignTool` so the system can:

- preserve the full design information gathered from the user-AI conversation
- avoid losing key constraints during prompt generation
- transform the preserved design information into model-appropriate prompts for `Z-Image`, `sd15_anime`, and future workflows
- make the generation process auditable, inspectable, and iteratable

This design does not implement code. It defines the target workflow, data layers, UI behavior, and AI call sequence.

## 2. Problem Statement

The current workflow effectively does this:

1. collect user answers into `_collectedTraits`
2. ask AI to summarize traits into one natural-language prompt
3. sanitize and truncate the prompt
4. send the final prompt to the selected image workflow

This has four major weaknesses:

- the complete character card and the final render prompt are treated as if they were the same thing
- high-value structural constraints are not explicitly separated from decorative or explanatory information
- Chinese design descriptions are vulnerable to later cleanup stages that remove non-English text
- prompt generation, model adaptation, and quality review happen in one mixed step

As a result, the tool can keep the conversation history while still losing important design intent before generation.

## 3. Design Principles

The new workflow follows these principles:

- **Full preservation first**: the original design information must remain intact
- **Late compression, not early compression**: compression should happen only when preparing the final model prompt
- **Constraint priority over prose quality**: if information must be shortened, keep the hard constraints first
- **Model-aware prompting**: different workflows need different prompt styles
- **Inspectable intermediate layers**: the user and the system should be able to see what was preserved, transformed, and omitted
- **One image, one plan**: the final render prompt must describe the current image task, not the entire lore document

## 4. Recommended Architecture

### 4.1 Summary

Replace the current one-step prompt generation with a six-layer workflow:

1. Character Card
2. Must-Keep Constraints
3. Visual Plan
4. Model Adapter
5. Render Prompt
6. Prompt Review

The final render prompt becomes the result of this pipeline, not the direct summary of the raw conversation.

### 4.2 Why this is the recommended approach

This structure solves the core issue without trying to make the model directly understand a giant design brief. It also matches the likely product behavior of stronger generation systems: preserve context, plan the image, adapt to the model, and validate before rendering.

## 5. Workflow Layers

### 5.1 Layer 0: Character Card

**Purpose**

Store the full design information gathered from dialogue, including long-form descriptions and nuanced design reasoning.

**Characteristics**

- complete
- not optimized for image generation
- may remain in Chinese
- may include explanation, symbolism, and reasoning

**Examples of content**

- body requirements
- costume structure
- weapon details
- cybernetic rules
- design element carriers
- supplementary notes

**Output type**

Structured JSON plus a user-readable card view.

### 5.2 Layer 1: Must-Keep Constraints

**Purpose**

Extract the constraints that must survive every transformation step.

**Examples**

- full bare legs with no hard occlusion
- one hand may be a bionic prosthetic, but no exposed external interface
- short upper garment + high waist + high-slit overskirt with under-shorts
- blue-silver palette
- princess-cut hairstyle
- cyberpunk anime-semi-realistic rendering

**Rules**

- short, explicit, non-decorative
- no design explanation
- written in machine-friendly form
- each constraint should be atomic

**Output type**

Ordered constraint list with priority levels.

### 5.3 Layer 2: Visual Plan

**Purpose**

Convert the character card and hard constraints into an image-focused plan before writing the final prompt.

**Questions this layer answers**

- what is the primary subject in this image
- which silhouette cues matter most
- which costume structures must be visible
- which details are secondary
- what pose and framing best expose the requested design
- what rendering style should dominate the image

**Important rule**

The visual plan is still not the final prompt. It is a planning artifact for the next stage.

**Output type**

A structured plan document plus a human-readable summary.

### 5.4 Layer 3: Model Adapter

**Purpose**

Translate the visual plan into the writing style required by the selected image workflow.

**Route-specific behavior**

- `sd15_anime`
  - emphasize silhouette, anime beauty, readable shape language, controlled line rhythm
  - simplify over-dense material language
- `zimage_showcase`
  - emphasize natural English, material readability, pose, lighting, subject clarity
  - reduce design-spec prose and use renderable descriptions
- `zimage_img2img`
  - focus on delta changes from the current reference
  - do not restate the whole character unless necessary

**Output type**

Model-adapted prompt instructions.

### 5.5 Layer 4: Render Prompt

**Purpose**

Produce the final prompt actually sent to the image model.

**Required structure**

1. Identity
2. Body and silhouette
3. Outfit structure
4. Cybernetic and weapon details
5. Material and color
6. Pose and framing
7. Lighting and rendering style

**Rules**

- describe one image only
- prioritize visible structure over lore
- avoid internal contradictions
- keep high-priority constraints early
- remain natural and model-friendly

### 5.6 Layer 5: Prompt Review

**Purpose**

Check the generated prompt before rendering.

**Review questions**

- did the prompt preserve all must-keep constraints
- did it lose any structural requirement
- did it introduce style conflict
- did it become too verbose or too vague
- did it accidentally include non-renderable explanation

**Behavior**

- if review passes: allow generation
- if review fails: trigger one rewrite attempt
- if still failing: show the issue list to the user

## 6. Proposed UI Flow

### 6.1 Existing User Experience Problem

At the moment the user mainly sees:

- role card summary
- generate prompt
- generated prompt
- generate image

This makes prompt generation feel like a black box.

### 6.2 New UI Flow

Add a small staged prompt workflow panel before image generation.

**Recommended sequence**

1. `角色卡`
2. `硬约束`
3. `画面规划`
4. `最终提示词`
5. `审查结果`

### 6.3 Minimal UI Surface

For the first version, only expose the following:

- `角色卡` tab: read-only summary
- `硬约束` tab: atomic must-keep list
- `最终提示词` tab: editable render prompt
- `审查结果` line: pass/fail with missing-constraint list

### 6.4 Advanced UI Surface

Later versions can expose:

- `画面规划` tab
- candidate prompt comparison
- route switch comparison between `sd15_anime` and `zimage_showcase`
- result scoring for previously used prompts

## 7. Proposed Data Structure

The project should stop storing only one cached prompt string as the main artifact.

### 7.1 New Prompt Bundle Shape

```json
{
  "characterCard": {
    "traits": {},
    "extraNotes": "",
    "rawSummary": ""
  },
  "mustKeepConstraints": [
    {
      "id": "full_bare_legs",
      "priority": "critical",
      "text": "Full bare legs remain visible with no hard occlusion."
    }
  ],
  "visualPlan": {
    "subject": "",
    "silhouette": [],
    "outfitVisibility": [],
    "secondaryDetails": [],
    "pose": "",
    "framing": "",
    "renderingDirection": ""
  },
  "renderPrompts": {
    "sd15_anime": "",
    "zimage_showcase": "",
    "zimage_img2img": ""
  },
  "review": {
    "status": "pass",
    "missingConstraints": [],
    "conflicts": [],
    "notes": []
  }
}
```

### 7.2 Persistence Rules

- save all layers into project storage
- keep the latest successful prompt per workflow
- keep the review result that approved that prompt
- keep room for prompt history later, but do not require it in version one

## 8. AI Call Sequence

### 8.1 Current Sequence

```text
traits -> one LLM call -> final prompt -> sanitize -> render
```

### 8.2 New Sequence

```text
traits + notes
  -> AI call A: extract must-keep constraints
  -> AI call B: build visual plan
  -> AI call C: adapt plan to active workflow
  -> AI call D: review final prompt
  -> sanitize only as final safety layer
  -> render
```

### 8.3 AI Call Responsibilities

**AI Call A: Constraint Extractor**

Input:

- full trait set
- user supplementary notes
- workflow-independent context

Output:

- atomic must-keep constraints with priority

**AI Call B: Visual Planner**

Input:

- full character card
- must-keep constraints

Output:

- visual plan for one target image

**AI Call C: Prompt Writer**

Input:

- visual plan
- must-keep constraints
- target workflow id

Output:

- model-ready render prompt

**AI Call D: Prompt Reviewer**

Input:

- render prompt
- must-keep constraints
- target workflow id

Output:

- pass/fail
- missing constraint list
- rewrite recommendation

## 9. Input and Output Contracts

### 9.1 Constraint Extractor Contract

**Input**

```json
{
  "traits": {},
  "extraNotes": "",
  "designFlow": [],
  "language": "zh-CN"
}
```

**Output**

```json
{
  "constraints": [
    {
      "priority": "critical",
      "category": "outfit",
      "text": "High-slit overskirt with under-shorts must remain readable."
    }
  ]
}
```

### 9.2 Visual Planner Contract

**Input**

```json
{
  "characterCard": {},
  "constraints": []
}
```

**Output**

```json
{
  "subject": "single full body female cybernetic assassin",
  "silhouette": [
    "eastern soft hourglass figure",
    "bare full legs",
    "short upper garment with high waist"
  ],
  "focusZones": [
    "legs",
    "waist structure",
    "prosthetic hand",
    "sleeve blade"
  ],
  "pose": "balanced standing pose with readable lower-body exposure",
  "framing": "full body shot visible from head to toe",
  "renderingDirection": "anime-leaning semi-realistic cyberpunk illustration"
}
```

### 9.3 Prompt Writer Contract

**Input**

```json
{
  "workflowId": "zimage_showcase",
  "visualPlan": {},
  "constraints": []
}
```

**Output**

```json
{
  "prompt": "..."
}
```

### 9.4 Prompt Reviewer Contract

**Input**

```json
{
  "workflowId": "zimage_showcase",
  "prompt": "...",
  "constraints": []
}
```

**Output**

```json
{
  "status": "pass",
  "missingConstraints": [],
  "conflicts": [],
  "notes": []
}
```

## 10. Length Strategy

### 10.1 Core Rule

Do not push the full character card directly into the image model.

### 10.2 Suggested Length Budget

- Character Card: unlimited for storage
- Must-Keep Constraints: short atomic list
- Visual Plan: moderate length, AI-facing only
- Render Prompt: target `180-260` English words for `Z-Image`
- Practical upper zone: avoid exceeding `300` English words unless explicitly justified

### 10.3 Why this strategy

Long prompts are not free. Even if an API accepts more characters, model-side token limits, weighting bias toward early content, and internal rewrite behavior mean very long prompts often reduce reliability instead of improving it.

## 11. How This Learns From Stronger Products

This design does not assume access to proprietary systems like `Holopix` or `Image2`. Instead it adopts the workflow lessons that likely make them strong:

- preserve context upstream
- perform task decomposition before rendering
- separate planning from prompt writing
- allow model-specific adaptation
- review prompt quality before generation
- treat the final prompt as an execution artifact, not as the raw truth source

## 12. Rollout Plan

### Phase 1

- add `mustKeepConstraints`
- add route-aware final prompt generation
- add review result display

### Phase 2

- add `visualPlan`
- expose prompt review issues in UI
- save per-workflow prompt history

### Phase 3

- add multiple prompt candidates
- add automatic candidate scoring
- add edit/refinement workflow for `img2img`

## 13. Success Criteria

This design is successful when:

- full character information remains preserved in project storage
- final prompts consistently keep the hard constraints
- prompt quality remains model-appropriate instead of design-document-like
- switching workflows changes the writing style without losing the design core
- users can inspect what information was kept, transformed, or dropped

## 14. Risks

- more AI stages increase latency
- exposing too many intermediate layers can overwhelm users if UI is not carefully staged
- poor constraint extraction would poison later stages
- over-aggressive review could make prompt generation feel rigid or repetitive

## 15. Recommendation

Adopt this workflow incrementally:

- first separate `characterCard`, `mustKeepConstraints`, and `renderPrompt`
- then add `visualPlan`
- finally add prompt review and candidate comparison

This keeps the implementation manageable while solving the core problem early: preserving design information without directly dumping the full role card into the rendering model.
