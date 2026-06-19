# ECC Tools 参考分析 — AgentShield 安全扫描 & 跨平台 Skill 打包

> 来源：[Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) — 140K+ Stars
> 本项目参考 ECC 的架构模式，不直接依赖其代码

## 一、ECC 核心架构分层

ECC 将 Agent Harness 分为三层：

| 层 | ECC 组件 | 本项目对应 |
|---|---------|----------|
| **Skill 层** | 181 skills（每个 `SKILL.md` 独立），按语言/框架分类 | `.trae/skills/` — 25 个 Skill，按项目类型/领域分类 |
| **Agent 层** | 47 agents — 组合多个 skills 的工作流定义 | `.opencode/agents/` — ue-project-router、ue-lyra-gas-implementer 等 |
| **Security 层** | AgentShield — 102 条安全规则，每次 Agent 会话扫描 | 本项目缺此层 — 本次引入 |

## 二、跨平台 Skill 打包方式（ECC 模式参考）

### ECC 的 manifest.json 结构
```json
{
  "version": "0.3.2",
  "skills": [
    "comet/SKILL.md",
    "comet-open/SKILL.md"
  ],
  "languages": [
    { "id": "en", "name": "English", "skillsDir": "skills" },
    { "id": "zh", "name": "中文", "skillsDir": "skills-zh" }
  ]
}
```

### ECC 的跨平台适配策略
| 平台 | Skills 目录 | 特殊处理 |
|------|-----------|---------|
| Claude Code | `.claude/skills/` | 标准 skills 目录 |
| Cursor | `.cursor/skills/` | hooks + rules 格式适配 |
| OpenCode | `.opencode/skills/` | Agent 定义文件转换 |
| **Trae** | `.trae/skills/` | **本项目的目标平台** |
| Codex | `.codex/skills/` | MCP 配置适配 |
| Gemini CLI | `.gemini/skills/` | 全局路径差异处理 |

### 本项目可采纳的跨平台策略
```
.trae/
├── skills/          # Trae 主平台
├── scripts/         # 平台无关的 PowerShell 脚本
├── references/      # 跨平台架构参考
└── rules/           # 项目级规则
```

## 三、AgentShield 安全扫描（102 规则）

ECC 的 AgentShield 扫描三类安全问题：

### 1. Prompt Injection 防护
- **规则数**：~35 条
- **检测点**：Skill 文件中是否有可被注入的模板变量、未转义的用户输入
- **本项目落地**：Skill 文件不包含 `{{user_input}}` 等未转义占位符

### 2. Config Drift 检测
- **规则数**：~30 条
- **检测点**：`.task.yaml` 字段是否合法、路由表是否一致、Guard 脚本是否可执行
- **本项目落地**：`task-state.ps1` 已有 enum 验证 + `task-guard.ps1` preflight 检查

### 3. Guardrail Gap 检测
- **规则数**：~37 条
- **检测点**：是否有未经 Guard 的 Skill 跳过、是否有未归档的任务泄漏、是否有跳过阻塞点的路径
- **本项目落地**：状态机强制约束 + Red Flags 自检表

### 本项目安全扫描实现方式

不引入 ECC 依赖，直接通过以下方式实现等价功能：

| 检查类型 | 检查时机 | 实现方式 |
|---------|---------|---------|
| Skill 文件完整性 | `comet init` 等效入口 | 检查 manifest 与实际文件一致性 |
| `.task.yaml` schema 校验 | 每次 Guard 运行前 | `task-state.ps1` 的 enum 验证（已有） |
| 网络复制违禁关键字 | Implement 阶段 Guard | `task-guard.ps1` 的机械化检查（本次新增） |
| 跳过阻塞点检测 | Router Decision Core | Red Flags 自检表（已有） |

## 四、ECC 其他值得借鉴的模式

### 4.1 持续学习（Continuous Learning）
ECC 从 Agent 会话中自动提取模式到可复用的 skills。本项目可通过 `Docs/AI/17-Self-Improving-Framework.md` 实现等价机制。

### 4.2 Hooks 运行时
ECC 的 hooks 在 Agent 操作前后触发（pre-tool / post-tool）。本项目通过 `task-guard.ps1` 的阶段守卫实现了等价机制。

### 4.3 选择性安装（Selective Install）
ECC 允许按需安装 skills（core/developer/security/full profiles）。本项目的 Plan 阶段路由表实现了按项目类型选择性加载 Skill 的等价机制。

## 五、结论

| 维度 | ECC 方案 | 本项目方案 | 差距 |
|------|---------|----------|------|
| 跨平台打包 | manifest.json + 安装脚本 | `.trae/skills/` 目录约定 | 成熟度差距（ECC 支持 6+ 平台） |
| 安全扫描 | AgentShield 102 规则 | Guard 机械化检查 + enum 验证 | 规则数量差距（可在后续迭代中扩展） |
| 持续学习 | 自动从会话提取模式 | `17-Self-Improving-Framework.md` | 功能差距（ECC 自动化程度更高） |
| Hooks | pre/post-tool hook | Guard 阶段守卫 | 等价 |
| 选择性安装 | 4 种 profile | 路由表按项目类型分派 | 等价 |
