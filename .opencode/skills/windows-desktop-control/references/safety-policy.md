# Safety Policy: Windows Desktop Control

## 1. 危险操作确认

以下操作必须先获得用户确认后才能执行：

| 操作 | 确认方式 |
|------|----------|
| 关闭应用窗口 | 口头确认 "确认关闭 XXX？" |
| 删除 Actor / Blueprint | 口头确认 "确认删除 XXX？" |
| 终止进程 (kill_process) | 口头确认 "确认终止进程 PID XXX？" |
| 执行危险终端命令 (rm, format, regedit 等) | Hermes approvals.mode 自动处理 |
| 修改系统配置文件 | 口头确认 |

## 2. 窗口白名单

### 默认允许操控

- Visual Studio Code
- Unreal Editor / Unreal Engine
- Chrome / Edge / Firefox / Brave
- Windows Terminal / PowerShell / Command Prompt
- Explorer / File Manager
- Notepad / Notepad++
- Discord / Telegram / Slack

### 需要额外确认

- 任务管理器
- 注册表编辑器
- 系统设置
- 任何标题包含 "admin" / "elevated" 的窗口

### 禁止操控

- Windows Logon / Lock Screen
- UAC (User Account Control) 弹窗
- Windows Security / Defender 界面

## 3. 操作频率限制

| 操作类型 | 最大频率 |
|----------|----------|
| 截图 | 1次/秒 |
| 点击 | 3次/秒 |
| 键入 | 无限制（但每字符间隔 ≥ 20ms） |
| UIA 树查询 | 1次/2秒（树可能很大） |

## 4. 操作日志格式

```json
{
  "timestamp": "2026-06-21T15:30:00.000Z",
  "tool": "computer_click",
  "target": {"element_name": "Save Button", "x": 500, "y": 300},
  "result": "success",
  "window": "Visual Studio Code",
  "duration_ms": 45
}
```

## 5. 错误处理

- 操作失败后自动重试 1 次
- 连续失败 3 次停止，报告给用户
- MCP 连接断开时，不自动重连，报告错误让用户决定

## 6. 隐私保护

- 截图可能包含敏感信息，不自动保存到磁盘
- 截图仅在当前会话中使用，会话结束后不保留
- UIA 树可能包含文本内容，不记录到持久日志
