---
id: candidate-hermes-api-config-pitfalls-2026-06-22
source: multi-session_debugging
status: candidate
phase: plan
project_type: other
module: hermes-agent
severity: high
tags:
  - phase:plan
  - mod:hermes-agent
  - dom:api-config
  - pat:provider-key-mismatch
  - pat:api-mode-misdetection
  - pat:context-compression-failure
  - sys:hermes
  - sys:codex
  - sys:opencode
---

# Candidate: Hermes/Codex/OpenCode API 配置踩坑与常见故障

## Failure Event

Hermes Agent 连续多会话无法正常对话——回复出现 1s 后消失、对话历史丢失/重复、自动中断。根因是模型 API 配置链路断裂：provider 和实际 key 不匹配，api_mode 被误检测，context compression 因认证失败而静默截断上下文。

## Evidence

### 1. Provider 与 API Key 不匹配（致命）

**现象**: Hermes 对话回复闪现后消失，日志报 `HTTP 401: Missing Authentication header`。

**根因**: `config.yaml` 配置 `provider: openrouter`，但 `.env` 里的 `OPENROUTER_API_KEY` 实际是讯飞（Xunfei）的 API key（格式 `ed6388ae...`，65 字符），不是 OpenRouter 的 `sk-or-...` 格式 key。OpenRouter 收到不属于它的 key 就直接 401。

**规则**: 
- **每个 provider 的 key 有独特格式**，不能混用：
  - OpenRouter: `sk-or-...`
  - MiniMax-CN: `sk-cp-...`
  - 讯飞/Xunfei: `{apiSecret}:{apiKey}` 编码格式
  - NVIDIA: `nvapi-...`
  - Z.AI/GLM: `ed6388ae...` 格式（32位hex:base64）
- **绝不能把 A provider 的 key 塞进 B provider 的 env var**。Hermes 的 `OPENROUTER_API_KEY` 只能放 OpenRouter key。
- 如果没有某个 provider 的真实 key，就不要配置为该 provider。

### 2. 模型名与 Endpoint 不匹配（致命）

**现象**: 日志报 `PathDomainError: Model Not Found`。

**根因**: 讯飞 coding endpoint (`maas-coding-api.cn-huabei-1.xf-yun.com/v2`) 不认 `glm-5.1` 这个模型名。它只认自己注册的模型 ID，如 `astron-code-latest`。而 `z-ai/glm-5.1` 是 OpenRouter 上注册的模型路由 ID，只能通过 OpenRouter 的 API 调用。

**规则**:
- **模型名是 endpoint 特定的**。同一个底层模型在不同 provider 有不同 ID：
  - OpenRouter: `z-ai/glm-5.1`, `deepseek/deepseek-v4-pro`
  - 讯飞 Coding: `astron-code-latest`
  - MiniMax-CN: `MiniMax-M3`, `minimax-m2.7`
  - Z.AI 官方: `glm-5`, `glm-4-9b`
- 换 provider 必须同时换模型名。

### 3. api_mode 误检测（严重）

**现象**: 配置了 `minimax-cn` provider 后，Hermes 自动把 `api_mode` 设为 `anthropic_messages`，导致请求格式不匹配。

**根因**: Hermes 的 `runtime_provider.py` 有 URL 自动检测逻辑——如果 base_url 以 `/anthropic` 结尾，自动切换为 `anthropic_messages`。MiniMax-CN 的某些 endpoint 路径触发了这个误判。

**规则**:
- MiniMax-CN (`api.minimaxi.com/v1`) 是 OpenAI 兼容协议，必须用 `chat_completions`。
- 讯飞 Coding endpoint 也是 OpenAI 兼容，必须用 `chat_completions`。
- **务必在 config.yaml 里显式设置 `api_mode: chat_completions`**，不要依赖自动检测。
- 只有这些情况用非 chat_completions：
  - `api.openai.com` → `codex_responses`（GPT-5.x 工具调用）
  - `api.x.ai` → `codex_responses`
  - URL 含 `/anthropic` → `anthropic_messages`
  - `api.kimi.com/coding` → `anthropic_messages`

### 4. Context Compression 认证失败导致暴力截断（严重）

**现象**: 对话历史丢失最新内容，上下文被暴力截断。

**根因**: Hermes 的 context compression（上下文压缩）使用独立的 auxiliary.compression 配置。如果 compression 的 provider/key 配置错误（如指向 OpenRouter 但 key 是讯飞的），compression API 调用 401 失败，Hermes 不会报错给用户，而是静默地跳过压缩，直接暴力截断上下文到 `context_length` 限制。

**规则**:
- `auxiliary.compression` 的 provider 和 key 必须独立配置正确，不能依赖主模型的 provider。
- 压缩失败时，`abort_on_summary_failure: true` 比 `false` 更安全——至少会报错而不是静默截断。
- 当前正确配置：`compression.provider: minimax-cn, compression.model: MiniMax-M3`。

### 5. Hermes auth.json Credential Pool 状态污染

**现象**: 即使修复了 config.yaml，Hermes 仍然用旧 provider 发请求。

**根因**: Hermes 的 `auth.json` 里维护一个 credential pool，记录每个 provider 的 key 状态。如果之前用 OpenRouter 401 失败过，`last_status: "exhausted"` 会被缓存。即使 config 改了 provider，旧 pool 记录可能干扰路由。

**规则**:
- 改完 config 后，检查并清理 `auth.json` 里的 `last_status: exhausted` 记录。
- 路径：`.tools/hermes-worker/auth.json` 和每个 profile 下的 `auth.json`。

### 6. Codex / OpenCode 的 API 配置

**Codex**（当前环境）:
- API 配置在 Codex Desktop App 的设置界面，不在项目文件里。
- 使用 OpenAI 官方认证，不走 OpenRouter。
- 项目级别的 skill/config 不影响 Codex 自身的模型选择。

**OpenCode**:
- API 配置在 `~/.opencode/config.json` 或 `~/.config/opencode/config.json`。
- 支持 NVIDIA provider（`NVIDIA_API_KEY` env var）。
- 模型路由：`deepseek-ai/deepseek-v4-pro`, `z-ai/glm-5.1` 等走 NVIDIA endpoint。

### 7. 同步脚本硬编码检查

**现象**: 修复 config 后，下次运行 `sync-hermes-workflow.ps1` 又把配置改回错误的值。

**根因**: 脚本里的 `Test-JinliModelPairing` 函数硬编码了 `provider must be openrouter` + `default must be z-ai/glm-5.1` 的检查。

**规则**:
- 同步脚本的模型配对检查必须跟实际 provider 保持同步。
- 当前正确值：`provider: minimax-cn, default: MiniMax-M3, context_length: 1000000`。

## Draft Root Cause

Hermes 的 API 配置是多层的（config.yaml → .env → auth.json → runtime_provider.py 自动检测 → credential pool），任何一层不匹配都会导致请求失败。最危险的失败模式是"静默失败"——compression 401 后暴力截断、api_mode 误检后格式不匹配、credential pool 缓存旧状态——这些都不给用户明确的错误提示。

## Draft Rule

1. **Provider ↔ Key ↔ Model 三位一体**：换 provider 必须同时换 key env var 和模型名，三者缺一不可。
2. **显式 api_mode**：不信任自动检测，在 config.yaml 里显式写明。
3. **Compression 独立验证**：auxiliary.compression 的 provider/key 必须独立可用，直连测试通过。
4. **auth.json 清理**：改 provider 后手动清理 credential pool 的 exhausted 状态。
5. **同步脚本联动**：config 改完后必须同步更新 sync 脚本的硬编码检查。
6. **直连验证优先**：改完配置后先用 Python/curl 直接调 API 验证 200，再启动 Hermes。

## Promotion Check
- [x] Observed or reproducible failure
- [x] Reusable rule
- [x] Clear verification method
- [x] Useful for Router or Implement retrieval
