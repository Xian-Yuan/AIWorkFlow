# Web Subagent Enforcement

## 目标

本文件约束 Web 项目在使用 `subagent-driven-development` 技能时必须严格逐 Task 执行
**实现 → spec 审查 → 代码审查** 的三段闸门，禁止内联执行跳过审查阶段。

## 问题背景

在 AIRPGWeb 素材系统重构中观察到以下模式：

- `subagent-driven-development` 技能被成功加载并展开全部流程说明
- 但执行时所有 Task 被内联执行（同一会话内串行），没有真正分派独立的 review agent
- 缺少 spec-compliance review → 属性面板遮挡画布的设计问题未能提前发现
- 缺少 code-quality review → 无法在 Task 级别拦截类型错误和布局问题
- 预览可达性验证写在 plan 里但执行时被跳过，用户反馈"页面打不开"

**根因**：技能文件展开后把"dispatch subagent"理解为"你应该完成这些步骤"，
而不是"你必须创建独立 agent 会话去执行这些步骤"。

## 适用范围

当前工作区内所有 Web 项目：

- `Project/AIRPGWeb`
- `Project/CharacterDesignTool`

## 核心规则

### 规则 1：禁止内联执行替代子 agent 审查

当 `subagent-driven-development` 技能加载后，每完成一个实现 Task，
**必须**依次执行以下两个审查步骤，且必须使用独立子 agent 会话：

1. **spec-compliance-review** — 对照原始 spec 逐条检查实现是否覆盖所有需求
2. **code-quality-review** — 检查类型安全、未使用变量、布局溢出、边界情况

审查不通过 → implementer 修复 → 重新审查 → 直到通过。

**禁止**：在同一会话内手动阅读代码声称"看起来没问题"作为审查替代。

### 规则 2：审查顺序不可颠倒

spec-compliance 必须在 code-quality 之前。
如果 spec 审查发现缺失需求，先修复需求缺失再进入代码审查。
不允许在 spec 还没通过时就讨论代码风格。

### 规则 3：每个 Task 独立闸门

不能用"最后跑一次全量测试通过"替代逐 Task 审查。
每个 Task 必须在审查通过后才能标记 completed 并进入下一个 Task。

### 规则 4：预览验证必须在所有 Task 完成后执行

在所有 Task 的 spec 和 code 审查都通过后，必须：

1. 启动 dev server 或 preview server
2. 确认当前实际输出的预览 URL
3. 使用 `node -e "fetch(...)"` 验证 HTTP 200
4. 调用 `OpenPreview` 或直接打开浏览器标签页
5. 确认页面无报错后才向用户汇报

**禁止**：在未执行上述步骤时说"页面已更新""你可以看了"。

### 规则 5：preview server 端口策略

- 每次修复或重启后优先使用同一端口
- 如果端口被占用，递增端口号
- 重启后必须在用户端重新打开新 URL
- 不允许假设用户看到的还是旧标签页

## 执行流程

```text
For each Task N:
  ├── Dispatch implementer subagent (./implementer-prompt.md)
  │   └── implementer 实现、测试、自检、提交
  ├── Dispatch spec-compliance reviewer subagent
  │   └── 对照 spec 逐条检查 → 不通过则 implementer 修复 → 重审到通过
  ├── Dispatch code-quality reviewer subagent
  │   └── 检查类型安全、布局、边界 → 不通过则 implementer 修复 → 重审到通过
  └── 标记 Task N completed

After all Tasks completed:
  ├── 全量测试
  ├── 构建
  ├── 启动 preview server
  ├── HTTP 200 验证
  ├── OpenPreview
  └── 向用户汇报
```

## 交接要求

每个 Task 完成后最少必须包含：

```text
Task N: <任务名称>
实现: <git commit hash>
Spec 审查: PASS / FAIL → 修复 → PASS
代码审查: PASS / FAIL → 修复 → PASS
```

全部 Task 完成后最少必须包含：

```text
项目:
测试文件数:
测试用例数:
构建: PASS/FAIL
页面 URL:
HTTP 状态:
```

## 与现有文档的关系

- 本文档补充 `16-DeepSeek4Pro-Workflow-Profile.md` 中的 `Plan → Implement → Review → Verify` 流程
- 本文档细化 `12-MultiAgent-Workflow.md` 中 subagent-driven 的逐 Task 闸门规则
- 预览验证规则与 `22-Web-Preview-Handoff-And-Verify.md` 一致，本文档追加了"禁止乐观汇报"条款
