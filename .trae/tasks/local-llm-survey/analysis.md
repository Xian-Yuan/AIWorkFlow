# Local LLM Survey — Analysis Report

## 目的
爸爸需要小璃查找本地的AI大模型，确认是否支持多模态，若不支持则根据当前电脑配置推荐合适的模型。

## 现有模型排查结果

### 检测工具
- Ollama（模型管理工具），模型目录位于 `E:\Ollama\models`
- 模型存储方式：Ollama GGUF 格式（blob 存储）

### 已安装模型清单

| 模型 | 参数量 | 磁盘占用 | 模型类型 | 多模态支持 |
|------|--------|---------|---------|-----------|
| qwen2.5-coder:14b | 14B | 8.98 GB | 纯文本代码生成 | ❌ 不支持 |
| qwen3:14b | 14B | 9.28 GB | 纯文本通用对话 | ❌ 不支持 |

### 结论
**❌ 本地已安装的模型均不支持多模态。**

两者均为纯文本（Text-Only）大语言模型，不具备图像/视觉理解能力。

## 硬件配置分析

| 组件 | 参数 | 说明 |
|------|------|------|
| CPU | Intel Core i5-13600KF | 14核/20线程，最高睿频5.1GHz |
| GPU | NVIDIA GeForce RTX 4060 Ti | 8GB GDDR6 VRAM（当前空余~5.8GB） |
| 内存 | 32GB DDR4 | — |
| 系统盘 (C:) | 221.6GB / 空余129.6GB | — |
| 数据盘 (E:) | 931.5GB / 空余153.8GB | **固态硬盘（SSD）** ✅ 适合存模型 |

### 硬件瓶颈分析
- **VRAM 8GB**：是主要限制。常见的多模态模型（如 Qwen2.5-VL-7B、LLaVA-13B）：
  - 7B 参数模型 4-bit 量化后约需 5-6GB VRAM → **适合**
  - 13B 参数模型 4-bit 量化后约需 9-10GB VRAM → **超出显存，需用部分系统内存**
  - 72B+ 参数模型 → ❌ 完全不可行
- **系统 RAM 32GB**：充足，可支持 CPU + GPU 混合推理
- **E盘 SSD 153.8GB 空余**：可存放多个 7B 多模态模型

## 多模态模型推荐

### 🥇 首选推荐：Qwen2.5-VL-7B

| 项目 | 内容 |
|------|------|
| 模型 | Qwen2.5-VL-7B (Qwen2.5-VL-7B-Instruct) |
| 出品 | 阿里巴巴/通义千问 |
| 大小 | 约 5-6GB（默认 Q4_K_M 量化） |
| VRAM | ✅ 完全在 8GB 以内 |
| 硬件加速 | NVIDIA CUDA 全量支持 |
| Ollama 拉取命令 | `ollama pull qwen2.5-vl:7b` |
| 多模态能力 | ✅ 图像理解、OCR、图表分析、视觉问答 |
| 语言能力 | 中文/英文均优，继承 Qwen 系列强项 |

**推荐理由：**
- 爸爸已经用 Qwen 系列（qwen3:14b, qwen2.5-coder:14b），生态一致
- Qwen2.5-VL 是当前开源多模态的第一梯队，效果接近 GPT-4V
- 7B 规模完美适配 8GB VRAM，量化后运行流畅
- Ollama 一行命令即可拉取使用
- 中文支持优秀

### 🥈 备选方案

| 模型 | 大小 (4-bit) | VRAM 需求 | 中文支持 | 推荐场景 |
|------|-------------|-----------|---------|---------|
| **llava:7b** | ~4.5 GB | ~5GB | 一般 | 轻量多模态，兼容性最好 |
| **minicpm-v** | ~3.5 GB | ~4GB | 好 | 轻量化首选，面部识别强 |
| **bakllava:7b** | ~5 GB | ~5.5GB | 一般 | LLaVA 改进版，推理更强 |
| **gemma3:12b** | ~8 GB | ~8.5GB | 一般 | ⚠️ 刚好撑满 VRAM，风险偏高 |

### 不推荐的模型

| 模型 | 理由 |
|------|------|
| LLaVA-13B / Qwen2.5-VL-72B | 量化后仍超 8GB VRAM，推理速度慢 |
| InternVL2-26B | 超 VRAM，需大量系统内存，体验差 |
| CogVLM2 | 参数量过大，不适用于 8GB 卡 |

## 配置建议

### 自动环境变量设置（若 Ollama 命令不可用）
Ollama 虽已安装（模型目录存在），但可执行文件未加入 PATH。推荐：
```powershell
# 下载 Ollama 安装包到 E 盘
# 安装后会自动配置环境变量
# 或设置 OLLAMA_MODELS 环境变量指向 E:\Ollama\models
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "E:\Ollama\models", "User")
```

### 拉取多模态模型
```powershell
ollama pull qwen2.5-vl:7b
```

### 使用示例
```powershell
# 问图像内容
ollama run qwen2.5-vl:7b "这张图片里有什么？" --image path/to/image.jpg
```

## 总结
- **❌ 现有模型不支持多模态**
- **✅ 硬件（RTX 4060 Ti 8GB + 32GB RAM + E盘 SSD）完全支持 7B 级别多模态模型**
- **🥇 推荐安装 Qwen2.5-VL-7B**（与现有 Qwen 生态一致，中文最优）
- **🥈 备选 llava:7b 或 minicpm-v**（更轻量）
