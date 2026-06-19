# UE5.7 单机游戏项目规则

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

## Harness Engineering 核心原则（Agent 驾驭工程）

> 来源：OpenAI 2026.2 [*Harness Engineering*](https://openai.com/index/harness-engineering/)
> 关键数据：3人团队5个月100万行生产代码、人均日合并3.5个PR、Agent单次运行最长6小时

这些原则适用于**所有项目类型**（UE5 / Web / Other），是 Agent 工作流设计的基础：

| # | 原则 | 含义 | 本项目落地方式 |
|---|------|------|--------------|
| 1 | **Humans steer, agents execute** | 人类设计环境、指定意图，Agent 执行代码 | Plan 阶段由人类确认 routing + tasks，Implement 阶段 Agent 自主执行 |
| 2 | **Repository knowledge is system of record** | 仓库外知识对 Agent 不可见——Slack、口头讨论、Google Docs 都不存在 | `.trae/` 规则文件 + `Docs/AI/` + `CLAUDE.md` 是唯一真相源 |
| 3 | **AGENTS.md is a table of contents, not an encyclopedia** | ~100行目录指向深层文档，不把所有规则塞一个文件 | `CLAUDE.md` 精简为目录 → 指向 `.trae/rules/` 和 `Docs/AI/` |
| 4 | **Enforce architecture mechanically** | linter + structural test + CI 强制执行架构约束，不靠人工代码审查 | Review 阶段前运行 `task-guard.ps1` 机械化检查（见 Phase 3） |
| 5 | **Agent legibility is the goal** | 代码优化目标：Agent 可读性 > 人类可读性 | 注释用中文（Agent 理解优先级）、命名清晰、文件结构扁平 |
| 6 | **Fewer tools, more expressiveness** | 少而精的工具 > 多而杂的工具。渐进披露 > 一次性全加载 | Skill 路由表保持精炼（UE5: 10个 / Web: 6个 / Other: 3个） |
| 7 | **Progressive disclosure** | Agent 递归发现上下文，不是一次性全塞入 | 先加载 CLAUDE.md 目录 → 按需读取深层 Docs/AI/ 文档 |
| 8 | **Corrections are cheap, waiting is expensive** | 高吞吐下事后修复比阻塞合并门槛更高效 | Review 不阻塞流转（有条件通过仍可推进），Verify 阶段集中修复 |

## 工作流（Plan → Implement → Review → Verify — Comet 风格，多项目类型）

所有任务（UE5 / Web / 其他）通过 `ue-project-router` 唯一入口启动，自动检测项目类型和任务阶段，状态机驱动流转。

### 模型分层策略（Pro + Flash）

> 详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md`

采用 DeepSeek V4 Pro（深度推理）+ V4 Flash（快速执行）分层使用，成本降低 60-80%：

| 阶段 | 推荐模型 | 原因 | Token 占比 |
|------|---------|------|-----------|
| Plan | **Pro** | 深度推理、架构决策、边界条件识别 | 10-15% |
| Implement | **Flash** | 执行密集型，单文件编码质量与 Pro 差距极小 | 60-80% |
| Review + Verify | **Pro**（同一会话） | 审查+编译+修复+验收，无需切换模型 | 10-15% |

自动化：每阶段结束运行 `task-handoff.ps1 <task-name>` 自动生成交接模板。

### 入口与状态机

- **唯一入口**：`ue-project-router`（`.trae/skills/ue-project-router/SKILL.md`）
- **状态文件**：`.trae/tasks/<task-name>/.task.yaml`（含 `project_type` 字段：`ue5` / `web` / `other`）
- **状态管理**：`.trae/scripts/task-state.ps1`（init/get/set/transition/check）
- **守卫检查**：`.trae/scripts/task-guard.ps1`（plan/implement/review/verify -Apply）

### 阶段流转

```
任何项目需求
  ↓ ue-project-router (项目类型检测 + 阶段检测)
Phase 1: Plan     [Pro]  → task-guard plan -Apply → phase: implement
Phase 2: Implement [Flash] → task-guard implement -Apply → phase: review
  ├─ UE5:  ue-lyra-gas-implementer / ue5-cpp-gameplay / ...
  ├─ Web:  web-implementer → web-fullstack / ui-ux-pro-max / ...
  └─ Other: brainstorming → 按需加载
Phase 3: Review+Verify [Pro] → task-guard review -Apply → task-guard verify -Apply → phase: archive
  ├─ UE5:  code-quality-reviewer → ue-ai-validator（同一 Pro 会话）
  ├─ Web:  code-quality-reviewer → npm build + test（同一 Pro 会话）
  └─ Other: 按配置执行
Phase 4: Archive   → task-state transition archived
```

### 项目类型检测（Step 0，最先执行）

| 检测依据 | 判定为 |
|---------|--------|
| 提到 UE、虚幻、Lyra、GAS、Blueprint、Build.cs、.uproject | **UE5 项目** |
| 提到 React/Vue/Node/HTML/CSS/JS/API/数据库/前后端、有 package.json | **Web 项目** |
| 无法判定 | **AskUserQuestion** 询问 |

### 阶段一：Plan（由 ue-project-router 主导）
1. 检测项目类型（UE5/Web/Other）
2. **搜索已有设计文档**（强制，先于外部搜索）
   - Glob 搜索 `Docs/superpowers/specs/` + `Docs/superpowers/plans/`
   - 读取 2-4 篇最相关的设计文档 → 提取关键约束
   - **隐含需求推导**：从设计文档反向推导用户没说出口的前提条件
     - 如：装备文档有品质体系 → 沙盒必须复用，不能另搞一套
     - 如：战斗文档有 12 步管线 → 沙盒不能截断/简化管线
     - 推导结果写入 `analysis.md` 的"隐含需求"章节
   - 硬门禁（二选一即阻断）：
     - 设计文档存在但未引用 → 禁止进入依赖链推导
     - 设计文档中定义了模型/管线/校验/UI 约定，但隐含需求章节未覆盖 → 禁止进入依赖链推导
3. 分析需求 + 澄清模糊点 + 读取 failure memory
4. **开源项目参考搜索**（系统性/功能性需求强制执行，hotfix 除外）
   - WebSearch 搜索关键实现 → WebFetch 读取 2-3 个高质量架构
   - 输出结构化对比摘要到 analysis.md
5. 搜索项目内已有实现 + 引擎/框架原生方案
6. 按项目类型选择对应路由表和 Skill
7. 拆分任务、决定单/多 Agent 协作
8. 输出 routing.md + tasks.md，用户确认后自动流转
9. 写回状态字段：`clarification_status`、`user_confirmed_plan`、`router_skill_loaded`

本阶段禁止修改任何代码。

### 阶段二：Implement（按项目类型加载主 Skill）
1. 入口验证：`task-state.ps1 check <name> implement`
2. 编辑前硬门禁：`task-state.ps1 can-edit <name>`，失败时禁止任何 `edit/write/apply_patch`
3. Web 项目先进入 `web-implementer`，再由它加载主 Web skill
4. 首次编辑前可按需读取少量 failure memory，输出 `Pre-Edit Failure Reminder`
5. 读取 routing.md 获取主 Skill，**用 Skill tool 加载**（`Skipping this step is prohibited.`）
6. 按项目类型遵循对应编码规范
7. 每完成一项立即打勾 tasks.md 并提交
8. 构建/编译验证（UE5: UnrealBuildTool / Web: npm run build）

### 阶段三：Review（由 code-quality-reviewer 主导，不区分项目类型）
1. 框架/结构合规检查
2. 冗余分析（是否与已有实现重复）
3. 安全审查（UE5: 网络复制/RPC / Web: XSS/SQL注入/密钥暴露）
4. 输出质检报告，通过后自动流转

### 阶段四：Verify（按项目类型分派）
- **UE5**：`ue-ai-validator`（编译 + AI选型 + 资产接线 + 回归）
- **Web**：router 直接执行（npm build + test + 功能回归 + UI 截图）
- **Other**：按项目配置执行
- 输出验收报告到 `.trae/tasks/<name>/verification-report.md`

### Basic Memory 第一阶段
- `Docs/Memory/README.md` 是 failure memory 的规则说明
- `Docs/Memory/indexes/memory-index.md` 是 Router / Implement 的轻量检索入口
- `Review FAIL` / `Verify FAIL` / workflow regression fail 可生成 `Docs/Memory/candidates/` 中的 memory candidate
- 只有通过转正门槛的 candidate 才能进入 `Docs/Memory/failures/`
- memory 注入只允许摘要，不允许整篇 memory 原文进入 prompt

### 阻塞点（必须用 AskUserQuestion 暂停）
- Step 0: 项目类型无法自动判定时
- Step 0: 活跃任务选择（继续/新建）
- Phase 1: routing.md + tasks.md 审查确认
- Phase 3: 审查不通过时的修复/接受决策
- Phase 4: 验证失败时的修复/接受决策

### DeepSeek 硬门禁（Fail-Closed）
- `user_confirmed_plan != true` → 禁止进入实现
- `router_skill_loaded != true` → 禁止进入实现
- `clarification_status` 不为 `not_needed/answered` → 禁止进入实现
- 未执行 `task-state.ps1 can-edit <name>` → 禁止任何文件编辑
- `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md` 是 DeepSeek4Pro 的共享 prompt/profile 真相源

### 嵌套 Skill 触发规则
各实现 Skill 中必须使用 `Immediately execute: Use the Skill tool to load the X skill. Skipping this step is prohibited.` 句式触发嵌套 Skill，不得以普通对话替代。

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

### 自检清单
- [ ] UCLASS/USTRUCT/UENUM 宏语法正确
- [ ] UFUNCTION 参数 Blueprint 兼容
- [ ] UPROPERTY 元数据完整（EditAnywhere/BlueprintReadOnly/Category）
- [ ] API 导出宏（GAME_API）使用正确
- [ ] 子系统获取方式正确（避免双重 TEXT 包装）
- [ ] 日志格式化语法正确
- [ ] UENUM meta=() 语法正确

## 编译验证

```powershell
# 增量编译
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## 文档

优先参考：
- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/02-Project-Truth-Source.md`
- `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
- `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

更新时机：
- 实现前：更新 target.md
- 实现中：更新临时代码区.md
- 实现后：更新 UE5_Error_Prevention_Guide.md

## 禁止事项

- ❌ 使用网络复制功能（Replicated/ReplicatedUsing/OnRep）
- ❌ 使用 RPC（Server/Client/NetMulticast）
- ❌ 直接修改引擎代码
- ❌ 跳过编译验证直接交付
- ❌ 每次报错都创建新文档
- ❌ 在阶段一中修改代码
- ❌ 使用已弃用的 UE5 API
- ❌ 解决完报错不更新 UE5_Error_Prevention_Guide.md

## 游戏策划文档分层规则（GDD 文档体系）

### 分层原则

采用行业标准两层级文档体系：**框架文档（架构与规则）+ 数据手册（具体数值）**。

```
框架文档（GDD 主文档）          数据手册（配套数值表）
  定义: 系统如何运作               定义: 具体数据是什么
  内容: 规则/公式/流程图/关系      内容: 配方表/掉落表/数值曲线/NPC清单
  受众: 所有人（对齐愿景）         受众: 程序员+数值策划（实现参考）
  频率: 低频更新（规则变更时）     频率: 高频更新（数值调优/新增内容时）
```

### 强制拆分规则

以下内容**禁止**写入主框架文档，必须独立为数据手册：

| 数据类型 | 独立文档 | 格式 |
|---------|---------|------|
| 配方表（材料×数量×效果） | 制作与装备数据手册 | 表格 |
| 掉落表（必定/概率/稀有） | 生物与掉落数据手册 | 表格 |
| 草药分布（地貌×季节×稀有度） | 草药与炼金数据手册 | 表格 |
| NPC教学清单（NPC×教授内容×好感门槛） | NPC教学与技能数据手册 | 表格 |
| 数值公式/曲线（属性/经验/伤害） | 角色成长与数值数据手册 | 公式+表格 |
| 装备数值表（伤害/暴击/射程/重量/耐久） | 制作与装备数据手册 | 表格 |
| 生物战斗属性（HP/伤害/MP/AP） | 生物与掉落数据手册 | 表格 |

### 文档命名规范

```
框架文档:  YYYY-MM-DD-airpg-<主题>-design.md
数据手册:  YYYY-MM-DD-airpg-<系统>-data.md

示例:
  2026-05-24-airpg-ai-npc-rpg-design.md           ← 框架
  2026-05-25-airpg-crafting-equipment-data.md      ← 数据
  2026-05-25-airpg-character-progression-data.md    ← 数据
```

### 交叉引用规则

- 框架文档中引用数据手册用相对链接：`见数据手册：[xxx-data.md §N](./xxx-data.md#章节)`
- 数据手册开头声明配套框架文档
- 每个数据手册顶部写清对应框架文档的具体章节号
- 禁止在框架文档中重复数据手册的内容（不写"具体数值"，只写"见数据手册"）

## 测试分层约定（Web 项目）

### 文件放置规则

| 层 | 路径模式 | 框架 | 范围 |
|----|---------|------|------|
| **Domain 纯逻辑** | `src/domain/<模块>/__tests__/<模块>.test.ts` | Vitest | 纯函数 I/O、边界值、不变量 |
| **Persistence** | `src/persistence/**/*.test.ts` | Vitest | CRUD + 序列化往返 |
| **Runtime 服务** | `src/runtime/**/*.test.ts` | Vitest | 服务调用 + 状态变更 |
| **UI 组件** | `src/presentation/**/*.test.tsx` | Vitest + React DOM | 静态渲染 + 关键文案断言 |
| **E2E** | `tests/*.spec.ts` | Playwright | 完整用户流程（有浏览器） |

### 每个模块的最小覆盖目标

| 层 | 必须覆盖 |
|----|---------|
| domain | 核心函数的正常输入/边界值/错误输入 各 1 条 |
| persistence | save → load 往返一致 + list 返回非空 |
| runtime | create → mutate → query 状态链 |
| UI | 关键文案 + 组件渲染不崩溃 |
| E2E | 新建游戏 → 核心交互 → 存档 → 回主菜单 |

### 新增模块时的测试门禁

- 新建 domain 模块 → 必须同步创建 `__tests__/` 目录和至少 1 条冒烟测试
- 新建 UI 组件 → 至少 1 条渲染断言（包含关键按钮/文案）
- 修复 bug → 先写失败测试再现 bug → 再修复代码 → 测试通过

### 设计与测试的交叉约束

- 设计文档中标注"必补测试"的用例 → 实现阶段必须补齐
- 设计文档 §测试策略 章节的用例清单 → 实现完成后逐条对照打勾
- E2E 测试的交互流程 → 必须匹配 spec.md 中的 Scenario 编号

## DeepSeek API 优化

### 模型分层（Pro + Flash）

> 详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md`

Plan/Review/Verify 用 Pro（深度推理），Implement 用 Flash（快速执行），成本降低 60-80%。阶段边界 `/clear` + 切换模型 + handover。

### Context Caching

> Context Caching 默认启用。静态内容（CLAUDE.md/rules/skills）前置组成稳定前缀 → 重复请求输入 token 成本降至 1/10。
> 动态信息（状态/时间戳/进度）用 `<system-reminder>` 追加，**不修改 prompt 前缀**，避免缓存断裂。
> 阶段边界（Plan/Implement/Review/Verify 完成后）自然 /clear；长任务中研究型工作用 subagent 隔离上下文。
