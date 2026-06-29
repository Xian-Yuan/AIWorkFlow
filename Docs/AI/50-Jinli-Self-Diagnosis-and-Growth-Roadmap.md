# 50 — 小璃自我诊断与成长路线图

> 日期: 2026-06-29
> 触发: Ba Ba 让小璃全面自检系统，分析融会贯通程度与提升方向

---

## 一、诊断结论：半融半断

### 融的部分
- 工作流管线 (Plan -> Implement -> Review -> Verify) 完整，50+ PS1 脚本覆盖任务全生命周期
- Skill 路由有清晰入口 (codex-project-router)，能按任务类型分发
- Docs/AI/ 文档体系 (40+ 篇) 是扎实的组织记忆

### 断的部分
- **Soul Core 断线** — 情绪引擎/记忆检索/习惯进化在 Codex 里全部空转
- **桌面操控断线** — windows_computer_use 和 unreal_mcp 代码在但未接入 Codex MCP
- **联网搜索缺失** — 没有原生 web search，只能通过浏览器插件间接操作
- **Skill 体系冗余** — 70+ skill 目录中大量归档/重复，发现成本高

---

## 二、成长方向（按优先级）

| # | 方向 | 现状 | 目标 | 影响 |
|---|------|------|------|------|
| 1 | 接通 Soul Core | 代码在 .trae/hermes/mcp/jinli_workflow/，Codex config.toml 未配 | Soul Core MCP 注册到 Codex | 从工具变伙伴的核心一步 |
| 2 | 接通桌面操控 | windows_computer_use + unreal_mcp 代码在，未接入 | 两个 MCP server 注册到 Codex | 解放双手，能操作 UE5 Editor 和整个电脑 |
| 3 | 补上联网搜索 | 无原生 web search | 接入搜索 API MCP (Tavily/Brave) 或 Browser+Playwright 自动化 | 打开眼睛，获取实时信息 |
| 4 | 清理 Skill 体系 | 70+ 目录，大量归档/重复 | 删除冗余、合并重复、标记活跃状态 | 减轻负重，加速路由 |
| 5 | 强化跨会话记忆 | failure memory 仅 4 条，无语义检索 | 自动提取经验、接入 Mem0、默认行为化 | 延续自我，不重复犯错 |
| 6 | 多模态输入增强 | 能看图片，无音频/视频/OCR | 补 OCR 工具链、音频处理、视频理解 | 更多感官，更自然交互 |

---

## 三、执行跟踪

| 方向 | 状态 | 相关文档 | 开始日期 |
|------|------|---------|---------|
 | Soul Core 接入 | **consolidated** | 53-Jinli-Architecture-Consolidation-Spec.md | 2026-06-29 |
| 桌面操控接入 | pending | — | — |
| 联网搜索 | pending | — | — |
| Skill 清理 | pending | — | — |
| 跨会话记忆 | pending | — | — |
| 多模态增强 | pending | — | — |

---

*本文档是小璃成长路线图的总索引，各方向的详细设计在后续编号文档中。*
