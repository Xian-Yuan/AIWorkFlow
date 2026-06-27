# Spec

## Scenario 1: Open Developer Mode

Given 用户打开主界面  
When 点击 `开发者模式`  
Then 进入开发者模式首页  
And 能看到 `地图绘制` 模块入口  
And 能返回主界面

## Scenario 2: Open Map Editor

Given 用户位于开发者模式首页  
When 点击 `地图绘制`  
Then 进入地图编辑器  
And 显示工具栏、图层列表、画布、当前层 tile palette  
And 默认载入一张可编辑的新地图

## Scenario 3: Paint By Active Layer

Given 用户进入地图编辑器  
When 切换到某一图层并选择对应 tile  
And 在画布点击某个格子  
Then 仅当前图层对应 cell 被写入  
And 其他图层同坐标不应被污染  
And palette 只显示当前图层允许绘制的 tile

## Scenario 4: Undo And Redo

Given 用户已经进行至少一次绘制  
When 点击撤销  
Then 最近一次绘制结果被回退  
When 再点击重做  
Then 刚才回退的结果被恢复

## Scenario 5: Save And Reopen Map

Given 用户在地图编辑器中修改了地图  
When 点击保存  
Then 地图以 `MapAsset` 形式持久化到本地数据库  
When 之后从地图列表重新打开  
Then 之前保存的层数据仍然存在

## Scenario 6: Adjacent Ghost Preview

Given 世界中存在多个相邻地图 placement  
When 用户编辑当前地图  
Then 画布可显示与当前地图直接相邻的只读幽灵层参考  
And 幽灵层不可直接编辑  
And 不相邻地图不应显示

## Scenario 7: Publish Runtime Map

Given 用户保存了一张地图  
When 将其设为运行时地图  
Then 运行时桥接可把 `MapAsset` 转成游戏使用的显示结构  
And 进入游戏时优先显示已发布地图

## Scenario 8: AI Draft Assist

Given 用户在 AI 辅助面板输入房屋草稿需求  
When 点击生成草稿  
Then 系统返回结构化布局草稿  
And 草稿至少包含房间区域、门位和建议说明  
And 草稿默认作为建议/预览数据，不直接覆盖正式层

## Scenario 9: Pixel Asset Size Template Defines Real Footprint

Given 用户在素材库新建或编辑一个像素素材  
When 选择 `8x8 / 16x16 / 24x24 / 32x32` 其中一个尺寸模板并保存  
Then 保存后的素材真实 `pixelWidth / pixelHeight` 与所选模板一致  
And 地图编辑器调色板读取到的素材占用范围与该真实尺寸一致  
And 不再把预览规格误当作地图占格尺寸

## Scenario 10: Canvas Zoom Does Not Change Pixel Semantics

Given 用户在素材库绘制模式中放大或缩小画板  
When 在画板上编辑任意像素  
Then 每次操作仍只作用于真实像素网格中的目标像素  
And 缩放只改变视图大小  
And 不改变素材真实尺寸或地图放置占格

## Scenario 11: Shared Tool Behavior Across Asset Library And Map Editor

Given 用户在素材库和地图编辑器之间切换  
When 使用画笔、橡皮、吸管及其子工具  
Then 两边工具状态组织与交互规则保持一致  
And 以地图绘制当前工具行为为准  
And 不出现一边可矩形填充、另一边没有对应能力的漂移

## Scenario 12: Larger Pixel Board In Asset Library

Given 用户在素材库中选择 `16x16`、`24x24` 或 `32x32` 素材模板  
When 进入绘制画板  
Then 画板显示对应的真实像素网格数量  
And 用户可在更大的画板中进行单像素精细绘制  
And 画板布局不会因为固定 `8x8` 网格而限制素材实际尺寸
