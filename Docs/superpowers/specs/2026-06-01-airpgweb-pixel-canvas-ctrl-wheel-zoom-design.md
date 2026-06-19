# AIRPGWeb Pixel Canvas Ctrl Wheel Zoom Design

## Goal

为 `AIRPGWeb` 素材库像素画板增加与地图绘制一致的 `Ctrl + 鼠标滚轮` 缩放交互，同时保留现有“缩小画板 / 放大画板”按钮作为备用入口。

本次设计只解决“更容易进行像素级绘画”的视图交互问题，不改变真实像素尺寸语义，不扩展新的绘制工具，也不调整地图编辑器现有缩放规则。

## Context

当前素材库画板已经支持单像素绘制，但缩放方式只有按钮，导致在较大模板下快速放大到适合精细绘制的倍率不够顺手。

地图绘制已经具备 `Ctrl + 滚轮` 缩放行为，用户明确要求素材库画板对齐这一交互习惯：

- `Ctrl + 滚轮` 作为主缩放方式
- 现有按钮继续保留
- 缩放后仍然是对真实单像素的编辑，不得改变素材真实尺寸

## Scope

### In Scope

- 为素材库画板增加 `Ctrl + 滚轮` 缩放
- 与地图绘制保持相同的滚轮方向语义
- 保留现有按钮缩放
- 阻止浏览器默认页面级 `Ctrl + 滚轮` 缩放
- 保证未按 `Ctrl` 时仍可正常滚动画板容器

### Out Of Scope

- 不改地图绘制的缩放实现
- 不新增平移、惯性缩放、双指缩放等交互
- 不修改真实像素尺寸模板逻辑
- 不新增新的画板工具或快捷键体系

## User Experience

### Primary Interaction

当鼠标位于素材库像素画板区域时：

- 按住 `Ctrl`
- 滚动鼠标滚轮
- 向上滚动时放大画板
- 向下滚动时缩小画板

缩放结果直接作用于当前画板显示倍率，即 `canvasZoom`，不改变：

- `pixelWidth`
- `pixelHeight`
- 已保存素材占格
- 单次绘制命中的真实像素坐标

### Fallback Interaction

以下按钮继续保留并与滚轮缩放共用同一状态：

- `缩小画板`
- `放大画板`

按钮和滚轮都必须更新同一个 `canvasZoom`，避免出现两套缩放状态。

### Default Scrolling

用户未按 `Ctrl` 时：

- 普通滚轮继续作为画板容器滚动
- 不触发缩放
- 不拦截默认滚动行为

### Browser Protection

用户按住 `Ctrl` 滚轮时：

- 必须 `preventDefault()`
- 防止浏览器页面整体缩放
- 缩放只作用于像素画板本身

## Architecture

### Main Entry

主改动入口：

- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`

该组件已经负责：

- 画板显示
- 像素单元渲染
- 指针绘制交互
- 缩放按钮交互

因此本次应在该组件中直接接入 `wheel` 监听逻辑，而不是额外创建新的缩放容器层。

### State Reuse

继续复用已有状态：

- `state.canvasZoom`
- `dispatch({ type: 'set-canvas-zoom', zoom })`

不引入新的缩放状态字段，避免按钮缩放和滚轮缩放分叉。

### Behavior Contract

缩放计算应与当前按钮语义保持一致：

- 每次滚轮触发按固定步长增减
- 仍由 reducer 负责 clamp 到已有缩放范围

这样可以保证：

- 按钮与滚轮逻辑统一
- 测试只需验证输入方式不同，不必验证两套缩放规则

## Component-Level Design

### PixelEditorCanvas

在画板包裹区域增加 `onWheel` 处理：

- 若 `event.ctrlKey !== true`，直接返回
- 若 `event.ctrlKey === true`：
  - 调用 `event.preventDefault()`
  - 根据 `deltaY` 决定放大或缩小
  - 通过 `dispatch({ type: 'set-canvas-zoom', zoom: ... })` 更新显示倍率

推荐保持与地图绘制一致的方向：

- `deltaY < 0` -> 放大
- `deltaY > 0` -> 缩小

### Reducer

`pixel-editor-reducer.ts` 原则上不需要新增 action。

当前已有：

- `set-canvas-zoom`

并且 reducer 已负责缩放范围限制，因此这里优先复用，不重复实现边界判断。

## Testing

### Required Verification

- 画板按钮缩放仍然可用
- `Ctrl + 滚轮` 可以放大
- `Ctrl + 滚轮` 可以缩小
- 未按 `Ctrl` 的滚轮不会改变 `canvasZoom`
- 缩放后仍可对单个真实像素绘制
- 现有素材尺寸模板与地图占格回归不受影响

### Suggested Test Coverage

- 若当前测试体系便于覆盖事件处理，则为 `PixelEditorCanvas` 增加交互测试
- 若组件事件测试成本过高，则至少保证 reducer 相关缩放状态测试继续通过，并通过页面验证补足

## Risks

- `Ctrl + 滚轮` 若未阻止默认行为，浏览器可能整体缩放页面
- 若滚轮绑定位置不对，可能导致用户在画板外触发缩放
- 若未区分 `Ctrl` 与普通滚轮，画板区域正常滚动会被破坏
- 若滚轮与按钮使用不同步长或不同边界，缩放体验会不一致

## Acceptance Criteria

- 用户在素材库画板中按住 `Ctrl` 并滚动滚轮时，可以直接缩放画板
- 用户仍可通过按钮缩放画板
- 未按 `Ctrl` 时，滚轮保留默认滚动能力
- 缩放只影响画板显示倍率，不影响真实像素绘制与保存尺寸
- 页面重新打开后交互可正常使用，无立即报错
