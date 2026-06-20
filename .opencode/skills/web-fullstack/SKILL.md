---
name: web-fullstack
description: "通用网页全栈开发。覆盖前后端（React/Vue + Node/Java/Go/Python）、RESTful API设计、数据库操作、项目架构、部署。非UE项目开发时调用。"
---

# 网页全栈开发

## 定位

通用网页全栈开发助手，适用于以下场景：
- 前端：React / Vue / 原生 HTML+CSS+JS
- 后端：Node.js / Java Spring Boot / Go / Python FastAPI
- 数据库：MySQL / PostgreSQL / SQLite / MongoDB
- API 设计：RESTful / 统一响应体 / 异常处理
- 项目搭建、依赖管理、构建配置

## DeepSeek4Pro 实现门禁

参考：`Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`

在任何 `edit` / `write` / `apply_patch` 前，必须执行：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
& $TASK_STATE can-edit <task-name>
```

如果 `can-edit` 失败：
- 只允许读文件、搜索、提问、分析
- 不允许写代码
- 不允许假装已经加载或执行了某个 skill

## 固定执行顺序

1. Read state
2. Check phase
3. Run `can-edit`
4. Read `routing.md` / `analysis.md` / `spec.md` / `tasks.md`
5. Execute the actual implementation
6. Confirm local preview URL is reachable
7. Re-open the current preview page in browser/preview module
8. Build and test

实现前先输出：

```text
PHASE: implement
AUTH: <blocked|allowed>
NEXT: <ask|search|read|edit>
BLOCKER: <none|...>
```

## 工作流

### 阶段一：需求理解
1. 明确项目类型（纯前端 / 纯后端 / 全栈）
2. 确认技术栈偏好（语言、框架、数据库）
3. 确认功能范围和优先级
4. 本阶段不写代码，先输出方案

### 阶段二：方案设计
1. 设计项目目录结构
2. 设计 API 路由和数据模型
3. 设计前端组件树和状态管理
4. 输出文件变更清单

### 阶段三：代码实现
1. 按分层顺序实现（数据模型 → API → 前端）
2. 遵循项目现有代码风格
3. 添加适当错误处理
4. 每次发生实质性代码修改后，必须确认 dev server 仍可访问
5. 不允许默认沿用旧标签页；必须重新确认当前有效预览 URL
6. 若有预览工具，必须重新打开当前有效页面后再做可见行为验证

## 本地预览守卫

对本地 Web 应用，进入反馈或声称“页面已修复/可见”前，必须完成：

1. 启动或复用 dev server
2. 获取当前有效 URL（固定端口或实际漂移端口）
3. 运行 `.trae/scripts/web-preview-guard.ps1`
4. 只有在 URL 可访问后，才能重新打开浏览器预览页
5. 若守卫失败，先恢复服务，不允许假装页面已经可用

## 后端通用规范

### API 响应体
```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

### 分层架构
```
Controller  → 参数校验、路由
Service     → 业务逻辑
Repository  → 数据访问
Model/DTO   → 数据结构
```

### 安全
- 所有用户输入必须校验和转义
- 数据库操作使用参数化查询，禁止拼接 SQL
- 敏感信息（密钥、密码）不写入代码或日志
- API 接口实施认证和授权

## 前端通用规范

### 组件原则
- 单一职责：每个组件只做一件事
- Props 向下，事件向上
- 状态提升到最近的公共父组件
- 优先使用框架推荐的组合模式

### 网络请求
- 统一封装请求函数，集中管理 API 地址
- 统一错误处理和用户提示
- 加载状态和空状态的 UI 处理

## 数据库规范

### 建表
- 每表必备字段：id, create_time, update_time
- 字段名使用下划线命名（snake_case）
- 适当添加索引，避免全表扫描
- 外键关系明确，但根据性能需求决定是否使用物理外键

### 查询
- 禁止 SELECT *
- 大数据量查询必须分页
- 复杂查询优先用联表而非多次查询

## 参考文件

- `references/tech-stack-quickref.md` — 技术栈速查
- `references/typescript6-breaking-changes.md` — TypeScript 6 破坏性变更（useRef 初始值、Vitest 类型指令等）
