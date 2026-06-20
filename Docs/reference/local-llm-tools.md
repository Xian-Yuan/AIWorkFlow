# 本地大模型工具与方案参考

> 整理日期：2026-06-20
> 环境：RTX 4060 Ti 4GB VRAM | Ollama 0.30.0-rc31 | Ollama API @ localhost:11434

---

## 一、当前本地模型清单

| 模型 | 大小 | 类型 | 参数量 | 量化 | 主要用途 |
|:----:|:----:|:----:|:------:|:----:|:---------|
| `openbmb/minicpm-v4.6` | 1.5 GB | 🖼️ 视觉多模态 | 1.3B | Q4_0 | 图文理解、OCR、文档分析、视频分析 |
| `qwen3:14b` | 8.6 GB | 💬 通用对话 | 14B | — | 通用推理、知识提取、信息整理 |
| `qwen2.5-coder:14b` | 8.4 GB | 💻 代码 | 14B | — | 代码生成、自动化脚本、任务编排 |

**存储位置**: `E:\Ollama\models\`（通过 `OLLAMA_MODELS` 环境变量指定）
**API 地址**: `http://localhost:11434`

---

## 二、方向一：简单重复任务自动化

### 2.1 Ollama API 直接调用（最轻量）

```python
import requests
import json

response = requests.post("http://localhost:11434/api/chat", json={
    "model": "qwen2.5-coder:14b",
    "messages": [{"role": "user", "content": "你的任务指令"}],
    "stream": False,
    "options": {"temperature": 0.1}  # 低温度减少随机性
})
print(response.json()["message"]["content"])
```

**适用场景**：
- 批量格式化数据（JSON/CSV 转换）
- 代码重构/代码审核
- 文本分类/标签生成
- 日志分析摘要
- 批量翻译

### 2.2 llm-workflow（轻量工作流框架）

- **地址**: https://pypi.org/project/llm-workflow/
- **说明**: 轻量级 LLM 工作流框架，支持任务链（前一个任务输出作为下一个输入）、记忆追踪、Token 用量统计
- **安装**: `pip install llm-workflow`
- **特点**:
  - 支持 OpenAI 兼容 API（Ollama 也支持）
  - 内置 `OpenAIChat` 类，自动跟踪 token 消耗
  - Workflow 对象串联多个任务
  - 透明调试，可检查每个步骤的输入/输出

```python
from llm_workflow.openai import OpenAIChat

# Ollama 兼容 OpenAI API
model = OpenAIChat(
    model="qwen2.5-coder:14b",
    base_url="http://localhost:11434/v1"  # Ollama OpenAI 兼容端点
)
result = model("你的问题")
print(f"Token 消耗: {model.total_tokens}")
```

### 2.3 OpenClaw（Ollama 官方自动化框架）

- **地址**: https://ollama.com/ (OpenClaw 集成)
- **说明**: Ollama 官方合作的自动化 agent 框架，通过 `ollama launch openclaw` 启动
- **特点**: 内置 Web 工具、文件操作、任务调度

---

## 三、方向二：联网搜索 + 信息整理（本地 RAG）

### 3.1 Open WebUI 🥇（推荐首选）

- **地址**: https://github.com/open-webui/open-webui
- **⭐**: 65k+ Stars
- **说明**: Ollama 最强 Web 界面，内置 RAG + 联网搜索
- **安装方式**:
  ```bash
  # Docker（推荐）
  docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway \
    -v open-webui:/app/backend/data --name open-webui \
    --restart always ghcr.io/open-webui/open-webui:main

  # 或 pip 安装
  pip install open-webui
  ```
- **关键特性**:
  - 内置 RAG（上传 PDF/Word/代码文件→提问）
  - 联网搜索集成（Google/Brave Search API）
  - 多模型切换（在 Ollama 模型间自由切换）
  - 完全本地运行，数据不出机器
  - 文档对话时显示引用来源

### 3.2 AnythingLLM（桌面应用）

- **地址**: https://github.com/Mintplex-Labs/anything-llm
- **⭐**: 30k+ Stars
- **说明**: 本地 RAG 桌面应用，支持多文档工作区
- **特点**:
  - 拖拽文件即用，无需配置
  - 显示精确引用来源（哪份文档、哪段内容）
  - 支持多工作区隔离不同项目
  - 底层可切换 Ollama 模型

### 3.3 RAGFlow（企业级 RAG 引擎）

- **地址**: https://github.com/infiniflow/ragflow
- **⭐**: 83.2k Stars
- **说明**: 开源 RAG 引擎，深度文档解析能力
- **特点**:
  - 支持 PDF/DOCX/Excel/图片 深度解析
  - 布局保留（表格、图表、公式）
  - Agent 工作流编排
  - 可对接 Ollama 作为本地 LLM 后端

### 3.4 LangChain RAG（开发者框架）

- **地址**: https://github.com/langchain-ai/langchain
- **说明**: Python RAG 框架，完全可控
- **安装**: `pip install langchain langchain-ollama chromadb`
- **最小示例**:
  ```python
  from langchain_ollama import OllamaLLM
  from langchain.chains import RetrievalQA
  from langchain_community.vectorstores import Chroma

  llm = OllamaLLM(model="qwen3:14b", base_url="http://localhost:11434")
  # ... 构建检索链
  ```

### 3.5 技术要点：RAG 最佳实践

| 要点 | 说明 |
|------|------|
| **分块策略** | 500-1000 tokens/块，重叠 10-20% |
| **嵌入模型** | 可用 `nomic-embed-text`（Ollama 内置） |
| **推荐模型** | Qwen 系列（128K-262K 上下文）= 优秀的 RAG 基座 |
| **检索增强** | Hybrid Search（向量 + BM25 关键词）> 纯向量搜索 |
| **文档解析** | Docling (IBM) 或 Unstructured.io 预处理 |

参考文章：
- [Local RAG: Chat With Your Documents](https://dev.to/lingdas1/local-rag-chat-with-your-documents-open-source-private-390o)
- [15 Best Open-Source RAG Frameworks (2026)](https://apidog.com/blog/best-open-source-rag-frameworks/)
- [Local RAG in 2026: Build a Private Document AI](https://runaihome.com/blog/local-rag-private-document-ai-2026/)

---

## 四、方向三：知识图谱

### 4.1 Microsoft GraphRAG（行业标杆）

- **地址**: https://github.com/microsoft/graphrag
- **⭐**: 28k+ Stars
- **论文**: https://arxiv.org/pdf/2404.16130
- **文档**: https://microsoft.github.io/graphrag/
- **说明**: 微软出品，从文档自动提取实体→关系→社区层级→摘要
- **流程**:
  1. 提取实体和关系 → 构建知识图谱
  2. Leiden 社区检测 → 层级社区划分
  3. 每个社区生成 LLM 摘要
  4. 查询路由（本地实体搜索 / 全局主题搜索）
- **技术要点**:
  - 支持 Ollama 作为 LLM 后端（需配置 `llm` 节点指向 Ollama）
  - 索引阶段耗 Token 较多（但可本地 qwen3:14b 跑）
  - 查询阶段较轻量

### 4.2 Neo4j LLM Knowledge Graph Builder

- **地址**: https://github.com/neo4j-labs/llm-graph-builder
- **⭐**: 2.8k+ Stars
- **在线试用**: https://llm-graph-builder.neo4jlabs.com/
- **说明**: Neo4j 官方工具，上传文档→LLM 提取实体关系→存入 Neo4j
- **特点**:
  - 支持多种文档格式（PDF、网页、文本）
  - 实体关系可视化
  - 社区摘要（新功能）
  - 需要 Neo4j 数据库（可本地运行 AuraDB Free 或 Docker）

### 4.3 Cognee（统一记忆层）

- **地址**: https://github.com/topics/cognee (需搜索)
- **说明**: 向量+图谱混合存储，模块化知识图谱管道
- **特点**:
  - 支持 NetworkX（开发） / Neo4j / FalkorDB（生产）
  - 提供高 Level API（`cognee.add()` / `cognee.search()`）
  - 也提供自定义管道（`extract_graph_from_data`）
  - 支持可视化

```python
import cognee

# 高 Level API
await cognee.add("your documents")
result = await cognee.search(query_text="你的问题")

# 自定义管道
from cognee.tasks.graph import extract_graph_from_data
from cognee.modules.pipelines import run_tasks
```

### 4.4 SwarmVault 🆕（本地优先，推荐）

- **地址**: https://github.com/swarmclawai/swarmvault
- **网站**: https://www.swarmvault.ai/
- **说明**: 基于 Karpathy LLM Wiki 模式，本地优先的知识图谱 + RAG
- **安装**: `npm install -g @swarmvaultai/cli`
- **工作流**:
  1. `swarmvault quickstart ./your-repo` — 从文件构建
  2. `swarmvault query "问题"` — 查询知识库
  3. `swarmvault graph serve` — 可视化知识图谱
  4. 支持 MCP 接口 → 其他 AI Agent 可读取
- **特点**: 本地文件驱动（Markdown + JSON），渐进式构建

### 4.5 Atomic（桌面知识图谱 APP）

- **地址**: https://github.com/kenforthewin/atomic
- **网站**: https://atomicapp.ai/
- **⭐**: 1.5k Stars
- **说明**: AI 原生知识图谱桌面应用
- **功能**:
  - 语义搜索（向量搜索笔记）
  - Wiki 合成（自动根据标签生成维基文章）
  - 智能对话（引用笔记原文）
  - 空间画布（关系力导向图）
  - 自动标签 + 嵌入
  - MCP 集成（可接入 Claude/Cursor）

### 4.6 CocoIndex + Kuzu（实时知识图谱管道）

- **地址**: https://github.com/cocoindex-io/cocoindex
- **教程**: https://dev.to/cocoindex/build-real-time-knowledge-graphs-from-documents-using-cocoindex-kuzu-with-llms-live-updates-n1b
- **说明**: ~200 行 Python 构建实时知识图谱管道，支持增量更新
- **技术栈**: CocoIndex（数据处理引擎）+ Kuzu（嵌入式图数据库）+ LLM（实体关系提取）

参考文章：
- [Best Knowledge Graph Tools for LLM Agents in 2026](https://www.opensourceaireview.com/blog/best-knowledge-graph-tools-for-llm-agents-in-2026-ranked)
- [LLM-empowered knowledge graph construction: A survey](https://arxiv.org/abs/2510.20345)
- [From LLMs to Knowledge Graphs: Building Production-Ready Graph Systems](https://medium.com/@claudiubranzan/from-llms-to-knowledge-graphs-building-production-ready-graph-systems-in-2025-2b4aff1ec99a)
- [GraphRAG vs Baseline RAG](https://microsoft.github.io/graphrag/)

---

## 五、方向四：视频 → 知识图谱

### 5.1 video-analyzer

- **地址**: https://github.com/byjlw/video-analyzer
- **⭐**: 1.5k Stars
- **说明**: 本地视频分析工具，Ollama + Whisper + 视觉模型
- **流程**:
  1. OpenCV 提取关键帧 + Whisper 字幕转录
  2. 视觉 LLM（如 MiniCPM-V 4.6）分析每帧
  3. 结合字幕生成视频内容描述
  4. 输出结构化 JSON
- **技术要点**:
  - 可完全本地运行
  - 支持任何 Ollama 视觉模型
  - Whisper 用于音频转文字
  - 支持 OpenAI 兼容 API 作为备选

### 5.2 Docling（IBM 文档解析）

- **地址**: https://github.com/docling-project/docling
- **说明**: IBM 开源，PDF/PPT/图片/DOCX → LLM 可用格式
- **特点**:
  - 布局保留（表格、图表、公式）
  - 输出 Markdown / JSON
  - 是 RAG 系统的前置预处理最佳选择

### 5.3 推荐组合方案

```
视频文件
  ├──→ Whisper (本地) → 字幕文本
  └──→ OpenCV → 关键帧 → MiniCPM-V 4.6 → 帧描述
         ↓
    qwen3:14b 结构化提取
         ↓
    实体 + 关系
         ↓
    存入知识图谱 (SwarmVault / Neo4j / GraphRAG)
```

**理由**：
- Whisper 本地运行，无需 API 费用
- MiniCPM-V 4.6 仅 1.3GB VRAM，适合 4GB 显卡
- qwen3:14b 有 128K 上下文，一次处理大量结构化结果
- 知识图谱存储后可反复查询

---

## 六、总体推荐优先级

| 优先级 | 项目 | 预计工作量 | 省 Token 效果 |
|:------:|------|:----------:|:------------:|
| 🥇 | **搭建 Open WebUI**（RAG + 联网搜索）| 1-2 小时 | ⭐⭐⭐⭐⭐ |
| 🥈 | **Python 自动化脚本**（重复任务委派）| 0.5-1 小时 | ⭐⭐⭐⭐ |
| 🥉 | **SwarmVault 知识图谱** | 2-3 小时 | ⭐⭐⭐ |
| 4 | **视频→知识图谱管道** | 4-8 小时 | ⭐⭐ |

---

## 七、Ollama 性能优化参考

### 7.1 关键环境变量

| 变量 | 推荐值 | 说明 |
|:----:|:------:|------|
| `OLLAMA_MODELS` | `E:\Ollama\models` | 模型存储路径（已设置 ✅） |
| `OLLAMA_NUM_THREAD` | 自动 | CPU 线程数，一般无需手动设置 |
| `OLLAMA_SCHED_SPREAD` | `1` | 多 GPU 时分散加载（你单 GPU 不需要） |

### 7.2 批处理优化

- 增大 `num_batch`（默认 512 → 可尝试 1024-2048）提升吞吐 50-150%
- 低 `temperature`（0.1-0.3）→ 确定性输出，适合自动化任务
- 参考文章: [Ollama Performance Optimization (2026)](https://eastondev.com/blog/en/posts/ai/20260410-ollama-performance-optimization)

### 7.3 模型选择策略

| 任务类型 | 推荐模型 | 理由 |
|---------|---------|------|
| 简单文本处理/分类 | `qwen2.5-coder:14b` | 确定性好，指令遵循强 |
| 复杂推理/知识提取 | `qwen3:14b` | 128K 上下文，推理能力强 |
| 图片/视频分析 | `minicpm-v4.6` | 仅 1.3GB VRAM，视觉能力优秀 |
| 多轮对话 | `qwen3:14b` | 对话流畅度更好 |

---

## 八、相关资源汇总

### 官方文档
- Ollama API 文档: https://github.com/ollama/ollama/blob/main/docs/api.md
- Ollama OpenAI 兼容端点: `http://localhost:11434/v1`
- Ollama 集成列表: https://docs.ollama.com/integrations

### 参考文章
1. [Ollama Tips & Tricks 2026](https://blog.reviewaitool.com/2026/05/11/ollama-tips-tricks-2026/)
2. [Complete Ollama Tutorial (2026)](https://dev.to/proflead/complete-ollama-tutorial-2026-llms-via-cli-cloud-python-3m97)
3. [Ollama vs LM Studio (2026)](https://www.aitooldiscovery.com/how-to/ollama-vs-lm-studio)
4. [Local AI Agents Guide (2026)](https://www.geeky-gadgets.com/local-ai-agents-guide-2026/)
5. [Best Open-Source Agent Projects (2026)](https://flowith.io/blog/10-best-open-source-agent-projects-github-2026/)
6. [Ollama Performance Optimization (2026)](https://eastondev.com/blog/en/posts/ai/20260410-ollama-performance-optimization)

### GitHub 仓库汇总

| 项目 | ⭐ | 链接 |
|:----:|:--:|:----|
| RAGFlow | 83.2k | https://github.com/infiniflow/ragflow |
| Open WebUI | 65k+ | https://github.com/open-webui/open-webui |
| AnythingLLM | 30k+ | https://github.com/Mintplex-Labs/anything-llm |
| Microsoft GraphRAG | 28k+ | https://github.com/microsoft/graphrag |
| LangChain | 公开 | https://github.com/langchain-ai/langchain |
| Neo4j LLM Graph Builder | 2.8k+ | https://github.com/neo4j-labs/llm-graph-builder |
| video-analyzer | 1.5k | https://github.com/byjlw/video-analyzer |
| Atomic | 1.5k | https://github.com/kenforthewin/atomic |
| SwarmVault | — | https://github.com/swarmclawai/swarmvault |
| CocoIndex | — | https://github.com/cocoindex-io/cocoindex |
| Docling | — | https://github.com/docling-project/docling |
| llm-workflow | — | https://pypi.org/project/llm-workflow/ |
