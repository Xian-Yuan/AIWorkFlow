# ruflo 安装配置指南

Date: 2026-06-18
目标读者: 马维斯（手动执行）
当前状态: ruflo 已卸载，模型文件（90MB ONNX）残留在 `~/.cache/xenova/` 和 `~/.cache/claude-flow/`

---

## 一、ruflo 是什么

`ruvnet/ruflo` ([GitHub](https://github.com/ruvnet/ruflo)) — Claude Code 的多 Agent 元工具链。
60K+ Stars，npm 公开包 `ruflo@latest`。

本工作区使用 ruflo 的唯一功能：**语义内存搜索**。
```powershell
ruflo memory search -q "plan gate bypassed" -n 3
```
在 `Docs/Memory/` 中检索语义相近的 failure memory，即使关键词不完全匹配。

---

## 二、前置条件

| 依赖 | 当前状态 | 操作 |
|------|---------|------|
| Node.js (≥18) | ❌ 未安装 | 先装 Node.js |
| npm | ❌ 随 Node.js 安装 | — |
| ruflo 模型文件 | ✅ 已缓存 | 无需重新下载（90MB `all-MiniLM-L6-v2` 已在本地） |

---

## 三、安装步骤

### Step 1: 安装 Node.js（非 C 盘）

**不装在 C 盘的方法：**

1. 下载 Node.js 安装包：https://nodejs.org/en/download/
2. 运行安装程序，在"Destination Folder"步骤改为 `D:\NodeJS`（或其他非 C 盘路径）
3. **勾选** "Automatically install the necessary tools"
4. 完成安装后，验证：
```powershell
node --version   # 应输出 v18+ 或 v20+
npm --version    # 应输出 9+
```

### Step 2: 配置 npm 全局路径（避免 C 盘）

npm 默认把全局包装在 `C:\Users\<用户名>\AppData\Roaming\npm`。改为非 C 盘：

```powershell
# 创建非 C 盘目录
New-Item -ItemType Directory -Path "D:\npm-global" -Force
New-Item -ItemType Directory -Path "D:\npm-cache" -Force

# 配置 npm
npm config set prefix "D:\npm-global"
npm config set cache "D:\npm-cache"

# 把 D:\npm-global 加入 PATH（永久）
[Environment]::SetEnvironmentVariable("Path", "$env:Path;D:\npm-global", "User")

# 重启终端使 PATH 生效
```

### Step 3: 安装 ruflo

```powershell
# 全局安装（安装到 D:\npm-global）
npm install -g ruflo@latest

# 验证安装
ruflo --version
```

### Step 4: 验证模型加载

模型文件已缓存在：
- `C:\Users\87372\.cache\xenova\transformers\Xenova\all-MiniLM-L6-v2\onnx\model.onnx`（90MB）
- `C:\Users\87372\.cache\xenova\transformers\sentence-transformers\all-MiniLM-L6-v2\`

安装完成后，测试语义搜索：
```powershell
ruflo memory search -q "workflow plan" -n 1
```

如果模型加载成功，应输出 JSON 结果。如果仍然尝试下载：
```powershell
# 强制离线模式（直接读本地缓存）
$env:TRANSFORMERS_OFFLINE="1"
ruflo memory search -q "test" -n 1
```

### Step 5: 集成验证

```powershell
# 测试 memory-retrieve.ps1 的语义搜索路径
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "E:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1" `
  -Phase plan -ProjectType other -Scope router -Module workflow -Limit 1 -Semantic
```
应输出检索结果而非空（之前因 ruflo 不可用而静默降级返回空）。

---

## 四、注意事项

- **模型文件已在 C 盘**：`~/.cache/xenova/` 和 `~/.cache/claude-flow/` 的模型缓存是标准路径，HuggingFace/Xenova 生态默认使用该路径。如果要移动模型到非 C 盘，需设置环境变量 `TRANSFORMERS_CACHE=D:\huggingface-cache` 并复制文件过去。不是必须的——模型已经在 C 盘且只有 90MB。
- **npm 全局包路径**：`D:\npm-global` 可换成任意非 C 盘路径。
- **ruflo 是完整的 Agent 框架**：本次仅使用 `memory search` 子命令。不需要执行 `ruflo init`（那会安装 hooks/swarm/agent 等全部组件）。
- **版本**：当前最新 `v3.12.3`（2026-06-17），通过 `npm install -g ruflo@latest` 自动获取。

---

## 五、回退

如果 ruflo 仍然无法识别本地模型，不阻塞系统运行——`memory-retrieve.ps1` 的 `-Semantic` 参数会静默降级为关键词匹配。语义搜索是锦上添花，不是必备功能。
