# Analysis: Jinli Soul Core MCP Plugin

> **完整分析见设计文档**: `Project/Jinli/Docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md` (676 行，含架构设计、工具定义、实现规范、验收标准)

## Architecture Context
- 三层架构: SKILL.md (指令层) → MCP Server (工具层) → soul-core.ps1 (引擎层)
- 11 个 MCP 工具映射 11 个 CLI 命令
- Node.js + @modelcontextprotocol/sdk + zod

### System boundaries
- Plugin: C:\Users\87372\plugins\jinli-soul-core\ (NEW)
- Engine: Project/Jinli/scripts/soul-core.ps1 (unchanged)
- Data: Project/Jinli/data/ (unchanged, read-only for Plugin)
- SKILL.md: migrated from skills/ to plugin/skills/

### Dependency map
- types.mjs → tools.mjs → server.mjs → E2E test
- SKILL.md upgrade independent of Server implementation

## Mature Solution Evidence
- 参考现有 creative-production / data-analytics / github plugins
- Codex MCP 标准 runtime (Node.js 24)
- 引擎层零改动，风险隔离

### Project-local evidence
- Soul Core v1.1: 18 Pester tests passing, full release archived
- Agent Bridge v2.0: proven CLI integration pattern
- Self-Evolution Engine: proven evolve-self.ps1 CLI pattern

### Official/framework evidence
- Codex MCP Plugin system: standard plugin.json + .mcp.json + package.json format
- @modelcontextprotocol/sdk ^1.29: official MCP Server implementation
- zod ^4.4: standard schema validation for tool inputs/outputs

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| MCP Plugin (this spec) | Type-safe, guaranteed execution, native tooling | Requires Node.js, new code | **Selected** |
| SKILL.md only (current) | Zero new code, already working | Unreliable triggering, fragile parsing | Current baseline |
| Wrapper script | Simpler than MCP | Not native tooling, same fragility | Rejected |

### Rejected shortcuts
- Do NOT skip MCP Server and keep SKILL.md-only (unreliable triggering)
- Do NOT modify soul-core.ps1 to add HTTP API (engine stays pure CLI)
- Do NOT auto-apply SKILL.md changes without testing each tool

### Selected mature path
Implement MCP Plugin per the 676-line design spec: Node.js MCP Server wrapping soul-core.ps1 CLI with 11 type-safe tools. Upgrade SKILL.md from PowerShell commands to MCP tool calls. Engine and data layers unchanged.

## Acceptance Criteria
AC01-AC12: 功能验收（每个工具正确返回结构化 JSON），详见 spec §8
NF01-NF05: 非功能验收（性能、并发、schema 验证），详见 spec §8

## Automated Verification Plan
- 逐个工具调用验证 (soul_init/auto/turn/end/status/memory/learn/evolve/discover/check)
- Pester 18 测试零回归
- soul-core-safety-assert.ps1 全部通过

## Allowed / Forbidden Changes
See routing.md
