# Web Preview Handoff And Verify

## 目标

本文件用于约束 Web 项目在实现、交接、验证、汇报前的本地预览流程，避免出现以下问题：

- dev server 终端看起来在运行，但页面实际不可访问
- 浏览器还停留在旧标签页，用户看到的不是当前最新代码
- 端口漂移后仍沿用旧地址
- 交付时只说“应该可以”，没有实际页面打开证据

## 适用范围

适用于当前工作区内所有 Web 项目，尤其是：

- `Project/CharacterDesignTool`
- `Project/AIRPGWeb`

## 核心规则

### 1. 每次实质性代码修改后必须重验预览

凡是修改了前端可见行为、页面布局、交互逻辑、路由、状态管理或本地 dev 配置，都必须重新执行预览验证。

### 2. 不允许默认相信旧标签页

只要发生以下任一情况，就必须重新打开页面：

- dev server 重启
- 端口变化
- 浏览器标签页长时间挂起
- HMR 失效
- 用户明确表示页面不可用

### 3. 先确认 URL 可访问，再声称页面可用

在说“页面已更新”“你可以看了”“我已经修好”之前，必须先确认：

- 当前有效 URL 已知
- URL 可访问
- 页面已重新打开

## 固定执行顺序

### 实现后最小流程

1. 启动或复用 dev server
2. 确认当前实际输出的预览 URL
3. 使用 `.trae/scripts/web-preview-guard.ps1` 检查 URL 可达
4. 在浏览器/预览模块重新打开当前有效页面
5. 再进行 DOM、交互、截图或人工查看验证
6. 最后才允许向用户汇报页面可用

## 预览守卫

推荐命令：

```powershell
powershell -ExecutionPolicy Bypass -File ".trae/scripts/web-preview-guard.ps1"
```

用途：

- 在常见本地端口中轮询可访问地址
- 快速识别本机是否存在有效预览页

限制：

- 若同时存在多个本地 Web 服务，不能只依赖“某个端口可访问”
- 必须优先结合当前 dev server 实际输出的 URL 判断本次任务应打开哪个页面

## 交接要求

### Web Handoff 最少必须包含

```text
项目:
任务:
已修改文件:
dev server 命令:
当前有效 URL:
是否重新打开预览页:
页面是否实际可访问:
已执行验证:
当前风险:
```

### 示例

```text
项目: AIRPGWeb
任务: 地图编辑器拖拽实时预览修复
已修改文件:
- src/presentation/react-shell/dev-mode/TileCanvas.tsx
- src/domain/map-editor/editor-reducer.ts

dev server 命令:
- npm exec vite -- --host=127.0.0.1 --port=4173

当前有效 URL:
- http://localhost:5174/

是否重新打开预览页:
- 是

页面是否实际可访问:
- 是

已执行验证:
- 预览守卫通过
- 浏览器重新打开页面
- E2E 通过

当前风险:
- 本机存在多个本地端口响应时，必须以当前 vite 输出地址为准
```

## 验证清单

- [ ] 已知当前 dev server 实际输出的 URL
- [ ] 已确认 URL 可访问
- [ ] 已重新打开浏览器/预览页
- [ ] 没有把旧标签页当成验证依据
- [ ] 若端口漂移，已明确记录新端口
- [ ] 已完成至少一项页面级验证（DOM / 交互 / 截图 / 人工查看）
- [ ] 向用户汇报时包含最终有效 URL

## 失败处理

### 场景 1：终端看起来正常，但 URL 不可访问

处理：

1. 不要声称页面可用
2. 先重查实际端口
3. 重新启动 dev server 或恢复服务
4. 再次运行预览守卫
5. 重新打开页面

### 场景 2：多个本地端口都能访问

处理：

1. 以当前任务对应 dev server 输出为准
2. 不要只因为 `localhost:5173` 能开就默认它是正确页面
3. 必要时重新启动当前项目 dev server，确保日志里有明确地址

### 场景 3：用户说“页面不可用”

处理：

1. 优先按 bug 处理，而不是假设用户没刷新
2. 先复验预览 URL
3. 重新打开最新页面
4. 再决定是环境问题还是业务问题

## 与其他文档的关系

- 通用 Web 工作流入口：`Docs/AI/01-AI-Development-Playbook.md`
- Skill 路由与 Web Implement 约束：`Docs/AI/11-Skill-Routing-Workflow.md`
- 多智能体交接模板：`Docs/AI/09-Agent-Handoff-Templates.md`
- Web skill 细则：
  - `.trae/skills/web-fullstack/SKILL.md`
  - `.trae/skills/webapp-testing/SKILL.md`
