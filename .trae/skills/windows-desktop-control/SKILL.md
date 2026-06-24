---
name: windows-desktop-control
description: "Windows 桌面操控能力。通过 pywinauto (UIA) + pyautogui (截图/键鼠) + unreal-mcp (UE5 Editor) 实现三层混合桌面操控。"
version: 1.0.0
author: 金璃好帮手
metadata:
  hermes:
    tags: [desktop, windows, automation, pywinauto, pyautogui, unreal-mcp, computer-use]
    mcp_servers: [windows-computer-use, desktop-commander, unreal-mcp]
---

# Windows Desktop Control

通过三个 MCP Server 实现 Windows 桌面操控能力：

1. **windows-computer-use** — pywinauto (UIA) + pyautogui (截图/键鼠)
2. **desktop-commander** — 终端控制 + 文件系统
3. **unreal-mcp** — UE5 Editor 操控（需 UE5 运行）

## 三层混合架构

```
优先级链：
1. UIA Accessibility Tree → 精确定位元素（最快最准）
2. OCR + 截图 → 定位不支持 UIA 的应用元素
3. 截图 + 视觉 LLM → 坐标级点击（兜底，最慢最贵）
```

## 何时使用

- 需要操控桌面应用（VS Code、浏览器、Office、UE5 Editor 等）
- 需要截屏分析当前界面
- 需要查看窗口列表或切换窗口
- 需要在 UE5 Editor 中创建/修改 Actor 或 Blueprint

## 操作模板

### 查看当前屏幕

```
1. computer_screenshot() → 获取截图
2. 用 Vision 分析截图内容
3. 根据分析结果决定下一步操作
```

### 切换到指定应用

```
1. computer_list_windows() → 查看所有窗口
2. computer_activate_window(title) → 激活目标窗口
3. computer_screenshot() → 确认窗口已激活
```

### 点击 UI 元素（优先 UIA）

```
1. computer_get_uia_tree(window_title) → 获取 UI 树
2. 在 UI 树中找到目标元素的 name/automation_id
3. computer_click(element_name="目标元素名") → 精确点击
4. 如果 UIA 失败 → computer_screenshot() → Vision 定位坐标 → computer_click(x, y)
```

### 输入文字

```
1. computer_type(text="内容", element_name="输入框") → 定位并输入
2. 如果需要清空先输入 → computer_type(text="内容", clear_first=True)
```

### UE5 Editor 操作

```
1. ue_status() → 检查 UE5 是否运行
2. ue_list_actors() → 列出场景中的 Actor
3. ue_create_actor(actor_type="Cube") → 创建 Actor
4. ue_compile_blueprint(name="BP_Name") → 编译 Blueprint
```

## 安全策略

### 危险操作（需要用户确认）

- 关闭应用窗口
- 删除文件或 Actor
- 执行可能破坏性的终端命令
- 修改系统配置

### 安全窗口白名单

默认允许操控的窗口：
- Visual Studio Code
- Unreal Editor
- Chrome / Edge / Firefox
- Windows Terminal / PowerShell
- Explorer

### 操作日志

所有桌面操控操作都会记录：
- 时间戳
- 操作类型（click/type/scroll/activate）
- 目标（元素名或坐标）
- 结果（成功/失败/错误信息）

## 错误恢复

| 错误 | 恢复策略 |
|------|----------|
| UIA 元素未找到 | 降级到截图+OCR |
| 窗口未找到 | 列出所有窗口让用户选择 |
| UE5 未运行 | 提示用户启动 UE5 |
| MCP 连接失败 | 报告错误，建议检查 MCP 配置 |
| 操作超时 | 重试一次，失败则报告 |

## 方案选择陷阱

### ❌ agent-desktop 不支持 Windows

agent-desktop (lahfir/agent-desktop, 870★, Rust) 的 npm 包 **不包含 Windows 二进制文件**。源码明确标注：

> "Windows and Linux support is coming in Phase 2."

安装后运行会报错：`Error: Native binary not found for win32-x64`。**不要在 Windows 环境下尝试使用 agent-desktop**，直接使用自建的 `windows-computer-use` MCP Server。

### ✅ 自建 windows-computer-use MCP Server

基于 pywinauto + pyautogui + Pillow + mcp SDK，已实现 8 个工具：
- `computer_screenshot` — 截屏（全屏或指定窗口）
- `computer_list_windows` — 列出所有可见窗口（标题、PID、位置）
- `computer_activate_window` — 激活窗口（标题子串匹配）
- `computer_click` — 点击（元素名或坐标）
- `computer_type` — 输入文字（可指定元素、可清空）
- `computer_press_key` — 按键组合（如 ctrl+c）
- `computer_scroll` — 滚动
- `computer_get_uia_tree` — 获取窗口 UIA 树（结构化元素层级）

代码位置：`.trae/hermes/mcp/windows_computer_use/`
依赖安装：`pip install pywinauto pyautogui Pillow mcp`

### DesktopCommanderMCP 启动方式

DesktopCommanderMCP 的 npm bin `desktop-commander` 不能直接作为 MCP command 使用。正确启动方式：

```json
{
  "command": "node",
  "args": ["D:/npm-global/node_modules/@wonderwhy-er/desktop-commander/dist/index.js"]
}
```

即用 `node` 直接执行 `dist/index.js`，而不是调用 npm bin symlink。

### MCP Server JSON-RPC 测试

用 printf + pipe 快速验证 MCP Server 是否正常：

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}\n{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | python -m windows_computer_use
```

注意：必须用 `printf` 而不是 `echo`，因为 `echo` 在某些 shell 下不解析 `\n` 为换行。MCP 协议要求每个 JSON 消息独占一行。

## 参考文档

- `references/safety-policy.md` — 安全策略详情（窗口白名单、危险操作确认、频率限制、隐私保护）
- `references/mcp-configuration.md` — MCP Server 配置详情（mcp.json 路径、完整配置、代码位置、依赖安装）
- `references/electron-app-control.md` — Electron/Chromium 应用操控策略（UIA 不可用时的截图+Vision+坐标方案、实测结果、应用分类）

## Electron/Chromium 应用操控策略

Electron 应用（VS Code、OpenCode、Discord、Slack 等）的 UIA 树**几乎为空**——只能看到窗口框架（Window → Pane → RootView），内部 UI 元素全部不可见。这是因为 Chromium 内部自行渲染，不走系统 UIA 协议。

**正确操控流程**：
1. `computer_activate_window(title)` → 激活窗口
2. `computer_screenshot()` → 截图
3. Vision 分析截图 → 定位目标元素坐标
4. `computer_click(x, y)` → 坐标点击
5. `computer_type(text)` → 键入文字
6. 再次截图确认结果

**不要尝试**：`computer_get_uia_tree()` 对 Electron 应用无意义，只会返回空壳结构。`computer_click(element_name=...)` 也无法工作。

**常见 Electron 应用坐标参考**（1920x1080 全屏）：
- 输入框/消息区：通常在底部中央，y ≈ 950-1000
- 侧边栏：左侧 x ≈ 0-300
- 标签栏：顶部 y ≈ 0-40
- 发送按钮：输入框右侧

## 注意事项

- pywinauto 的 UIA 后端对 UWP/现代 WinUI 应用支持有限
- **Electron/Chromium 应用 UIA 树为空，必须用截图+Vision+坐标方案**
- 游戏应用（DirectX/OpenGL 全屏）通常不支持 UIA，需用截图方案
- pyautogui 的坐标基于主显示器，多显示器需注意偏移
- 操作间隔建议 ≥ 100ms，避免过快导致应用未响应
- `computer_get_uia_tree` 的 depth 参数最大 6，避免输出过大
- pyautogui.write() 只支持 ASCII 字符，中文输入需用 pywinauto 的 type_keys()
- pywinauto 的 title_re 参数使用正则匹配，特殊字符需转义
- 截图通过 MCP JSON-RPC 传输 base64 可能因过大导致 JSON 解析失败，直接用 Python pyautogui.screenshot() 更可靠

## PowerShell 截屏 + 本地视觉模型 UI 检查

当 MCP 的 `computer_screenshot` 不可用或需要更轻量的方案时，可用 PowerShell 截屏 + Ollama 本地视觉模型：

```bash
# 1. 截屏（git-bash 中调用 PowerShell）
powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; \$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; \$bitmap = New-Object System.Drawing.Bitmap(\$screen.Width, \$screen.Height); \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap); \$graphics.CopyFromScreen(\$screen.Location, [System.Drawing.Point]::Empty, \$screen.Size); \$bitmap.Save('E:\UEGameDevelopment\screenshot.png'); \$graphics.Dispose(); \$bitmap.Dispose()"

# 2. 用 Ollama 视觉模型分析
python -c "
import base64, httpx
with open(r'E:\UEGameDevelopment\screenshot.png', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode()
resp = httpx.post('http://localhost:11434/api/generate', json={
    'model': 'openbmb/minicpm-v4.6:latest',
    'prompt': '描述截图中浏览器窗口的内容...',
    'images': [img_b64],
    'stream': False
}, timeout=120)
print(resp.json().get('response', ''))
"
```

**局限性**：minicpm-v4.6（1.5GB 小模型）对复杂 UI 的理解力有限——可能误识别元素、混淆窗口、遗漏细节。适合做大致状态判断（页面是否加载、是否有错误弹窗），不适合精确 UI 自动化。

**优先级**：API 端点验证 > PowerShell 截屏 + 视觉模型 > 手动截图分析
