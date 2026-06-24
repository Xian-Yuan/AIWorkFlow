# Obsidian 大一统分类方案

## 现状盘点

### 当前 ObsidianVault 结构（14 个顶层目录，各自为政）

| 目录 | 文件数 | 内容 |
|------|--------|------|
| 虚幻/ | 177 md | UE5 知识：c++ 47, 蓝图 77, Niagara 22, 关卡/pcg 13, 功能实现 9, 优化 4, 其他 5 |
| 驱煞/ | 29 md | UE5 ARPG 课程笔记：第三周/第四周/第五周/课程外修改 |
| 我的项目/ | 56 md | 个人项目：建木计划、米国当邪修、绝命厨师 |
| 日程规划/ | 15 md | 2024/2025 日程 |
| 墨化S4/ | 7 md | 不明 |
| JinliKG/ | 234 md | AI 视频知识图谱（226 视频 + 3 Concept + 2 Index + 2 Entry + 1 Candidate） |
| AE/API/Houdini/MD/PS/P4V/zb/模型/ | 各 1 md | 零散单文件笔记 |

### 当前两套分类体系不统一

| 来源 | 分类体系 | 问题 |
|------|----------|------|
| bili_classify.py | P0-记忆架构, P0-Hermes实战, P1-Skill自进化, P1-Agent架构, P1-Token优化, P2-代码检索, P2-上下文扩展, P2-Codex实战, P3-AI编程工具, P3-开源项目, P3-模型能力, P4-其他 | 只覆盖 88 个视频，有 P0-P4 优先级但类别名偏技术 |
| JinliKG Index | other, ai-agent, ai-coding, prompt-engineering, ai-knowledge, llm-serving, ai-content, dev-tool, ai-research, dev-infra, ai-frontend, game-dev, search-engine | 覆盖 226 个视频但用英文 slug，跟上面的中文分类完全对不上 |
| Obsidian 顶层 | 虚幻, 驱煞, 我的项目, 日程规划... | 按人生领域分，跟知识主题分类是不同维度 |

## 设计原则

1. **两个正交维度**：领域（知识是关于什么的）x 来源（知识从哪来的），不要混在一起
2. **中文名 + 英文 slug**：目录用中文让人看着舒服，slug 用于检索和编程
3. **优先级保留但独立**：P0-P4 是优先级标签，不是分类名
4. **已有内容不破坏**：只移动和重新组织，不删除任何文件
5. **虚幻/UE5 知识也要纳入**：不只是 AI 视频，你积累的 UE5 知识也是记忆的一部分

## 大一统分类方案

### 顶层：领域分类

`
ObsidianVault/
  知识/                          # 所有结构化知识的家
    AI/                          # AI 领域知识
      记忆架构/                  # P0: 记忆系统设计、Hermes、Letta、MemGPT
      Agent架构/                 # P1: 多Agent协作、Agentic Loop、自主代理
      Skill工程/                 # P1: Skill生命周期、自进化、Harness
      Token优化/                 # P1: Token节省、上下文压缩、RTK/Headroom
      代码检索/                  # P2: RAG、GraphRAG、语义搜索、代码索引
      上下文扩展/                # P2: 长上下文、灯塔注意力、窗口扩展
      编程工具/                  # P3: Codex、Cursor、vibe coding、MCP
      模型能力/                  # P3: 模型评测、推理优化、多模型融合
      知识管理/                  # 跨P: Obsidian、个人知识库、知识图谱
      提示工程/                  # Prompt 技巧、SOP、模板
      内容创作/                  # AI 辅助写作、视频、前端
      开发基建/                  # DevOps、Docker、K8s、搜索服务
    UE/                          # Unreal Engine 知识
      C++/                       # UE5 C++ 开发
      蓝图/                      # 蓝图系统
      Niagara/                   # 特效系统
      关卡与PCG/                 # 关卡设计、程序化生成
      渲染与优化/                # 渲染管线、性能优化
      GAS与游戏系统/             # Gameplay Ability System、战斗、养成
      动画/                      # 动画蓝图、状态机、RootMotion
      打包与部署/                # 打包、导出Web、平台适配
    通用开发/                    # 不限于 AI/UE 的开发知识
      工具链/                    # Git、CI/CD、编辑器
      编程语言/                  # Python、Rust、TypeScript
      基础设施/                  # Docker、K8s、数据库
  项目/                          # 个人项目记录
    建木计划/
    绝命厨师/
    其他项目/
  日程/                          # 时间规划
  收藏/                          # 未分类的零散收藏（临时落脚点）
  JinliKG/                       # 保持！知识图谱的技术层（Concepts/Sources/Indexes/Inbox）
`

### 两套分类的映射

| bili_classify.py (88视频) | JinliKG Index (226视频) | 大一统目录 |
|---|---|---|
| P0-记忆架构 | ai-knowledge | 知识/AI/记忆架构/ |
| P0-Hermes实战 | ai-agent | 知识/AI/记忆架构/ |
| P1-Skill自进化 | prompt-engineering | 知识/AI/Skill工程/ |
| P1-Agent架构 | ai-agent | 知识/AI/Agent架构/ |
| P1-Token优化 | llm-serving | 知识/AI/Token优化/ |
| P2-代码检索 | search-engine | 知识/AI/代码检索/ |
| P2-上下文扩展 | ai-coding | 知识/AI/上下文扩展/ |
| P2-Codex实战 | ai-coding | 知识/AI/编程工具/ |
| P3-AI编程工具 | ai-coding | 知识/AI/编程工具/ |
| P3-开源项目 | ai-research | 知识/AI/编程工具/ |
| P3-模型能力 | llm-serving | 知识/AI/模型能力/ |
| P4-其他 | other | 收藏/ |
| (无) | ai-content | 知识/AI/内容创作/ |
| (无) | dev-tool | 知识/AI/编程工具/ |
| (无) | dev-infra | 知识/通用开发/基础设施/ |
| (无) | ai-frontend | 知识/AI/内容创作/ |
| (无) | game-dev | 知识/UE/GAS与游戏系统/ |
| (无) | ai-knowledge | 知识/AI/知识管理/ |

### 现有 UE5 内容的迁移

| 当前位置 | 文件数 | 新位置 |
|----------|--------|--------|
| 虚幻/c++/ | 47 | 知识/UE/C++/ |
| 虚幻/蓝图/ | 77 | 知识/UE/蓝图/ |
| 虚幻/Niagara/ | 22 | 知识/UE/Niagara/ |
| 虚幻/关卡设计与pcg/ | 13 | 知识/UE/关卡与PCG/ |
| 虚幻/功能实现/ | 9 | 知识/UE/GAS与游戏系统/ |
| 虚幻/优化/ + 虚幻/UE渲染/ | 5 | 知识/UE/渲染与优化/ |
| 虚幻/UE打包注意事项/ + 虚幻/UE导出web资产注意事项/ | 3 | 知识/UE/打包与部署/ |
| 驱煞/ | 29 | 知识/UE/GAS与游戏系统/ |

### 现有零散内容的归属

| 当前位置 | 新位置 | 理由 |
|----------|--------|------|
| 我的项目/ | 项目/ | 保持子目录结构 |
| 日程规划/ | 日程/ | 直接迁移 |
| AE/ | 收藏/ | 单文件 |
| API/ | 知识/通用开发/工具链/ | GitHub API |
| Houdini/ | 收藏/ | 程序化建模，暂归收藏 |
| 模型/ | 知识/AI/模型能力/ | 3D模型相关 |
| MD/PS/P4V/zb/ | 收藏/ | 单文件零散笔记 |
| 墨化S4/ | 项目/ | 如果属于某项目 |

### 优先级标签（作为 frontmatter/tag，不作为目录名）

每个知识笔记的 frontmatter 加：

`yaml
priority: P0    # 直接指导小璃设计
# priority: P1  # 强相关，工作中频繁用到
# priority: P2  # 有参考价值，偶尔查阅
# priority: P3  # 泛了解，扩展视野
# priority: P4  # 待分类/低相关
`

### JinliKG 的角色

JinliKG 保持不变，它是知识图谱的技术层。视频笔记通过 [[wiki-link]] 连接到 知识/AI/ 下的概念笔记。两个入口看同一份知识：
- 知识/ -> 按主题树状浏览
- JinliKG/ -> 按图谱关系浏览

## 记忆路由规则

小璃接到问题时，按以下顺序查找知识：

1. **领域路由**：问题是 UE 还是 AI 还是通用开发？
2. **子领域路由**：AI 记忆架构？AI Agent？UE C++？UE 蓝图？
3. **优先级加权**：P0 > P1 > P2 > P3，同优先级按 forgetting_score 排序
4. **跨域关联**：查 AI 记忆架构时也查 UE 的 StateTree/BT 知识（通过 JinliKG [[链接]]）
5. **Obsidian 检索**：向量索引 + FTS5
6. **memory.db 检索**：knowledge_items FTS5

## 执行计划

### Phase 1: 创建目录结构 + 写路由规则 (不移动文件)

- 创建 知识/AI/ 和 知识/UE/ 子目录
- 创建 知识/通用开发/ 子目录
- 创建 项目/ 和 日程/ 和 收藏/ 目录
- 写 obsidian-taxonomy.json 路由规则文件
- 更新 JinliKG/Jinli-KG-Entry.md 加入新目录的链接

### Phase 2: 迁移现有内容 (用 Obsidian 的方式)

- 虚幻/ -> 知识/UE/
- 驱煞/ -> 知识/UE/GAS与游戏系统/
- 我的项目/ -> 项目/
- 日程规划/ -> 日程/
- 零散文件 -> 收藏/

### Phase 3: 给视频笔记加分类标签

- 读取 bili_classify.py 的分类结果
- 更新 JinliKG/Sources/Videos/ 下每个 .md 的 frontmatter：
  - 加 category: AI/记忆架构
  - 加 priority: P0
  - 加 domain: AI
- 更新 knowledge_items 表的 tags 列

### Phase 4: 重建向量索引

- python scripts/build_obsidian_index.py (索引范围扩展到整个 知识/ 目录)
- 更新 obsidian_retrieve.py 的搜索路径
