# AIRPGWeb Pixel Precise Paint And Grid Design

## Goal

为 `AIRPGWeb` 素材库像素画板补齐真正可用的像素级绘制能力，并统一以下交互语义：

- `Ctrl + 滚轮` 作为主缩放方式
- 单像素细网格线始终显示
- 画笔粗细使用 `1-8` 的 `NxN` 正方形像素笔刷

本次设计的目标不是重写整套画板架构，而是在当前素材库画板基础上补足精细编辑能力，让用户可以稳定识别、选择并修改单个真实像素。

## Background

当前素材库画板存在三个直接问题：

1. `Ctrl + 滚轮` 缩放未按预期生效
2. 单像素边界不够清晰，用户无法稳定辨认每一个真实像素
3. 画笔粗细只覆盖有限范围，无法满足 `1-8` 的像素级块绘制需求

现有画板已经采用“每个像素一个交互单元”的实现方式，适合在当前阶段做增量修复，而不是立即切换到全新的 `canvas` 渲染架构。

## Scope

### In Scope

- 修正素材库画板 `Ctrl + 滚轮` 缩放交互
- 保留现有缩放按钮作为备用入口
- 始终显示单像素细网格线
- 保留并强化模板分组粗网格线
- 将画笔粗细扩展为 `1-8`
- 将 `1-8` 明确定义为 `NxN` 正方形像素笔刷
- 让笔刷和橡皮都遵循同样的 `NxN` 规则

### Out Of Scope

- 不重写为单一 `canvas` 渲染器
- 不增加平移、惯性缩放、双指缩放
- 不实现围绕鼠标中心的缩放定位
- 不新增悬浮笔刷预览层
- 不修改地图编辑器现有缩放体系

## Selected Approach

采用“保留当前 DOM 像素格实现，补强交互与显示语义”的方案。

原因如下：

- 当前问题集中在交互失效和视觉辨识不足，不需要为了这轮问题重写底层
- 每个像素已有独立交互单元，天然适合落实单像素级点击与拖拽绘制
- 在当前模板范围 `8x8 / 16x16 / 24x24 / 32x32` 下，DOM 数量仍可接受
- 该方案改动集中、验证路径清晰、回归风险最低

## User Experience

### Zoom

素材库画板区域支持与地图绘制一致的主缩放方式：

- 按住 `Ctrl`
- 滚动鼠标滚轮
- 向上滚动时放大
- 向下滚动时缩小

同时保留现有：

- `缩小画板`
- `放大画板`

按钮与滚轮必须共用同一个 `canvasZoom` 状态。

未按 `Ctrl` 时：

- 不触发缩放
- 保留画板容器默认滚动行为

按住 `Ctrl` 触发滚轮缩放时：

- 必须阻止浏览器默认页面缩放
- 缩放只影响像素画板本身

### Pixel Grid

画板必须始终显示两层视觉信息：

1. 单像素细网格线
2. 模板分组粗网格线

其中：

- 单像素细网格线用于标识每一个真实像素单元
- 模板分组粗网格线用于标识当前素材尺寸模板的分组边界

视觉要求：

- 细网格线更浅、更细
- 粗网格线更明显、更重
- 两者同时存在时不能互相覆盖到难以辨认

### Brush Size

画笔粗细采用固定规则：

- 范围为 `1-8`
- `1` 表示一次绘制 `1x1`
- `2` 表示一次绘制 `2x2`
- ...
- `8` 表示一次绘制 `8x8`

该规则同样适用于：

- 笔刷
- 橡皮

边界规则：

- 如果 `NxN` 区块超出画板边界，只绘制落在有效范围内的部分
- 不报错，不扩展画板

### Pixel Precision

用户将能够通过以下方式进行像素级修改：

- `brushSize = 1` 时，点击单个像素仅修改该一个真实像素
- `brushSize = 1` 时，拖拽连续修改经过的单像素路径
- 细网格线始终可见，帮助用户准确识别目标像素

## Architecture

### Main Components

主改动集中在以下文件：

- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css`

### PixelEditorCanvas

职责：

- 承载缩放交互
- 呈现像素格
- 呈现单像素细网格与模板粗网格
- 响应点击/拖拽绘制

本次需要确保：

- `Ctrl + 滚轮` 真正绑定到正确的滚动容器
- 普通滚轮继续让容器滚动
- 像素格样式明确区分“细网格”和“粗分组线”

### Pixel Editor State

继续复用现有缩放状态：

- `canvasZoom`

继续复用现有动作：

- `set-canvas-zoom`

需要扩展的状态：

- `brushSize` 从当前有限范围扩为 `1-8`

### Paint Model

绘制模型保持当前“按真实像素单元写入”的方向，但需要明确约束：

- 所有绘制命中都以真实像素坐标为准
- 画笔粗细只是覆盖范围变化，不改变命中坐标语义
- `brushSize = N` 时使用 `NxN` 正方形覆盖

## Data And State Rules

### Brush Size Type

`brushSize` 应支持：

- `1 | 2 | 3 | 4 | 5 | 6 | 7 | 8`

属性面板的 UI 也必须与该范围一致。

### Zoom Limits

继续沿用现有缩放边界限制机制，不额外引入第二套边界规则。

目标是保证：

- 按钮缩放
- `Ctrl + 滚轮` 缩放

都走同一个 reducer 约束路径。

## Interaction Details

### Brush

- 点击：立即对目标像素执行 `NxN` 绘制
- 拖拽：沿拖拽路径持续执行 `NxN` 绘制

### Eraser

- 点击：对目标像素执行 `NxN` 擦除
- 拖拽：沿拖拽路径持续执行 `NxN` 擦除

### Fill

填充工具仍按连通区域工作，不受 `brushSize` 影响。

### Rectangle Tools

矩形相关工具继续沿用现有逻辑，不在本次设计中改变它们的语义，只保证：

- 单像素网格显示增强后仍然可正常使用

## Visual Design Rules

### Fine Grid

- 用于每个真实像素之间的边界
- 颜色更浅
- 线条更细
- 必须始终可见

### Group Grid

- 用于模板分组边界
- 明显强于单像素细网格
- 不取消当前分组边界逻辑

### Readability Priority

视觉优先级如下：

1. 像素填充颜色
2. 模板分组粗线
3. 单像素细线

这样可以保证：

- 已绘制像素不会被网格压得看不清
- 分组结构仍然明显
- 单像素边界始终可辨认

## Testing Strategy

### Required Automated Coverage

- `Ctrl + 滚轮` 的缩放换算逻辑
- `brushSize` 支持 `1-8`
- `brushSize = 1` 时只修改单个像素
- `brushSize = 8` 时按边界裁切，不越界
- 橡皮同样遵循 `NxN` 规则

### Required Manual Verification

在页面中确认：

1. 按住 `Ctrl + 滚轮` 时画板可以缩放
2. 未按 `Ctrl` 时滚轮保持滚动容器行为
3. 单像素细网格始终可见
4. `brushSize = 1` 时可以稳定修改单个像素
5. `brushSize = 8` 时一次绘制 `8x8` 像素块
6. 橡皮在 `1-8` 下与笔刷一致

## Risks

- 如果滚轮事件绑定层级不对，`Ctrl + 滚轮` 仍可能不生效
- 如果细网格和粗网格样式权重处理不好，视觉上会显得过乱
- 若 `brushSize` 类型只在 UI 扩展而 reducer 未同步，运行时会出现行为与显示不一致
- 若拖拽绘制仍受当前矩形逻辑影响，用户可能感觉不是连续单像素绘制

## Acceptance Criteria

- 素材库画板支持 `Ctrl + 滚轮` 缩放
- 缩放按钮继续可用
- 未按 `Ctrl` 时滚轮不触发缩放
- 单像素细网格始终显示
- 模板分组粗网格继续显示
- `brushSize` 支持 `1-8`
- `brushSize = 1` 时可以进行真正的单像素绘制
- `brushSize = 8` 时按 `8x8` 正方形像素块绘制
- 页面重开后功能可访问且无立即报错
