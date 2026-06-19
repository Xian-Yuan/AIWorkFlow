# AIRPGWeb Tile 编辑器开源方案调研

日期：2026-05-31
项目：`g:\UEGameDevelopment\Project\AIRPGWeb`
状态：设计期调研结果，已筛选可吸收内容

## 1. 调研目标

本次调研不泛搜所有 tile 编辑器，而是只围绕当前需求的关键问题进行：

- 分层 tile 编辑器结构
- tile 数据模型与导出格式
- 墙/门/拐角的规则式绘制
- 多地图拼接与相邻地图可视参考
- 编辑器结果与运行时显示的桥接

## 2. 样本项目

### 2.1 `mapeditor/tiled`

- 仓库：<https://github.com/mapeditor/tiled>
- 参考重点：
  - 多层地图编辑
  - 任意属性系统
  - JSON/TMX 数据格式
  - World 文件与相邻地图显示
  - Terrain/Wang/Blob 规则式 tile 放置

### 2.2 `blurymind/tilemap-editor`

- 仓库：<https://github.com/blurymind/tilemap-editor>
- 参考重点：
  - 轻量 Web tile 编辑器 UI
  - 多 tilemap / 多 tileset
  - 工具栏、图层、撤销重做
  - 作为模块嵌入其他 Web 项目

### 2.3 `wareya/autotyler`

- 仓库：<https://github.com/wareya/autotyler>
- 参考重点：
  - autotile / bitmask 生成思路
  - 边缘、角、规则集合
  - 用小输入生成完整 tile 变体

### 2.4 `excaliburjs/excalibur-tiled`

- 仓库：<https://github.com/excaliburjs/excalibur-tiled>
- 参考重点：
  - 运行时读取 Tiled 地图数据
  - 资源化加载后直接加到场景
  - 解析与显示解耦

## 3. 关键发现

## 3.1 Tiled 最值得借鉴的不是界面，而是数据与世界组织

从 `README`、`worlds.rst`、`json-map-format.rst` 和 `terrain.rst` 可以确认：

- 地图、图层、tile、对象都可以带任意属性
- `.world` 文件用 `maps + 坐标` 定义一个更大的世界
- 编辑当前地图时，可以看到世界中的其他地图并快速切换
- 支持 `onlyShowAdjacentMaps`，说明“只显示相邻地图”本身就是成熟需求
- JSON 地图结构天然支持 `layers`、`properties`、`chunks`
- Terrain / Wang / Blob 的价值是：规则先定义，tile 再自动选，不靠人工硬拼

对本项目最有价值的吸收点：

- `MapAsset / WorldAsset / WorldPlacement` 的设计方向是对的
- “相邻地图只读幽灵层”是成熟且必要的，不是额外花哨功能
- 地图数据结构应尽量接近 `layers + properties + optional chunks`
- 墙门系统后续应预留向规则式 autotile 演进的接口

## 3.2 轻量 Web 编辑器最有价值的是交互骨架

`blurymind/tilemap-editor` 的 README 明确展示了这些能力：

- 多 tileset
- 多 tilemap
- 多图层与可见性
- 画笔、橡皮、桶填充、吸管、随机 tile
- 撤销/重做
- 响应式界面
- 可作为模块嵌入其他 Web 项目
- 数据导入导出与自定义 exporter/importer

对本项目最有价值的吸收点：

- 开发者模式中的编辑器完全可以按“嵌入式模块”设计
- 工具栏能力首版应至少做到画笔/橡皮/填充/吸管/保存
- `撤销/重做` 虽然不是当前阻塞项，但很适合在实施计划中尽早纳入
- 自定义 importer/exporter 思路适合后续做 AI 草稿导入和运行时桥接

不建议直接照搬的点：

- 它偏通用 tile 画布，不天然适合房屋拓扑/门位 socket 这类强约束编辑
- 它的数据示例更偏 tileset/tiles 图像导向，不足以直接承载我们要的房屋结构规则

## 3.3 autotile 真正重要的是“规则族”，不是某一套图片

`autotyler` 和 Tiled `terrain.rst` 共同说明：

- autotile 的本质是根据邻接关系和规则集选择最终 tile
- 常见规则集至少区分：
  - corner
  - edge
  - mixed
  - blob/47-tile
- 如果没有完整的拓扑族，墙和门迟早会断

对本项目最有价值的吸收点：

- 我们当前阶段不需要一开始上完整 47-tile 自动地形
- 但必须从第一版就把墙体 family 建完整：
  - 直墙
  - 角墙
  - T 字连接
  - 十字连接
  - 端头
  - 门位 socket
- 后续如果要自动修墙或自动补角，这套 family 才有扩展基础

## 3.4 运行时桥接必须是正式能力，不是调试脚本

`excalibur-tiled` 最值得借鉴的点不是具体引擎，而是：

- 地图先作为资源读取
- 解析所有数据
- 然后直接加到场景

对本项目最有价值的吸收点：

- 编辑器输出不该只是“一个给人看的 JSON”
- 必须有 `RuntimeMapLoader` 或同类桥接层
- 游戏运行时要明确读 `MapAsset / WorldAsset`
- 这样才能保证“编辑器看到的”和“游戏运行的”是一份东西

## 4. 推荐吸收清单

### 4.1 直接吸收

- Tiled 的 `world` 组织思想
- Tiled 的 `onlyShowAdjacentMaps` 思路
- Tiled 风格的 `layers + properties + optional chunks`
- 轻量编辑器的工具栏与图层控制交互
- importer/exporter 扩展点
- autotile 的 `规则族先于显示`
- 运行时资源加载桥接

### 4.2 有选择吸收

- Terrain / Wang / Blob
  - 当前只吸收思想，不直接完整照搬
- 无限地图 chunk
  - 当前先预留结构，不在首版做真正无限地图

### 4.3 不建议当前阶段吸收

- 完整 TMX/TMJ 兼容
- 全套 Tiled 复杂对象层编辑
- 全自动地形/全部门墙规则自动推导
- 过重的图像资源管线

## 5. 对当前设计文档的反哺

基于调研，当前主设计稿建议补强以下几点：

### 5.1 地图资产格式应向 Tiled JSON 思想靠拢

不是要兼容 Tiled，而是吸收这些结构概念：

- `layers`
- `properties`
- `chunks`
- `objects`
- `tilesets/visual presets`

这样未来不管是扩成大世界还是接 AI，都更稳。

### 5.2 世界拼接必须加入“相邻地图只读幽灵层”

这是调研后最明确应写成硬需求的一项。

不然：

- 路会接不上
- 墙会断边
- 跨图房屋/广场会错位

### 5.3 首版应考虑撤销/重做进入实施计划

虽然不一定写进 MVP 最小交付，但应进入计划，不宜长期缺失。

### 5.4 运行时桥接要单独成层

建议在主设计稿中明确一个组件：

- `RuntimeMapLoader`
- 或 `RuntimeWorldLoader`

不要把运行时读取逻辑散落进当前游戏显示组件。

### 5.5 AI 输出应优先结构化草稿

从调研看，最稳的方式仍然是：

- AI 生成结构化布局
- 编辑器渲染草稿层
- 用户确认后合入正式层

而不是让 AI 直接吐最终视觉结果覆盖地图。

## 6. 当前最终建议

对 `AIRPGWeb` 最合适的路线不是“照搬某一个开源项目”，而是：

- 借 `Tiled` 的世界/图层/数据组织
- 借轻量 Web 编辑器的交互骨架
- 借 autotile 的规则族思路
- 借运行时资源加载桥接模式

综合后形成本项目自己的方案：

- 游戏内开发者模式
- 分层 tile 编辑器
- 相邻地图只读参考
- MapAsset / WorldAsset / MapLink
- RuntimeMapLoader
- AI 草稿层与指定层美化

这条路线最符合当前项目阶段，也最能避免后续返工。
