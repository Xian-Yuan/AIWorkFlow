# WP07 Result: vsummary 完整批量工作流

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-22

## 需求

实现 vsummary 的完整批量工作流，包括：
- 3级 API key 池（免费 → 个人 → 付费）
- 智能限流检测与自动切换
- 完整工作流编排（采集 → 下载 → 导入 → ASR → 总结）
- 进度通知与报告
- 状态持久化与恢复

## 变更文件

| 文件 | 状态 | 行数 |
|------|------|------|
| `workflow/provider_pool.py` | 新建 | 462 |
| `workflow/vsummary_adapter.py` | 新建 | 117 |
| `workflow/pipeline.py` | 新建 | 241 |
| `workflow/notifier.py` | 新建 | 138 |
| `workflow/__init__.py` | 新建 | 16 |
| `workflow.py` | 新建 | 295 |
| `test_workflow.py` | 新建 | 209 |
| `test_e2e.py` | 新建 | 192 |
| `WORKFLOW_README.md` | 新建 | 183 |
| `.env` | 更新 | +10 |

**总新增**: ~1,853 行

## 架构

```
┌────────────────────────────────────────────────────┐
│              workflow.py (CLI 入口)                │
│  status / test / reset / run                       │
└─────────────────┬──────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
ProviderPool  Adapter     Pipeline
(3级 key池)   (vsummary桥) (视频处理)
    │             │             │
    └─────────────┴─────────────┘
                  │
                  ▼
              Notifier
        (本地/日志/Webhook)
```

## 核心组件

### 1. ProviderPool (`provider_pool.py`)

3级 tier 排序 + 状态追踪：
- `free` tier (智普 GLM-4-Flash) — 公共免费，最高优先
- `personal` tier (NVIDIA DeepSeek V4-Pro) — 爸爸的，free限流时切换
- `premium` tier (备用付费) — 兜底

状态枚举：`active` / `rate_limited` / `invalid` / `cooldown` / `untested`

每次调用后根据错误码自动更新：
- 429 → `rate_limited` + 自动冷却 5-10 分钟
- 401/403 → `invalid` (永久禁用)
- 5xx/timeout → `failure` (连续3次进入冷却)

状态持久化到 `~/.vsummary/provider_state.json`，重启后自动恢复。

### 2. VsummaryProviderAdapter (`vsummary_adapter.py`)

桥接 ProviderPool 和 vsummary 后端：
- `ensure_available_provider()` — 获取可用 provider
- `apply_to_vsummary()` — 把配置写入 vsummary 后端
- `handle_response_error()` — 解析错误并标记 provider 状态

### 3. VideoPipeline (`pipeline.py`)

单个视频的完整处理管道：
1. 时长筛选
2. 视频文件存在性检查
3. 已有 summary 跳过
4. 音频轨道检查 (ffprobe)
5. 导入 vsummary
6. 生成总结 (带 provider 自动切换)
7. 验证结果

返回统一 `VideoProcessResult`。

### 4. Notifier (`notifier.py`)

多通道通知：
- `local_file` — 写入 `data/notifications/YYYY-MM-DD.log`
- `log` — 打印到 stdout
- `console` — 强制刷屏（关键节点）
- `webhook` — 钉钉/飞书/企微通用格式 (可选)
- `email` — 占位

## AC 映射

| 验收项 | 实现位置 | 验证方式 |
|--------|----------|----------|
| 3级 API key 池 | `provider_pool.py::ProviderPool.get_best_provider` | 单元测试 #5 |
| 限流自动冷却 | `provider_pool.py::ProviderState.mark_rate_limited` | 单元测试 #2 + E2E #1 |
| 无效 key 永久禁用 | `provider_pool.py::ProviderState.mark_invalid` | 单元测试 #1 |
| 状态持久化 | `provider_pool.py::_save_state / _load_state` | 单元测试 #3 + E2E #3 |
| 故障自动切换 | `vsummary_adapter.py::ensure_available_provider` | E2E #1 (真实脚本验证) |
| 完整工作流 | `pipeline.py::VideoPipeline.process` | 集成测试 (`run` 命令) |
| 多种通知通道 | `notifier.py` | run 命令输出验证 |
| 进度报告 JSON | `workflow.py::cmd_run` | `data/workflow_report.json` |
| 状态可视化 | `workflow.py::cmd_status` | status 命令输出 |
| .env 配置 | `.env` (新增 NVIDIA_API_KEY + ZHIPU_API_KEY) | status 命令读取 |

## 验证结果

### 单元测试 (test_workflow.py)
```
测试 1: ProviderPool 基础功能 — ✅ 通过
测试 2: Provider 状态追踪   — ✅ 通过
测试 3: 状态持久化          — ✅ 通过
测试 4: 默认 Provider 加载   — ✅ 通过 (2个: nvidia + zhipu)
测试 5: 优先级排序          — ✅ 通过
🎉 全部测试通过！
```

### E2E 测试 (test_e2e.py)
```
E2E #1: 故障切换 — ✅ 全部场景通过
  ✅ 初始选 free (backup1)
  ✅ backup1 限流后切 personal (primary)
  ✅ primary 限流后切 premium (backup2)
  ✅ Invalid 永久禁用
  ✅ 全失败返回 None
  ✅ Reset 恢复

E2E #2: 审计日志    — ✅ 4条事件正确
E2E #3: 状态持久化 — ✅ 重启后正确恢复
E2E #4: 日志大小限制 — ✅ 1000条上限
🎉 全部 E2E 测试通过！
```

### 真实场景验证
```
测试前: 当前最佳: zhipu_glm4flash (free)
模拟 zhipu 限流后:
  当前最佳: nvidia_deepseek (personal/爸爸的) ✅
  zhipu 状态: rate_limited ✅
NVIDIA 真实测试: 200 OK ✅
```

### CLI 命令验证
- ✅ `python workflow.py status` — 正确显示状态
- ✅ `python workflow.py test` — 测试通过
- ✅ `python workflow.py reset` — 重置生效
- ✅ `python workflow.py run` — 完整工作流跑通

## 范围控制

- ✅ 只改 vsummary 目录下的文件
- ✅ 没有删除任何文件
- ✅ 没有覆盖其他人的改动
- ✅ 没有动 vsummary 核心后端代码
- ✅ Extra scope taken: **no**

## 下次启动使用方法

```bash
cd E:\Obsidian\tools\vsummary
python workflow.py status                    # 看状态
python workflow.py run                       # 一键跑批
python workflow.py run --max-duration 600    # 自定义时长
```

## 待优化（不在本 WP 范围）

- 视频下载（B站 yt-dlp 失败时的重试逻辑）
- ffmpeg 解码失败时的降级方案（已知3个无音频视频）
- Webhook 通知（需要 .env 配置 VSUMMARY_WEBHOOK_URL）
- 邮件通知（占位，未实现）

## 风险

- **NVIDIA API 免费版限流**：频繁使用可能 429，已实现自动冷却 10 分钟
- **智普 API 免费版限流**：已实现自动冷却 5 分钟并切换到 NVIDIA
- **视频文件损坏**：3个视频无音频轨道，需重新下载
