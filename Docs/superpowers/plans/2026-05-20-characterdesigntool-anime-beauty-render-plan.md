# CharacterDesignTool Anime Beauty Render Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `anime beauty` the default generation direction for `CharacterDesignTool`, keep realistic rendering optional, and normalize `meaty thighs`-style body requests into beauty-safe prompt language.

**Architecture:** Reuse the existing image-generation pipeline instead of adding a new subsystem. Switch the default workflow selection to the existing anime-capable route, add a style-routing layer in prompt generation, and centralize body-language normalization inside `prompt-composer.js` so both LLM prompts and fallback prompts share the same safety rules.

**Tech Stack:** Browser-side JavaScript, Node.js bridge server, ComfyUI workflow metadata, Markdown specs/plans

---

## File Structure

- Modify: `Project/CharacterDesignTool/comfyui-workflows.js`
  - Change the default workflow and clarify which routes are anime-first versus realistic fallback.
- Modify: `Project/CharacterDesignTool/comfyui-bridge.js`
  - Keep runtime metadata aligned with `comfyui-workflows.js` so backend template defaults match frontend routing.
- Modify: `Project/CharacterDesignTool/prompt-composer.js`
  - Add centralized beauty-safe normalization helpers for lower-body wording and render-style routing.
- Modify: `Project/CharacterDesignTool/interview-engine.js`
  - Replace the Z-Image-only system prompt with style-aware prompt generation and route the recommended prompt label based on the selected workflow.
- Verify: `Project/CharacterDesignTool/workflows/sd15-anime-api.json`
  - Confirm the existing anime workflow stays usable as the default route without JSON changes.
- Verify: `Project/CharacterDesignTool/workflows/zimage-showcase-api.json`
  - Confirm the realistic fallback route still works after metadata updates.

## Task 1: Make Anime Workflow The Default Route

**Files:**
- Modify: `Project/CharacterDesignTool/comfyui-workflows.js`
- Modify: `Project/CharacterDesignTool/comfyui-bridge.js`

- [ ] **Step 1: Inspect the current default workflow references**

```javascript
// comfyui-workflows.js
window.COMFYUI_DEFAULT_WORKFLOW = "zimage_showcase";

// comfyui-bridge.js
const TEMPLATE_REGISTRY = {
  zimage_showcase: {
    defaultModel: "zimage"
  },
  sd15_anime: {
    defaultModel: "sd15"
  }
};
```

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js"
```

Expected:

- both files pass syntax check before edits

- [ ] **Step 2: Change frontend workflow metadata to default to anime beauty**

```javascript
// comfyui-workflows.js
  zimage_showcase: {
    id: "zimage_showcase",
    name: "Z-Image 写实角色",
    desc: "写实备用路线，适合明确要求真实材质和更强照片感的角色",
    width: 960,
    height: 1280,
    steps: 8,
    cfg: 1.0,
    model: "zimage",
    family: "zimage",
    workflowFile: "zimage-showcase-api.json",
    promptPrefix: "",
    negativePrompt: "",
    smokeTest: false,
    experimental: false
  },
  sd15_anime: {
    id: "sd15_anime",
    name: "二次元美型角色（默认）",
    desc: "默认主路线，优先保证美型比例、脸型和腿部线条",
    width: 768,
    height: 1024,
    steps: 24,
    cfg: 7,
    model: "sd15",
    family: "sd15",
    workflowFile: "sd15-anime-api.json",
    promptPrefix: "anime beauty style, elegant character proportions, attractive silhouette, refined hands and feet, full body character illustration",
    negativePrompt: "worst quality, low quality, blurry, noisy, bad anatomy, overweight body, swollen calves, thick ankles, extra limbs, text, watermark, cropped",
    smokeTest: false,
    experimental: false
  }

window.COMFYUI_DEFAULT_WORKFLOW = "sd15_anime";
```

- [ ] **Step 3: Mirror the same route intent in backend template metadata**

```javascript
// comfyui-bridge.js
  zimage_showcase: {
    id: "zimage_showcase",
    file: "zimage-showcase-api.json",
    defaultModel: "zimage",
    family: "zimage",
    smokeTest: false,
    experimental: false,
    promptPrefix: "",
    negativePrompt: "",
    width: 960,
    height: 1280,
    steps: 8,
    cfg: 1.0,
    injection: {
      checkpointNodeId: "1",
      positiveNodeId: "2",
      negativeNodeId: "3",
      latentNodeId: "4",
      samplerNodeId: "5",
      saveNodeId: "7",
      vaeLoaderNodeId: ""
    }
  },
  sd15_anime: {
    id: "sd15_anime",
    file: "sd15-anime-api.json",
    defaultModel: "sd15",
    family: "sd15",
    smokeTest: false,
    experimental: false,
    promptPrefix: "anime beauty style, elegant character proportions, attractive silhouette, refined hands and feet, full body character illustration",
    negativePrompt: "worst quality, low quality, blurry, noisy, bad anatomy, overweight body, swollen calves, thick ankles, extra limbs, text, watermark, cropped",
    width: 768,
    height: 1024,
    steps: 24,
    cfg: 7,
    injection: {
      checkpointNodeId: "4",
      latentNodeId: "5",
      positiveNodeId: "6",
      negativeNodeId: "7",
      samplerNodeId: "3",
      saveNodeId: "9",
      vaeLoaderNodeId: ""
    }
  }
```

- [ ] **Step 4: Re-run syntax validation**

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js"
```

Expected:

- both commands exit with code `0`

- [ ] **Step 5: Commit the metadata route switch**

```bash
git add Project/CharacterDesignTool/comfyui-workflows.js Project/CharacterDesignTool/comfyui-bridge.js
git commit -m "feat: make anime route the default character generator"
```

## Task 2: Centralize Beauty-Safe Body Normalization

**Files:**
- Modify: `Project/CharacterDesignTool/prompt-composer.js`

- [ ] **Step 1: Add explicit render-route and body-normalization helpers near the prompt utilities**

```javascript
var BEAUTY_ROUTE_META = {
  sd15_anime: {
    id: "sd15_anime",
    style: "anime_beauty",
    displayName: "二次元美型"
  },
  zimage_showcase: {
    id: "zimage_showcase",
    style: "realistic",
    displayName: "写实"
  },
  zimage_img2img: {
    id: "zimage_img2img",
    style: "realistic",
    displayName: "写实细化"
  }
};

function getRenderRouteMeta(workflowId){
  return BEAUTY_ROUTE_META[workflowId] || {
    id: workflowId || "sd15_anime",
    style: "anime_beauty",
    displayName: "二次元美型"
  };
}
```

- [ ] **Step 2: Replace the XP lower-body wording map with beauty-safe anime defaults**

```javascript
var XP_NOTE_MAP = {
  "肉腿": {
    anime_beauty: "Thighs should look softly full with elegant anime proportions, smooth leg lines, and a clear taper into slender calves. Avoid overweight appearance, swollen joints, or excessive thickness.",
    realistic: "Thighs should appear softly full and proportionate, with controlled volume and natural taper into the calves. Avoid overweight appearance or exaggerated heaviness."
  },
  "裸足": {
    anime_beauty: "Feet are bare and visible, with refined ankles, neat toe alignment, and a soft but attractive anime shape.",
    realistic: "Feet are bare and visible, with clean skin, natural toe alignment, and slender ankles."
  },
  "光腿": {
    anime_beauty: "Legs are bare from mid-thigh to ankle, with smooth skin shading and a graceful anime contour from thigh to calf.",
    realistic: "Legs are bare from mid-thigh to ankle, with smooth skin, natural highlights, and balanced calf-to-thigh proportion."
  },
  "绝对领域": {
    anime_beauty: "A short skirt reveals the upper thigh, while thigh-high socks frame the leg line without making the thighs look heavy.",
    realistic: "A short skirt reveals the upper thigh, while thigh-high socks create a clean exposed skin band and balanced leg proportions."
  }
};
```

- [ ] **Step 3: Introduce a reusable lower-body guard helper and use it in `buildTraitsForLLM()`**

```javascript
function buildLowerBodyGuard(style){
  if (style === "realistic"){
    return "Maintain balanced lower-body proportions, avoid overweight appearance, and keep ankles and calves clearly defined.";
  }
  return "Maintain elegant anime proportions, keep the silhouette slim and attractive, and avoid swollen calves, thick ankles, or overweight appearance.";
}

function getXpNote(value, workflowId){
  var route = getRenderRouteMeta(workflowId);
  var entry = XP_NOTE_MAP[value];
  if (entry && typeof entry === "object"){
    return entry[route.style] || entry.anime_beauty || entry.realistic || "";
  }
  return "Describe body preferences with controlled, attractive proportions and no exaggerated heaviness.";
}

function buildTraitsForLLM(collectedTraits, designFlow, workflowId){
  var flow = designFlow || (window.DESIGN_FLOW || []);
  var route = getRenderRouteMeta(workflowId);
  var lines = [
    "Render Route: " + route.displayName,
    "Style Direction: " + route.style,
    "Body Guard: " + buildLowerBodyGuard(route.style)
  ];

  flow.forEach(function(step){
    var value = (collectedTraits && collectedTraits[step.id]) ? collectedTraits[step.id] : "";
    if (!value || value === "你帮我选" || value === "你帮我决定" || value === "无特殊偏好") return;

    if (step.id === "xp"){
      lines.push("XP Body Constraint (HIGHEST PRIORITY): " + getXpNote(value, workflowId));
      return;
    }

    // Keep the existing per-field mapping logic after this branch.
  });

  return lines.join("\n");
}
```

- [ ] **Step 4: Normalize fallback narrative output away from design-sheet wording**

```javascript
function composeNaturalNarrative(ctx, translations, workflowId){
  var route = getRenderRouteMeta(workflowId);
  var narrative = [];
  narrative.push("Create a single full body character illustration with the entire figure visible from head to toe.");
  if (route.style === "anime_beauty"){
    narrative.push("Favor elegant anime beauty, attractive line design, refined limbs, and controlled lower-body softness.");
  } else {
    narrative.push("Favor realistic materials and natural proportions while keeping the silhouette controlled and attractive.");
  }

  // Keep the existing subject/job/design-style assembly here.

  narrative.push(buildLowerBodyGuard(route.style));
  return narrative;
}
```

- [ ] **Step 5: Expose the new helpers to `window` and verify syntax**

```javascript
window.BEAUTY_ROUTE_META = BEAUTY_ROUTE_META;
window.getRenderRouteMeta = getRenderRouteMeta;
window.buildLowerBodyGuard = buildLowerBodyGuard;
window.getXpNote = getXpNote;
window.buildTraitsForLLM = buildTraitsForLLM;
```

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\prompt-composer.js"
```

Expected:

- syntax check passes

- [ ] **Step 6: Commit the prompt normalization layer**

```bash
git add Project/CharacterDesignTool/prompt-composer.js
git commit -m "feat: normalize body prompts for anime beauty rendering"
```

## Task 3: Make Prompt Generation Route-Aware

**Files:**
- Modify: `Project/CharacterDesignTool/interview-engine.js`

- [ ] **Step 1: Replace the Z-Image-only system prompt with a route-aware prompt instruction**

```javascript
const STYLE_AWARE_PROMPT_SYSTEM = `You are a character design prompt engineer for a game character generator.

Your task: Convert collected character traits into one natural English prompt for a single full body character image.

CRITICAL RULES:
1. Write in fluent natural English prose.
2. Output only the prompt text.
3. Always describe a single character, fully visible from head to toe.
4. If the style direction is anime_beauty, prioritize elegant anime proportions, attractive silhouette rhythm, refined hands and feet, and controlled lower-body softness.
5. If the style direction is realistic, prioritize material realism and natural anatomy without making the lower body look overweight.
6. Never mention text, labels, character sheets, layout panels, callouts, or reference boards.
7. Never use Chinese characters or non-English words.
8. Keep body traits controlled and attractive; never exaggerate thickness or heaviness.

Structure:
[Identity] -> [Outfit and materials] -> [Body features] -> [Accessories] -> [Pose and composition] -> [Lighting and style]

Always end with studio lighting and presentation quality language.`;
```

- [ ] **Step 2: Pass workflow context into trait building and fallback narrative generation**

```javascript
var activeWorkflowId = "";
if (window.getSelectedTemplateId){
  activeWorkflowId = window.getSelectedTemplateId() || "";
}
if (!activeWorkflowId && window.COMFYUI_DEFAULT_WORKFLOW){
  activeWorkflowId = window.COMFYUI_DEFAULT_WORKFLOW;
}

if (window.buildTraitsForLLM){
  traitsForLLM = window.buildTraitsForLLM(_collectedTraits, DESIGN_FLOW, activeWorkflowId);
}

llmPrompt = await callAI(STYLE_AWARE_PROMPT_SYSTEM, traitsForLLM, 1200, 0.8, false);

var narrativeArr = window.composeNaturalNarrative
  ? window.composeNaturalNarrative(_collectedTraits, translations, activeWorkflowId)
  : [];
```

- [ ] **Step 3: Make the prompt bundle label reflect the active route**

```javascript
var routeMeta = window.getRenderRouteMeta
  ? window.getRenderRouteMeta(activeWorkflowId)
  : { displayName: "二次元美型" };

var promptBundle = {
  recommendedVariantId: "primary",
  variants: [
    {
      id: "primary",
      label: routeMeta.displayName + " 提示词",
      prompt: llmPrompt,
      note: routeMeta.style === "realistic" ? "自然英语·写实路线" : "自然英语·二次元美型路线"
    }
  ],
  context: _collectedTraits,
  templateId: templateId
};
```

- [ ] **Step 4: Validate syntax**

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js"
```

Expected:

- syntax check passes

- [ ] **Step 5: Commit the route-aware prompt generation change**

```bash
git add Project/CharacterDesignTool/interview-engine.js
git commit -m "feat: route prompts by anime beauty and realistic styles"
```

## Task 4: Manual Verification Of The Full Generation Loop

**Files:**
- Verify: `Project/CharacterDesignTool/comfyui-workflows.js`
- Verify: `Project/CharacterDesignTool/comfyui-bridge.js`
- Verify: `Project/CharacterDesignTool/prompt-composer.js`
- Verify: `Project/CharacterDesignTool/interview-engine.js`
- Verify: `Project/CharacterDesignTool/workflows/sd15-anime-api.json`
- Verify: `Project/CharacterDesignTool/workflows/zimage-showcase-api.json`

- [ ] **Step 1: Run syntax checks together**

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\prompt-composer.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js"
```

Expected:

- all commands exit with code `0`

- [ ] **Step 2: Launch the local tool and confirm the default workflow**

Run:

```powershell
node "g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js"
```

Expected:

- bridge starts on `http://127.0.0.1:3000`
- `/api/workflows` reports `sd15_anime` as the default frontend route

- [ ] **Step 3: Manual prompt-generation verification**

Use this sample trait set inside the browser flow:

```text
性别: 女
体型: 娇小
种族: 精灵
XP: 肉腿
发型: 双马尾
服装板式: 洛丽塔裙
设计流派: 洛可可
渲染风格: 二次元
```

Expected prompt properties:

- contains `full body` or `head to toe`
- contains anime-beauty language
- does not contain `plump thighs`
- contains lower-body guard language such as `elegant anime proportions` or `avoid overweight appearance`
- does not contain `character sheet`, `layout`, `panel`, or Chinese text

- [ ] **Step 4: Manual route-switch verification**

In the browser, switch from the default anime route to the realistic `zimage_showcase` route and regenerate the prompt.

Expected differences:

- anime route emphasizes beauty, silhouette, refined limbs, and controlled softness
- realistic route emphasizes natural proportions and materials
- both routes avoid overweight lower-body wording

- [ ] **Step 5: Final commit after verification**

```bash
git add Project/CharacterDesignTool/comfyui-workflows.js Project/CharacterDesignTool/comfyui-bridge.js Project/CharacterDesignTool/prompt-composer.js Project/CharacterDesignTool/interview-engine.js
git commit -m "feat: add anime beauty render routing and safe body prompts"
```

## Self-Review

- Spec coverage:
  - default anime route: covered by Task 1
  - beauty-safe body normalization: covered by Task 2
  - render precision split and prompt routing: covered by Tasks 2 and 3
  - realistic route retained as optional: covered by Tasks 1 and 4
- Placeholder scan:
  - no `TODO`, `TBD`, or undefined files remain in this plan
  - each task includes exact files and commands
- Type consistency:
  - shared helper names are consistent across tasks: `getRenderRouteMeta()`, `buildLowerBodyGuard()`, `getXpNote()`, `buildTraitsForLLM()`, `composeNaturalNarrative()`
