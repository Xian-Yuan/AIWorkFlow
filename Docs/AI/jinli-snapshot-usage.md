# jinli-snapshot.ps1 — 小璃系统审计快照

> 自动生成/采集时间: 2026-06-26

## 用途

对当前 workspace 中"小璃"（双 Agent 架构 + Soul Core + 强制机制）的真实状态做一次性快照，用于：

- 审计小璃系统是否"按设计活着"
- 比较不同时间点的状态变化（`-Compare`）
- CI 门禁：发现 CRITICAL 缺口时退出码非零（`-Strict`）
- 给 Ba Ba 做"今天到底跑成什么样"的事实依据

## 快速使用

```powershell
# 默认 Apply 模式: 写到 .trae\state\jinli-snapshot.json
.\.trae\scripts\jinli-snapshot.ps1

# DryRun: 打印 JSON 到 stdout,不写文件
.\.trae\scripts\jinli-snapshot.ps1 -DryRun

# Apply + Json: 既写文件又打印 JSON
.\.trae\scripts\jinli-snapshot.ps1 -Apply -Json

# 自定义输出路径
.\.trae\scripts\jinli-snapshot.ps1 -Apply -OutputPath "D:\audit\snapshot.json"

# Strict: 发现 CRITICAL gap 时 exit 2 (CI 用)
.\.trae\scripts\jinli-snapshot.ps1 -Strict

# Compare: 与上一次快照对比,打印 diff
.\.trae\scripts\jinli-snapshot.ps1 -Compare

# 解决 ExecutionPolicy 限制
powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\.trae\scripts\jinli-snapshot.ps1 -DryRun
```

## 输出结构 (15 个顶层字段)

```json
{
  "snapshot_version": "1.0",
  "generated_at": "2026-06-26T02:45:42Z",
  "tool": "jinli-snapshot.ps1",
  "tool_version": "1.0.0",
  "workspace": "E:\\UEGameDevelopment",
  "overall_status": "ok|warn|critical",
  "summary": {
    "skill_files_checked": 4,
    "skill_files_present": 4,
    "authority_state": "ok|missing|invalid",
    "opencode_agents_count": 2,
    "active_tasks_count": 69,
    "tasks_with_doc_impact": 69,
    "critical_gaps": 0,
    "warn_gaps": 0,
    "info_gaps": null
  },
  "skills": {
    "plan_agent":         { "exists": true, "path": "...", "frontmatter": {...}, "meta": {"size_bytes":..., "sha256":..., "modified_at":...} },
    "implement_agent":    { ... },
    "soul_core_contract": { ... },
    "soul_engine_ref":    { ... }
  },
  "authority": {
    "issuer_key_id": "...",
    "issuer_public_exists": true,
    "issuer_private_exists": false,
    "issuer_sid": "S-1-...",
    "algorithm": "ECDSA_P256_SHA256",
    "public_blob_sha256": "..."
  },
  "opencode_agents": [
    { "id": "plan", "path": ".opencode\\agents\\金璃小天才.md", "exists": true, "references_canonical": true, ... },
    { "id": "implement", "path": ".opencode\\agents\\金璃好帮手.md", "exists": true, "references_canonical": true, ... }
  ],
  "skill_directories": [
    { "id": "skills",        "path": "skills/",         "summary": {"exists": true, "subdir_count": 74} },
    { "id": "trae_skills",   "path": ".trae/skills/",   "summary": {"exists": true, "subdir_count": 74} },
    { "id": "opencode_skills", "path": ".opencode/skills/", "summary": {"exists": true, "subdir_count": 74} },
    { "id": "codex_skills",  "path": ".codex/skills/",  "summary": {"exists": true, "subdir_count": 74} },
    { "id": "agents_skills", "path": "agents/",         "summary": {"exists": true, "subdir_count": 74} }
  ],
  "active_tasks": [
    { "project": "jinli", "task": "2026-06-23-T13-retro", "path": ".trae/tasks/...", "doc_impact_exists": true, "packet_files": {...} },
    ...
  ],
  "memory": {
    "hermes_memory_dir_exists": true,
    "mem0_config_exists": true,
    "mem0_enabled": false
  },
  "agents_md": {
    "exists": true,
    "size_bytes": 14137,
    "line_count": 172,
    "sha256": "...",
    "modified_at": "2026-06-26T02:34:40Z"
  },
  "gaps": [
    { "severity": "info", "category": "memory", "subject": "mem0", "message": "..." },
    ...
  ]
}
```

## Overall Status 判定

| critical_gaps | warn_gaps | overall_status |
|:-:|:-:|:-:|
| > 0 | * | `critical` |
| = 0 | > 0 | `warn` |
| = 0 | = 0 | `ok` (info gaps 不影响) |

## Gap 类别 (severity 等级)

| 类别 | severity | 触发条件 |
|------|:--:|----------|
| `issuer_public_key` | critical | `.trae/authority/issuer-public.json` 不存在 |
| `issuer_private_key` | critical | 私钥文件出现在 repo (违反安全策略) |
| `agents_md` | critical | 根目录 `AGENTS.md` 不存在 |
| `skill_dir` | critical | 必需的 skill 根目录不存在 |
| `skill_files` | warn | canonical skill 文件 (4 个核心) 缺失 |
| `agent_pointer` | warn | `.opencode/agents/*.md` 不引用 canonical path |
| `doc_governance` | warn | active task 缺 `doc-impact.md` |
| `memory` | info | Mem0 配置但 disabled (Phase 2 deferred) |

## 已知 PowerShell 5.1 编码陷阱 (踩坑记录)

踩了 5 个坑,都已修。**留给未来的小璃避免重蹈**:

### 1. `[switch]` 参数与变量名冲突
PowerShell 变量大小写不敏感,`[switch]$Json` 参数会让 `$json` 也是 `SwitchParameter`,导致 `+ op_Addition` 失败。

**修法**: 用不同名,例如 `$jsonFinal`。

### 2. 分段 JSON 拼接
`ConvertFrom-Json -AsHashtable` + `ConvertTo-Json` 在大对象上会触发 SwitchParameter binding bug。

**修法**: 用 `StringBuilder` 分段拼,每段 try/catch + Safe-ConvertToJson。

### 3. 两个 top-level JSON 对象
如果 `metaJson` 是完整 `{...}` JSON 字符串,后面又追加 `, "summary": {...}`,文件解析时看到两个对象 → invalid。

**修法**: 所有 field 入**单一**顺序 hashtable,一次 StringBuilder 拼接。

### 4. `` `u{XXXX} `` Unicode escape (PS6+ only)
PowerShell 5.1 **完全不处理** `` `u{91D1} `` 这种 escape 序列,会被当作 9 字符字面量 `` `u{91D1} ``。

**修法**: 用 `[System.Text.Encoding]::UTF8.GetString([byte[]]@(0xE9,0x87,0x91,...))` 运行时构造。

### 5. Chinese path 在 PS5.1 Chinese Windows 上
即便 source 文件是正确 UTF-8,`Test-Path "金璃小天才\SKILL.md"` 在中文 Windows locale 下也返回 False。

**修法**: 用 ASCII alias 或运行时 byte array 构造路径,**不要在 source 里写中文字符串字面量**。

## 双 IDE 兼容性

`.trae/scripts/jinli-snapshot.ps1` **双 IDE 共用**:
- Trae: 直接运行
- OpenCode: 同样路径
- Codex: 通过 shared task packet workflow 调用

## 维护提醒

- 修改 canonical skills 列表 (`$CANONICAL_SKILLS` 数组) 时,同步更新 `.opencode/agents/*.md` 的 canonical 路径
- 新增 skill 根目录时,在 `$SKILL_DIRS` 数组加一行
- 想加新 gap 检查,加在 `Build-GapList` 函数末尾

## 当前快照状态 (2026-06-26 02:45Z)

```
overall_status:    ok
critical/warn/info: 0 / 0 / 1
file size:         50591 bytes (UTF-8 BOM)
skills:            4/4 present
opencode_agents:   2/2 present (金璃小天才 + 金璃好帮手)
active_tasks:      69 (69/69 with doc_impact.md, 49/69 with complete packet)
authority:         ok (ECDSA-P256, no private key on disk)
memory:            hermes dir present, Mem0 disabled (Phase 2 deferred)
AGENTS.md:         14137 bytes, 172 lines
only info gap:     Mem0 deferred (设计如此)
```