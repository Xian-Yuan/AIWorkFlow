---
name: rag-hallucination-guard
description: "RAG与幻觉预防技能。实现检索增强生成、CoVe自验证、结构化推理、多供应商交叉验证。用于提升AI输出质量、减少幻觉、增强代码可靠性。"
---

# RAG + 幻觉预防 — 模型输出质量增强

## 概述

基于 2025-2026 年学术界和工业界最佳实践，提供减少模型幻觉、提升输出质量的工程化技能。

## 核心策略层

### Layer 1：基础提示词约束
```
在回答任何问题之前：
1. 如果信息不在提供的上下文中，明确说"我无法确定"
2. 不要编造 API/函数/方法名——先在代码库中搜索确认
3. 引用代码时标明文件和行号
4. 不确定时主动询问而非猜测
```

### Layer 2：Chain-of-Verification（CoVe）自验证

**四阶段流程：**

1. **Create（创建）**：生成初始回答
2. **Outline（分解）**：将回答分解为可独立验证的声明
3. **Verify（验证）**：逐条检查每个声明是否可被证实
4. **Emit（输出）**：只输出通过验证的声明

实施要点：
- 每次代码生成后，检查是否使用了不存在的 API/方法
- 断言（assertion）必须验证，不能假设
- 数字/配置/路径引用必须找到源文件确认

### Layer 3：RAG 检索增强

当需要外部知识时：
1. **先检索，后回答**：搜索项目代码库或网络获取权威来源
2. **标注来源**：每个事实声明附带来源引用
3. **上下文管理**：检索结果需要去重和压缩，防止上下文溢出
4. **质量过滤**：优先权威来源，忽略低质量内容

### Layer 4：多源交叉验证

对关键决策：
1. 同一问题用不同搜索词检索多次
2. 对比多个来源的一致性
3. 不一致时优先选择最权威/最新来源
4. 标记不确定信息并标注置信度

## 代码生成特别规则

### 函数/Method 调用检查
```markdown
在调用任何函数前必须确认：
1. 函数存在于当前项目依赖中
2. 参数签名正确（通过 docs/APIRef 或源码确认）
3. 返回值类型匹配
4. 不凭记忆写 API 调用
```

### 幻觉预防检查清单
- [ ] 所有 API 调用是否在依赖中存在？
- [ ] 所有文件路径是否在当前项目中存在？
- [ ] 所有配置项名称是否正确？
- [ ] 所有数值是否有依据而非猜测？
- [ ] 是否为不确定信息标注了置信度？
- [ ] 是否在回答中区分了"事实"和"推测"？

## 高性能 RAG 模板

```
// RAG 查询伪代码
function grounded_answer(question):
    // Step 1: 检索
    query_variants = expand_query(question)       // 生成 3-5 个变体
    candidates = hybrid_search(codebase + docs)   // 稀疏+密集检索
    ranked = rerank(candidates, question)         // Cross-encoder 重排

    // Step 2: 上下文压缩
    context = deduplicate_and_summarize(
        ranked,
        token_budget=8000     // 为回答留空间
    )

    // Step 3: 生成 + 验证
    answer = generate(question, context)
    verified = self_verify(answer, context)        // CoVe 验证
    return verified.with_sources()
```

## 重要提醒

这些技术是**工程约束**而非可选建议。每次代码生成和回答都应遵循最低限度的验证流程。
