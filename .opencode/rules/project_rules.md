# OpenCode 项目规则（UE5.7 单机游戏）

> **真相源**: 本文件是 `.trae/rules/project_rules.md` 的 OpenCode 适配版。
> 与 Trae 工作流共享引擎/环境/编码规范/禁止事项，但工作流机制不同。

---

## 引擎与环境

- 引擎版本：UE5.7
- 平台：Windows
- 项目方向：单机游戏（严格禁止网络复制/RPC/DS）
- 开发范式：Lyra + GAS + AI 驱动
- 编译工具：UnrealBuildTool

## 核心原则

- 单机游戏注重本地性能优化
- 严格禁止使用任何网络复制功能
- 优先使用 UE 提供的功能和方案，避免重复造轮子
- 避免重复实现项目中已经存在的功能
- 优先通过 GameFeature Plugin 扩展 Lyra
- 优先通过 Experience → PawnData → InputConfig → AbilitySet 串接角色玩法
- 优先数据驱动，不优先硬编码资源路径

## OpenCode 工作流（Agent 驱动）

OpenCode 使用 **Agent 定义文件**（`.opencode/agents/*.md`）驱动工作流，而非脚本状态机。

### 入口与阶段流转

```
用户需求
   ↓
ue-project-router (primary agent)
  ├─ 阶段 0: 需求理解与澄清
  ├─ 阶段 1: 方案搜索（项目内 + 网络）
  ├─ 阶段 2: 任务拆分（复杂系统必须）
  ├─ 阶段 3: 路由决策（主 skill + 协作模式）
  └─ 阶段 4: 上下文管理（文档懒加载 + subagent 隔离）
   ↓
Implement → Review → Verify (通过 subagent 协作)
```

### 模型分层策略（Pro + Flash）

> 详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md`

采用 DeepSeek V4 Pro（深度推理）+ V4 Flash（快速执行）分层使用：

| 阶段 | 推荐模型 | 原因 |
|------|---------|------|
| Plan（Router） | **Pro** | 深度推理、架构决策、边界条件识别 |
| Implement | **Flash** | 执行密集型，单文件编码质量与 Pro 差距极小 |
| Review + Verify | **Pro**（同一会话） | 审查+编译+修复+验收，无需切换模型 |

自动化：每阶段结束运行 `task-handoff.ps1 <task-name>` 自动生成交接模板。

### 双 Agent 体系

OpenCode 采用 **Plan + Implement 双 Agent 架构**。Plan 负责"想清楚做什么"，Implement 负责"把它做出来"。

| Agent | 类型 | 职责 | 定义文件 |
|-------|------|------|---------|
| `金璃小天才` | **primary** | 入口路由、需求澄清、设计文档检索、隐性需求推导、依赖链推导、成熟方案搜索、任务拆分、spec 生成 | `.opencode/agents/金璃小天才.md` |
| `金璃好帮手` | subagent | 按 spec 实现代码、编译验证、重复检测、对照 spec 自检。通过动态加载 skill 切换领域知识（UE5/Web） | `.opencode/agents/金璃好帮手.md` |

**设计原则：**
- 不要让 agent 的数量超过问题本身需要的认知边界数
- Plan 阶段用 Pro 模型（深度推理），Implement 阶段用 Flash 模型（快速执行）
- 金璃好帮手 合并了原 ue-lyra-gas-implementer、web-implementer、ue-ai-validator、code-quality-reviewer 的职责
- character-designer 移出开发流水线，保留 skill 但不再作为 OpenCode agent
- 领域知识通过 skill 动态加载，不通过 agent 静态拆分

### Skill 规则

- Skill 定义在 `.opencode/skills/<name>/SKILL.md`（部分 symlink 到 `.trae/skills/<name>/`）
- 通过 `skill` 工具加载，**禁止跳过 skill 加载直接实现**
- 主 skill 选一个，次 skill 选 0-1 个，不加载无关 skill

### 任务文件结构

任务以 `.opencode/tasks/<task-name>/` 目录组织：

```
.opencode/tasks/<task-name>/
├── .task.yaml        # 任务状态（phase, project_type, status）
├── routing.md        # 路由决策（需求理解 + 方案 + 路由）
├── spec.md           # 行为规范（GIVEN/WHEN/THEN Scenario）
├── tasks.md          # 任务清单（按依赖图排序）
└── analysis.md       # 依赖链推导 + 隐式需求
```

## Harness Engineering 核心原则

> 来源：OpenAI 2026.2 [*Harness Engineering*](https://openai.com/index/harness-engineering/)

| # | 原则 | OpenCode 落地方式 |
|---|------|-----------------|
| 1 | **Humans steer, agents execute** | Plan 阶段由 Router 输出 routing.md + tasks.md，用户确认后进入实现 |
| 2 | **Repository knowledge is system of record** | `.opencode/` + `Docs/AI/` + `CLAUDE.md` 是唯一真相源 |
| 3 | **AGENTS.md is a table of contents, not an encyclopedia** | `CLAUDE.md` 精简为目录 → 指向 `.opencode/agents/` 和 `Docs/AI/` |
| 4 | **Enforce architecture mechanically** | Review 阶段 code-quality-reviewer 做机械化检查 |
| 5 | **Agent legibility is the goal** | 中文注释优先、命名清晰、文件结构扁平 |
| 6 | **Fewer tools, more expressiveness** | 主 skill 选一个 + 若干次 skill，不堆砌 |
| 7 | **Progressive disclosure** | 先加载路由摘要 → 按需读取深层文档 |
| 8 | **Corrections are cheap, waiting is expensive** | Review 不阻塞流转，Verify 阶段集中修复 |

## 协作顺序

```text
用户输入需求
  → ue-project-router (路由 + 计划)
  → 用户确认 routing.md + tasks.md
  → ue-project-router 用 task 工具 spawn subagent(s)
     ├─ UE5: ue-lyra-gas-implementer (+ ue-ai-validator 并行)
     ├─ Web: web-implementer → 加载 web-fullstack/ui-ux-pro-max/webapp-testing
     └─ Other: general subagent
  → code-quality-reviewer (Review + Verify)
  → 用户确认结论
```

## UE5 编码规范

### 宏与反射
```cpp
UCLASS(BlueprintType, Blueprintable)
class GAME_API UMyClass : public UObject
{
    GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable, Category = "Game")
    void MyFunction();

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Config")
    float MyValue = 1.0f;
};
```

### 头文件包含顺序
1. 当前模块的 PCH 或核心头文件
2. 引擎公共头文件（CoreMinimal.h）
3. 项目内其他模块头文件
4. 第三方库头文件

### 智能指针规范
- UObject 派生类：使用 TObjectPtr（UPROPERTY）
- 非 UObject 资源：使用 TSharedPtr / TSharedRef
- 跨模块弱引用：使用 TWeakObjectPtr
- 唯一所有权：使用 TUniquePtr

### 内存与性能
- 缓存常用子系统引用，避免重复 GetWorld()->GetSubsystem()
- 使用对象池减少运行时分配
- 批量操作合并，减少函数调用开销

## 编译验证

```powershell
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## 禁止事项（OpenCode 强制）

- ❌ 使用网络复制功能（Replicated/ReplicatedUsing/OnRep）
- ❌ 使用 RPC（Server/Client/NetMulticast）
- ❌ 直接修改引擎代码
- ❌ 跳过编译验证直接交付
- ❌ 不使用 `task` 工具 spawn subagent 而手动模拟其职责
- ❌ 使用已弃用的 UE5 API
- ❌ 在阶段一中修改代码
- ❌ 修改 `.trae/` 目录中的文件（独立工作流互不干扰）

## 操作授权规则

**无需确认，直接执行**：
- 文件读写、搜索、编辑、创建、移动/重命名
- 命令执行（编译、脚本、git status/diff/log/add/commit/stash）
- 检索（网页搜索、文档查询）
- 协作（task 子Agent、skill）

**需用户同意**：
- 文件删除（任何形式的删除）
- 版本回退（reset --hard / revert / push --force / commit --amend）
- 网络推送（git push）

**禁止**：
- 修改 `.opencode/` 和 `.git/` 目录中非本项目文件
- 修改引擎源码
- 跳过 git hooks

## 真相源优先级

所有 Agent 按以下顺序取证：
1. `Docs/AI/01-AI-Development-Playbook.md`
2. `Docs/AI/02-Project-Truth-Source.md`
3. `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
4. `Docs/AI/11-Skill-Routing-Workflow.md`
5. `Docs/AI/12-MultiAgent-Workflow.md`
6. 当前任务最相关的 `Docs/AI/*`
7. `.opencode/rules/project_rules.md`（本文件）
8. `.opencode/agents/<agent-name>.md`（对应 Agent 定义）
9. `Docs/CodeTemplates/*`
10. `Docs/APIRef/*`


## 文件放置规则（强制）

**所有工具、依赖、临时文件必须放在 G 盘，禁止写入 C 盘。**

- 第三方工具: `G:\UEGameDevelopment\.tools\`
- 临时下载/解压: `G:\UEGameDevelopment\.tmp\`（用后清理）
- 项目代码: `G:\UEGameDevelopment\Project\`
- 脚本: `G:\UEGameDevelopment\.trae\scripts\`
- 文档: `G:\UEGameDevelopment\Docs\`

**禁止**: `C:\tmp\`, `C:\Users\...\.codex\tools\`, `C:\Users\...\AppData\`（Codex 自身配置除外）
