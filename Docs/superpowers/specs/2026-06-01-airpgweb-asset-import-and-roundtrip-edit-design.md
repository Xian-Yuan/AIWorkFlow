# AIRPGWeb Asset Import And Roundtrip Edit Design

## Goal

为素材系统增加外部图片导入、导入后进入像素画板二次编辑、以及覆盖/另存为保存流程，使素材库成为真正可持续维护的资产入口。

## Background

用户希望：

- 不只是手绘素材
- 还可以把现有图片导入进来
- 导入后可以继续到像素画板中做二次编辑
- 编辑完成后既能覆盖原素材，也能另存为新素材

这要求素材系统支持“导入 -> 预览 -> 编辑 -> 保存回素材库”的完整闭环。

## Scope

### In Scope

- 外部图片导入
- 导入后保留原始尺寸
- 提供一键适配模板尺寸
- 从素材库打开素材进入像素画板编辑
- 保存时允许覆盖或另存为

### Out Of Scope

- 不在本设计中引入复杂图像处理管线
- 不自动进行高级 AI 去噪、描边或风格化

## Import Rules

### Default Size Policy

导入图片后默认：

- 保留原始像素尺寸

同时提供：

- 一键适配到模板尺寸

这满足用户确认的规则：

- 原图保真保留
- 同时兼容当前模板体系

### Source Tracking

导入素材应记录来源：

- `sourceType = imported`
- `sourceMeta` 可记录基本导入信息

### Thumbnail Generation

导入后立即生成缩略图，以便进入素材库卡片浏览。

## Editing Flow

### Open For Edit

用户在素材库中查看素材详情时，可以点击：

- `编辑`

此时系统跳转到 `绘制素材` 模块，并加载当前素材的像素数据。

### Roundtrip Behavior

无论素材来源于：

- 手绘
- 导入

都应进入同一套像素画板编辑器，而不是分成两套编辑逻辑。

## Save Behavior

保存时采用双选项：

- 覆盖原素材
- 另存为新素材

这与用户确认的 `C` 一致。

### Overwrite

覆盖原素材时：

- 保留原 `id`
- 更新像素数据
- 更新缩略图
- 更新 `updatedAt`

### Save As

另存为新素材时：

- 生成新 `id`
- 默认允许修改名字
- 复制当前像素内容与元数据
- 形成一份新素材

## Template Adaptation

### Why It Exists

导入图片未必天然落在项目模板尺寸上。

因此需要一个显式动作：

- `适配到模板尺寸`

### Behavior

执行该动作时：

- 不覆盖原始素材记录，除非用户显式选择覆盖保存
- 在当前编辑会话中生成适配结果
- 适配后用户仍可继续逐像素编辑

## UI Structure

### In Asset Library

素材详情中提供：

- 导入入口
- 编辑入口
- 基础元数据显示

### In Drawing Editor

绘制素材模块中提供：

- 当前素材信息
- 保存
- 覆盖原素材
- 另存为
- 尺寸适配操作

## Data Requirements

素材模型至少需要支持：

- 原始像素数据
- `sourceType`
- `sourceMeta`
- `thumbnail`
- `pixelWidth`
- `pixelHeight`
- `previewTileSize`
- `tags`
- `defaultTiling`

## Risks

- 如果导入后只保存缩略图而不保存真实像素数据，后续无法进入像素画板做精确修改
- 如果尺寸适配直接覆盖原数据而没有用户确认，容易破坏导入原图
- 如果覆盖保存和另存为不分开，素材管理会变得危险或混乱

## Acceptance Criteria

- 素材库支持导入外部图片
- 导入后默认保留原始尺寸
- 支持一键适配到模板尺寸
- 素材可从素材库进入像素画板做二次编辑
- 保存时支持覆盖原素材或另存为新素材
- 导入素材和手绘素材进入同一套统一资产体系
