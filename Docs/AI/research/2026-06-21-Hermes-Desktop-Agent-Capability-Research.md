# Hermes Agent 能力提升研究 — 综合报告

**日期**: 2026-06-21
**目标**: 让 Hermes Agent 像马维斯一样操控电脑上的应用

---

## 一、核心发现：关键项目

### 🥇 Tier 1 — 必须研究/集成

| 项目 | Stars | 语言 | 核心价值 |
|------|-------|------|----------|
| [microsoft/UFO](https://github.com/microsoft/UFO) | 9,067★ | Python | **Windows 桌面 Agent 标杆**。UFO³ 支持多设备、多应用编排。双 Agent 架构(AppAgent+GlobalAgent)。使用 Windows UIA API + GPT-4V。有正式论文(arXiv:2511.11332, 2504.14603)。YouTube 演示: https://www.youtube.com/watch?v=NGrVWGcJL8o |
| [chongdashu/unreal-mcp](https://github.com/chongdashu/unreal-mcp) | 2,000★ | C++ | **UE MCP 服务器！直接让 AI 控制 Unreal Engine**。支持 Actor 管理、Blueprint 开发、节点图编辑、输入映射。UE 5.5+。这是我们项目的杀手级集成！ |
| [lahfir/agent-desktop](https://github.com/lahfir/agent-desktop) | 870★ | Rust | **原生桌面自动化 CLI**。通过 OS Accessibility Tree 操控任何应用，不需要截图/像素匹配。97% token 节省（vs 截图方案）。Rust 高性能。支持 MCP/CLI。跨平台。 |
| [wonderwhy-er/DesktopCommanderMCP](https://github.com/wonderwhy-er/DesktopCommanderMCP) | 6,188★ | TypeScript | **最流行的桌面 MCP Server**。终端控制 + 文件系统搜索 + diff 编辑。已有 Windows 桌面 App (Beta)。npm 安装即用。 |

### 🥈 Tier 2 — 参考架构/方案

| 项目 | Stars | 语言 | 核心价值 |
|------|-------|------|----------|
| [browser-use/browser-use](https://github.com/browser-use/browser-use) | 99,708★ | Python | 浏览器自动化标杆。Playwright + DOM + 视觉混合方案。架构模式可借鉴到桌面。 |
| [pywinauto/pywinauto](https://github.com/pywinauto/pywinauto) | 6,077★ | Python | **Windows GUI 自动化标准库**。Win32 API + UIA 后端。确定性元素定位。最适合作为 Windows MCP 的底层。 |
| [asweigart/pyautogui](https://github.com/asweigart/pyautogui) | 12,566★ | Python | 跨平台截图+键鼠。pywinauto 的兜底补充（应对不支持 UIA 的应用）。 |
| [showlab/computer_use_ootb](https://github.com/showlab/computer_use_ootb) | 1,949★ | Python | Anthropic computer-use 开箱即用版。Docker 沙箱。截图→LLM→Action 循环参考。 |
| [xlang-ai/OSWorld](https://github.com/xlang-ai/OSWorld) | 2,953★ | Python | OS 级 Agent 基准测试。NeurIPS 2024。评估框架参考。 |

### 🥉 Tier 3 — 补充参考

| 项目 | Stars | 语言 | 核心价值 |
|------|-------|------|----------|
| [OpenAdaptAI/OpenAdapt](https://github.com/OpenAdaptAI/OpenAdapt) | 1,618★ | Python | 录制→回放→AI 自动化。RPA 升级方案。 |
| [microsoft/WinAppDriver](https://github.com/microsoft/WinAppDriver) | 4,031★ | C# | Selenium 兼容 Windows 应用驱动。Appium 生态。 |
| [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) | 87,489★ | TypeScript | MCP 官方服务器集合。包含文件系统、GitHub、SQLite 等参考实现。 |
| [hrrrsn/mcp-vnc](https://github.com/hrrrsn/mcp-vnc) | 51★ | TypeScript | VNC 远程桌面 MCP。远程操控方案。 |

---

## 二、三种主流技术路线对比

### 路线 A：Accessibility Tree（推荐 ⭐⭐⭐⭐⭐）

**代表**: agent-desktop, UFO, pywinauto

| 优势 | 劣势 |
|------|------|
| 确定性元素定位（name/automationId/class） | 部分应用不支持 UIA（游戏、自定义渲染） |
| Token 极省（agent-desktop 声称 97% 节省） | Windows 和 macOS/Linux 的 a11y API 不同 |
| 速度快（直接 API 调用，无需截图） | 需要 per-app 适配 |
| 可获取完整 UI 树结构 | UWP/现代 WinUI 支持有限 |

**适合**: VS Code、Office、浏览器、UE Editor、标准 Win32/WPF 应用

### 路线 B：截图+视觉 LLM（通用但慢）

**代表**: Anthropic computer-use, computer_use_ootb

| 优势 | 劣势 |
|------|------|
| 任何应用都能操控 | Token 消耗巨大（每步传截图） |
| 不依赖 a11y 支持 | 精度低（坐标偏移问题） |
| 跨平台一致 | 延迟高（2-5秒/步） |
| 实现简单 | 无法处理动态内容 |

**适合**: 游戏、自定义渲染应用、a11y 不可用的场景

### 路线 C：混合方案（最佳实践 ⭐⭐⭐⭐⭐）

**代表**: UFO v2/v3, browser-use（浏览器域）

```
优先级链：
1. 先尝试 Accessibility Tree → 精确操控
2. Accessibility 失败 → 截图+OCR → 定位元素
3. 都失败 → 截图+视觉 LLM → 坐标点击（兜底）
```

---

## 三、推荐实现方案

### 方案：三层混合 Windows Computer Use MCP

```
┌──────────────────────────────────────────────┐
│           Hermes Agent (LLM)                 │
│         ↓ MCP tool calls                     │
├──────────────────────────────────────────────┤
│     windows-computer-use MCP Server          │
│  ┌─────────────┐ ┌──────────┐ ┌───────────┐ │
│  │ Layer 1:    │ │ Layer 2: │ │ Layer 3:  │ │
│  │ pywinauto   │ │ OCR+截图 │ │ 视觉LLM  │ │
│  │ (UIA/Win32) │ │ (Tesseract│ │ (Claude/ │ │
│  │ 精确定位     │ │ /WinOCR) │ │  GPT-4V) │ │
│  └─────────────┘ └──────────┘ └───────────┘ │
│         ↓ 优先级递减                          │
├──────────────────────────────────────────────┤
│  工具:                                        │
│  • computer_screenshot()                      │
│  • computer_click(x,y | element_name)         │
│  • computer_type(text)                        │
│  • computer_press_key(key)                    │
│  • computer_list_windows()                    │
│  • computer_activate_window(title)            │
│  • computer_get_uia_tree()                    │
│  • computer_scroll(direction, amount)         │
│  • computer_drag(from, to)                    │
│  • computer_wait_for_element(name, timeout)   │
└──────────────────────────────────────────────┘
```

### 集成路径

#### Phase 1: 即刻可用（1-2天）

1. **安装 DesktopCommanderMCP** → `hermes mcp add desktop-commander`
   - 即获终端控制 + 文件搜索 + diff 编辑
   - 已有 6000+ 星，成熟稳定

2. **安装 agent-desktop** → `npm install -g agent-desktop`
   - Rust 原生，Windows 支持
   - 通过 a11y tree 操控任何应用
   - 97% token 节省 vs 截图方案

3. **配置 Gateway + Telegram** → 随时随地指挥

#### Phase 2: UE5 深度集成（3-5天）

1. **安装 unreal-mcp** → 让 Hermes 直接控制 UE Editor
   - 创建/修改 Blueprint
   - Actor 管理
   - 编译 + 运行检查
   - 这是**项目专属杀手级能力**

2. **开发 windows-computer-use MCP** → 三层混合方案
   - 基于 pywinauto (Layer 1) + OCR (Layer 2) + 视觉 (Layer 3)

#### Phase 3: 自主化（1周+）

1. 多应用编排（参考 UFO³ Galaxy 架构）
2. Kanban 多 Agent 协作
3. Cron 定时巡检

---

## 四、学术论文参考

| 论文 | arXiv | 核心贡献 |
|------|-------|----------|
| UFO: UI-Focused Agent for Windows OS | 2402.03939 | Windows UI Agent，双 Agent 架构 |
| UFO²: Future-Ready Agent OS | 2504.14603 | 多设备编排，Galaxy 架构 |
| UFO³: Weaving the Digital Agent Galaxy | 2511.11332 | 跨设备、跨应用生态 |
| OSWorld: Benchmarking Multimodal Agents | NeurIPS 2024 | OS 级 Agent 评估基准 |
| Anthropic Computer Use Blog | anthropic.com/news | 截图→Action 循环参考 |

---

## 五、关键洞察

1. **agent-desktop 是最快路径** — Rust 原生、a11y tree、MCP 兼容、97% token 节省。不需要自己造轮子。

2. **unreal-mcp 是 UE 项目的杀手级集成** — 2000 星、活跃维护、直接控制 UE5 Editor。比自建 UE MCP 快 10 倍。

3. **UFO³ 的 Galaxy 架构是未来方向** — 从单设备 Agent 到多设备 Galaxy。我们的多 Profile 架构可以映射到这个模式。

4. **DesktopCommanderMCP 是最小启动成本** — 6k 星、TypeScript、npm 一行安装。今天就能用。

5. **混合方案是唯一正确答案** — 纯视觉太慢太贵，纯 a11y 有盲区，混合三层是工业级方案。

6. **Hermes 的架构优势是真实的** — Profile/MCP/Cron/Gateway/Skill/Memory 是所有 Agent 框架里最完整的。只差桌面操控这一块。

---

*研究由金璃好帮手完成，2026-06-21*
