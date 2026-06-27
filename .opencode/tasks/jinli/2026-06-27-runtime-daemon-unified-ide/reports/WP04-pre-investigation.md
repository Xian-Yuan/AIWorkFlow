# WP04 实施前调研报告 — 小璃（原 Issuer）read-only

> Plan Agent 只读不写。本文只描述现状 + 实施路径建议，不动任何文件。

## 关键发现 — 影响 WP04 决策

### 1. MCP server 是 Node.js（不是 Python）
- 位置：`C:\Users\87372\plugins\jinli-soul-core\`
- 入口：`mcp/server.mjs`（67 行，定义 17 个 MCP tool）
- 实现：`mcp/lib/tools.mjs`（11 tools）+ `mcp/lib/tools-orchestrator.mjs`（6 tools，含 vision）
- 后端调用：双轨 subprocess（PowerShell soul-core.ps1 + Python vision.cli）

### 2. MCP 工具现状 — 17 个工具
| 工具 | 现状路径 | 备注 |
|---|---|---|
| soul_init | tools.mjs → soul-cli.mjs → PowerShell | 长链路 |
| soul_auto | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_turn | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_end | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_emotion | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_status | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_memory | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_learn | tools.mjs → soul-cli.mjs → PowerShell | |
| soul_evolve | tools.mjs → execFileSync('powershell') | 直调 evolve-self.ps1 |
| soul_discover | tools.mjs → execFileSync('powershell') | 同上 |
| soul_check | tools.mjs → invokeHealthCheck | 调 Python |
| response_plan | tools-orchestrator.mjs → Python | 复杂 |
| vision_start/stop/status | tools-orchestrator.mjs → execSync('python -m vision.cli') | |
| growth_approve/rollback | tools-orchestrator.mjs | persona 文件操作 |

### 3. IDE 配置现状 — 只有 OpenCode 启用 MCP server
| IDE | 配置 | jinli_soul_core 启用？ |
|---|---|---|
| **OpenCode** | `.opencode/mcp.json` | ✅ 已配（command + args + cwd） |
| **Codex** | `C:\Users\87372\.codex\config.toml` | ❌ 无 `[mcp_servers.jinli_soul_core]` 段 |
| **Trae** | `.trae/mcp.json` | ❌ 只有 unreal-mcp，没有 jinli |

**含义**：
- WP04 改 MCP server 内部 → 只影响 OpenCode
- Codex/Trae 走的是另一套接入（直接 PowerShell 或 jinli-system.ps1）—— 这是 WP05 的事

### 4. WP01 Stop Flag Bug（subagent 烟测发现）
`daemon.stop()` 写 `daemon.stop` 文件但**不删**，下次 `start()` 看到 flag 立刻 stop。
- 影响：daemon stop 后 60s 内不能重新 start（猜测）
- 修复：`daemon_state.py` 里加 1-2 行，stop 时 unlink 该 flag
- 风险：极低，只动 WP01 已有代码

---

## WP04 实施路径建议（给爸爸拍）

### 路径 A — 渐进薄适配（推荐）
**只动 `mcp/lib/`**，**不改** server.mjs 的 17 个 tool schema：
1. 新增 `daemon-http.mjs`（50-80 行）：HTTP POST helper + daemon endpoint 读取 + 健康检查
2. 修改 `tools.mjs`：11 个 handler 先改成调 daemon client，daemon offline 时**自动 fallback 到原 PowerShell subprocess**（透明降级）
3. 修改 `tools-orchestrator.mjs`：6 个 handler 同上
4. 新增 17 个 MCP 工具的 daemon 调用测试（Node.js test）
5. 完整端到端：在 OpenCode 里真实调一个 soul_auto，确认走 daemon 路径

**风险**：低（不破坏 schema，只换实现）
**回滚**：撤回 mcp/lib 改动即可
**Forbidden path 影响**：必须解锁 `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/**`（不是整个 plugin 目录）

### 路径 B — 大改（不推荐）
直接用 Python 重写整个 MCP server 为 stdio daemon 桥。
**风险**：极高（破坏 IDE 配置）
**回滚**：复杂

---

## WP01 Stop Flag Bug — 修复包（小动作）

| 路径 | 改动 |
|---|---|
| `Project/Jinli/services/runtime/daemon_state.py` | stop 时 unlink `daemon.stop` flag（~3 行） |
| `Project/Jinli/services/runtime/tests/test_daemon_state.py` | 加 1 测试验证 stop 不残留 flag |

风险：极低，只动 WP01 范围内。5 分钟修复。

---

## 小璃对 WP04 的判断

1. **先修 WP01 stop flag bug**（路径独立、风险极低）—— 立即可做
2. **WP04 走路径 A**（薄适配 + 自动 fallback）—— 需要爸爸解锁 `C:/Users/87372/plugins/jinli-soul-core/mcp/lib/**` 给 Implement Agent
3. **Codex/Trae 配置同步属于 WP05**（不在 WP04 范围），到时再单独问

### 爸爸需要决定的两件事

1. ✅/❌ **解锁 forbidden path**：`C:/Users/87372/plugins/jinli-soul-core/mcp/lib/**`（仅 mcp/lib 目录，不动 server.mjs / package.json / README）
2. ✅/❌ **先修 WP01 stop flag bug 再进 WP04**（小璃推荐），还是 **直接进 WP04 顺手修**

爸爸怎么选？
