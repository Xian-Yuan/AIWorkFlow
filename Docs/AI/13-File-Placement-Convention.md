---
domain: ai
domain_path: ai/skill-scheduling
kg_node_id: node.doc-ai-ai-13-file-placement-convention-2759
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.13-file-placement-convention.2759

---

# 文件放置规范（File Placement Convention）

## 核心原则

```
G:\UEGameDevelopment\               # ★ 辅助开发真相源（AI 流程 + 知识库 + 工具）
│                                     职责：所有 Skill、Agent、APIRef、ErrorKB、
│                                           CodeTemplates、脚本、架构文档
│
├── Project\                         # 项目文件（纯游戏内容）
│   └── LyraStarterGame - 5.7\       #   职责：源码、资产、游戏设计文档、进度
│       ├── Source/                   #   C++ 源码
│       ├── Content/                  #   资产
│       ├── Config/                   #   项目配置
│       ├── Plugins/                  #   游戏插件
│       ├── Documentation/            #   ★ 仅限：游戏设计文档 + 开发进度
│       └── .trae/                    #   IDE 配置（项目级规则）
```

**铁律**：项目文件夹 = 游戏产品。根目录 = AI 大脑。二者职责不交叉。

---

## 目标

AI 创建新文件时必须遵守此规范，**禁止在未确认目录归属的情况下随意创建文件**。

---

## 项目目录总览

```
G:\UEGameDevelopment/              # 项目根（代码 + AI 流程）
├── .opencode/                     # OpenCode IDE 配置
│   ├── agents/                    #   agent 定义 (*.md)
│   └── skills/                    #   skills 索引（→ .trae/skills/ 的 junction）
├── .trae/                         # Trae IDE 配置（skills 真相源）
│   └── skills/                    #   所有 skill 定义
├── Docs/                          # 所有文档
│   ├── AI/                        #   AI 主导开发流程规则
│   ├── APIRef/                    #   API 签名参考
│   ├── CodeTemplates/             #   可复制的代码模板
│   ├── Community/                 #   社区资源
│   ├── ConfigRef/                 #   配置参考
│   ├── GAS/                       #   GAS 架构文档
│   ├── Lyra/                      #   Lyra 架构文档
│   ├── Troubleshooting/           #   排错指南 + 错误知识库
│   ├── Tutorials/                 #   教程
│   ├── UE5/                       #   UE5 通用文档
│   └── UE5.7/                     #   UE5.7 特定文档
├── MLCase/                        # UE 工程文件（虚幻项目根）
│   ├── Config/                    #   UE 配置文件
│   ├── Content/                   #   资产（蓝图、数据资产、地图）
│   ├── Docs/                      #   工程内部文档（不承担 AI 流程规则）
│   ├── Plugins/GameFeatures/      #   GameFeature 插件
│   ├── Source/                    #   C++ 源码
│   └── *.uproject                 #   UE 项目文件
└── Scripts/                       # 项目工具脚本
    └── sync-skills.ps1
```

---

## 文件类型 → 目标目录

| 文件类型 | 必须放在 | 禁止放在 |
|----------|----------|----------|
| `.h` / `.cpp` 源码 | `MLCase/Source/<Module>/Public\|Private/` | 项目根、Docs/ |
| 蓝图 / 数据资产 / 地图 | `MLCase/Content/` | 项目根 |
| `.uplugin` (GFP) | `MLCase/Plugins/GameFeatures/<Name>/` | 其他 Plugin 目录 |
| Skill（`SKILL.md`） | `.trae/skills/<name>/` | Docs/、MLCase/ |
| Agent（`*.md`） | `.opencode/agents/` | Docs/、MLCase/ |
| 架构 / 流程文档 | `Docs/` 下对应子目录 | 项目根、MLCase/ |
| API 参考文档 | `Docs/APIRef/` | 项目根 |
| 代码模板 | `Docs/CodeTemplates/` | 项目根 |
| 错误知识库条目 | `Docs/Troubleshooting/ErrorKnowledgeBase/` | 其他地方 |
| 项目脚本工具 | `Scripts/` | 项目根 |
| 临时实验代码 | 见下方 [临时文件规则] | 项目根、MLCase/ 根 |

---

## 文件命名规则

| 类型 | 规则 | 示例 |
|------|------|------|
| C++ 类 | `U`/`A`/`F` 前缀 + PascalCase | `UGameplayAbility_MyAttack` |
| C++ 文件 | 类名一致 (.h/.cpp) | `MyGame.Build.cs` |
| 蓝图 | `BP_` / `B_` / `GE_` / `GA_` | `BP_MyCharacter` |
| 数据资产 | `DA_` + PascalCase | `DA_MyWeaponConfig` |
| 资产目录 | 英文小写 + 下划线 | `weapons/`, `enemies/` |
| 文档 | 数字前缀 + 英文短横线 | `01-File-Placement-Convention.md` |
| 脚本 | kebab-case | `sync-skills.ps1` |
| Agent | kebab-case | `ue-project-router.md` |
| Skill 目录 | kebab-case | `ue57-lyra-gas-ai-singleplayer` |
| 错误知识库 | `E<编号>-<分类>-<英文描述>` | `E001-Compile-MissingGeneratedBody.md` |

---

## 临时文件规则

- 实验代码 → 粘贴到 `MLCase/临时代码区.md`，**不创建独立 .cpp 文件**
- 临时工作文件 → 在 `MLCase/Workbench/` 下创建（如不存在先手动创建目录）
- **禁止**：在 `MLCase/` 根或项目根直接堆放 `.cpp` / `.txt` / `.log`

---

## AI 创建文件前的检查流程

1. **确认文件类型** → 属于上述哪个类别
2. **确认目标目录** → 查「文件类型→目标目录」表
3. **确认目录存在** → 不存在则先创建
4. **确认命名正确** → 按命名规则
5. **再创建文件**

---

## 项目文件夹规则（Project Folder Rules）

### 项目文件夹只允许存放

| 允许 | 示例 |
|------|------|
| C++ 源码 | `Source/`, `Plugins/*/Source/` |
| UE 资产 | `Content/`, `Plugins/*/Content/` |
| 项目配置 | `Config/`, `*.uproject`, `*.ini` |
| 游戏设计文档 | `Documentation/GameDesign/` — 玩法设计、系统需求、数值设计 |
| 开发进度文档 | `Documentation/Progress/` — 完成情况、待办事项、里程碑 |
| IDE 配置 | `.trae/rules/` — 项目级 AI 规则 |

### 项目文件夹禁止存放

| 禁止 | 原因 | 应放在根目录 |
|------|------|-------------|
| GAS/Lyra 架构教程 | 通用知识，不是项目专属 | `Docs/GAS/`、`Docs/Lyra/` |
| 编译指南 | 通用流程 | `Docs/` 或 Scripts/ |
| 错误预防文档 | 通用知识 | `Docs/Troubleshooting/ErrorKnowledgeBase/` |
| 代码规范（通用部分） | 跨项目适用 | `Docs/AI/` |
| 学习资料/教程代码 | 学习完成后应移除 | 做成 Skill 或删除 |
| 外部教程压缩包/源码 | 一次性学习材料 | 学习后删除，知识沉淀到 Skill |
| API 参考文档 | 通用知识 | `Docs/APIRef/` |
| 日志文件 (*.log) | 构建产物 | 删除或 .gitignore |
| 临时 C++ 实验文件 | 不稳定的代码 | `临时代码区.md` 或删除 |

### 学习资料 → Skill 转化流程

```
发现学习资料（教程/课程/外部仓库）
        │
        ▼
深入学习研究 ──→ 提取可复用的模式和规则
        │
        ▼
完善已有 Skill 或创建新 Skill（放入 .trae/skills/）
        │
        ▼
删除原始学习资料（源码已内化到 Skill）
```

### 项目 Documentation/ 子目录规范

```
<项目根>/Documentation/
├── GameDesign/        # ★ 保留：玩法设计文档
│   ├── Combat.md
│   ├── Progression.md
│   └── EnemyAI.md
├── Progress/          # ★ 保留：开发进度追踪
│   ├── Done.md
│   ├── InProgress.md
│   └── Milestones.md
└── (禁止放置 CodeGuidelines/、编译指南、架构分析等辅助文档)
```

## 编号规范（Numbering Convention）

**所有 Docs/ 子目录中的文件使用 `NN-英文描述.md` 格式编号。**
NN 为两位数序号，从 01 开始递增，无跳号。

### 新建编号文件时

1. **先运行检测脚本**：`powershell -File Scripts/check-numbering.ps1` 查看当前最大编号
2. **使用下一个编号**：脚本输出的 `next available` 值
3. **创建后再运行一次**：`powershell -File Scripts/check-numbering.ps1` 确认无冲突
4. **如果发生冲突**：`powershell -File Scripts/check-numbering.ps1 -Fix` 自动修复

### 编号目录

| 目录 | 编号范围 | 当前最大 |
|------|:---:|:---:|
| `Docs/AI/` | 01-20 | 20 |
| `Docs/GAS/` | 01-10 | 10 |
| `Docs/Lyra/` | 01-13 | 13 |
| `Docs/UE5/` | 01-06 | 06 |
| `Docs/UE5.7/` | 01-03 | 03 |

### 违规自动修复

`Scripts/check-numbering.ps1 -Fix` 自动将冲突文件重命名为下一个可用编号，保证无冲突、无跳号。

- 文件在错误位置 → 编译/打包/寻址失败
- 根目录堆临时文件 → 无法追溯，需人工清理
- AI 不按规范放置 → 浪费修复时间

---

## 规则注册指南 (Rule Registration Guide)

### 新增规则的标准流程

当需要添加新的工作流规则时，按以下步骤操作：

**Step 1: 判断规则的执行方式**

| 规则类型 | 执行方式 | 示例 |
|---------|---------|------|
| 文件放置、阶段门禁、脚本检查 | `mechanical` — 脚本自动检查，违规硬阻断 | R001, R002 |
| 代码规范、设计约束、沟通规则 | `llm-self-check` — LLM 在 SKILL.md 指令下自检 | R003, R008 |

**Step 2: 在 rule-registry.json 中注册**

```json
{
  "id": "R017",
  "name": "your-rule-name",
  "category": "governance|domain|workflow|communication",
  "priority": "P0|P1|P2",
  "description": "一句话描述规则",
  "source": "Docs/AI/XX-Your-Doc.md",
  "enforcement": "mechanical|llm-self-check",
  "trigger": "on-write|on-code-write|on-plan-start|on-task-complete|...",
  "check": "engine/your-check-script.ps1"  // 仅 mechanical 类型需要
}
```

**Step 3: 如果是 mechanical 类型，实现检查脚本**

检查脚本必须：
- 接受明确的输入参数
- 违规时 exit 1
- 通过时 exit 0
- 输出清晰的错误信息（含违规文件路径 + 正确做法）

**Step 4: 如果是 llm-self-check 类型，更新对应 SKILL.md**

在相关 Skill 的 SKILL.md 中增加规则引用：
```markdown
## 规则遵守
本 Agent 遵守 rule-registry.json 中的以下规则：
- R003: 禁止网络复制/RPC/Prediction
- R004: 禁止修改 Lyra 核心源码
```

**Step 5: 运行验证**

```powershell
engine\rule-enforcer.ps1 validate-registry
```

### 反模式：不要做的事

- ❌ 只写 Docs/AI/ 文档但不注册到 rule-registry.json
- ❌ 注册了 mechanical 规则但不实现检查脚本
- ❌ 在多个 SKILL.md 中重复定义同一规则
- ❌ 规则变更后不更新 rule-registry.json
