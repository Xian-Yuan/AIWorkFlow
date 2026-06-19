# Basic Memory Retrieval And Mem0 Design

日期：2026-05-31
项目：`g:\UEGameDevelopment`
状态：已确认设计，待用户审阅

## 1. 目标

为当前工作区建立 `Basic Memory` 第二阶段设计：在保留 `Docs/Memory/` 作为主真相源的前提下，引入统一的本地检索脚本，并接入 `Mem0` 作为本地实验性质的增强检索层。

本阶段要解决的问题：

1. 让 `Router` 和 `Implement` 能通过统一脚本读取少量高相关 failure memory，而不是依赖人工翻文件
2. 在本地检索不足时，引入 `Mem0` 做补充检索，但不让 `Mem0` 取代文件真相源
3. 只同步正式 `failure memory` 到 `Mem0`，避免把 candidate 或低质量记录写入外部记忆层
4. 在保证 token 预算可控的前提下，为后续真正实现脚本和 SDK 接入提供稳定结构

## 2. 范围

本次范围内：

- 设计统一检索脚本 `memory-retrieve.ps1`
- 设计 `Mem0` 本地实验配置、健康检查与同步脚本
- 设计 `Router + Implement` 的接入契约
- 规定本地优先、`Mem0` 增强的检索顺序
- 规定 `Mem0` 只同步正式 `failure memory`
- 规定第二阶段的 token 预算、故障回退、安全规则和验证结构

本次范围外：

- 不在本 spec 阶段直接实现 PowerShell 脚本
- 不在本 spec 阶段安装或调用真实 `Mem0 SDK`
- 不引入 candidate 自动转正
- 不把 `Review` 作为 `Mem0` 检索消费者
- 不把 `Mem0` 用作新的工作流或状态系统

## 3. 现状

当前工作区已经具备：

- `Docs/Memory/` 目录结构
- `failure memory` / `candidate` / `index` / `template` 基础文件
- `Router` / `Implement` / `Review` / `regression` 的 memory 契约文档
- `DeepSeek4Pro` profile 中的摘要注入约束

当前仍然缺少：

- 统一的本地检索脚本
- `Mem0` 的配置和同步路径
- “本地结果不足时才补查 `Mem0`”的机械化逻辑
- 可执行的健康检查和回退规范

## 4. 核心原则

- **文件真相源优先**：`Docs/Memory/failures/*.md` 仍然是 failure memory 的唯一主真相源
- **本地优先检索**：先查 `memory-index.md` 和本地 failure files，再决定是否补查 `Mem0`
- **Mem0 只是增强层**：`Mem0` 不能接管主工作流，也不能成为唯一依赖
- **只同步正式 memory**：candidate、临时失败和低质量记录不能进入 `Mem0`
- **摘要注入**：无论本地还是 `Mem0`，都只允许输出短摘要，不允许整篇原文进入 prompt
- **Fail-soft 回退**：`Mem0` 不可用时，不阻塞 `Router` / `Implement`

## 5. 推荐架构

推荐采用“本地真相源 + 统一检索脚本 + Mem0 本地实验增强层”的双层方案。

### 5.1 检索链

```text
Router / Implement
  -> memory-retrieve.ps1
      -> local index + failures
      -> if insufficient and mem0 enabled
           -> Mem0 local experiment query
      -> summary-only output
```

### 5.2 同步链

```text
Docs/Memory/failures/*.md
  -> mem0-sync.ps1
  -> Mem0 local experiment store
```

### 5.3 健康检查链

```text
mem0-healthcheck.ps1
  -> config validation
  -> endpoint reachability
  -> availability status
```

## 6. 目录与文件结构

第二阶段建议在第一阶段基础上新增：

```text
.trae/
  memory/
    mem0.config.json
  scripts/
    memory-retrieve.ps1
    mem0-sync.ps1
    mem0-healthcheck.ps1
```

职责划分：

- `Docs/Memory/`
  - 主真相源
- `.trae/memory/mem0.config.json`
  - 本地实验配置
- `.trae/scripts/memory-retrieve.ps1`
  - 统一检索入口
- `.trae/scripts/mem0-sync.ps1`
  - 正式 memory 同步脚本
- `.trae/scripts/mem0-healthcheck.ps1`
  - 本地实验健康检查

## 7. memory-retrieve.ps1 设计

### 7.1 作用

为 `Router` 和 `Implement` 提供统一的 failure memory 检索入口。

### 7.2 输入参数

建议输入契约：

```powershell
-Phase <plan|implement>
-ProjectType <ue5|web|other>
-Scope <router|implement>
-Module <module-name>
-Tags <string[]>
-Limit <int>
-UseMem0 <bool>
-TaskName <string>
```

### 7.3 本地检索流程

1. 读取 `Docs/Memory/indexes/memory-index.md`
2. 按以下字段做初筛：
   - `Phase`
   - `Scope`
   - `ProjectType`
   - `Module`
   - `Tags`
   - `Severity`
3. 根据索引命中的文件路径，读取少量 `Docs/Memory/failures/*.md`
4. 只提炼：
   - `Bad Pattern`
   - `Correct Rule`
   - `Verification`

### 7.4 何时补查 Mem0

只有满足以下条件之一，才允许补查 `Mem0`：

- 本地结果数量不足
  - `Router < 2`
  - `Implement < 1`
- 本地结果存在，但相关度仅命中 tags，未命中 `phase/module/scope`
- 当前任务属于高风险标签
  - `save`
  - `load`
  - `verification`
  - `implicit-requirement`
  - `workflow`
- 显式启用 `-UseMem0 $true`

### 7.5 输出对象

脚本内部建议先输出结构化对象，再格式化为 prompt 摘要：

```powershell
@{
  Source = "local" | "local+mem0"
  Scope = "router" | "implement"
  Phase = "plan" | "implement"
  Count = 1
  Items = @(
    @{
      Id = "memory-router-save-system-missing-2026-06-01"
      Source = "local"
      Title = "路由阶段遗漏保存系统前置依赖"
      BadPattern = "看到退出弹窗需求就直接做 UI"
      CorrectRule = "先确认 SaveGame 是否存在"
      Verification = "routing.md 必须明确保存依赖"
    }
  )
}
```

### 7.6 文本输出格式

`Router`：

```text
Relevant Failure Memories
1. 保存/退出类需求：曾遗漏保存系统前提。Rule: 先确认 SaveGame 是否存在。Verify: routing.md 必须写出保存依赖或明确缺失前提。
```

`Implement`：

```text
Pre-Edit Failure Reminder
1. 不要只修 UI 表层。Rule: 涉及保存/加载必须检查状态恢复链。Verify: 功能验证包含恢复后的可见状态。
```

## 8. mem0-healthcheck.ps1 设计

### 8.1 作用

在任何 `Mem0` 查询或同步前，快速判断本地实验环境是否可用。

### 8.2 检查项

- `mem0.config.json` 是否存在
- `enabled` 是否为 `true`
- endpoint 是否可访问
- 必要环境变量是否存在（若未来需要）
- timeout 设置是否在合理范围

### 8.3 输出状态

- `available`
- `unavailable`
- `misconfigured`

### 8.4 工作流规则

- `unavailable` 或 `misconfigured` 时，`memory-retrieve.ps1` 必须自动退回本地检索
- 健康检查失败不能阻塞 `Router` / `Implement`

## 9. mem0-sync.ps1 设计

### 9.1 同步来源

只同步：

- `Docs/Memory/failures/*.md`

且必须满足：

- `severity >= medium`
- `Correct Rule` 非空
- `Verification` 非空
- `mem0_sync_status` 为 `not_synced` / `stale` / `sync_failed`

### 9.2 不同步内容

- `Docs/Memory/candidates/*.md`
- 未转正 failure
- 缺少验证标准的 memory
- 低价值、不可泛化记录

### 9.3 同步后的回写字段

```yaml
mem0_sync_status: synced
mem0_memory_id: <returned-id>
```

失败时：

```yaml
mem0_sync_status: sync_failed
```

文件内容更新后：

```yaml
mem0_sync_status: stale
```

## 10. Mem0 数据映射

建议每条正式 memory 映射为结构化记录：

```json
{
  "memory_id": "memory-router-save-system-missing-2026-06-01",
  "project": "UEGameDevelopment",
  "type": "failure_memory",
  "phase": "plan",
  "scope": ["router", "implement"],
  "project_type": "ue5",
  "module": "save-system",
  "tags": ["router", "save", "implicit-requirement"],
  "severity": "high",
  "bad_pattern": "看到退出弹窗需求就直接进入 UI 实现",
  "correct_rule": "先确认 SaveGame 是否存在、状态是否可恢复",
  "verification": "routing.md 或 analysis.md 必须明确保存依赖或缺失前提"
}
```

同步时只上传结构化摘要，不上传整篇对话、长日志或候选文件。

## 11. mem0.config.json 设计

建议配置：

```json
{
  "enabled": false,
  "mode": "local-experiment",
  "endpoint": "http://127.0.0.1:8000",
  "project": "UEGameDevelopment",
  "use_for_scopes": ["router", "implement"],
  "sync_only_promoted_failures": true,
  "max_results_router": 3,
  "max_results_implement": 2,
  "timeout_ms": 1500
}
```

配置规则：

- 默认 `enabled = false`
- 明确写死 `use_for_scopes = ["router", "implement"]`
- timeout 必须短，避免阻塞工作流
- 不在仓库中保存 secret 或 token

## 12. 安全与隐私规则

- 不把任何 API key 或 secret 写入仓库
- 若未来需要认证，只允许走环境变量
- 不同步完整对话历史
- 不同步 review/verify 全文
- 不同步长日志
- 不同步 candidate
- 不同步用户偏好闲聊内容
- 不同步业务敏感数据

## 13. Token 预算

沿用第一阶段上限，不放宽。

### Router

- 默认 `top 2`
- 高风险最多 `top 3`
- 摘要目标约 `200-300` 中文字

### Implement

- 默认 `top 1`
- 高风险最多 `top 2`
- 摘要目标约 `120-180` 中文字

### 硬规则

- 本地 + `Mem0` 合并结果后仍不得超预算
- 只允许摘要，不允许原文
- 相关度不足时返回空，不凑满

## 14. 故障与回退

第二阶段必须 fail-soft：

- `Mem0` 挂掉 -> 本地检索继续工作
- endpoint 超时 -> 返回本地结果
- 配置错误 -> 输出 `mem0_unavailable`
- `Mem0` 结果过多 -> 按预算截断
- `Mem0` 空结果 -> 不影响 `Router` / `Implement`

即：

- **`Mem0` 是增强层，不是单点依赖**

## 15. 接入点

### Router

```powershell
& .\.trae\scripts\memory-retrieve.ps1 `
  -Phase plan `
  -ProjectType ue5 `
  -Scope router `
  -Module router `
  -Tags @('save', 'implicit-requirement') `
  -Limit 2 `
  -UseMem0 $true `
  -TaskName my-task
```

### Implement

```powershell
& .\.trae\scripts\memory-retrieve.ps1 `
  -Phase implement `
  -ProjectType web `
  -Scope implement `
  -Module save-system `
  -Tags @('verification', 'restore') `
  -Limit 1 `
  -UseMem0 $true `
  -TaskName my-task
```

## 16. 验证结构

### 16.1 本地检索验证

- 空索引时返回空
- 单条 memory 命中正确
- `Router` 不超过 `top 3`
- `Implement` 不超过 `top 2`

### 16.2 健康检查验证

- endpoint 不可达 -> `unavailable`
- 配置缺失 -> `misconfigured`
- 不阻塞本地检索

### 16.3 同步验证

- 正式 memory 可同步
- candidate 不可同步
- `sync_failed` 可重试
- `stale` 可重同步

### 16.4 工作流集成验证

- `Router` 能拿到 `Relevant Failure Memories`
- `Implement` 能拿到 `Pre-Edit Failure Reminder`
- `Mem0` 不可用时工作流仍正常

## 17. 实施顺序建议

1. 先创建 `.trae/memory/mem0.config.json`
2. 再实现 `mem0-healthcheck.ps1`
3. 再实现 `memory-retrieve.ps1` 的本地检索部分
4. 验证本地检索通过后，再实现 `UseMem0` 补查路径
5. 最后实现 `mem0-sync.ps1`
6. 再把 `Router / Implement` 的文档契约升级成真实脚本调用

## 18. 成功标准

第二阶段完成后，应满足：

1. `Router + Implement` 有统一检索脚本入口
2. 本地检索在 `Mem0` 不可用时仍可独立工作
3. `Mem0` 只同步正式 `failure memory`
4. `Docs/Memory/` 继续保持主真相源地位
5. token 注入预算不超过第一阶段限制
6. `Mem0` 本地实验不影响当前 fail-closed workflow

## 19. 风险点

- 如果本地索引字段设计不稳定，后续 `Mem0` 映射会反复返工
- 如果 `UseMem0` 默认开启，可能增加不必要 token 和依赖波动
- 如果同步边界被放宽到 candidate，会快速污染 `Mem0`
- 如果未来直接把 `Mem0` 结果当真相源，可能破坏仓库优先原则

## 20. 缺失信息与默认假设

当前默认假设：

- `Mem0` 采用本地实验方式接入
- 只服务 `Router + Implement`
- 只同步正式 `failure memory`
- `Review` 第一版不消费 `Mem0`
- `Mem0` 不负责 candidate 转正

若后续要扩展到：

- `Review` 读取增强记忆
- 自动 rerank / embedding
- 云端托管 `Mem0`
- 多项目共享 memory 空间

应作为下一阶段独立设计。
