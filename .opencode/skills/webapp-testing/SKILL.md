---
name: webapp-testing
description: "Web应用测试工具包。用Playwright进行本地Web应用自动化测试，包括截图、元素发现、控制台日志捕获、服务器生命周期管理。适用于前端功能验证、回归测试、UI调试。"
---

# WebApp Testing — Web应用测试

## 概述

Web应用测试工具包，提供 Playwright 自动化测试本地 Web 应用的能力。支持截图、DOM 检查、控制台日志、服务器生命周期管理。

## DeepSeek4Pro 门禁与状态

参考：`Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`

读日志、截图、DOM 侦察可以在未授权状态下执行。

如果本次任务需要新建或修改测试脚本，必须先执行：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
& $TASK_STATE can-edit <task-name>
```

如果 `can-edit` 失败：
- 允许只读验证
- 允许提出测试建议
- 不允许修改测试文件或业务文件

进入主要动作前输出：

```text
PHASE: <implement|verify>
AUTH: <blocked|allowed>
NEXT: <ask|search|read|edit|verify>
BLOCKER: <none|...>
```

## 固定执行顺序

1. Read state
2. Determine whether this is read-only verification or implementation-time test editing
3. If any file edit is needed, run `can-edit`
4. Inspect the running app or start the required server
5. Confirm the preview URL is actually reachable
6. Re-open the current page in browser/preview module
7. Capture evidence
8. Report pass/fail with concrete evidence

## 决策树

```
用户任务 → 是静态HTML？
  ├─ 是 → 直接读HTML识别选择器 → 写Playwright脚本
  └─ 否（动态应用）→ 服务器是否已运行？
       ├─ 否 → 先启动服务器 → 再写测试脚本
       └─ 是 → 先探路再行动（侦察模式）
```

## 侦察-行动模式

对动态 Web 应用：
1. 导航到页面 + `page.wait_for_load_state('networkidle')`
2. 截图或检查 DOM 获取实际渲染的选择器
3. 用发现的选择器执行自动化操作

**关键：永远不要硬编码选择器，等页面加载完再查询。**

## 预览可用性守卫

在本地 Web 项目中，不能只因为终端里有 dev server 输出就假定页面可用。

进入页面验证前，必须执行：

1. 启动或确认 dev server
2. 通过 `.trae/scripts/web-preview-guard.ps1` 确认 URL 可访问
3. 若存在旧标签页，重新打开当前有效预览页
4. 只有页面实际可访问后，才能继续做 DOM 侦察、交互测试或截图

若 URL 无法访问：

- 先恢复服务
- 重新确认实际端口
- 重新打开正确页面
- 不允许把失效旧页当成验证对象

## 测试脚本模板

### 元素发现
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:PORT')
    page.wait_for_load_state('networkidle')  # 关键！

    # 发现元素
    buttons = page.query_selector_all('button')
    inputs = page.query_selector_all('input')
    links = page.query_selector_all('a')

    # 截图
    page.screenshot(path='screenshot.png', full_page=True)
    browser.close()
```

### 交互测试
```python
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto('http://localhost:PORT/login')

    # 填写表单
    page.fill('#username', 'testuser')
    page.fill('#password', 'testpass')
    page.click('button[type="submit"]')

    # 等待跳转
    page.wait_for_url('**/dashboard')
    assert page.text_content('h1') == 'Dashboard'
    browser.close()
```

### 控制台日志捕获
```python
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()

    logs = []
    page.on('console', lambda msg: logs.append(f'[{msg.type}] {msg.text}'))
    page.on('pageerror', lambda err: logs.append(f'[ERROR] {err.message}'))

    page.goto('http://localhost:PORT')
    page.wait_for_load_state('networkidle')

    with open('console.log', 'w') as f:
        f.write('\n'.join(logs))
    browser.close()
```

## 选择器策略（优先级从高到低）
1. `role=` — 按 ARIA 角色（最稳定）
2. `text=` — 按文本内容
3. `#id` — ID 选择器
4. CSS 选择器 — 最后手段

## Vitest + Playwright 共存陷阱

当项目同时使用 Vitest（单元测试）和 Playwright（E2E 测试）时，Vitest 会误拾 `tests/` 目录下的 `.spec.ts` / `.test.ts` 文件，导致 Playwright 测试被 Vitest 当作单元测试执行而报错。

**修复：在 `vite.config.ts` 中限制 Vitest 的 include 范围：**

```typescript
/// <reference types="vitest/config" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    // 其他 vitest 配置...
  },
})
```

**目录约定：**
- `src/**/*.test.ts` — Vitest 单元测试
- `tests/**/*.spec.ts` — Playwright E2E 测试

## Playwright 浏览器选择

Playwright 默认下载 Chromium（约 180MB），在受限网络环境可能反复超时。

**替代方案：使用系统已安装的 Edge 浏览器：**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test'

export default defineConfig({
  use: {
    channel: 'msedge',  // 使用系统 Edge，跳过 Chromium 下载
  },
  projects: [
    {
      name: 'edge',
      use: { channel: 'msedge' },
    },
  ],
})
```

**前提：** 系统必须已安装 Microsoft Edge。

**注意：** 首次运行前仍需安装 Playwright 的 OS 依赖（`npx playwright install-deps`），但不需要下载浏览器本身。

## 最佳实践
- 始终 `wait_for_load_state('networkidle')` 后再检查 DOM
- 使用无头模式（headless=True）加速
- 截图保存为 png 便于视觉调试
- 先 --help 查看工具选项再使用
