# CharacterDesignTool Prompt Workflow V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a layered prompt pipeline for `CharacterDesignTool` that preserves the full character card, extracts hard constraints, generates a visual plan, adapts prompts per workflow, and exposes prompt review information before rendering.

**Architecture:** Keep the current browser-side architecture and add one focused pipeline module instead of spreading new logic across `interview-engine.js`. Persist new prompt workflow artifacts inside the existing project storage model, then extend the existing prompt bar UI to display the extra layers with minimal layout changes.

**Tech Stack:** Browser-side JavaScript, Node.js `node:test`, existing project storage in `localStorage`, existing prompt bar UI in `chat-ui.js`

---

## File Structure

- Create: `Project/CharacterDesignTool/prompt-workflow.js`
  - Centralizes prompt workflow data shaping, per-workflow prompt artifacts, constraint extraction, visual plan defaults, and review helpers.
- Modify: `Project/CharacterDesignTool/interview-engine.js`
  - Replaces the one-shot prompt assembly path with the new multi-stage workflow orchestration.
- Modify: `Project/CharacterDesignTool/prompt-composer.js`
  - Supplies prompt-writer helpers, review helpers, and route-aware fallback generation used by the new workflow module.
- Modify: `Project/CharacterDesignTool/project-store.js`
  - Persists new workflow artifacts in project records and restores them correctly on project load.
- Modify: `Project/CharacterDesignTool/chat-ui.js`
  - Extends prompt bar rendering to expose `角色卡`、`硬约束`、`画面规划`、`最终提示词`、`审查结果`.
- Modify: `Project/CharacterDesignTool/interview.html`
  - Adds minimal containers for the prompt workflow panel inside the existing prompt bar.
- Modify: `Project/CharacterDesignTool/style.css`
  - Styles the new prompt workflow summary blocks and tabs without changing the overall layout system.
- Create: `Project/CharacterDesignTool/tests/prompt-workflow.test.js`
  - Covers prompt workflow bundle shaping, constraint persistence, and review state.
- Modify: `Project/CharacterDesignTool/tests/prompt-composer.test.js`
  - Covers visual plan generation and review helpers.
- Modify: `Project/CharacterDesignTool/tests/project-store.test.js`
  - Covers persistence and restoration of the new prompt workflow bundle shape.

## Task 1: Add The Prompt Workflow Core Module

**Files:**
- Create: `Project/CharacterDesignTool/prompt-workflow.js`
- Test: `Project/CharacterDesignTool/tests/prompt-workflow.test.js`

- [ ] **Step 1: Write the failing test for the new workflow bundle shape**

```javascript
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

function loadPromptWorkflow() {
  const source = fs.readFileSync("g:\\UEGameDevelopment\\Project\\CharacterDesignTool\\prompt-workflow.js", "utf8");
  const sandbox = {
    console,
    window: {}
  };
  sandbox.window = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(source, sandbox);
  return sandbox;
}

test("buildPromptWorkflowBundle creates layered prompt workflow artifacts", () => {
  const sandbox = loadPromptWorkflow();
  const bundle = sandbox.buildPromptWorkflowBundle({
    workflowId: "zimage_showcase",
    traits: {
      xp: "光腿",
      garmentSilhouette: "短上装高腰高开叉半裙衬裤",
      artStyle: "二次元偏写实"
    },
    mustKeepConstraints: [
      { id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }
    ],
    visualPlan: {
      subject: "single full body female cybernetic assassin",
      pose: "standing pose"
    },
    renderPrompt: "Full body shot visible from head to toe. ...",
    review: {
      status: "pass",
      missingConstraints: [],
      conflicts: [],
      notes: []
    }
  });

  assert.equal(bundle.workflowId, "zimage_showcase");
  assert.equal(bundle.characterCard.traits.xp, "光腿");
  assert.equal(bundle.mustKeepConstraints[0].id, "bare_legs");
  assert.equal(bundle.renderPrompts.zimage_showcase.prompt, "Full body shot visible from head to toe. ...");
  assert.equal(bundle.review.status, "pass");
});
```

- [ ] **Step 2: Run the test and confirm it fails because the module does not exist yet**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
```

Expected:

- FAIL with file read or undefined function errors for `prompt-workflow.js`

- [ ] **Step 3: Create the minimal prompt workflow module**

```javascript
"use strict";

function clonePromptWorkflowValue(value){
  return JSON.parse(JSON.stringify(value || null));
}

function normalizeConstraintList(list){
  return (list || []).filter(Boolean).map(function(item, index){
    return {
      id: item.id || ("constraint_" + index),
      priority: item.priority || "important",
      category: item.category || "general",
      text: String(item.text || "").trim()
    };
  }).filter(function(item){
    return !!item.text;
  });
}

function buildPromptWorkflowBundle(input){
  var workflowId = input?.workflowId || "zimage_showcase";
  var promptText = String(input?.renderPrompt || "").trim();

  return {
    workflowId: workflowId,
    characterCard: {
      traits: clonePromptWorkflowValue(input?.traits || {}),
      extraNotes: String(input?.extraNotes || ""),
      rawSummary: String(input?.rawSummary || "")
    },
    mustKeepConstraints: normalizeConstraintList(input?.mustKeepConstraints),
    visualPlan: clonePromptWorkflowValue(input?.visualPlan || {
      subject: "",
      silhouette: [],
      outfitVisibility: [],
      secondaryDetails: [],
      pose: "",
      framing: "",
      renderingDirection: ""
    }),
    renderPrompts: Object.assign({}, input?.renderPrompts || {}, {
      [workflowId]: {
        workflowId: workflowId,
        prompt: promptText
      }
    }),
    review: Object.assign({
      status: "pending",
      missingConstraints: [],
      conflicts: [],
      notes: []
    }, clonePromptWorkflowValue(input?.review || {}))
  };
}

window.clonePromptWorkflowValue = clonePromptWorkflowValue;
window.normalizeConstraintList = normalizeConstraintList;
window.buildPromptWorkflowBundle = buildPromptWorkflowBundle;
```

- [ ] **Step 4: Re-run the new test and confirm it passes**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
```

Expected:

- PASS with `1` test and `0` failures

- [ ] **Step 5: Commit the workflow core module**

```bash
git add Project/CharacterDesignTool/prompt-workflow.js Project/CharacterDesignTool/tests/prompt-workflow.test.js
git commit -m "feat: add prompt workflow core bundle helpers"
```

## Task 2: Add Constraint Extraction, Visual Plan, And Prompt Review Helpers

**Files:**
- Modify: `Project/CharacterDesignTool/prompt-composer.js`
- Modify: `Project/CharacterDesignTool/tests/prompt-composer.test.js`

- [ ] **Step 1: Add a failing test for visual plan and prompt review helpers**

```javascript
test("buildVisualPlanSummary prioritizes visible structure for one image", () => {
  const sandbox = loadPromptComposer();
  const plan = sandbox.buildVisualPlanSummary({
    bodyType: "性感女性",
    garmentSilhouette: "短上装高腰高开叉半裙衬裤",
    weaponType: "袖剑",
    artStyle: "二次元偏写实"
  }, [
    { id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }
  ], "zimage_showcase");

  assert.match(plan.subject, /single/i);
  assert.match(plan.framing, /full body/i);
  assert.ok(plan.focusZones.includes("legs"));
});

test("reviewRenderPrompt reports missing must-keep constraints", () => {
  const sandbox = loadPromptComposer();
  const review = sandbox.reviewRenderPrompt("A cybernetic assassin in blue silver styling.", [
    { id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }
  ]);

  assert.equal(review.status, "fail");
  assert.equal(review.missingConstraints[0].id, "bare_legs");
});
```

- [ ] **Step 2: Run the prompt-composer tests and confirm the new cases fail**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-composer.test.js"
```

Expected:

- FAIL with `buildVisualPlanSummary` and `reviewRenderPrompt` undefined

- [ ] **Step 3: Add minimal helper implementations to `prompt-composer.js`**

```javascript
function buildMustKeepConstraints(collectedTraits){
  var constraints = [];
  if (collectedTraits?.xp === "光腿"){
    constraints.push({
      id: "bare_legs",
      priority: "critical",
      category: "body",
      text: "Full bare legs remain visible with no hard occlusion."
    });
  }
  if (collectedTraits?.garmentSilhouette){
    constraints.push({
      id: "garment_structure",
      priority: "critical",
      category: "outfit",
      text: String(collectedTraits.garmentSilhouette)
    });
  }
  return constraints;
}

function buildVisualPlanSummary(collectedTraits, constraints, workflowId){
  var route = getRenderRouteMeta(workflowId);
  var focusZones = [];
  if ((constraints || []).some(function(item){ return item.id === "bare_legs"; })){
    focusZones.push("legs");
  }
  if (collectedTraits?.weaponType){
    focusZones.push("weapon");
  }

  return {
    subject: "single full body " + (collectedTraits?.species || "character"),
    silhouette: [
      String(collectedTraits?.bodyType || ""),
      String(collectedTraits?.garmentSilhouette || "")
    ].filter(Boolean),
    outfitVisibility: [String(collectedTraits?.garmentSilhouette || "")].filter(Boolean),
    secondaryDetails: [String(collectedTraits?.secondaryElement || "")].filter(Boolean),
    focusZones: focusZones,
    pose: "balanced standing pose with readable costume structure",
    framing: "full body shot visible from head to toe",
    renderingDirection: route.style === "anime_beauty"
      ? "anime beauty rendering with readable silhouette"
      : "natural rendering with readable materials and structure"
  };
}

function reviewRenderPrompt(promptText, constraints){
  var prompt = String(promptText || "");
  var missing = (constraints || []).filter(function(item){
    var lowerPrompt = prompt.toLowerCase();
    if (item.id === "bare_legs"){
      return !/bare legs|full bare legs|legs are bare/i.test(lowerPrompt);
    }
    return prompt.indexOf(item.text) === -1;
  });

  return {
    status: missing.length ? "fail" : "pass",
    missingConstraints: missing,
    conflicts: [],
    notes: missing.length ? ["Prompt omitted one or more hard constraints."] : []
  };
}

window.buildMustKeepConstraints = buildMustKeepConstraints;
window.buildVisualPlanSummary = buildVisualPlanSummary;
window.reviewRenderPrompt = reviewRenderPrompt;
```

- [ ] **Step 4: Re-run the prompt-composer tests and confirm they pass**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-composer.test.js"
```

Expected:

- PASS with all prompt-composer tests green

- [ ] **Step 5: Commit the prompt helper layer**

```bash
git add Project/CharacterDesignTool/prompt-composer.js Project/CharacterDesignTool/tests/prompt-composer.test.js
git commit -m "feat: add prompt workflow planning and review helpers"
```

## Task 3: Orchestrate The New Workflow In Prompt Generation

**Files:**
- Modify: `Project/CharacterDesignTool/interview-engine.js`
- Modify: `Project/CharacterDesignTool/prompt-workflow.js`
- Test: `Project/CharacterDesignTool/tests/prompt-workflow.test.js`

- [ ] **Step 1: Extend the workflow test with orchestration expectations**

```javascript
test("assemblePromptWorkflowResult keeps card, constraints, plan, prompt, and review together", () => {
  const sandbox = loadPromptWorkflow();
  const result = sandbox.assemblePromptWorkflowResult({
    workflowId: "zimage_showcase",
    traits: { xp: "光腿", garmentSilhouette: "短上装高腰高开叉半裙衬裤" },
    extraNotes: "银链绕双踝单圈足链",
    mustKeepConstraints: [{ id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }],
    visualPlan: { subject: "single full body cybernetic assassin" },
    renderPrompt: "Full body shot visible from head to toe. Full bare legs remain visible with no hard occlusion.",
    review: { status: "pass", missingConstraints: [], conflicts: [], notes: [] }
  });

  assert.equal(result.characterCard.extraNotes, "银链绕双踝单圈足链");
  assert.equal(result.renderPrompts.zimage_showcase.prompt.includes("Full body shot"), true);
  assert.equal(result.review.status, "pass");
});
```

- [ ] **Step 2: Run the workflow tests and confirm the new orchestration test fails**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
```

Expected:

- FAIL with `assemblePromptWorkflowResult` undefined

- [ ] **Step 3: Add orchestration helpers in `prompt-workflow.js` and call them from `doGeneratePrompt()`**

```javascript
function assemblePromptWorkflowResult(input){
  return buildPromptWorkflowBundle(input);
}

window.assemblePromptWorkflowResult = assemblePromptWorkflowResult;
```

```javascript
// interview-engine.js inside doGeneratePrompt()
var mustKeepConstraints = window.buildMustKeepConstraints
  ? window.buildMustKeepConstraints(_collectedTraits, activeWorkflowId)
  : [];

var visualPlan = window.buildVisualPlanSummary
  ? window.buildVisualPlanSummary(_collectedTraits, mustKeepConstraints, activeWorkflowId)
  : null;

var renderReview = window.reviewRenderPrompt
  ? window.reviewRenderPrompt(llmPrompt, mustKeepConstraints, activeWorkflowId)
  : { status: "pass", missingConstraints: [], conflicts: [], notes: [] };

var promptBundle = window.assemblePromptWorkflowResult
  ? window.assemblePromptWorkflowResult({
      workflowId: activeWorkflowId,
      traits: _collectedTraits,
      extraNotes: _collectedTraits.extraNotes || "",
      mustKeepConstraints: mustKeepConstraints,
      visualPlan: visualPlan,
      renderPrompt: llmPrompt,
      review: renderReview
    })
  : {
      recommendedVariantId: "primary",
      variants: [{ id: "primary", label: routeMeta.displayName + " 提示词", prompt: llmPrompt }]
    };
```

- [ ] **Step 4: Re-run the workflow test and confirm it passes**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
```

Expected:

- PASS with all workflow tests green

- [ ] **Step 5: Run syntax validation for the modified runtime files**

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\prompt-workflow.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js"
```

Expected:

- both commands exit with code `0`

- [ ] **Step 6: Commit the orchestration layer**

```bash
git add Project/CharacterDesignTool/prompt-workflow.js Project/CharacterDesignTool/interview-engine.js Project/CharacterDesignTool/tests/prompt-workflow.test.js
git commit -m "feat: orchestrate layered prompt workflow generation"
```

## Task 4: Persist And Restore The New Prompt Workflow Artifacts

**Files:**
- Modify: `Project/CharacterDesignTool/project-store.js`
- Modify: `Project/CharacterDesignTool/tests/project-store.test.js`

- [ ] **Step 1: Add failing persistence tests**

```javascript
test("saveCurrentProject persists prompt workflow artifacts", () => {
  const { sandbox } = loadProjectStore();
  sandbox.setCurrentProject({
    id: "p_demo",
    name: "测试角色"
  });
  sandbox.getCollectedTraits = () => ({ xp: "光腿" });
  sandbox.getCollectedFollowups = () => ({});
  sandbox.getPromptVariantBundle = () => ({
    workflowId: "zimage_showcase",
    characterCard: { traits: { xp: "光腿" }, extraNotes: "", rawSummary: "" },
    mustKeepConstraints: [{ id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }],
    visualPlan: { subject: "single full body character" },
    renderPrompts: { zimage_showcase: { workflowId: "zimage_showcase", prompt: "Full body shot..." } },
    review: { status: "pass", missingConstraints: [], conflicts: [], notes: [] }
  });

  sandbox.saveCurrentProject();
  const project = sandbox.getProjects()[0];
  assert.equal(project.promptBundle.review.status, "pass");
  assert.equal(project.promptBundle.mustKeepConstraints[0].id, "bare_legs");
});
```

- [ ] **Step 2: Run the project-store tests and confirm the new persistence test fails if bundle shape is not handled safely**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-store.test.js"
```

Expected:

- FAIL if prompt workflow bundle restoration or persistence drops the new nested fields

- [ ] **Step 3: Update persistence to keep the new prompt workflow structure untouched**

```javascript
// project-store.js
cp.promptBundle = window.getPromptVariantBundle
  ? cloneObj(window.getPromptVariantBundle() || null)
  : (cp.promptBundle || null);

if (window.restorePromptVariantBundle){
  window.restorePromptVariantBundle(
    cloneObj(p.promptBundle || null),
    p.currentPromptVariantId || "primary"
  );
}
```

```javascript
// Ensure createProject default shape stays compatible with the new primary id.
currentPromptVariantId: "primary",
```

- [ ] **Step 4: Re-run the project-store tests and confirm they pass**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-store.test.js"
```

Expected:

- PASS with all project-store tests green

- [ ] **Step 5: Commit the persistence work**

```bash
git add Project/CharacterDesignTool/project-store.js Project/CharacterDesignTool/tests/project-store.test.js
git commit -m "feat: persist layered prompt workflow artifacts"
```

## Task 5: Expose The New Workflow Layers In The Prompt Bar UI

**Files:**
- Modify: `Project/CharacterDesignTool/interview.html`
- Modify: `Project/CharacterDesignTool/chat-ui.js`
- Modify: `Project/CharacterDesignTool/style.css`

- [ ] **Step 1: Add a failing UI test for workflow summary rendering**

```javascript
test("renderPromptWorkflowSummary shows constraints, visual plan, and review status", () => {
  const source = fs.readFileSync("g:\\UEGameDevelopment\\Project\\CharacterDesignTool\\chat-ui.js", "utf8");
  const sandbox = {
    console,
    document: {
      createElement() { return { innerHTML: "", appendChild() {}, style: {}, className: "" }; },
      getElementById() { return null; },
      querySelectorAll() { return []; }
    },
    window: {}
  };
  sandbox.window = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(source, sandbox);

  const html = sandbox.renderPromptWorkflowSummary({
    mustKeepConstraints: [{ id: "bare_legs", priority: "critical", text: "Full bare legs remain visible with no hard occlusion." }],
    visualPlan: { subject: "single full body character", pose: "balanced standing pose" },
    review: { status: "pass", missingConstraints: [], conflicts: [], notes: [] }
  });

  assert.match(html, /bare_legs|Full bare legs/i);
  assert.match(html, /single full body character/i);
  assert.match(html, /pass|通过/i);
});
```

- [ ] **Step 2: Run the UI-adjacent tests and confirm the new case fails**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-menu-button.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
```

Expected:

- FAIL for `renderPromptWorkflowSummary` undefined if not yet implemented

- [ ] **Step 3: Add minimal prompt workflow summary UI**

```html
<!-- interview.html inside promptContent -->
<div id="promptWorkflowSummary" class="prompt-workflow-summary"></div>
<div id="promptWorkflowReview" class="prompt-workflow-review"></div>
```

```javascript
function renderPromptWorkflowSummary(bundle){
  if(!bundle) return "";
  var constraints = (bundle.mustKeepConstraints || []).map(function(item){
    return '<li>' + esc(item.text || "") + '</li>';
  }).join("");
  var plan = bundle.visualPlan || {};
  var review = bundle.review || {};

  return '' +
    '<div class="prompt-stage-card">' +
      '<h4>硬约束</h4>' +
      '<ul>' + constraints + '</ul>' +
    '</div>' +
    '<div class="prompt-stage-card">' +
      '<h4>画面规划</h4>' +
      '<div>' + esc(plan.subject || "") + '</div>' +
      '<div>' + esc(plan.pose || "") + '</div>' +
    '</div>' +
    '<div class="prompt-stage-card">' +
      '<h4>审查结果</h4>' +
      '<div>' + esc(review.status || "pending") + '</div>' +
    '</div>';
}

// chat-ui.js inside showPromptBar()
var workflowSummary = $e("promptWorkflowSummary");
if(workflowSummary){
  workflowSummary.innerHTML = renderPromptWorkflowSummary(_promptVariantBundle);
}
```

```css
.prompt-workflow-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 12px;
}

.prompt-stage-card {
  background: #0f172a;
  border: 1px solid #334155;
  border-radius: 10px;
  padding: 10px 12px;
  color: #cbd5e1;
}
```

- [ ] **Step 4: Re-run the UI-adjacent tests and confirm they pass**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-menu-button.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\chat-ui.js"
```

Expected:

- tests pass
- syntax check exits with code `0`

- [ ] **Step 5: Commit the prompt workflow UI**

```bash
git add Project/CharacterDesignTool/interview.html Project/CharacterDesignTool/chat-ui.js Project/CharacterDesignTool/style.css Project/CharacterDesignTool/tests/prompt-workflow.test.js
git commit -m "feat: expose prompt workflow summary in prompt bar"
```

## Task 6: Final End-To-End Verification

**Files:**
- Verify: `Project/CharacterDesignTool/prompt-workflow.js`
- Verify: `Project/CharacterDesignTool/prompt-composer.js`
- Verify: `Project/CharacterDesignTool/interview-engine.js`
- Verify: `Project/CharacterDesignTool/project-store.js`
- Verify: `Project/CharacterDesignTool/chat-ui.js`
- Verify: `Project/CharacterDesignTool/interview.html`
- Verify: `Project/CharacterDesignTool/style.css`
- Verify: `Project/CharacterDesignTool/tests/prompt-workflow.test.js`
- Verify: `Project/CharacterDesignTool/tests/prompt-composer.test.js`
- Verify: `Project/CharacterDesignTool/tests/project-store.test.js`
- Verify: `Project/CharacterDesignTool/tests/project-menu-button.test.js`
- Verify: `Project/CharacterDesignTool/tests/comfyui-workflows.test.js`
- Verify: `Project/CharacterDesignTool/tests/comfyui-bridge-config.test.js`

- [ ] **Step 1: Run the full test suite**

Run:

```powershell
node --test "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-workflow.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\prompt-composer.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-store.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\project-menu-button.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\comfyui-workflows.test.js" "g:\UEGameDevelopment\Project\CharacterDesignTool\tests\comfyui-bridge-config.test.js"
```

Expected:

- all tests pass
- no failures

- [ ] **Step 2: Run syntax checks on all modified runtime files**

Run:

```powershell
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\prompt-workflow.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\prompt-composer.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\project-store.js"
node --check "g:\UEGameDevelopment\Project\CharacterDesignTool\chat-ui.js"
```

Expected:

- all commands exit with code `0`

- [ ] **Step 3: Manual browser verification**

Use this concrete scenario:

```text
XP偏好: 光腿
服装板式: 短上装高腰高开叉半裙衬裤
武器: 袖剑
设计流派: 赛博朋克
渲染精度: 二次元偏写实
补充: 银链绕双踝单圈足链
```

Verify in UI:

- prompt bar shows `硬约束`
- prompt bar shows `画面规划`
- prompt bar shows `审查结果`
- final prompt still appears in the editable prompt area
- project reload preserves these sections

- [ ] **Step 4: Final commit after verification**

```bash
git add Project/CharacterDesignTool/prompt-workflow.js Project/CharacterDesignTool/prompt-composer.js Project/CharacterDesignTool/interview-engine.js Project/CharacterDesignTool/project-store.js Project/CharacterDesignTool/chat-ui.js Project/CharacterDesignTool/interview.html Project/CharacterDesignTool/style.css Project/CharacterDesignTool/tests
git commit -m "feat: add layered prompt workflow for character generation"
```

## Self-Review

- Spec coverage:
  - layered workflow: covered by Tasks 1, 2, and 3
  - UI surface for workflow stages: covered by Task 5
  - persistence rules: covered by Task 4
  - route-aware prompting and review: covered by Tasks 2 and 3
  - incremental rollout: the plan follows the spec's phase order
- Placeholder scan:
  - no `TODO`, `TBD`, or undefined file paths remain
  - each task names exact files, commands, and expected outcomes
- Type consistency:
  - shared names are stable across tasks: `buildPromptWorkflowBundle()`, `assemblePromptWorkflowResult()`, `buildMustKeepConstraints()`, `buildVisualPlanSummary()`, `reviewRenderPrompt()`
