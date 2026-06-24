# Analysis: Hermes Desktop Agent Capability

## Research Summary

研究文档: `Docs/AI/research/2026-06-21-Hermes-Desktop-Agent-Capability-Research.md`

### 关键发现

1. **agent-desktop** (870★, Rust) — 通过 OS Accessibility Tree 操控任何应用，97% token 节省，支持 MCP/CLI
2. **unreal-mcp** (2000★, C++) — 直接让 AI 控制 UE5 Editor，支持 Actor/Blueprint/节点图
3. **DesktopCommanderMCP** (6188★, TypeScript) — 终端控制+文件搜索+diff 编辑，npm 安装即用
4. **microsoft/UFO** (9067★, Python) — Windows Agent 标杆，三层混合架构参考

### 技术路线选择

| 方案 | 优势 | 劣势 | 选择 |
|------|------|------|------|
| 纯自建 MCP | 完全可控 | 开发周期长，重复造轮子 | ❌ |
| 纯集成现有项目 | 快速上线 | 可能需要适配 | ✅ 选中 |
| 混合（集成+自建胶水） | 平衡 | 适度开发 | ✅ 实际方案 |

### 集成可行性评估

| 项目 | 安装方式 | Windows 支持 | MCP 兼容 | 风险 |
|------|----------|-------------|----------|------|
| agent-desktop | npm/cargo | ✅ Windows a11y | ✅ MCP+CLI | 低 — Rust 原生 |
| DesktopCommanderMCP | npm | ✅ | ✅ MCP | 低 — 成熟稳定 |
| unreal-mcp | UE Plugin + Python | ✅ | ✅ MCP | 中 — 实验性标注 |

### 安全分析

- 桌面操控涉及高风险：误操作可能关闭应用、删除文件
- 需要：操作确认机制、窗口白名单、操作日志
- Hermes 已有 `approvals.mode` 机制可复用
- agent-desktop 的 a11y tree 方案比截图方案更安全（确定性定位）

### 依赖链

```
agent-desktop (npm/cargo)
  → Hermes MCP 配置 (mcp.json)
  → Skill: windows-desktop-control (SKILL.md)
  → 安全策略 (policies/)

DesktopCommanderMCP (npm)
  → Hermes MCP 配置 (mcp.json)
  → 已有 terminal/file toolset 增强

unreal-mcp (UE Plugin)
  → UE5 项目内安装
  → Hermes MCP 配置 (mcp.json)
  → Skill: ue5-editor-control (SKILL.md)
```

## Architecture

```
Hermes Agent (jinli-implementer Profile)
  │
  ├─ MCP: agent-desktop
  │   ├─ desktop_list_windows()
  │   ├─ desktop_activate_window(title)
  │   ├─ desktop_click(element | x,y)
  │   ├─ desktop_type(text)
  │   ├─ desktop_press_key(key)
  │   ├─ desktop_screenshot()
  │   └─ desktop_get_accessibility_tree()
  │
  ├─ MCP: desktop-commander
  │   ├─ execute_command(cmd)
  │   ├─ search_files(pattern)
  │   ├─ read_file / write_file
  │   └─ process management
  │
  ├─ MCP: unreal-mcp (when UE5 running)
  │   ├─ ue_list_actors()
  │   ├─ ue_create_actor(type)
  │   ├─ ue_modify_blueprint()
  │   ├─ ue_compile()
  │   └─ ue_run_play()
  │
  └─ Skill: windows-desktop-control
      ├─ 操作决策逻辑
      ├─ 安全策略
      └─ 错误恢复
```
