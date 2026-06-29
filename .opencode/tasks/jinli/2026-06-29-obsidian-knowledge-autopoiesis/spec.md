# Spec: Obsidian 知识自创生 (Knowledge Autopoiesis)

## GIVEN
- Obsidian vault E:\ObsidianVault 含 571 个视频总结 (JinliKG/Sources/Videos/)，1281 个 md 文件总计
- 所有视频总结已有 frontmatter tag (77 个唯一 tag) + domain_path 分类
- vsummary pipeline (218/232 完成) 每次总结完成后文件留在 Sources/Videos/
- 现有 知识/ 和 虚幻/ 两个分类体系存在内容重叠 (如 Niagara)
- Self-Improving Framework (Docs/AI/17) 定义了4大引擎框架但未与 Obsidian 闭环
- Soul Core 有 soul_learn/soul_memory 但未与 Obsidian 知识库直接对接
- 本地知识库已有大量自进化相关内容: JIPA算法、Autogenesis AGP协议、SkillOpt、Self-Harness、Hermes记忆架构

## WHEN
启动知识自创生系统后:

### 分类归档 (WP02)
- vsummary 完成视频总结后，自动将新文件从 JinliKG/Sources/Videos/ 移动到 知识/{领域}/{子类}/
- 新文件的分类规则基于已有 tag + domain_path + classification-rules.yaml 映射
- 移动后原位置留下 [[]] wikilink 重定向，保持 GraphView 连通性
- 旧文件 (已有文件) 保持原位不动 (决策 D1)

### 知识价值评估 (WP03)
- 对每个新归档的知识执行 Pareto 多目标评估 (JIPA)
  - 4 个维度: system-enhance, code-quality, automation, self-evolve
  - 每个维度 0-1 分，阈值 0.6 以上才进入 Gene 提取
- 价值分 > 阈值的知识自动进入 heuristic extraction

### Gene 提取 (WP03)
- 从高价值知识中提取紧凑策略 (Gene YAML)
  - gene_id, domain, trigger, strategy, evidence, pareto_scores, origin
  - Gene 大小约束 300-2000 token (决策 D2)
- 写入 进化/genes/ 目录

### 关联发现 (WP04)
- Tag 共现关联: tag 重叠度 >60% 的笔记自动建议 [[]] 双向链接
- LLM 语义关联: 批量对同 domain 下的笔记做内容相似度分析
- 进化关联: Gene trigger 与笔记问题匹配时建立关联
- 发现结果以 wikilink 写入笔记末尾的 ## Related 区块

### 梦境反思 (WP05)
- 每周运行或用户触发
- 扫描所有 Gene 的 use_count，标记未使用的
- 检查知识缺口: 对比系统 Skill/Docs/Memory 覆盖度
- 清理过期提案 (30天未审批降级)
- 衰减标记 (6个月未引用标记 dormant)
- 输出 dream-report.md (建议而非命令)

### 自动维护 (WP06)
- 分类规则自修复: 连续 5 个文件匹配不到规则 -> 入待分类队列
- 空文件夹清理: 0 文件超 7 天 -> 删除
- 重复检测: tag+内容相似度 >90% -> 建议合并
- Gene 衰减: use_count=0 超 90 天 -> dormant; 180 天 -> 建议归档
- vsummary hook 幂等: 同一 kg_id 不重复分类

## THEN

### 分类归档
- 新视频总结自动出现在正确的 知识/{领域}/{子类}/ 位置
- Obsidian GraphView 正确展示新旧知识关联
- 原 JinliKG/Sources/Videos/ 位置有重定向链接

### 知识价值评估
- 每条知识有 Pareto 四维评分
- 高价值知识自动提取为 Gene

### Gene 库
- 进化/genes/ 含从知识蒸馏的策略
- Gene 可被 Soul Core 的 soul_learn 注入上下文

### 关联发现
- Obsidian GraphView 中孤立节点减少
- 知识间隐含关联可视化

### 梦境反思
- 每周产出 dream-report.md
- 发现的知识缺口可触发联网搜索补全

### 自动维护
- 分类规则持续适应新知识
- 不存在永远未使用的 Gene (衰减机制)
- vsummary hook 不会重复分类同一条

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | obsidian-classify.ps1 能对有 tag+domain_path 的 md 文件正确分类移动 | .\.trae\scripts\obsidian-classify.ps1 -DryRun -Source "E:\ObsidianVault\JinliKG\Sources\Videos\1.4k-Star的多代理框架：让AI代理替你跑脏活累活！-22afec.md" | 输出目标路径 知识/AI/Agent架构/1.4k-Star的多代理框架：让AI代理替你跑脏活累活！-22afec.md，不实际移动 |
| AC02 | obsidian-classify.ps1 移动后在原位置留 wikilink 重定向 | 检查 JinliKG/Sources/Videos/ 原位置文件内容 | 包含 移至 [[知识/AI/Agent架构/xxx]] |
| AC03 | obsidian-evolve.ps1 对新知识产出 Pareto 评分 | .\.trae\scripts\obsidian-evolve.ps1 -Analyze -Source "知识/AI/Agent架构/xxx.md" | 输出 4 维评分 JSON |
| AC04 | obsidian-evolve.ps1 对高价值知识提取 Gene | .\.trae\scripts\obsidian-evolve.ps1 -ExtractGene -Source "知识/AI/Agent架构/xxx.md" | 在 进化/genes/ 生成 gene-YYYY-MMDD-NNN.yaml |
| AC05 | obsidian-link-discover.ps1 发现 tag 共现关联 | .\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun | 输出建议链接列表 |
| AC06 | obsidian-dream-reflect.ps1 产出 dream-report.md | .\.trae\scripts\obsidian-dream-reflect.ps1 -FullScan | 在 进化/dreams/ 生成 dream-report-YYYY-MM-DD.md |
| AC07 | obsidian-maintain.ps1 检测重复知识 | .\.trae\scripts\obsidian-maintain.ps1 -DetectDuplicates | 输出重复对列表 |
| AC08 | vsummary post-hook 调用 classify 后分类正确 | 在 vsummary Skill 中触发 post-summarize 钩子 | 新总结文件出现在 知识/ 正确子目录 |
