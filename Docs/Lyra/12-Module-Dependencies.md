# Module Dependencies（模块依赖）

说明（English + 中文解释）：This document declares module/plugin dependencies and compile order notes for our UE5.7 single-player project（本文件用于声明 UE5.7 单机项目的模块/插件依赖与编译顺序注意事项）。

## 1. Core Modules（核心模块）
- LyraGame（运行时核心，含 GAS 集成）
- LyraEditor（编辑器扩展，仅编辑器目标）

## 2. Plugins（插件）
- EnhancedInput（输入系统）
- UIExtension（UI 框架扩展）
- CommonGame / CommonUser（通用框架组件，遵循单机约束）
- GameFeatures（按需模块化，单机场景谨慎启用）

## 3. Dependency Rules（依赖规则）
- 禁止循环依赖（No circular deps）：模块/插件只依赖“下游”层
- 单机约束：不引入网络复制相关模块；不使用 Replication/RPC/Replays
- 共享数据：统一通过 DataTable/Config/Save 层实现，避免跨模块硬引用资产

## 4. Compile Order Notes（编译顺序）
- 按引擎与插件 → 游戏模块的顺序编译
- 引入新插件后，同步更新本文件，并在 UE5_7_Compile_Guide.md 中记录编译验证步骤
- 使用前向声明降低编译开销；公共头文件避免包含实现细节

## 5. Cross References（交叉引用）
- Architecture_Overview.md（整体架构）
- UE5_7_Compile_Guide.md（编译指引）
- DataTable_Standards.md（数据表标准）
- GameplayTag_Governance.md（标签治理）

