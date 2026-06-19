# Resource Inventory

> 自动生成于 2026-05-10 — 仓库 UE5 开发资源完整清单
> 用于 Skill 增强、文档引用和项目维护

---

## 1. Skills (20)

| # | Skill | 路径 | 用途 |
|---|-------|------|------|
| 1 | ue57-lyra-gas-ai-singleplayer | `.trae/skills/ue57-lyra-gas-ai-singleplayer/` | Lyra+GAS+AI 单机全栈开发主 Skill |
| 2 | lyra-gas-dev | `.trae/skills/lyra-gas-dev/` | Lyra+GAS 全栈: Experience/GFP/GA/GE/AS/Equipment/Weapon/Input/UI |
| 3 | ue-lyra-gas-implementer | `.trae/skills/ue-lyra-gas-implementer/` | Agent: Lyra/GAS 实现 (6 交付物/任务) |
| 4 | ue-project-router | `.trae/skills/ue-project-router/` | Agent: 需求路由 (4 阶段) |
| 5 | ue-ai-validator | `.trae/skills/ue-ai-validator/` | Agent: AI 验证 + 编译/运行时/资产检查 |
| 6 | ue5-auto-assistant | `.trae/skills/ue5-auto-assistant/` | 通用 UE5 入口 + 自动路由 |
| 7 | ue5-cpp-gameplay | `.trae/skills/ue5-cpp-gameplay/` | C++ gameplay: Actor/Component/DataAsset/反射/复制 |
| 8 | ue5-blueprint-workflow | `.trae/skills/ue5-blueprint-workflow/` | 蓝图 validate-first + MCP 自动化 |
| 9 | ue5-architecture | `.trae/skills/ue5-architecture/` | 模块边界/Build.cs/反射暴露/循环依赖 |
| 10 | ue5-mass-entity | `.trae/skills/ue5-mass-entity/` | Mass Entity ECS: Fragment/Processor/Trait/Chunk |
| 11 | ue5-animation-guide | `.trae/skills/ue5-animation-guide/` | AnimBlueprint: 速度采样/方向选择/混合/RootMotion |
| 12 | ue5-debug-validation | `.trae/skills/ue5-debug-validation/` | QA: 方案/代码/编译/运行时 4 阶段 |
| 13 | ue5-save-load-replication | `.trae/skills/ue5-save-load-replication/` | SaveGame/序列化/RepNotify/RPC |
| 14 | ue5-ui-umg-slate | `.trae/skills/ue5-ui-umg-slate/` | UMG/Slate/CommonUI/WidgetController MVC |
| 15 | ue5-pcg-building | `.trae/skills/ue5-pcg-building/` | PCG 建筑: Shape Grammar/lot 生成/6 阶段 Graph |
| 16 | ue5-world-interaction | `.trae/skills/ue5-world-interaction/` | 世界交互: 拾取/生成/重叠检测/生命周期 |
| 17 | ue5-performance-packaging | `.trae/skills/ue5-performance-packaging/` | 性能/打包: stat unit/GPU/资产验证/go-no-go |
| 18 | ue5-module-router | `.trae/skills/ue5-module-router/` | 按模块名路由 (RenderCore/AIModule/...) |
| 19 | **xg-uecpp-course** | `.trae/skills/xg-uecpp-course/` | UE C++ 课程: 容器/委托/多线程/HTTP~GAS (37 章) |

### Skill 文档引用链完整性

| Skill | CodeTemplates | APIRef | ErrorKB | CommonPatterns |
|-------|:---:|:---:|:---:|:---:|
| ue57-lyra-gas-ai-singleplayer | ✅ | ✅ | ✅ (P87) | ✅ |
| lyra-gas-dev | ✅ | ✅ | ✅ | ✅ |
| ue5-cpp-gameplay | ✅ | ✅ | ✅ | ✅ |
| ue5-debug-validation | - | ✅ (UEMacros) | ✅ (Phase 3) | - |
| ue5-blueprint-workflow | - | - | - | - |
| xg-uecpp-course | - | - | 独立知识库 | 独立 references |

---

## 2. Documentation (100+ files)

### 2.1 Docs/AI/ — AI 开发手册 (20 files)

| 文件 | 核心内容 |
|------|----------|
| 01-AI-Development-Playbook.md | AI 5 步强制工作流 |
| 02-Project-Truth-Source.md | 项目约束 + L0-L3 授权级别 |
| 03-Singleplayer-Lyra-GAS-Rules.md | 单机 Lyra/GAS 规则 |
| 04-Asset-Checklists.md | 资产接线检查表 |
| 05-StateTree-BT-EQS-SmartObject.md | AI 框架选型指南 |
| 06-GameplayTag-Registry.md | Tag 命名规范 |
| 07-Test-Checklists.md | 测试验证 |
| 08-AntiPatterns.md | 常见反模式 |
| 09-Agent-Handoff-Templates.md | 多 Agent 交接模板 |
| 10-Execution-Examples.md | 可执行示例 |
| 11-Skill-Routing-Workflow.md | Skill 路由逻辑 |
| 12-MultiAgent-Workflow.md | 多 Agent 协作规则 |
| 13-File-Placement-Convention.md | 文件放置规范 |
| 14-Coding-Standards.md | 编码规范 |
| 15-FailSafe-AntiBloat.md | 反冗余措施 |
| 16-Quality-Grade-Rules.md | 质量等级 |
| 17-Self-Improving-Framework.md | 自改进框架 (4 引擎) |
| 18-Validation-Checklist.md | 最终验证 |
| 19-Unreal-Conventions.md | UE 约定 |
| 20-Terminology-Rules.md | 术语标准 |

### 2.2 Docs/Lyra/ — Lyra 架构 (13 + Animation/11 + Camera/5)

**主文档:**
- 01-Overview.md — Lyra 概述与架构
- 02-ExperienceSystem.md — Experience 系统
- 03-GameFeaturePlugins.md — GameFeature Plugin 系统
- 04-ModularGameplay.md — Modular Gameplay 模式
- 05-PawnCharacterSystem.md — Pawn/Character 系统
- 06-EquipmentSystem.md — 装备系统
- 07-InventorySystem.md — 背包系统
- 08-WeaponSystem.md — 武器系统
- 09-InputSystem.md — 输入系统
- 10-UIExtensionSystem.md — UI 扩展系统
- 11-AnimationSystem.md — 动画系统
- 12-Module-Dependencies.md — 模块依赖关系
- 13-Modular-Character-System.md — 模块化角色系统

**Animation/ (11 files):** 速度/方向/墙检测/跳跃/下落/加速度/旋转/CardinalAnimSet 等
**Camera/ (5 files):** 镜头抖动/第三人称/第一人称/镜头混合/TargetOffset

### 2.3 Docs/GAS/ — GAS 架构 (10 files)

01-Overview, 02-ASC, 03-GameplayAbility, 04-GameplayEffect, 05-AttributeSet, 06-GameplayCue, 07-AbilityTasks, 08-Targeting, 09-Prediction, 10-BestPractices

### 2.4 Docs/UE5/ — UE5 通用 (6 files)

GameplayFramework, Networking, EnhancedInput, CommonUI, AssetManager, DataTable

### 2.5 Docs/UE5.7/ — UE5.7 特定 (3 files)

NewFeatures, LyraUpgrade, LyraStarterGame compile guide

### 2.6 Docs/Tutorials/ — 教程 (3 files)

SetupLyraProject, First60MinGAS, CreateGameFeature

---

## 3. Code Templates (9 类, 8 创建指南)

| 模板目录 | 内容 | 创建指南 |
|----------|------|:---:|
| NewGameFeature/ | 完整 GFP: .uplugin + Build.cs + 源码 | ✅ |
| NewGameplayAbility/ | GA_MyAbility.h/.cpp + GA_LyraAbility 示例 | ✅ |
| NewAttributeSet/ | AttributeSet 完整实现 (含复制/回调) | - |
| NewGameplayEffect/ | GE 配置指南 (策略/修饰符/组件) | ✅ |
| NewEquipmentType/ | Equipment 完整创建流程 | ✅ |
| NewWeaponType/ | Weapon 完整创建流程 | ✅ |
| NewExperience/ | Experience 完整创建流程 | ✅ |
| NewPawnData/ | PawnData 配置指南 | ✅ |
| NewInputConfig/ | InputConfig + InputMapping 配置 | ✅ |

---

## 4. API Reference (7 files)

| 文件 | 内容 |
|------|------|
| **CommonPatterns.md** | 10 种经实战验证的代码模式 (ASC 获取/伤害/属性/事件/目标/GameplayCue/Lyra ASC) |
| **GASCoreClasses.md** | GAS 全部核心类的 public 函数签名 |
| **LyraCoreClasses.md** | Lyra 全部核心类的 public 函数签名 |
| **AbilityTaskSignatures.md** | 11 个 AbilityTask 完整 Create 签名 |
| **UECommonAPIRef.md** | UGameplayStatics/KismetSystemLibrary 高频 API |
| **UEMacrosRef.md** | UE 宏全谱 (含 Blueprint 互操作速查表 §15) |
| README.md | API 参考索引 |

---

## 5. Error Knowledge Base (30 entries)

| ID | Category | Title |
|----|----------|-------|
| E000 | - | TEMPLATE |
| E001 | Compile | MissingGeneratedBody |
| E002 | Compile | ModuleDependency |
| E003 | Compile | IncludePath |
| E004 | Compile | MemberNotFound |
| E005 | Compile | DeriveWithoutUCLASS |
| E006 | Compile | ModuleLoadFailed |
| E007 | Compile | LNK2019 |
| E008 | Compile | AttributeAccessors |
| E009 | Runtime | ExperienceNotFound |
| E010 | Asset | AssetManagerScan |
| E011 | Runtime | ASCNull |
| E012 | Runtime | AbilityCantActivate |
| E013 | Runtime | AbilityAlreadyActive |
| E014 | Runtime | GENotWorking |
| E015 | Runtime | GameplayCueNotTriggering |
| E016 | Runtime | GameFeatureLoadFailed |
| E017 | Runtime | ExperienceInfiniteLoop |
| E018 | Runtime | DebugCommands |
| E019 | Compile | GEditorLNK2019 |
| E020 | Asset | HISMCustomDataBaking |
| E021 | Logic | TArrayRemoveForward |
| E022 | Logic | FloatDivisionByZero |
| E023 | Logic | TArrayAddDuringIteration |
| E024 | Logic | HardcodedThreshold |
| E025 | Logic | BFSQueueBounds |
| E026 | Logic | DynamicMeshMaterialPollution |
| E027 | Logic | ON4NestedLoop |
| E028 | Logic | MaterialArrayBounds |
| E029 | Runtime | BatchBakeHang |

**分类统计:** Compile=9, Runtime=8, Asset=2, Logic=9, Template=1

---

## 6. xg-uecpp-course Knowledge Base (40+ files)

### Knowledge 章节 (knowledge/)

- ch1-3: 部署环境 / 引擎架构 / 反射系统
- ch4-7: TArray (14 files) / TMap (8 files) / TSet (5 files) / 基础案例 (6 files)
- ch8: 定时器 (4 files)
- ch9: 委托 (7 files: single-cast/multi-cast/dynamic/overview)
- ch10-20: 字符串 / GameplayTag / 日志 / Subsystem / 断言 / 配置 / 智能指针 / 多线程 / ControlFlows / 插件开发 / 第三方库封装
- ch21-24: LibWebP / Slate / JSON
- ch25-28: HTTP (基础/服务器/上传/流式传输)
- ch29-31: WebSocket (语音识别/语音合成/WebSocketServer)
- ch32: TCP (SMTP 邮件)
- ch33-36: 模板案例 / MMO 部署 / 多人网络基础 / GAS 案例

### 横向模式 (knowledge/横向-*.md)

容器选型决策 / 异步执行模式 / 网络通信演进 / 反射宏体系 / 依赖注入与配置 / 实战案例多项目策略

### References (references/, 21 files)

反射系统总览 / 容器选型指南 / TArray详解 / 委托体系详解 / 多线程详解 / ControlFlows详解 / 网络通信演进 / HTTP通信详解 / WebSocket通信详解 / TCP通信详解 / 配置与依赖注入 / 异步执行模式 / GAS体系详解 / Slate独立程序详解 / 第三方库封装指南 / 字符串处理详解 / 增强输入系统 / 网络同步基础 / 日志断言与调试 / 智能指针详解 / GameplayTag与定时器

---

## 7. Scripts (4 PowerShell)

| 脚本 | 功能 |
|------|------|
| sync-skills.ps1 | 同步 `.trae/skills/` -> `.opencode/skills/` (NTFS Junction) |
| check-placement.ps1 | 校验文件放置是否符合 File-Placement-Convention |
| check-numbering.ps1 | 检测 Docs/ 目录编号冲突 (`-Fix` 自动修复) |
| check-dead-code.ps1 | 检测 `#if 0` 块 / 30 天旧 TODO / 注释掉的 Build.cs 依赖 |

---

## 8. Agent Definitions (3)

| Agent | 路径 | 角色 |
|-------|------|------|
| ue-project-router | `.opencode/agents/ue-project-router.md` | 需求分析 + 路由分流 (4 阶段) |
| ue-lyra-gas-implementer | `.opencode/agents/ue-lyra-gas-implementer.md` | Lyra/GAS 主链路实现 (6 交付物) |
| ue-ai-validator | `.opencode/agents/ue-ai-validator.md` | AI 选型验证 + 编译/运行时/资产检查 |

---

## 9. MCP Bridge

- **配置文件:** `.opencode/mcp.json`
- **Bridge 路径:** `Project/MLCase/Plugins/unreal-mcp/mcp-server/`
- **功能:** Blueprint 自动化 / 插件管理 / 控制台命令

---

## 10. UE Projects

| 项目 | 路径 |
|------|------|
| MLCase (主项目) | `Project/MLCase/MLCase.uproject` |
| LyraStarterGame (参考) | `Project/LyraStarterGame - 5.7/LyraStarterGame.uproject` |

---

## 资源引用链图

```
用户需求
  └─ ue5-auto-assistant (入口)
       ├── ue57-lyra-gas-ai-singleplayer (Lyra/GAS/AI 主 Skill)
       │    └── 引用: CodeTemplates / APIRef / ErrorKB / MLCase Docs
       ├── lyra-gas-dev (Lyra/GAS 全栈)
       │    └── 引用: CodeTemplates / APIRef / ConfigRef / Lyra / GAS / Troubleshooting
       ├── ue5-cpp-gameplay (C++ Gameplay)
       │    └── 引用: CommonPatterns / UEMacrosRef / ErrorKB / UECommonAPI
       ├── ue5-debug-validation (QA)
       │    └── 引用: ErrorKB / UEMacrosRef
       ├── xg-uecpp-course (UE C++ 课程)
       │    └── 引用: knowledge/ (40+) / references/ (21)
       └── 其他 13 个专项 Skill
            └── 各自引用相关 Docs/ 子目录
```
