---
id: candidate-ccswitch-opencode-go-glm52-config-2026-06-23
source: configuration_knowledge
status: candidate
phase: plan
project_type: other
module: cc-switch
severity: medium
tags:
  - phase:plan
  - mod:skill
  - dom:ai
  - pat:configuration
  - sys:cc-switch
  - sys:opencode
  - sys:codex
---

# Candidate: CC Switch — OpenCode Go (GLM-5.2) 手动配置知识

## Knowledge Summary

CC Switch 桌面应用的 SQLite 数据库中手动添加 OpenCode Go provider 以使用 GLM-5.2 模型的完整知识。

---

## Key Finding 1: CC Switch SQLite Schema

CC Switch 使用 SQLite 数据库存储 provider 配置，数据库位置：

```
C:\Users\87372\.cc-switch\cc-switch.db
```

核心表 `providers` 结构（关键列）：

| 列名 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | TEXT | UUID | `cc-10002` |
| `name` | TEXT | 显示名称 | `OpenCode Go (GLM-5.2)` |
| `app_type` | TEXT | Codex 或 OpenCode 标签页 | `codex` / `opencode` |
| `model` | TEXT | 默认模型 | `glm-5.2` |
| `base_url` | TEXT | API 端点 | `https://opencode.ai/zen/go/v1` |
| `api_key` | TEXT | API Key | `sk-0hYg...` |
| `wire_api` | TEXT | 协议格式 | `chat` |
| `catalog` | TEXT | JSON 模型列表 | `["glm-5.2","glm-5.1",...]` |
| `sort` | INTEGER | 排序 | `4100` |

**关键约束**：
- `app_type = 'codex'` → 显示在 Codex 标签页（当前目标）
- `app_type = 'opencode'` → 显示在 OpenCode 标签页
- `wire_api = 'chat'` → OpenAI chat completions 格式（Codex 使用）
- `api_key` 必须与 OpenCode Go 订阅的真实 key 匹配

---

## Key Finding 2: OpenCode Go vs Zen 端点区别

| 维度 | OpenCode Go（订阅） | OpenCode Zen（免费） |
|------|-------------------|-------------------|
| API 端点 | `https://opencode.ai/zen/go/v1` | `https://opencode.ai/zen/v1` |
| GLM-5.2 | ✅ 可用 | ❌ 无 |
| GLM-5.1 | ✅ 可用 | ✅ 可用 |
| DeepSeek V4 系列 | ✅ 可用 | ❌ 无 (仅 V3) |
| 需要付费 | ✅ Go 订阅 (wrk_01KV2XV32792J2E1XA6ZRGMQCK) | ❌ 免费额度 |
| API 格式 | OpenAI 兼容 | OpenAI 兼容 |

**核心教训**：GLM-5.2 **仅**在 Go 端点上可用。配置了 Zen 端点就拿不到 GLM-5.2。

---

## Key Finding 3: GLM-5.2 底层模型映射

- OpenCode Go 注册名：`glm-5.2`
- 底层实际模型：`accounts/fireworks/models/glm-5p2`
- 直连验证命令（PowerShell）：
```powershell
$body = @{
  model = "glm-5.2"
  messages = @(@{role="user"; content="ping"})
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://opencode.ai/zen/go/v1/chat/completions" `
  -Method Post -Headers @{Authorization="Bearer sk-0hYg0x..."} `
  -ContentType "application/json" -Body $body
```

---

## Key Finding 4: CC Switch 手动配置步骤

1. 打开 CC Switch SQLite 数据库（DB Browser for SQLite 或 sqlite3 CLI）
2. 在 `providers` 表中插入新行
3. 关键配置值：
   - `name`: `OpenCode Go (GLM-5.2)`
   - `app_type`: `codex`（显示在 Codex 标签页）
   - `model`: `glm-5.2`
   - `base_url`: `https://opencode.ai/zen/go/v1`
   - `api_key`: 从 `auth.json` 获取（`C:\Users\87372\.local\share\opencode\auth.json` 中的 `opencode-go` API key）
   - `wire_api`: `chat`
   - `catalog`: `["glm-5.2","glm-5.1","deepseek-v4-pro","deepseek-v4-flash","kimi-k2.7-code","minimax-m3"]`
4. 重启 CC Switch 桌面应用使配置生效
5. 在 Codex 标签页选择新 provider 并设为当前

---

## Reusable Rules

1. **CC Switch provider 的双路由**：`app_type` 决定 provider 出现在哪个标签页（codex vs opencode），不是由 UI 配置决定。
2. **端点决定模型可用性**：同一个模型在不同端点可能有不同的可用性（GLM-5.2 只有 Go 端点有）。
3. **SQLite 手动配置**：CC Switch 的 UI 只能添加常见 provider，不常见的需要通过 SQLite 手动插入。
4. **wire_api 必须匹配**：Codex 只认 `chat`（OpenAI 格式），设错会导致 API 调用失败。
5. **钱包检查**：Go 订阅有余额限制，如果 API 返回 Insufficient balance，在 https://opencode.ai/workspace/wrk_01KV2XV32792J2E1XA6ZRGMQCK/billing 充值。

## Promotion Check
- [ ] Observed or reproducible failure
- [ ] Reusable rule
- [ ] Clear verification method
- [ ] Useful for Router or Implement retrieval
