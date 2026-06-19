---
name: github-project-search
description: "GitHub方案搜索。用户需要搜索开源项目、参考实现、技术方案时，使用GitHub MCP工具进行多维度搜索（仓库/代码/Issue），输出结构化对比报告。"
---

# GitHub 方案搜索

## 触发条件

用户说以下任一关键词时自动激活：
- "搜一下 GitHub 上有没有"
- "找一下类似的开源项目"
- "有没有现成的方案/实现"
- "帮我找一下 XXX 相关的项目"
- "搜索/查找 GitHub"

## 搜索策略

### 三阶段搜索法

**阶段 1：多关键词并行搜索**
对同一个需求用 3-4 个不同关键词搜仓库：
- 精确关键词（如 "MCP server windows automation"）
- 泛化关键词（如 "computer use agent"）
- 行业术语（如 "GUI automation tool"）
- 技术栈限定（如 "python desktop automation MCP"）

**阶段 2：深度探索**
在找到的顶级仓库中：
- 读取 README 确认功能匹配度
- 检查 stars/最近更新时间判断活跃度
- 搜索 Issues 了解社区成熟度

**阶段 3：对比输出**
输出结构化对比表：项目名 / Stars / 语言 / 核心功能 / 与需求匹配度 / 许可证

## 搜索技巧

### Stars 排序（默认）
```
search_repositories: query + stars desc → 找最成熟的项目
```

### 最近更新排序
```
search_repositories: query + updated desc → 找活跃项目
```

### 代码搜索
```
search_code: 搜具体实现 → "如何实现 XXX 功能的代码片段"
```

### Issue 搜索
```
search_issues: 搜问题 → "了解常见坑点和社区活跃度"
```

## 输出格式

```
## GitHub 搜索结果

### 需求理解
- [用户需求一句话]

### 搜索关键词
1. [关键词1] → N 结果
2. [关键词2] → N 结果

### 推荐项目
| 排名 | 项目 | Stars | 语言 | 匹配点 | 许可证 |
|-----|------|-------|------|--------|--------|
| 1 | xxx/xxx | 12K | Python | ✅ 完全匹配 | MIT |

### 推荐理由
- 为什么推荐第1名
- 和需求的对应关系
- 注意事项（是否已停更/架构限制等）
```
