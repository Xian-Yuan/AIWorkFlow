---
name: planning-with-files
description: "Manus风格文件化规划。复杂任务时用 task_plan.md/findings.md/progress.md 替代上下文窗口做持久记忆。适用于多步骤任务、研究任务、跨大量工具调用的工作。"
---

# Planning with Files — 文件化规划

核心原则：**上下文窗口 = RAM（易失），文件系统 = 磁盘（持久）。重要信息必须落盘。**

## 何时使用

**使用：** 多步骤任务（3+步骤）、研究任务、新建项目、跨大量工具调用的任务

**跳过：** 简单问题、单文件编辑、快速查询

## 三文件模式

每个复杂任务创建三个文件：

```
task_plan.md   → 阶段追踪 + 复选框进度
findings.md    → 研究发现、重要笔记
progress.md    → 会话日志、测试结果、错误记录
```

## 关键规则

### 1. 先建 Plan
修改代码前，必须先创建 task_plan.md：
```markdown
# 任务计划：[目标]

## 目标
[一句话描述最终目标]

## 当前阶段
Phase 1

## 阶段
### Phase 1：需求分析
- [ ] 理解需求
- [ ] 搜索已有实现
- **状态:** in_progress

### Phase 2：方案设计
- [ ] 设计架构
- [ ] 输出文件清单

### Phase 3：实现
- [ ] 实现核心逻辑
- [ ] 编译/运行验证

### Phase 4：质检
- [ ] code-quality-reviewer 审查
- **状态:** pending
```

### 2. 两操作规则
每 2 次搜索/浏览操作后，立即保存关键发现到 findings.md。

### 3. 决策前重读
每次重大决策前（写代码、执行命令、架构决策），先重读 task_plan.md。

### 4. 完成后更新
文件操作后立即更新 task_plan.md 阶段状态：`pending → in_progress → complete`

### 5. 记录所有错误
错误写入 findings.md，避免重复踩坑。

### 6. 结束前验证
停止前确认所有阶段标记为 complete、无未解决错误。

## 模板

### findings.md
```markdown
# 研究发现：[主题]

## 已有实现
- 文件/类/模式：xxx
- 位置：path/to/file

## 关键决策
- 决策：原因

## 错误记录
- 错误：根因 → 解决方案
```

### progress.md
```markdown
# 进度日志：[目标]

## 会话记录
### 2026-xx-xx HH:MM
- 完成：xxx
- 下一步：xxx
- 阻塞：无
```
