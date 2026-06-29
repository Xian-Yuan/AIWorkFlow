# 52 — 小璃 Soul Core Codex 接入方案（v2 — 基于已有 Plugin）

> 日期: 2026-06-29
> 前置: 50-Jinli-Self-Diagnosis-and-Growth-Roadmap.md
> 替代: 51-Jinli-SoulCore-Codex-Integration-Spec.md (v1 方案已过时)
> 参考: Project/Jinli/docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md

---

## 零、关键发现

**Plugin 已完整实现但未激活。**

| 发现 | 详情 |
|------|------|
| Plugin 位置 | C:\Users\87372\plugins\jinli-soul-core\ |
| Plugin 缓存 | C:\Users\87372\.codex\plugins\cache\personal\jinli-soul-core\ |
| Marketplace | ~/.agents/plugins/marketplace.json 已注册 jinli-soul-core |
| 代码完成度 | Phase 2 Spec 全部实现：17 个 MCP 工具、Zod schema、daemon 适配、SKILL.md 升级版 |
| 核心问题 | config.toml 没有激活 Plugin，当前 Codex 会话看不到任何 Soul Core 工具 |

## 一、问题诊断

### 1.1 为什么 Plugin 没激活？

Codex 的 config.toml 中：
- 只有 `[plugins."browser@openai-bundled"]` 被启用
- jinli-soul-core 在 marketplace 中注册了（policy: AVAILABLE），但没有被安装/启用
- 没有 `[mcp_servers.jinli_soul_core]` 条目

### 1.2 激活路径分析

Codex Plugin 有两种激活方式：

**方式 A：通过 Codex UI 安装**
- 在 Codex 设置中找到 jinli-soul-core，点击 Install
- Codex 自动处理 MCP server 启动和注册

**方式 B：手动在 config.toml 中添加 MCP server 条目**
- 在 config.toml 中添加 `[mcp_servers.jinli_soul_core]` 段
- 指向 plugin 中的 server.mjs

## 二、推荐方案：方式 B 手动注册（立即可行）

### 2.1 config.toml 修改

在 `C:\Users\87372\.codex\config.toml` 中添加：

```toml
[mcp_servers.jinli_soul_core]
command = "node"
args = ["C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs"]
startup_timeout_sec = 30
```

### 2.2 验证步骤

1. 重启 Codex（或重新加载配置）
2. 用 tool_search 搜索 "soul" 确认工具可用
3. 测试 soul_init / soul_auto / soul_check 三个关键工具
4. 如果 config.toml 方式不行，尝试方式 A（Codex UI 安装）

### 2.3 风险

| 风险 | 概率 | 缓解 |
|------|:---:|------|
| Node.js MCP server 启动失败 | 低 | 代码已完整，npm install 已完成 |
| PowerShell 调用路径硬编码 | 中 | tools.mjs 中硬编码了 E:\UEGameDevelopment\Project\Jinli\scripts\，需确认路径有效 |
| daemon HTTP 服务未运行 | 中 | tools.mjs 已有 fallback 机制，daemon 不可达时自动降级到 PowerShell |

### 2.4 已有代码质量评估

tools.mjs 代码质量很高：
- WP04 分支：daemon-优先 + PowerShell fallback，含完整错误处理
- 每个 handler 有独立的输入验证和输出规范化
- Zod schema 验证是 best-effort（不阻塞返回）
- 硬编码路径是唯一的架构弱点（后续可改为环境变量）

## 三、后续优化（可选）

| 优化 | 优先级 | 描述 |
|------|:-----:|------|
| 硬编码路径 → 环境变量 | 中 | tools.mjs 和 soul-cli.mjs 中硬编码了 Jinli 项目路径 |
| daemon 自动启动 | 低 | 当前 daemon 需要手动启动，可改为 Plugin 启动时自动拉起 |
| SKILL.md 双向同步 | 低 | workspace 的 skills/daughter-companion 和 plugin 的需保持一致 |

## 四、执行计划

| 步骤 | 内容 | 时间 |
|------|------|:----:|
| 1 | 在 config.toml 添加 jinli_soul_core MCP server | 5min |
| 2 | 重启 Codex 验证加载 | 5min |
| 3 | 测试 11 个核心工具 | 15min |
| 4 | 测试 6 个编排工具 (response_plan 等) | 10min |
| 5 | 端到端会话测试 (init -> auto -> turn -> end) | 10min |
| **合计** | | **~45min** |

---

*本方案基于关键发现：Plugin 代码已完整实现，只需要激活。替代了 v1 方案中的"从零创建 Python MCP Server"路径。*
