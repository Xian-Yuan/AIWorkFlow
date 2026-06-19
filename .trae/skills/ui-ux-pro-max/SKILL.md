---
name: ui-ux-pro-max
description: "UI/UX设计智能体。为Web应用、移动端、桌面端提供专业级UI/UX设计指导。涵盖React/Vue组件设计、Tailwind/CSS布局、可访问性、响应式设计、设计系统。需要设计前端界面时调用。"
---

# UI/UX Pro Max — 界面设计智能

## 定位

提供跨平台专业 UI/UX 设计指导，帮助 AI 生成符合现代设计标准的界面代码。

## DeepSeek4Pro 实现门禁

参考：`Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`

纯分析、方案比较、界面建议可以在未授权状态下进行。

任何实际代码修改前，必须执行：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
& $TASK_STATE can-edit <task-name>
```

如果 `can-edit` 失败：
- 只允许输出设计建议、问题分析、候选方案
- 不允许修改组件、样式、配置文件

## 固定执行顺序

1. Read state
2. Check phase
3. Run `can-edit` before any code or style edit
4. Read `routing.md` / `analysis.md` / `spec.md` / `tasks.md`
5. Output design or implement the approved UI change

实现前先输出：

```text
PHASE: implement
AUTH: <blocked|allowed>
NEXT: <ask|search|read|edit>
BLOCKER: <none|...>
```

## 设计原则

### 1. 视觉层级
- 最重要元素最大、最突出
- 使用颜色、大小、间距建立信息层级
- 每个页面只有一个主行动号召

### 2. 一致性
- 按钮、输入框、卡片等组件外观统一
- 间距系统保持一致（4px/8px 倍数）
- 颜色使用设计 Token 而非硬编码

### 3. 可访问性（WCAG 2.1 AA）
- 文字与背景对比度 ≥ 4.5:1
- 所有交互元素可键盘访问
- 图片必须有 alt 文本
- 表单必须有 label 关联

### 4. 响应式
- 移动优先设计
- 断点：sm(640px) / md(768px) / lg(1024px) / xl(1280px)
- 触摸目标 ≥ 44×44px

## 布局模式

### 卡片布局
```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div class="bg-white rounded-xl shadow-sm border p-6 hover:shadow-md transition-shadow">
    <h3 class="text-lg font-semibold mb-2">标题</h3>
    <p class="text-gray-600 text-sm">描述内容</p>
  </div>
</div>
```

### 表单设计
- 标签在输入框上方（不是左侧）
- 单列布局优于多列
- 错误信息紧邻相关字段下方
- 提交按钮右对齐或全宽

### 导航
- 桌面：顶部横栏（≤5项）或侧栏
- 移动：底部Tab栏 或 汉堡菜单
- 当前位置高亮

## 配色系统
```css
:root {
  --primary: #3b82f6;      /* 主色 - 按钮、链接 */
  --primary-hover: #2563eb;
  --bg: #ffffff;
  --surface: #f8fafc;      /* 卡片/面板背景 */
  --text: #0f172a;
  --text-secondary: #64748b;
  --border: #e2e8f0;
  --error: #ef4444;
  --success: #22c55e;
}
```

## 反馈状态
每个交互必须有反馈：
- **加载中**：骨架屏或 Spinner
- **空状态**：插图 + 引导文案 + 行动按钮
- **错误**：红色提示 + 重试按钮
- **成功**：绿色确认（Toast/内联均可）
- **禁用**：灰色 + cursor not-allowed

## 移动端特别规则
- 触控目标最小 44×44px
- 避免 hover 依赖（移动端无 hover）
- 输入框 zoom 不缩放的 viewport 设置
- 底部留出安全区（iPhone 底部横条）
