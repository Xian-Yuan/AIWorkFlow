# Project Truth Source

## 目标

本文件是 AI 开发时的项目级真相源，用来统一目录、命名、挂载点、扩展方式和禁止修改区。

## 当前工作区

- 根目录：`g:\UEGameDevelopment`
- 主 skill 目录：`g:\UEGameDevelopment\.trae\skills`
- 根文档目录：`g:\UEGameDevelopment\Docs`
- 项目示例与项目内文档：`g:\UEGameDevelopment\MLCase`

## 默认开发目标

- 引擎版本：UE5.7
- 项目方向：单机游戏优先
- 开发范式：Lyra + GAS + AI 驱动
- 平台：Windows

## 代码与内容扩展原则

- 优先通过 `GameFeature Plugin` 扩展 Lyra
- 优先通过 `Experience -> PawnData -> InputConfig -> AbilitySet` 串接角色玩法
- 优先数据驱动，不优先硬编码资源路径
- 优先复用现有项目实现和模板，避免重复造轮子

## 文档真相源

AI 在实现前应优先读取：

- `Docs/index.md`
- `Docs/CodeTemplates/*`
- `Docs/APIRef/*`
- `Docs/Lyra/*`
- `Docs/GAS/*`
- `Docs/AI/*`
- `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

## 项目内已知模式

- `MLCase` 已存在 `StateTreeAIController` 和自定义 `StateTreeTask`
- `MLCase` 已存在 `AAIController` 驱动的单位移动模式
- `MLCase` 已沉淀项目错误预防文档，修复通用问题时应优先回写该文档

## 命名与目录规则

- 所有新增文件使用英文命名
- 技能、能力、装备、武器、AI、配置建议按功能目录分层
- 文档与代码命名要稳定，避免频繁重命名导致资产重定向成本增加

## AI 操作授权（核心原则）

### 全权放行（无需确认，直接执行）

以下操作 AI 可直接执行，**不打断用户**：

- 读文件、搜索代码、新建/编辑文件、运行命令
- git status / diff / log / add / commit / stash / branch / checkout / merge / rebase
- 编译、运行 PIE、打包
- 修改 Lyra 核心源码、修改 .uproject / .uplugin
- 修改引擎插件源码（如确有必要）
- 删除临时文件（Intermediate/、Saved/、DerivedDataCache/）

### 必须确认（每次停止并询问）

以下操作 AI **必须先获得用户明确同意**：

- **删除任何文件**（Source/、Content/、Docs/、资产目录等 — 无一例外）
- **回退 Git 版本**（git reset --hard、git revert、删除 commit、force push）
- git push 到远程
- 修改 git config

## Git 仓库隔离原则

- **根目录 `G:\UEGameDevelopment\.git`**：只管理 opencode 工具链文件（`.opencode/`、`.trae/`、`Docs/` 等），**不追踪任何项目代码**
- **`Project/<项目名>/.git`**：各项目独立仓库，管理各自的 `.uproject`、`Source/`、`Content/`、`Config/` 等
- 根目录 `.gitignore` 永久排除 `Project/` 目录
- 新增 UE 项目时，在新项目根目录独立 `git init`，不纳入根仓库

## 开发约束

- 默认单机游戏，不引入网络复制、RPC、多人预测逻辑

## AI 交付最低要求

- 给出变更文件列表
- 标出主挂载点和依赖模块
- 提供数据资产或蓝图配置步骤
- 提供至少一轮编译/运行时验证建议
