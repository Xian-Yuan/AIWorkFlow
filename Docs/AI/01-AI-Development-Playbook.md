---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-01-ai-development-playbook-343d
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.01-ai-development-playbook.343d

---

# AI Development Playbook

## 目标

本手册定义 AI 在本项目中的标准执行流程，避免直接跳到写代码，导致架构漂移、函数误用、配置遗漏或资产链断裂。

## 强制工作流

### Step 1: 读取上下文

每次开始任务前，至少确认以下内容：

- 用户需求目标
- 当前引擎版本与项目形态
- 是否属于 `Lyra / GAS / AI / Input / SaveGame / UI`
- 是否已有可复用模板、现成类或插件实现

### Step 2: 读取固定文档

优先顺序如下：

1. `Docs/AI/02-Project-Truth-Source.md`
2. `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
3. `Docs/CodeTemplates/*`
4. `Docs/APIRef/*`
5. `Docs/Lyra/*`
6. `Docs/GAS/*`
7. `Docs/AI/04-Asset-Checklists.md`
8. `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
9. `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

### Step 3: 输出设计结果

在改代码前，先输出以下内容：

- 需求映射
- 1-3 个方案
- 文件变更清单
- 依赖模块变化
- 数据资产与蓝图配置清单
- 验证清单

### Step 4: 落地实现

实现顺序默认如下：

1. 数据资产与 GameplayTag
2. 最小 C++ 类对
3. 配置文件与模块依赖
4. 蓝图/编辑器配置步骤
5. 调试与回归验证
6. 文档更新

### Step 5: 自检

每次交付前必须检查：

- 是否复用现有类或模板
- 是否错误新增网络复制或 RPC
- 是否遗漏 `Build.cs` / `.uplugin` / 资源接线
- 是否遗漏 Blueprint 配置步骤
- 是否引用了不存在的 API 或错误函数名
- 是否更新了相关文档

## 输出契约

AI 的最终交付至少包含：

- 变更文件列表
- 关键类与挂载点
- 数据资产配置步骤
- 编译验证项
- 运行时验证项
- 回归风险


## 文件放置规则（强制）

**所有工具、依赖、临时文件必须放在 G 盘，禁止写入 C 盘。**

| 目录 | 用途 | 示例 |
|------|------|------|
| `G:\UEGameDevelopment\.tools\` | 第三方工具和可执行文件 | abtop.exe, context-mode, bolt-diy |
| `G:\UEGameDevelopment\Project\` | UE5 项目（含插件） | LyraStarterGame, MLCase |
| `G:\UEGameDevelopment\.agents\` | Agent Skills | task-orchestrator, anti-degradation |
| `G:\UEGameDevelopment\.trae\` | 脚本和任务状态 | verify.ps1, abtop.ps1, bolt-diy.ps1 |
| `G:\UEGameDevelopment\Docs\` | 文档和 Memory | AI/, Memory/ |

### 禁止写入 C 盘的位置

- `C:\tmp\` — 禁止。用 `G:\UEGameDevelopment\.tmp\` 替代
- `C:\Users\<user>\.codex\tools\` — 禁止。用 `G:\UEGameDevelopment\.tools\` 替代
- `C:\Users\<user>\AppData\` — 禁止（除非是 Codex/系统自身配置）

### 例外

- `~/.codex/config.toml` — Codex 自身配置，允许
- `~/.codex/skills/` — Codex 自身 Skills 目录，允许
- `~/.codex/plugins/` — Codex 自身插件缓存，允许
- pip/npm/pnpm 全局安装的包 — 允许（包管理器自身管理）

### 下载和克隆规则

1. 下载源码/zip 到 `G:\UEGameDevelopment\.tmp\` 作为暂存区
2. 解压、处理后将最终文件放入 `G:\UEGameDevelopment\.tools\` 或项目目录
3. 完成后清理 `G:\UEGameDevelopment\.tmp\`
4. 永远不要直接 clone 或下载到 C 盘

## 禁止事项

- 未分析现有实现就重写系统
- 未查 APIRef 就猜函数名
- 把多人网络方案当成单机默认方案
- 不说明蓝图/资产接线步骤
- 修改插件后不更新插件文档
- **禁止删除任何文件** — 删除前必须获得用户明确同意
- **禁止回退 Git 版本** — reset --hard / revert / commit --amend 等操作必须获得用户明确同意
- **禁止 git push** — 推送远程前必须获得用户明确同意
- 除上述三项外，所有操作全权放行，不打断用户
- **禁止向 C 盘写入任何文件** — 工具、依赖、临时文件、下载内容一律放在 G 盘（`G:\UEGameDevelopment\.tools\`、`G:\UEGameDevelopment\.tmp\` 等）
