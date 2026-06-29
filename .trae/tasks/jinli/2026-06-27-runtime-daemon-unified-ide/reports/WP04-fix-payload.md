# WP04 Fix Payload — daemon memory_adapter items[] 真流到 MCP 端

**Task**: `2026-06-27-runtime-daemon-unified-ide` / WP04-fix-payload
**Scope**: 修复 WP04 Scope A 的诚实声明 — 让 `soul_memory` 真走 daemon 路径
**Generated**: 2026-06-28
**Implementer**: 金璃好帮手（Implement Agent）
**Status**: ✅ COMPLETED — all gates passed

---

## 0. TL;DR

WP04 Scope A 完成后，原 claim.json 诚实承认 `_wp04_source` 永远等于 `'powershell_fallback'`
（因为 `daemon memory_adapter.py:132-137 gather()` 末尾 `self._summarize(result)`
只返回 summary 字符串，items 列表被吃掉）。本次修复把 items 端到端打通：

- **修复链**:
  1. `memory_adapter.py` — `gather()` payload 加 `items` / `item_count` 字段
  2. `api_server.py` — `handle_memory_query` 顶层透出 `items` / `item_count` / `query`
  3. `daemon-http.mjs` — 修 `readEndpoint()` 把 `protocol` 硬写 `'http'`（与 Python `client.py:215` 对齐）
  4. `tools.mjs` — `soulMemoryHandler` 升级为 daemon-优先 + 统一 items 形状
- **修改文件** (6 个)：
  - **MOD** `Project\Jinli\services\runtime\adapters\memory_adapter.py` (+`_extract_items` +`_item_to_jsonobj` static methods)
  - **MOD** `Project\Jinli\services\runtime\api_server.py` (`handle_memory_query` 顶层 items 透出)
  - **NEW** `Project\Jinli\services\runtime\tests\test_memory_adapter_items.py` (24 tests)
  - **MOD** `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\daemon-http.mjs` (readEndpoint protocol 硬写 http)
  - **MOD** `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools.mjs` (`soulMemoryHandler` 升级)
  - **MOD** `C:\Users\87372\plugins\jinli-soul-core\mcp\tests\test_daemon_http.mjs` (翻转 source 断言 + 加 empty-items test)
- **测试覆盖**:
  - **24/24 pass** — `test_memory_adapter_items.py` (new) — 覆盖 5 个 RecallResult/list/dict/str/None 形状
  - **15/15 pass** — `test_daemon_http.mjs` (Node.js) — 比 WP04 多了 1 个 empty-items test
  - **129/129 pass** — 全量 pytest (105 baseline + 24 new, **零回归**)
- **真实烟测**:
  - daemon 启动 → `curl POST /memory/query` 真返 `items=[1 item]`, `item_count=1`, `ok=true`
  - Node `soulMemoryHandler` 真返 `_wp04_source='daemon'`（非 powershell_fallback）

---

## 1. 修复前后对比

### 1.1 修复前 (WP04 Scope A 原始状态)

**daemon 端** `memory_adapter.py:131-143`:
```python
summary = self._summarize(result)
return gathered_record(
    self.key,
    source=self._import_path,
    summary=summary,
    payload={
        "asked": manifest.user_input,
        "result_summary": summary,
        # ← 缺 items / item_count
    },
)
```

**curl 响应**:
```json
{
  "ok": true,
  "memory_evidence": {
    "status": "gathered",
    "payload": {
      "asked": "jinli daemon",
      "result_summary": "recall returned 1 items"  // ← 只有 summary
    }
  }
}
```

**Node `soulMemoryHandler`**: 即使 daemon reachable, items 为空 → 走 PowerShell fallback
**`_wp04_source`**: 永远 `'powershell_fallback'`

### 1.2 修复后 (WP04-fix-payload)

**daemon 端** `memory_adapter.py:131-143` (改完):
```python
summary = self._summarize(result)
items = self._extract_items(result)  # ← 新增
return gathered_record(
    self.key,
    source=self._import_path,
    summary=summary,
    payload={
        "asked": manifest.user_input,
        "result_summary": summary,
        "items": items,            # ← WP04-fix-payload: surface real items
        "item_count": len(items),
    },
)
```

**curl 响应** (真实烟测 output):
```json
{
  "ok": true,
  "items": [{"layer": "L3", "memory_id": "prc_6f6359ff54_97ff58", "subject": "rule.call-user-daddy", "summary": "...", "importance": 1.0, ...}],
  "item_count": 1,
  "query": "jinli daemon",
  "memory_evidence": {
    "status": "gathered",
    "source": "Project.Jinli.services.memory.memory_service",
    "summary": "recall returned 1 items",
    "payload": {"asked": "...", "result_summary": "...", "items": [...], "item_count": 1},
    "degradation_reason": ""
  }
}
```

**Node `soulMemoryHandler`** (smoke test output):
```
query="jinli daemon" items=1 sources=["daemon"] types=["L3"] ids=["prc_6f6359ff54_97ff58"]
query="rule.call-user-daddy" items=2 sources=["daemon","daemon"] types=["L3","L1"] ids=["prc_...", "ep_..."]
query="completely-unmatched-zzz" items=0 sources=[] types=[]  (空也走 daemon 路径)
```

**`_wp04_source`**: `'daemon'` (daemon 在线 + ok=true 时)

---

## 2. 文件变更明细

### 2.1 MOD: `Project\Jinli\services\runtime\adapters\memory_adapter.py`

**目的**: 让 `gather()` payload 包含真实 items 列表，不只 summary 字符串

**变更**:
- 新增 `@staticmethod _extract_items(result)` (lines 161-202):
  - 处理 RecallResult dataclass / list / dict / str / None 五种 shape
  - RecallResult → `list(result.items)` + `_item_to_jsonobj` 归一化
  - dict with `items`/`memories`/`results`/`records` key → 取该 list
  - str → 单元素 list (或空)
  - None → `[]`
- 新增 `@staticmethod _item_to_jsonobj(item)` (lines 204-219):
  - 有 `to_dict()` 的对象 → 调 `to_dict()` (失败 fallback `str(item)`)
  - dict/str/other → 原样返回 (不丢信息)
- `gather()` payload 末尾加 `"items": items, "item_count": len(items)` (lines 137-141)
- `_summarize()` 加 RecallResult dataclass 处理 (lines 154-157)

### 2.2 MOD: `Project\Jinli\services\runtime\api_server.py`

**目的**: `handle_memory_query` 顶层透出 items，不要 caller 钻进 `memory_evidence.payload.items`

**变更**:
- `handle_memory_query` (lines 303-...) 返顶层 `items` / `item_count` / `query`
- `memory_evidence` 完整保留 (向下兼容已有 caller)
- 失败路径 (`ok=False`): `"error": "bad_request" | "memory_query_failed"`
- degraded 路径: `ok=True` + `items=[]` + `item_count=0` (caller 不需 special-case None)
- `typing` import 加 `List`

### 2.3 NEW: `Project\Jinli\services\runtime\tests\test_memory_adapter_items.py`

**目的**: 24 tests 覆盖 5 种 input shape + handle_memory_query 响应形状

**结构** (3 describe blocks):
- `TestExtractItems` (12 tests) — RecallResult/list/dict/str/None/edge cases
- `TestGatherReturnsItemsInPayload` (5 tests) — 真实 MemoryService 路径 + mock factory
- `TestHandleMemoryQueryResponseShape` (7 tests) — curl-shape contract: ok/items/item_count/query/evidence

### 2.4 MOD: `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\daemon-http.mjs`

**目的**: 修复 readEndpoint 返回的 `protocol: "tcp"` 实际是 HTTP 协议

**根因**: `daemon.py:331` 把 `protocol` 写为 `"tcp"` (raw transport label),
但 `client.py:215` Python 端硬写 `http://` 不读 endpoint.protocol。Node 端
原 `daemon-http.mjs:154` 用 `${ep.protocol}://` 拼 URL → `tcp://127.0.0.1:62667/memory/query`
不是合法 HTTP URL，Node `fetch()` 抛错 → daemonPost 返 null → handler 走 fallback。

**变更** (lines 154-160):
```js
// WP04-fix-payload: 强制 http (与 Python client.py:215 对齐)
const protocol = 'http';
return { host, port, pid, protocol };
```

### 2.5 MOD: `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools.mjs`

**目的**: `soulMemoryHandler` 升级为 daemon-优先 + 统一 items 形状

**变更**:
- 新增 `_normalizeDaemonItem(item)` (lines 307-345):
  - PowerShell-shape 字段 (id/type/content/weight/decay_factor/recall_count) — 向下兼容
  - daemon-shape 字段 (layer/memory_id/subject/summary/importance/score/strength/timestamp/tokens/related_subjects/extra) — 不丢信息
- 新增 `_callDaemon(query, maxTokens)` (lines 351-369):
  - readEndpoint → tcpReachable → daemonPost 三段 fail-soft
  - 返 `{ok, reason, evidence}` 统一结构
  - 永不抛 (try/catch)
- `soulMemoryHandler` 重写 (lines 371-423):
  - daemon 路径 (ok=true) → 真用 items, 标 `_wp04_source='daemon'`
  - fallback 路径 → PowerShell, 标 `_wp04_source='powershell_fallback'` + `_wp04_fallback_reason`
  - items 空列表也是合法 daemon 结果 (不静默 fallback)

### 2.6 MOD: `C:\Users\87372\plugins\jinli-soul-core\mcp\tests\test_daemon_http.mjs`

**目的**: 翻转 source 断言 + 加 empty-items test

**变更**:
- 旧 test "returns array with _wp04_daemon_reachable=true..." → 新 test
  "returns array with _wp04_source=daemon when daemon is alive" (asserts source='daemon')
- 新 test "returns empty array when daemon online but no items match" — 验证
  即使 items=[] 也走 daemon 路径 (不静默 fallback)

---

## 3. 验证证据

### 3.1 Pytest (Python 端)

```
$ python -m pytest Project/Jinli/services/runtime/tests/ -q
........................................................................
............................................................         [100%]
129 passed in 61.95s (0:01:01)
```

**105 baseline + 24 new = 129, 零回归。**

### 3.2 Node Tests

```
$ node --test ./mcp/tests/test_daemon_http.mjs
...
tests 15
suites 6
pass 15
fail 0
cancelled 0
skipped 0
todo 0
duration_ms 32520.7499
```

**15/15 pass (比 WP04 多了 1 个 empty-items test)。**

### 3.3 真实 daemon curl 烟测

```bash
$ python curl_memory_query.py 62667 'jinli daemon'
```

返回:
- `ok=True`
- `items_type=list`
- `items_len=1`
- `item_count=1`
- `query='jinli daemon'`
- `evidence.status='gathered'`
- `evidence.summary='recall returned 1 items'`
- `first_item_keys=['layer', 'memory_id', 'subject', 'summary', 'importance', 'decision', 'score', 'strength', 'recall_count', 'tokens', 'related_subjects', 'timestamp', 'extra']`

### 3.4 Node smoke handler (daemon 在线)

```
query="jinli daemon"                  items=1  sources=["daemon"]
query="rule.call-user-daddy"          items=2  sources=["daemon","daemon"]
query="completely-unmatched-zzz"      items=0  sources=[] (daemon 路径，不 fallback)
```

**`_wp04_source='daemon'` 真生效。**

---

## 4. 设计决策

### 4.1 items 形状统一

daemon items 同时含 **PowerShell 形状字段** (向后兼容) + **daemon 完整字段** (不丢信息):

```js
{
  // PowerShell-shape (backward compat)
  id: 'prc_6f6359ff54_97ff58',
  type: 'L3',
  content: '...',
  weight: 1.0,
  decay_factor: 1.0,
  recall_count: 0,
  // Daemon-shape (new — full recall metadata)
  layer: 'L3',
  memory_id: 'prc_6f6359ff54_97ff58',
  subject: 'rule.call-user-daddy',
  summary: '...',
  importance: 1.0,
  score: 1.0,
  strength: 1.0,
  timestamp: '2026-06-24T18:06:22.768538Z',
  tokens: 55,
  related_subjects: ['jinli.identity.address-preference'],
  extra: {pattern_type: 'tool_usage', environment: null},
  // WP04 diagnostics
  _wp04_source: 'daemon',
  _wp04_daemon_reachable: true,
  _wp04_daemon_summary: 'recall returned 1 items',
  _wp04_daemon_status: 'gathered',
  _wp04_daemon_attempted: true,
  _wp04_fallback_reason: null,
}
```

### 4.2 degraded 路径不假装 ok

`handle_memory_query` degraded 路径返 `ok=True` + `items=[]` + `item_count=0` +
`memory_evidence.status='degraded'`。**不静默 fallback** — caller 可从 evidence
判断真实状态。

### 4.3 adapter 抛错不掩饰

`handle_memory_query` MemoryAdapter 抛错 → `ok=False` + `error='memory_query_failed'`
+ `message=str(exc)`。**不假装 ok**。

### 4.4 空 list 是合法 daemon 结果

daemon 在线 + ok=true + items=[] → handler 返 `[]` + `_wp04_source='daemon'`
**不是** 静默 fallback。empty 本身就是"我问了但没匹配"的有效答案。

### 4.5 daemon-http.mjs protocol 硬写 'http'

不读 `endpointDoc.protocol` (因为 daemon 写错的 raw transport label)。
与 Python `client.py:215` 行为完全一致。

---

## 5. 范围遵守 (vs. WP04-fix-payload handoff)

### 5.1 已改文件 (unlocked 列表内)

| Path | 状态 | 备注 |
|---|---|---|
| `Project\Jinli\services\runtime\adapters\memory_adapter.py` | MODIFIED | +`__extract_items` +`_item_to_jsonobj` |
| `Project\Jinli\services\runtime\api_server.py` | MODIFIED (handle_memory_query only) | 顶层 items 透出 |
| `Project\Jinli\services\runtime\tests\test_memory_adapter_items.py` | NEW | 24 tests |
| `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\daemon-http.mjs` | MODIFIED | readEndpoint protocol 硬写 http |
| `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools.mjs` | MODIFIED (soulMemoryHandler only) | daemon-优先 + 统一形状 |
| `C:\Users\87372\plugins\jinli-soul-core\mcp\tests\test_daemon_http.mjs` | MODIFIED | 翻转 source 断言 + 加 empty-items test |

### 5.2 未触碰 (forbidden 列表内)

- `C:\Users\87372\plugins\jinli-soul-core\package.json`
- 17 tool schemas (server.mjs OUTPUT_SCHEMAS 未改)
- `C:\Users\87372\plugins\jinli-soul-core\mcp\server.mjs`
- `daemon.py` / `client.py` / `paths.py` / `daemon_state.py` / `service_registry*.py`
- `turn_manifest.py` / `turn_orchestrator.py` / `response_gate.py`
- `after_turn_commit.py` / `route_index.py` (WP01-03 稳定产品)
- `.task.yaml` / `routing.md` / `analysis.md` / `spec.md` / `tasks.md` / `requirements.md` / `execution-prompt.md`
- `.opencode/**`
- `C:\Users\87372\.codex\**`
- 16 个未迁移 tool handler (soul_init/auto/turn/end/emotion/status/learn/evolve/discover/check/response_plan/vision_*/growth_*)

### 5.3 额外修复 (超出 unlocked 列表外的发现)

`daemon-http.mjs` 修复是 WP04-fix-payload **unlocked 列表内**。不属于额外发现。
原 handler (WP04 写的) 用 `${ep.protocol}://` 拼 URL，daemon endpoint 里 `protocol='tcp'`
是 daemon.py:331 写错的 label，本次修改让 Node 端与 Python `client.py:215` 行为一致。

---

## 6. WP05+ Readiness

本次 fix 把 `_wp04_source='powershell_fallback'` 永远假阳性的根因消除了。
scope B (迁移 16 个未迁移工具到 daemon) 的前置条件已就绪:

- ✅ `daemon_http.py` 服务端稳定 (api_server.py)
- ✅ Node 端 `daemon-http.mjs` 适配层稳定 (daemonPost + readEndpoint 修对)
- ✅ `tools.mjs` daemon 优先模式可用 (`_callDaemon` 模板)
- ✅ Zod passthrough 容忍 `_wp04_*` 诊断字段
- ✅ pytest 129/129 + node --test 15/15 零回归

**建议 WP05+**: 优先迁移 GET 类只读工具 (soul_emotion/soul_status/soul_check)
— daemon 端已有对应端点或可一行加，风险最低。

---

## 7. 已知限制 (honest)

- **空 memory 库测试**: `test_memory_adapter_items.py` 的 degraded path tests 覆盖
  `status='missing'` / `status='degraded'` + `items=[]` (无 FTS5 / LLM embedder 环境)。
  真实环境 (有 FTS5) 下 `status='gathered'` + `items=[N]` (curl 烟测已验证)。
- **daemon 端 `protocol: "tcp"` 标签错误**: `daemon.py:331` 仍写 `"tcp"`。
  本次 fix 在 Node 端硬覆盖为 `"http"`，不修 daemon.py（避免扩大 scope）。
  WP05+ 可顺手把 daemon.py:331 改为 `"http"`。
- **未迁移工具的 _wp04 字段未标记**: 16 个未迁移工具的 handler 仍无 `_wp04_*` 字段
  (因为它们不走 daemon)。这是正确的 — 只有 daemon-走过的工具才有 source tag。

---

**Report version**: 1.0 | **Generated**: 2026-06-28 | **Status**: COMPLETED
