# AIRPGWeb Asset Library Browser Design

## Goal

把当前“边编辑边浏览”的素材页面拆出真正的 `素材库` 模块，使其只承担素材浏览与管理职责：

- 显示缩略图和名字
- 显示 tags 与尺寸
- 按名字、tag、尺寸搜索
- 点击素材放大预览
- 从素材库进入二次编辑

## Background

现有 `AssetLibraryScreen` 更接近“素材编辑器”，而不是真正素材库。

用户需要的是：

- 一个只看素材的浏览模块
- 能快速搜名字、搜 tag、按尺寸过滤
- 能看放大预览
- 能从浏览态打开素材进入编辑器

因此该模块必须从编辑流程中独立出来。

## Scope

### In Scope

- 新建真正的 `素材库` 浏览模块
- 列表化素材卡片展示
- 搜索与过滤
- 详情预览
- 跳转到编辑模块

### Out Of Scope

- 不在本设计中直接实现外部图片解析细节
- 不在本设计中承担像素画板的主编辑职责

## Module Responsibility

素材库模块只负责：

- 读素材
- 展素材
- 找素材
- 看素材
- 打开素材去编辑

素材库模块不负责：

- 主像素画板绘制
- 直接承担所有保存状态管理

## Main Views

### View 1: Browser List

默认主界面是素材卡片列表。

每个素材卡片应显示：

- 缩略图
- 名字
- 尺寸
- tags
- 来源类型

### View 2: Detail Preview

点击某个素材后进入详情预览。

详情中应显示：

- 放大缩略图或像素预览
- 名字
- tags
- 真实尺寸
- 模板尺寸
- 默认平铺状态
- 来源

并提供操作：

- 编辑
- 导入到绘制素材继续编辑

## Search And Filter Model

### Name Search

- 支持模糊匹配名字

### Tag Search

- 支持按 tag 匹配
- 后续可扩展为多 tag 组合

### Size Filter

- 按真实像素尺寸过滤
- 例如 `16x16`、`32x32`

### Combined Filtering

搜索条件允许组合生效：

- 名字 + tag
- tag + 尺寸
- 名字 + 尺寸

## Card Data Model

素材卡片至少依赖以下字段：

- `id`
- `name`
- `thumbnail`
- `pixelWidth`
- `pixelHeight`
- `tags`
- `updatedAt`
- `sourceType`

## UI Rules

### Browser Layout

素材库应采用卡片浏览布局，而不是左侧简单文本列表。

推荐视觉结构：

- 顶部搜索区
- 中部卡片网格
- 右侧或弹层详情预览

### Search Area

搜索区应至少包含：

- 名字搜索输入框
- tag 搜索输入框
- 尺寸过滤入口

### Empty States

素材库必须提供清晰空状态：

- 尚无素材
- 搜索无结果

## Navigation Rules

从开发模式主页进入：

- `素材库`

在素材库中：

- 点击素材卡片 -> 打开详情
- 点击编辑 -> 跳转到 `绘制素材`

## Repository Requirements

素材仓库接口需要支持：

- `list`
- `get`
- `save`
- 基于名字、tag、尺寸的筛选查询

即使底层仍是 Dexie，也不应把查询逻辑散落在页面组件里。

## Risks

- 如果浏览态仍和编辑态共用同一个大页面，搜索状态与编辑状态会互相干扰
- 如果 tags 只做成展示字段而不进入仓库查询接口，后续搜索会退化成前端硬筛
- 如果详情预览只用缩略图，不保留尺寸与元数据展示，用户很难管理素材

## Acceptance Criteria

- 开发模式存在独立的 `素材库` 浏览模块
- 素材库默认只展示已保存素材
- 每个素材显示缩略图、名字、尺寸、tags
- 支持按名字、tag、尺寸搜索
- 点击素材可看放大预览
- 可从素材库进入二次编辑流程
