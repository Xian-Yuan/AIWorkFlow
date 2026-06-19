# 错误知识库 (Error Knowledge Base)

## 目标

建立一个**可增长、可搜索、可自动命中**的错误知识库，让 AI 在每次修复错误后：
1. 抽象出 **现象 → 原因 → 解决方案 → 案例**
2. 回写到知识库
3. 下次遇到相同/相似错误时，先查询知识库，避免重复排查

## 目录结构

```
ErrorKnowledgeBase/
├── README.md                  # 本文件
├── TEMPLATE.md                # 条目模板
├── E000-Template.md
├── E001-Compile-GeneratedBody.md
├── E002-Compile-ModuleDependency.md
├── E003-Compile-IncludePath.md
├── ...                        # 持续增长
```

## 条目格式

每个条目是一个独立 Markdown 文件，文件名格式：`E<编号>-<简短描述>.md`

```markdown
---
id: E000
title: 错误标题
category: 编译错误 | 运行时错误 | 资产错误 | 逻辑错误
system: 所属系统 (UHT / GAS / Lyra / Build / 蓝图 / 容器 / 数学 / 线程)
severity: 阻断 | 严重 | 一般 | 建议
firstSeen: 2026-05-09
lastSeen: 2026-05-09
relatedIds: [E001, E002]
keywords: [关键词1, 关键词2]
---

## 现象

```
错误日志原文
```

## 原因

分析根本原因。

## 解决方案

具体修复步骤。

## 案例

```cpp
// 错误写法
// 正确写法
```

## 预防

如何避免此错误再次发生。

## 检测关键词

[关键词列表，用于模糊匹配]
```

## AI 工作流规则

1. **先查库**：遇到编译/运行时错误，先扫描 ErrorKnowledgeBase/ 的 `keywords` 和 `title`，用错误信息关键词模糊匹配。
2. **找到匹配** → 按已知方案修复，更新 `lastSeen`。
3. **找不到匹配** → 分析原因 → 修复 → 新建条目（使用 TEMPLATE.md）。
4. **禁止**：修复错误后不回写知识库。

## 搜索技巧

- 按 `category` 过滤：`编译错误` / `运行时错误` / `资产错误` / `逻辑错误`
- 按 `system` 过滤：`UHT` / `GAS` / `Lyra` / `Build` / `容器` / `数学`
- 按 `keywords` 搜索：用错误信息中的关键短语匹配
