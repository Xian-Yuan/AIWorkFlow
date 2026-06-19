# OpenCode 任务目录

每个任务按 `<task-name>/` 子目录组织，与 `.trae/tasks/` 格式对齐：

## 目录结构

```
.opencode/tasks/<task-name>/
├── .task.yaml        # 任务状态文件（phase, project_type, status 字段）
├── routing.md        # 路由决策（需求理解 + 方案搜索 + 路由选择）
├── spec.md           # 行为规范（GIVEN/WHEN/THEN 场景列表）
├── tasks.md          # 任务清单（按依赖图排序，逐项打勾）
└── analysis.md       # 依赖链推导 + 隐式需求提醒 + 架构方案引用
```

## 文件规范

### `.task.yaml`

```yaml
task_name: <name>
project_type: ue5 | web | other
phase: plan | implement | review | verify | archived
status: active | paused | completed | failed
clarification_status: not_needed | asked | answered
user_confirmed_plan: true | false
router_skill_loaded: true | false
created: YYYY-MM-DD
updated: YYYY-MM-DD
```

### `routing.md`

Router 的输出，包含：
- 需求理解（核心目标 + 边界范围）
- 方案搜索（项目内 + 网络参考）
- 任务拆分
- 路由决策（主 skill + 次 skill + 协作模式）

### `spec.md`

行为规范，OpenSpec 风格：
```markdown
## Scenario: <名称>
GIVEN <前提条件>
WHEN <用户操作>
THEN <期望行为>
```

### `tasks.md`

任务清单，按依赖图排序：
```markdown
- [ ] 1. [依赖: 无] 任务描述 → 交付物: <文件路径>
- [ ] 2. [依赖: 1] 任务描述 → 交付物: <文件路径>
```

### `analysis.md`

依赖链推导 + 隐含需求提醒：
```markdown
## 依赖链
- A → B → C

## 隐含需求
- 用户没说的前提条件

## 架构方案引用
- Docs/APIRef/...
```
