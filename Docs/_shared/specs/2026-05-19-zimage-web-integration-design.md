# Z-Image 网页接入设计

日期：2026-05-19
项目：`g:\UEGameDevelopment\Project\CharacterDesignTool`
状态：已确认，待实现计划

## 1. 目标

把 `Z-Image` 正式接入 `CharacterDesignTool` 网页端本地生图流程，使用户不需要打开 `ComfyUI` 手动选择模板，只需要在网页里：

1. 选择本地 `ComfyUI`
2. 选择 `Z-Image` 工作流模式
3. 点击 `🎨 出图`

系统即可自动完成：

- `角色设计展示图` 使用 `txt2img`
- 其他模式使用“最近展示图或手动指定参考图”作为输入，走 `img2img`
- 自动启动 `ComfyUI`
- 自动等待结果并回显到网页工作区

## 2. 范围

本次范围内：

- 新增网页中的 `Z-Image` 工作流选项
- 在 bridge 中注册 `Z-Image` 模板元数据
- 支持 `Z-Image 标准出图`
- 支持 `Z-Image Control（仅参考图 / 图生图）`
- 在项目数据中保存“展示主图”和“手动参考图”
- 在工作区中允许用户切换参考图

本次范围外：

- Pose / Depth / Canny / 多控制输入
- 直接在网页中暴露 steps / cfg / seed 等高级参数
- 重构整个图片工作区数据结构
- 继续修复 `ComfyUI` UI 模板显示问题

## 3. 用户规则

### 3.1 生成规则

- `角色设计展示模型` 是唯一的 `txt2img` 入口
- 其他模式不直接走 `txt2img`
- 其他模式默认使用“当前项目最近一次生成的展示主图”作为参考图，走 `img2img`
- 如果用户在工作区中手动指定了参考图，则优先使用该图
- 如果当前项目没有展示主图，且也没有手动指定参考图，则阻止生成，并提示先生成展示图或先指定参考图

### 3.2 用户体验

- 用户仍然只使用网页中的 `🎨 出图`
- 用户不需要进入 `ComfyUI` 里选模板
- 用户可以在工作区里修改“当前参考图”
- 切换项目后，参考图状态可以恢复

## 4. 接入方案

采用“复用现有本地生图链路”的方式接入。

### 4.1 前端

复用现有：

- `imageSource = comfyui`
- `comfyuiWorkflow`
- `comfyuiModel`
- `generateImagesX4()`
- `callComfyUILocal()`

扩展内容：

- 在 `comfyui-workflows.js` 新增 `Z-Image` 工作流元数据
- 在设置面板的工作流下拉中显示新的 `Z-Image` 选项
- 在工作区侧边栏增加“设为参考图 / 恢复默认参考图”动作
- 在本地生成时自动判断是 `txt2img` 还是 `img2img`

### 4.2 Bridge

复用现有：

- `TEMPLATE_REGISTRY`
- `ensureWorkflowTemplate()`
- `injectTemplateInputs()`
- `/api/generate`

扩展内容：

- 新增 `Z-Image` 模板定义
- 根据模板类型切换不同注入逻辑
- 标准模式：注入 checkpoint、prompt、negative、seed、steps、cfg、尺寸
- Control 模式：在标准注入基础上再注入参考图路径或输入图信息

### 4.3 数据持久化

在当前项目对象中新增两个字段：

- `primaryShowcaseImageId`
- `preferredReferenceImageId`

语义：

- `primaryShowcaseImageId`：最近一次成功生成的展示主图
- `preferredReferenceImageId`：用户手动在工作区指定的参考图，可为空

## 5. 工作流设计

### 5.1 网页工作流选项

第一版新增以下选项：

- `zimage_showcase`
  - 名称：`Z-Image 角色设计展示`
  - 用途：角色主展示图，走 `txt2img`
- `zimage_img2img`
  - 名称：`Z-Image 其他模式（参考图）`
  - 用途：基于展示图或手动参考图，走 `img2img`

### 5.2 模式映射

前端不额外新增复杂“生成类型”切换按钮，而是用 `workflow` 自身表达模式。

- 选择 `zimage_showcase` 时，bridge 运行 `txt2img`
- 选择 `zimage_img2img` 时，bridge 运行 `img2img`

## 6. 数据流

### 6.1 展示图生成

1. 用户在网页选择 `Z-Image 角色设计展示`
2. 点击 `🎨 出图`
3. 前端调用 `callComfyUILocal(prompt, settings)`
4. bridge 选择 `zimage_showcase` 模板并提交 `txt2img`
5. 成功后将结果写回工作区
6. 同时把该图标记为当前项目的 `primaryShowcaseImageId`

### 6.2 其他模式生成

1. 用户在网页选择 `Z-Image 其他模式（参考图）`
2. 点击 `🎨 出图`
3. 前端先解析当前项目参考图：
   - 优先 `preferredReferenceImageId`
   - 否则 `primaryShowcaseImageId`
4. 若没有可用参考图，则直接提示并终止
5. bridge 选择 `zimage_img2img` 模板并注入参考图
6. 生成成功后写回工作区

### 6.3 工作区参考图切换

1. 用户在工作区选择一张图片
2. 点击“设为参考图”
3. 当前项目记录 `preferredReferenceImageId`
4. 后续所有 `img2img` 默认使用该图

若用户点击“恢复默认参考图”：

- 清空 `preferredReferenceImageId`
- 重新回退到 `primaryShowcaseImageId`

## 7. 文件变更清单

### 7.1 修改文件

- `g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-workflows.js`
  - 新增 `Z-Image` 工作流元数据
- `g:\UEGameDevelopment\Project\CharacterDesignTool\comfyui-bridge.js`
  - 新增 `Z-Image` 模板注册与注入逻辑
- `g:\UEGameDevelopment\Project\CharacterDesignTool\project-store.js`
  - 持久化展示主图和参考图字段
- `g:\UEGameDevelopment\Project\CharacterDesignTool\chat-ui.js`
  - 工作区新增参考图操作
- `g:\UEGameDevelopment\Project\CharacterDesignTool\interview-engine.js`
  - 本地生图时注入参考图解析逻辑
- `g:\UEGameDevelopment\Project\CharacterDesignTool\interview.html`
  - 如需要，补参考图状态提示文案

### 7.2 新增文件

- `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-showcase-api.json`
- `g:\UEGameDevelopment\Project\CharacterDesignTool\workflows\zimage-img2img-api.json`

## 8. 注入策略

### 8.1 Showcase

必须注入：

- checkpoint
- prompt
- negative prompt
- width / height
- seed
- steps
- cfg

### 8.2 Img2Img

必须注入：

- checkpoint
- prompt
- negative prompt
- 参考图输入
- denoise 强度
- seed
- steps
- cfg

第一版的 `denoise` 使用固定默认值，不在网页暴露。

## 9. 错误处理

### 9.1 无参考图

当选择 `Z-Image 其他模式（参考图）` 且找不到：

- `preferredReferenceImageId`
- `primaryShowcaseImageId`

则前端直接提示：

- `请先生成角色设计展示图，或在工作区选择一张参考图`

### 9.2 参考图文件不存在

如果项目里记录的图片已被删掉或路径失效：

- bridge 返回明确错误
- 前端提示参考图失效，并建议重新指定

### 9.3 工作流文件缺失

若 `zimage-showcase-api.json` 或 `zimage-img2img-api.json` 缺失：

- bridge 返回模板缺失错误
- 前端提示本地模板未部署完整

## 10. 测试策略

### 10.1 功能验证

- 选择 `Z-Image 角色设计展示` 可成功 `txt2img`
- 生成成功后自动写入 `primaryShowcaseImageId`
- 选择 `Z-Image 其他模式（参考图）` 时可自动取最近展示图生成
- 工作区手动设为参考图后，后续 `img2img` 使用该图
- 清除手动参考图后恢复为“最近展示图优先”

### 10.2 回归验证

- 旧的 `sdxl_smoke / sdxl_portrait / sd15_anime / character_sheet_v1` 仍能在网页工作
- 自动启动 `ComfyUI` 不受影响
- 工作区图片回显不受影响
- 项目切换后展示图与参考图状态能恢复

## 11. 风险

- `Z-Image` 的 `img2img` 模板节点结构可能与现有简单注入逻辑差异较大，需要单独适配
- 当前 `ComfyUI` UI 中模板显示异常，但这不应阻塞网页通过 API 运行
- 如果 `ComfyUI` 自定义节点升级导致节点 ID 变化，模板注入会失效，因此必须优先采用“受控模板文件”

## 12. 实现原则

- 优先复用现有网页设置、bridge 接口和工作区数据结构
- 不新增不必要的第三方依赖
- 不要求用户进入 `ComfyUI` UI
- 第一版只做“展示图文生图 + 其他模式参考图图生图”
- 高级控制输入留到后续版本
