# Z-Image 网页接入实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在网页端本地 ComfyUI 模式下新增 Z-Image 工作流选项，展示图走 txt2img，其他模式基于参考图走 img2img，不需要手动打开 ComfyUI 选模板。

**Architecture:** 复用现有 bridge 模板注册和注入链路，新增两类 Z-Image 模板（showcase / img2img）并扩展注入逻辑支持参考图。前端新增工作流选项和参考图管理，项目持久化追踪展示主图和手动参考图。

**Tech Stack:** Node.js (bridge), Vanilla JS (frontend), ComfyUI API

---

### Task 1: 创建 Z-Image API 工作流模板文件

**Files:**
- Create: `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-showcase-api.json`
- Create: `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-img2img-api.json`

- [ ] **Step 1: 创建 showcase 工作流（txt2img）**

```json
{
  "1": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": { "ckpt_name": "z-image-turbo-fp8-aio.safetensors" }
  },
  "2": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "", "clip": ["1", 1] }
  },
  "3": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "", "clip": ["1", 1] }
  },
  "4": {
    "class_type": "EmptyLatentImage",
    "inputs": { "width": 1344, "height": 768, "batch_size": 1 }
  },
  "5": {
    "class_type": "KSampler",
    "inputs": {
      "seed": 0, "steps": 8, "cfg": 1.0,
      "sampler_name": "res_multistep", "scheduler": "simple", "denoise": 1.0,
      "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]
    }
  },
  "6": {
    "class_type": "VAEDecode",
    "inputs": { "samples": ["5", 0], "vae": ["1", 2] }
  },
  "7": {
    "class_type": "SaveImage",
    "inputs": { "filename_prefix": "zimageShowcase", "images": ["6", 0] }
  }
}
```

把以上内容写入 `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-showcase-api.json`。

- [ ] **Step 2: 创建 img2img 工作流**

```json
{
  "1": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": { "ckpt_name": "z-image-turbo-fp8-aio.safetensors" }
  },
  "2": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "", "clip": ["1", 1] }
  },
  "3": {
    "class_type": "CLIPTextEncode",
    "inputs": { "text": "", "clip": ["1", 1] }
  },
  "4": {
    "class_type": "LoadImage",
    "inputs": { "image": "reference_input.png" }
  },
  "5": {
    "class_type": "VAEEncode",
    "inputs": { "pixels": ["4", 0], "vae": ["1", 2] }
  },
  "6": {
    "class_type": "KSampler",
    "inputs": {
      "seed": 0, "steps": 8, "cfg": 1.0,
      "sampler_name": "res_multistep", "scheduler": "simple", "denoise": 0.6,
      "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["5", 0]
    }
  },
  "7": {
    "class_type": "VAEDecode",
    "inputs": { "samples": ["6", 0], "vae": ["1", 2] }
  },
  "8": {
    "class_type": "SaveImage",
    "inputs": { "filename_prefix": "zimageImg2img", "images": ["7", 0] }
  }
}
```

把以上内容写入 `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-img2img-api.json`。

- [ ] **Step 3: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-showcase-api.json g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-img2img-api.json
git commit -m "feat: add zimage showcase and img2img api workflow templates"
```

---

### Task 2: 在 comfyui-bridge.js 中注册 Z-Image 模型和模板

**Files:**
- Modify: `g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js`

- [ ] **Step 1: 在 MODEL_FILES 中新增 zimage**

找到 `const MODEL_FILES = {` 块（约第 21 行），在 sdxl 条目之前插入：

```javascript
const MODEL_FILES = {
  zimage: {
    id: "zimage",
    family: "zimage",
    checkpoint: "z-image-turbo-fp8-aio.safetensors",
    vae: ""
  },
  sdxl: {
```

- [ ] **Step 2: 在 TEMPLATE_REGISTRY 中新增 zimage_showcase 模板**

找到 `const TEMPLATE_REGISTRY = {` 块（约第 36 行），在 sdxl_smoke 条目之前插入：

```javascript
const TEMPLATE_REGISTRY = {
  zimage_showcase: {
    id: "zimage_showcase",
    file: "zimage-showcase-api.json",
    defaultModel: "zimage",
    family: "zimage",
    smokeTest: false,
    experimental: false,
    promptPrefix: "",
    negativePrompt: "low quality, blurry, worst quality, bad anatomy, watermark, text, signature, cropped",
    width: 1344,
    height: 768,
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
  zimage_img2img: {
    id: "zimage_img2img",
    file: "zimage-img2img-api.json",
    defaultModel: "zimage",
    family: "zimage",
    smokeTest: false,
    experimental: false,
    promptPrefix: "",
    negativePrompt: "low quality, blurry, worst quality, bad anatomy, watermark, text, signature, cropped",
    width: 1344,
    height: 768,
    steps: 8,
    cfg: 1.0,
    injection: {
      checkpointNodeId: "1",
      positiveNodeId: "2",
      negativeNodeId: "3",
      loadImageNodeId: "4",
      vaeEncodeNodeId: "5",
      samplerNodeId: "6",
      saveNodeId: "8",
      vaeLoaderNodeId: ""
    }
  },
  sdxl_smoke: {
```

- [ ] **Step 3: 扩展 injectTemplateInputs 支持 zimage 分支（早期返回）**

找到 `function injectTemplateInputs(workflow, templateMeta, modelKey, options) {` 函数（约第 313 行）。

在这个位置——紧接 `const seed = ...` 行**之后**（约第 323 行）、原有的 `if (!workflow[inject.checkpointNodeId] ...` **之后**、原有的注入赋值 `workflow[inject.checkpointNodeId].inputs.ckpt_name = ...` **之前**——插入 zimage 族早期返回分支：

现有代码结构（`const seed = ...` 之后）：
```javascript
  const seed = Number.isFinite(Number(options.seed)) ? Number(options.seed) : Math.floor(Math.random() * 9999999999999);

  if (!workflow[inject.checkpointNodeId] || ...) {
    throw new Error("工作流模板节点缺失...");
  }

  workflow[inject.checkpointNodeId].inputs.ckpt_name = modelMeta.checkpoint;
  ...
```

在上述 `if (!workflow[inject.checkpointNodeId] ...` 块**之后**、`workflow[inject.checkpointNodeId].inputs.ckpt_name = ...` **之前**，插入 zimage 分支：

```javascript
  if (templateMeta.family === "zimage") {
    if (!workflow[inject.checkpointNodeId] || !workflow[inject.positiveNodeId] || !workflow[inject.negativeNodeId]) {
      throw new Error("zimage 工作流模板节点缺失，无法注入参数");
    }
    workflow[inject.checkpointNodeId].inputs.ckpt_name = modelMeta.checkpoint;
    workflow[inject.positiveNodeId].inputs.text = promptText;
    workflow[inject.negativeNodeId].inputs.text = negativePrompt;

    if (inject.latentNodeId && workflow[inject.latentNodeId]) {
      workflow[inject.latentNodeId].inputs.width = width;
      workflow[inject.latentNodeId].inputs.height = height;
    }

    if (inject.loadImageNodeId && workflow[inject.loadImageNodeId]) {
      const refImagePath = options.referenceImagePath || "";
      if (refImagePath) {
        workflow[inject.loadImageNodeId].inputs.image = refImagePath;
      }
    }

    if (inject.samplerNodeId && workflow[inject.samplerNodeId]) {
      workflow[inject.samplerNodeId].inputs.seed = seed;
      workflow[inject.samplerNodeId].inputs.steps = steps;
      workflow[inject.samplerNodeId].inputs.cfg = cfg;
      if (templateMeta.id === "zimage_img2img" && typeof workflow[inject.samplerNodeId].inputs.denoise !== "undefined") {
        workflow[inject.samplerNodeId].inputs.denoise = Number.isFinite(Number(options.denoise)) ? Number(options.denoise) : 0.6;
      }
    }

    if (inject.saveNodeId && workflow[inject.saveNodeId]) {
      workflow[inject.saveNodeId].inputs.filename_prefix = options.filenamePrefix || "zimageDesign";
    }

    return {
      workflow: workflow,
      seed: seed,
      checkpoint: modelMeta.checkpoint,
      vae: ""
    };
  }
```

这段代码插入后，原有的 `workflow[inject.checkpointNodeId].inputs.ckpt_name = modelMeta.checkpoint;` 等 SD 族注入逻辑仍然保留，在 zimage 分支 `return` 之后继续执行。这样 `promptText`、`seed` 等变量已被正确计算。

- [ ] **Step 4: 在 getAvailableAssets 中支持 zimage 模型**

找到 `function getAvailableAssets() {` 函数（约第 241 行），确保它遍历 `MODEL_FILES` 时已覆盖 zimage —— 该函数用 `Object.keys(MODEL_FILES).forEach` 构造 assets，zimage key 新增后会自动被包含，无需额外修改。验证 `checkpoints` 目录下 `z-image-turbo-fp8-aio.safetensors` 文件存在即可。

- [ ] **Step 5: 确保 validateAssetsForTemplate 跳过 zimage 的 vae 检查**

找到 `function validateAssetsForTemplate`（约第 502 行）。该函数已包含 `if (modelMeta.vae && ...)` 的空 VAE 保护，因为设置了 `zimage.vae = ""`，会自然跳过。无需额外修改。

- [ ] **Step 6: 在 handleGenerateRequest 中透传 referenceImagePath**

找到 `async function handleGenerateRequest(res, body) {` 函数（约第 583 行）。

在 `const autoSmokeTest = ...` 行之后，新增参考图路径提取：

```javascript
    const referenceImagePath = body.referenceImagePath || "";
```

在 `runTemplate` 调用处（约第 604 行），把 options 从：

```javascript
      promptText: promptText,
      filenamePrefix: "characterDesign"
```

扩展为：

```javascript
      promptText: promptText,
      filenamePrefix: "characterDesign",
      referenceImagePath: referenceImagePath
```

- [ ] **Step 7: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js
git commit -m "feat: register zimage model and templates in bridge"
```

---

### Task 3: 更新 comfyui-workflows.js 前端元数据

**Files:**
- Modify: `g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js`

- [ ] **Step 1: 新增 Z-Image 工作流元数据**

在 `window.COMFYUI_WORKFLOW_META = {` 对象内，`sdxl_smoke` 之前插入：

```javascript
window.COMFYUI_WORKFLOW_META = {
  zimage_showcase: {
    id: "zimage_showcase",
    name: "Z-Image 角色设计展示",
    desc: "标准文生图，用于生成角色主展示图",
    width: 1344,
    height: 768,
    steps: 8,
    cfg: 1.0,
    model: "zimage",
    family: "zimage",
    workflowFile: "zimage-showcase-api.json",
    promptPrefix: "",
    negativePrompt: "low quality, blurry, worst quality, bad anatomy, watermark, text, signature, cropped",
    smokeTest: false,
    experimental: false
  },
  zimage_img2img: {
    id: "zimage_img2img",
    name: "Z-Image 其他模式（参考图）",
    desc: "基于展示图或手动参考图的图生图",
    width: 1344,
    height: 768,
    steps: 8,
    cfg: 1.0,
    model: "zimage",
    family: "zimage",
    workflowFile: "zimage-img2img-api.json",
    promptPrefix: "",
    negativePrompt: "low quality, blurry, worst quality, bad anatomy, watermark, text, signature, cropped",
    smokeTest: false,
    experimental: false
  },
  sdxl_smoke: {
```

- [ ] **Step 2: 新增 Z-Image 模型元数据**

在 `window.COMFYUI_MODEL_META = {` 对象内，`sdxl` 之前插入：

```javascript
window.COMFYUI_MODEL_META = {
  zimage: {
    id: "zimage",
    name: "Z-Image Turbo FP8",
    desc: "Z-Image Turbo 8步快速出图，10GB，适合 8GB 显存",
    family: "zimage",
    checkpoint: "z-image-turbo-fp8-aio.safetensors",
    vae: ""
  },
  sdxl: {
```

- [ ] **Step 3: 更新默认工作流**

将 `window.COMFYUI_DEFAULT_WORKFLOW = "sdxl_portrait";`（约第 89 行）修改为：

```javascript
window.COMFYUI_DEFAULT_WORKFLOW = "zimage_showcase";
```

- [ ] **Step 4: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js
git commit -m "feat: add zimage workflow and model metadata to frontend"
```

---

### Task 4: 在 project-store.js 中添加展示图和参考图持久化

**Files:**
- Modify: `g:\UEGameDevelopment\Project\CharacterDesignTool\project-store.js`

- [ ] **Step 1: 在 getImageSettings 中添加参考图字段默认值**

找到 `function getImageSettings() {` 函数（约第 489 行）。在 `_imageSettings.comfyuiAutoSmokeTest` 赋值后，`return _imageSettings;` 前，插入：

```javascript
  _imageSettings.primaryShowcaseImageId = _imageSettings.primaryShowcaseImageId || "";
  _imageSettings.preferredReferenceImageId = _imageSettings.preferredReferenceImageId || "";
```

- [ ] **Step 2: 在创建新项目时加入新字段默认值**

找到 `const p = {` 创建项目对象的位置（约第 195 行附近，`function createProject()` 内部）。在已有的 `currentPromptVariantId` 之后、`customName` 之前，插入：

```javascript
    primaryShowcaseImageId: "",
    preferredReferenceImageId: "",
```

- [ ] **Step 3: 在 saveCurrentProject 中持久化新字段**

找到 `function saveCurrentProject()`（约第 380 行附近）。在已有的保存逻辑中找到 `cp.currentPromptVariantId` 赋值，在其后插入：

```javascript
  cp.primaryShowcaseImageId = cp.primaryShowcaseImageId || "";
  cp.preferredReferenceImageId = cp.preferredReferenceImageId || "";
```

同时新增调用 `setPrimaryShowcaseImage` / `setPreferredReferenceImage` 时的持久化路径。在 `saveCurrentProject` 函数中，找到 `cp.selectedTemplateId = window.getSelectedTemplateId ...` 行附近，追加：

```javascript
  cp.primaryShowcaseImageId = window._primaryShowcaseImageId || cp.primaryShowcaseImageId || "";
  cp.preferredReferenceImageId = window._preferredReferenceImageId || cp.preferredReferenceImageId || "";
```

- [ ] **Step 4: 添加参考图管理函数**

在 `// ─── ComfyUI Settings ───` 区块末尾（约第 1050 行，`window.onComfyUIAutoSmokeChange = onComfyUIAutoSmokeChange;` 之后），追加以下函数：

```javascript
function setPrimaryShowcaseImage(imageId){
  window._primaryShowcaseImageId = imageId;
  var cp = window.getCurrentProject && window.getCurrentProject();
  if(cp){ cp.primaryShowcaseImageId = imageId; }
}

function getPrimaryShowcaseImage(){
  return window._primaryShowcaseImageId || "";
}

function setPreferredReferenceImage(imageId){
  window._preferredReferenceImageId = imageId;
  var cp = window.getCurrentProject && window.getCurrentProject();
  if(cp){ cp.preferredReferenceImageId = imageId; }
}

function getPreferredReferenceImage(){
  return window._preferredReferenceImageId || "";
}

function clearPreferredReferenceImage(){
  setPreferredReferenceImage("");
}

window.setPrimaryShowcaseImage = setPrimaryShowcaseImage;
window.getPrimaryShowcaseImage = getPrimaryShowcaseImage;
window.setPreferredReferenceImage = setPreferredReferenceImage;
window.getPreferredReferenceImage = getPreferredReferenceImage;
window.clearPreferredReferenceImage = clearPreferredReferenceImage;
```

- [ ] **Step 5: 在 loadProject 中恢复参考图状态**

找到 `function loadProject(projectId)`（约第 410 行附近）。在已有恢复逻辑 `if(window.setSelectedTemplateId)` 调用块之后，追加：

```javascript
  if(window.setPrimaryShowcaseImage) window.setPrimaryShowcaseImage(p.primaryShowcaseImageId || "");
  if(window.setPreferredReferenceImage) window.setPreferredReferenceImage(p.preferredReferenceImageId || "");
```

- [ ] **Step 6: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\project-store.js
git commit -m "feat: add showcase and reference image persistence to project-store"
```

---

### Task 5: 更新 interview-engine.js 本地生图链路

**Files:**
- Modify: `g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js`

- [ ] **Step 1: 在 callComfyUILocal 中注入参考图信息**

找到 `async function callComfyUILocal(promptText, imgSet) {` 函数（约第 1811 行）。

在 `var autoSmokeTest = imgSet.comfyuiAutoSmokeTest !== false;` 之后、`var status = await fetch(...` 之前（约第 1815-1816 行间），插入参考图解析逻辑：

```javascript
  var referenceImagePath = "";
  if(workflowId === "zimage_img2img"){
    referenceImagePath = (window.getPreferredReferenceImage && window.getPreferredReferenceImage()) || (window.getPrimaryShowcaseImage && window.getPrimaryShowcaseImage()) || "";
    if(!referenceImagePath){
      var cp = window.getCurrentProject && window.getCurrentProject();
      referenceImagePath = cp ? (cp.preferredReferenceImageId || cp.primaryShowcaseImageId || "") : "";
    }
    if(!referenceImagePath){
      _UI_addMessage("system", "⚠️ 请先生成角色设计展示图，或在工作区选择一张参考图。");
      return null;
    }
    _UI_addMessage("system", "🖼️ 使用参考图进行生成...");
  }
```

- [ ] **Step 2: 在 /api/generate 请求体中加入参考图路径**

找到 `var resp = await fetch(bridgeUrl + "/api/generate", {` 块（约第 1832 行），在 body 的 JSON 中新增 `referenceImagePath` 字段：

将现有 body：
```javascript
    body: JSON.stringify({
      prompt: promptText,
      workflow: workflowId,
      model: modelKey,
      autoSmokeTest: autoSmokeTest
    })
```

替换为：
```javascript
    body: JSON.stringify({
      prompt: promptText,
      workflow: workflowId,
      model: modelKey,
      autoSmokeTest: autoSmokeTest,
      referenceImagePath: referenceImagePath
    })
```

- [ ] **Step 3: 展示图生成完成后标记 primaryShowcaseImageId**

找到 `generateImagesX4()` 函数（约第 1658 行）。在图片成功生成并写入工作区之后（`addImageToWorkspace` 调用后），追加展示图标记逻辑。

在 `addImageToWorkspace` 之后添加：
```javascript
      if(imgSet.comfyuiWorkflow === "zimage_showcase" && imageItem && imageItem.url){
        window.setPrimaryShowcaseImage && window.setPrimaryShowcaseImage(imageItem.url);
        if(window.saveCurrentProject) window.saveCurrentProject();
      }
```

`imageItem` 需要从 `addImageToWorkspace` 的返回值拿到。确认 `addImageToWorkspace` 返回 item 对象。

- [ ] **Step 4: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js
git commit -m "feat: inject reference image path for zimage img2img mode, mark showcase image"
```

---

### Task 6: 更新 chat-ui.js 工作区参考图操作

**Files:**
- Modify: `g:\UEGameDevelopment\Project\CharacterDesignTool\chat-ui.js`

- [ ] **Step 1: 重写 iwUseAsReference 为真实参考图设置**

找到 `function iwUseAsReference(){` 函数（约第 722 行）。完整替换：

```javascript
function iwUseAsReference(){
  if(_iwSelectedIndex < 0) return;
  var item = _iwItems[_iwSelectedIndex];
  if(window.setPreferredReferenceImage) window.setPreferredReferenceImage(item.url);
  if(window.saveCurrentProject) window.saveCurrentProject();
  _UI_addMessage && _UI_addMessage("system", "📌 已将所选图像设为当前参考图");
  iwRenderActions();
}
```

- [ ] **Step 2: 添加恢复默认参考图按钮函数**

在 `iwUseAsReference` 函数后面新增：

```javascript
function iwClearReferenceImage(){
  if(window.clearPreferredReferenceImage) window.clearPreferredReferenceImage();
  if(window.saveCurrentProject) window.saveCurrentProject();
  _UI_addMessage && _UI_addMessage("system", "🔄 已恢复默认参考图（最近展示图优先）");
  iwRenderActions();
}
```

- [ ] **Step 3: 在工作区详情面板底部的操作区增加两个按钮**

确保 `g:\UEGameDevelopment\Project\CharacterDesignTool\interview.html` 中 `#iwActions` 块已存在两个按钮。将现有的 `iwUseAsReference` 连接和新按钮加在 `iwRegenerateCurrent` 之后。

在 `interview.html` 中修改 `#iwActions` 区域（约第 484-487 行）：

```html
    <div class="iw-actions" id="iwActions" style="display:none">
     <button class="iw-action-btn primary" onclick="iwRegenerateCurrent()">🔄 重新生成</button>
     <button class="iw-action-btn" onclick="iwUseAsReference()">📌 设为参考图</button>
     <button class="iw-action-btn" onclick="iwClearReferenceImage()">🔄 恢复默认参考图</button>
    </div>
```

- [ ] **Step 4: 暴露新函数到 window**

在 `chat-ui.js` 文件末尾附近（`window.iwUseAsReference` 已存在的情况下），确保追加：

```javascript
window.iwUseAsReference = iwUseAsReference;
window.iwClearReferenceImage = iwClearReferenceImage;
```

- [ ] **Step 5: Commit**

```bash
git add g:\UEGameDevelopment\Project\CharacterDesignTool\chat-ui.js g:\UEGameDevelopment\Project\CharacterDesignTool\interview.html
git commit -m "feat: add reference image set/clear buttons in image workspace"
```

---

### Task 7: 遍历验证 + 收口

- [ ] **Step 1: 语法检查**

分别检查以下文件是否有明确语法错误：

```bash
node -c g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js
node -e "try{ require('fs').readFileSync('g:/UEGameDevelopment/Project/CharacterDesignTool/comfyui-workflows.js','utf8'); (0,eval)(fs.readFileSync('g:/UEGameDevelopment/Project/CharacterDesignTool/comfyui-workflows.js','utf8')); }catch(e){console.log(e.message)}"
node -e "(function(){ var fs=require('fs'); var s0=fs.readFileSync('g:/UEGameDevelopment/Project/CharacterDesignTool/project-store.js','utf8'); var s1=fs.readFileSync('g:/UEGameDevelopment/Project/CharacterDesignTool/interview-engine.js','utf8'); var s2=fs.readFileSync('g:/UEGameDevelopment/Project/CharacterDesignTool/chat-ui.js','utf8'); try{new Function(s0);console.log('project-store OK')}catch(e){console.log('project-store:',e.message)}; try{new Function(s1);console.log('interview-engine OK')}catch(e){console.log('interview-engine:',e.message)}; try{new Function(s2);console.log('chat-ui OK')}catch(e){console.log('chat-ui:',e.message)} })()"
```

- [ ] **Step 2: 确认工作流模板文件存在**

```bash
dir g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-showcase-api.json
dir g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-img2img-api.json
```

- [ ] **Step 3: 回归检查**

确认旧工作流选择 `sdxl_smoke` / `sdxl_portrait` / `sd15_anime` / `character_sheet_v1` 仍在工作流下拉中可正常显示和切换。

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "chore: final validation of zimage web integration"
```
