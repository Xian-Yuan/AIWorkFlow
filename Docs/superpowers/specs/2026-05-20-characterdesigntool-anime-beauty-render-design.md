# CharacterDesignTool Anime Beauty Render Design

Date: 2026-05-20
Status: Approved for planning
Project: `Project/CharacterDesignTool`
Topic: Default `anime beauty` rendering strategy for character generation

## 1. Goal

Design a stable generation strategy for CharacterDesignTool where the default visual target is `anime beauty`, while still allowing body traits such as `meaty thighs` to remain within a normal and attractive range.

This design focuses on:

- picking the correct default model direction
- defining body-language constraints that preserve beauty
- separating render precision from photorealism
- routing between anime, semi-realistic, and realistic output modes

This design does not include implementation code.

## 2. Problem Summary

The current default path uses `z-image-turbo-fp8-aio`, which is strong at realistic texture and material response but not ideal as the default model for anime-beauty characters.

Observed issue:

- when the prompt contains several soft-body terms such as `plump`, `rounded hips`, `fleshy calves`, and `slightly chubby hands and feet`, the model tends to interpret them as a full-body increase in softness or fat volume
- this pushes the result toward `thick` or `overweight-looking`, instead of the intended `beautiful anime proportions with soft thigh volume`

Root mismatch:

- target style: anime beauty
- current base model tendency: realistic body interpretation
- prompt body language: multiple additive weight-gain signals without strong beauty constraints

## 3. Core Decision

Set the default visual baseline to `anime beauty`.

This means:

- beauty and proportion are the first priority
- body softness is secondary and must never break silhouette elegance
- render precision does not automatically mean realistic anatomy or realistic fat distribution

Without an explicit user request for realism, the system should prefer:

- slimmer line design
- controlled thigh fullness
- narrower calves than thighs
- clear waist-to-hip rhythm
- stylized face and limb proportions

## 4. Recommended Strategy

### 4.1 Main Strategy

Use an `anime beauty` model as the default main model.

Keep the current `Z-Image AIO` path as:

- a backup realistic mode
- an optional refinement stage
- a user-selected route when they explicitly ask for realism

### 4.2 Supporting Strategy

Before sending prompt text to the image model, body-related wording must be normalized into constrained beauty language.

The system should treat user intent like:

- `meaty thighs`
- `soft legs`
- `cute chubby feet`

as aesthetic preferences, not literal body-mass expansion instructions.

### 4.3 Advanced Strategy

If higher-end quality is needed, split generation into two stages:

1. use anime model to lock beauty proportions
2. use a second pass for material polish, lighting polish, or detail refinement

This is an upgrade path, not the default pipeline.

## 5. Design Approaches

### Approach A: Keep current model, rewrite prompt semantics

Description:

- keep the current Z-Image workflow
- remove high-risk fatness wording
- inject stronger beauty constraints

Pros:

- minimal workflow change
- fastest validation path

Cons:

- unstable across seeds
- realistic base model still pulls body shape away from anime beauty

Use when:

- immediate low-cost testing is needed

### Approach B: Anime model by default, realistic model optional

Description:

- set anime beauty as the main route
- move realistic model to optional or fallback use

Pros:

- matches the confirmed target style
- greatly improves stability of face, limbs, and silhouette beauty
- easier to keep `meaty thighs` attractive instead of overweight

Cons:

- realistic material texture may be weaker in one-pass output

Use when:

- long-term default behavior should align with anime characters

Recommendation:

- this is the primary recommended approach

### Approach C: Two-stage generation

Description:

- first stage locks body type and beauty proportions
- second stage restores precision in cloth, material, and lighting

Pros:

- best final quality ceiling
- separates shape control from rendering polish

Cons:

- higher complexity
- more workflow management and tuning cost

Use when:

- premium mode is needed after core stability is solved

## 6. Beauty-Preserving Body Rules

The system must translate body preference language into a controlled structure.

### 6.1 Positive Constraints

Default beauty rules for lower body:

- thighs may be full, but must keep a smooth anime leg line
- calves must taper clearly from the thigh
- hips may be rounded, but pelvis width must stay controlled
- waist must remain readable
- knees and ankles must stay refined
- hands and feet may feel soft, but not swollen

### 6.2 Negative Constraints

Avoid default wording that often causes overweight output:

- `plump thighs`
- `fleshy calves`
- `rounded hips` combined with multiple other soft-body descriptors
- `slightly chubby hands and feet`
- repeated references to fullness across hips, thighs, calves, chest, hands, and feet in one prompt

### 6.3 Safe Replacement Language

Preferred body language examples:

- `soft thick thighs within elegant anime proportions`
- `rounded yet controlled thigh volume`
- `balanced hips with a slim waist`
- `gentle lower-body softness without overweight appearance`
- `smooth taper from full thighs to slender calves`
- `cute soft feet with neat shape and natural alignment`

## 7. Render Precision Rules

Render precision must be split into separate dimensions instead of being treated as realism.

### 7.1 Contour Precision

Highest priority:

- face shape
- eye placement
- limb length ratio
- thigh-to-calf transition
- ankle refinement
- overall silhouette rhythm

### 7.2 Material Precision

Second priority:

- satin
- fleece
- gauze
- pearl
- jade
- trim and embroidery separation

### 7.3 Lighting Precision

Third priority:

- controlled studio light
- readable form shading
- limited skin gloss
- material highlights without turning the image photorealistic

Rule:

- contour precision first
- material precision second
- lighting precision third

## 8. Routing Rules

### 8.1 Default Route

Use anime-beauty route when:

- user does not explicitly request realism
- user asks for cute, beautiful, elegant, idol-like, fairy-like, anime-like, or stylized presentation
- the prompt includes body traits that can easily become too heavy under realistic interpretation

### 8.2 Semi-Realistic Route

Use semi-realistic route when:

- user wants stronger material realism
- user still wants visible beauty stylization
- user asks for `between realistic and anime`

### 8.3 Realistic Route

Use realistic route only when:

- user explicitly asks for realistic skin, realistic body mass, or more真人质感
- beauty stylization is no longer the main priority

## 9. Prompt Normalization Rules

Before final prompt assembly, the system should normalize body requests into beauty-safe language.

Normalization examples:

- `meaty thighs` -> `soft thick thighs within elegant anime proportions`
- `chubby feet` -> `soft, cute feet with clean shape and natural toe alignment`
- `rounded hips` -> `balanced hips with controlled volume and a readable waist`

System rule:

- never stack more than two strong lower-body fullness descriptors in the same final prompt
- always pair fullness wording with beauty-control wording
- when the user asks for softness, add an anti-overweight guard phrase

Recommended guard phrase family:

- `avoid overweight appearance`
- `maintain elegant anime proportions`
- `keep the silhouette slim and attractive`
- `natural, controlled volume without heaviness`

## 10. Suggested Output Modes

The product should conceptually support three quality lanes:

### Lane 1: Anime Beauty Default

- default route
- stable beauty
- safest choice for attractive character generation

### Lane 2: Semi-Realistic Beauty

- optional route
- stronger materials and lighting
- still keeps stylized proportions

### Lane 3: Realistic Detail

- optional route
- for users who explicitly want realism
- not recommended as the default for this product goal

## 11. Risks

- keeping realistic model as default will continue to make `meaty thighs` unstable
- using `render precision` as a synonym for `realism` will keep dragging the system away from anime beauty
- if body descriptors are not normalized, prompt quality improvements alone will not solve the silhouette problem
- if multiple body areas are softened at once, even an anime model can drift toward heavy output

## 12. Success Criteria

The design is successful when:

- anime-beauty characters are the default result without needing manual prompt rescue
- `meaty thighs` reads as attractive softness instead of overweight mass
- thighs remain fuller than calves, while the leg line stays smooth
- face, hands, ankles, and feet remain refined
- users can still request semi-realistic or realistic rendering intentionally

## 13. Recommendation Summary

Adopt `Approach B` as the default product direction:

- anime-beauty model as the default main route
- realistic route kept as optional
- body wording normalized into beauty-safe language
- two-stage refinement kept as a future high-end upgrade
