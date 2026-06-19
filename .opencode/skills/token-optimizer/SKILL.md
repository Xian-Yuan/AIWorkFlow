---
name: token-optimizer
description: "Token优化与上下文效率。不降智的前提下大幅节省Token——渐进披露、模型路由、/compact、子Agent隔离、Prompt Caching、批量合并、文件过滤。适用于长会话、大项目、成本敏感场景。"
---

# Token Optimizer — 不降智的 Token 节省

## 核心认知

**Token 优化是上下文工程问题，不是提示词缩短问题。**

关键悖论反驳：精益上下文不仅省钱——还产生更好的输出。同一个方向，不是取舍。

## 你的 Token 烧在哪了？

每次你发消息，模型要重读**全部**对话历史：
- 消息1 = 1x → 消息10 = 10x → 消息30 = 31x
- 模型没有会话间记忆，每次都从头读
- 输入 Token 占 70%-90%，输出只占 10%-30%

## 策略分层（从最小改动开始）

### Tier 1：零代码改动，立即可用

#### 1. 压缩 Rules 文件（已做 ✅）
我们把 561 行 UE5 rules → 40 行通用 rules，**每次会话省 ~500 行 Token**。

#### 2. 精简 system prompt
```
❌ "请你作为一个资深的软件架构师，具有20年经验..."
✅ "资深开发。遵循项目规范。简练输出。"
```

#### 3. 批量合并消息
```
❌ 三条消息："改 auth" → "加限流" → "更新测试"
✅ 一条消息："重构 auth，加限流，更新两个测试"
```
节省：避免 3 次上下文加载

#### 4. 控制对话长度
15-20 条消息后开新会话。使用 handover 摘要传递关键上下文：
```
# 上轮摘要
- 完成了 RBAC 模块的 User/Role/Permission 三表
- 权限粒度到按钮级，super_admin 绕过
- 下一步：refreshToken 落库
```

#### 5. 编辑而非纠正
模型答错了？**编辑原消息**重发，而不是发"不对，我意思是 X"。编辑替换对话，纠正让对话变长。

### Tier 2：架构级优化

#### 6. 渐进披露（Progressive Disclosure）
Skills 只加载 metadata（~100 token/个），完整内容按需加载。
- 这就是为什么 Skills 比把所有规则塞进 rules.md 好
- 你已有的 27 个 Skills 都遵循这个模式

#### 7. 子 Agent 隔离
把大型研究/探索工作委托给子 Agent：
- 子 Agent 独立上下文读取大量文件
- 只返回摘要结果到主对话
- 主对话保持轻量，只接收结论

#### 8. /compact 压缩
手动或自动压缩对话历史。触发时机：64%-75% 上下文使用率。
- 保留代码变更和关键文件路径
- 丢弃冗长的分析过程和中间结果
- 88% 压缩率

#### 9. 模型路由
```
简单任务（格式化/翻译/分类）→ 轻量模型
复杂任务（架构设计/调试）→ 全量模型
深度推理（安全审计/架构师审查）→ 最高规格模型
```

#### 10. 文件过滤
用 `.claudeignore` / `.opencodeignore` 排除：
```
node_modules/  dist/  build/  .git/
*.lock  *.log  *.png  *.jpg
__pycache__/  .cache/  coverage/
```
单次交互 Token 从 150K → 60K（~60% 减少）

### Tier 3：高级技术（DeepSeek 专项）

#### 11. Prompt Caching（Provider 级）
- Anthropic：cache_control 标记稳定前缀，读取成本 10%（省 90%）
- OpenAI：自动缓存 >1024 token 的前缀，缓存命中的 Token 半价
- Google：缓存折扣 ~96%
- DeepSeek：Context Caching 通过 API，Prefill 成本从 7/次 → 0.7/次

#### 12. "三明治注入"（DeepSeek 1M Context 专有）
DeepSeek V4 1M 上下文下，"Lost in the Middle" 依然存在。关键信息放前 20% 或后 20%。

#### 13. 语义面包屑
在长上下文的关键段落之间插入微型摘要标记：
```
[上文要点：auth 模块用 JWT，accessToken 15min，refreshToken 7d]
...（中间大量代码）...
[继续：refreshToken 需要落库，支持踢下线]
```

### Trae/DeepSeek 特别适用

| 技术 | 效果 | 实施难度 |
|------|------|---------|
| 精简 user_rules（561→40行） | 每次会话省 ~500行 | ✅ 已完成 |
| Skills 渐进披露 | 每个 Skill 只加载 100 token 元数据 | ✅ 已有 |
| 15-20 条消息后 /clear | 避免 30x 惩罚 | 直接可用 |
| 批量合并任务 | 3次上下文加载→1次 | 直接可用 |
| Handover 摘要模板 | 跨会话保留关键上下文 | 直接可用 |
| 编辑原消息纠正 | 不累加历史 | 直接可用 |
| 模型路由（规划用完整模型，实现用轻量） | 30-80% 节省 | 需 Trae 支持 |
| planning-with-files 落盘 | 上下文=预算，文件=无限制 | ✅ 已有 Skill |
| 子 Agent 隔离研究 | 主对话不膨胀 | ✅ plan-agent 支持 |
