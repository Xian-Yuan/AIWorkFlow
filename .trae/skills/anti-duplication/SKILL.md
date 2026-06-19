---
name: anti-duplication
description: "AI多次修改导致代码冗余/重复的检测与预防。检测重复代码块、重构后验证无新重复、搜索先于创建、DRY强制。用于AI频繁修改后清理、Review阶段质量检查、重构后验证。"
---

# Anti-Duplication Protocol

## 定位

本 Skill 解决 AI 多次修改/重构导致的代码冗余和重复问题。核心原则：**每次修改都可能引入重复，必须主动检测而非事后补救。**

## 何时调用

- Implement 阶段：每次完成一个 task 后自检
- Review 阶段：提交前全量扫描
- 重构完成后：验证是否引入新重复
- 用户明确要求检查重复时

---

## 规则 1：搜索先于创建（Search-Before-Create）

**创建任何新类/函数/DataAsset/Blueprint 前，必须执行：**

```powershell
# C++ 代码搜索
rg -i "<关键词>" "Source/" "Plugins/" --include="*.h" --include="*.cpp" -l

# Blueprint/资产搜索
rg -i "<关键词>" "Content/" --include="*.uasset" -l

# 文档搜索
rg -i "<关键词>" "Docs/" --include="*.md" -l

# Skill 搜索
rg -i "<关键词>" ".trae/skills/" --include="SKILL.md" -l
```

**Agent 规则**：
- 搜索结果必须记录在 implementation-log.md 中
- 找到类似实现时，必须先评估是否可复用
- 不可复用的理由必须记录
- 禁止跳过搜索直接创建

## 规则 2：重复检测分级

| 级别 | 定义 | 阈值 | 动作 |
|:----:|------|:----:|------|
| **L1 - 完全重复** | 相同代码块，仅变量名/空格不同 | >= 6 行 | 立即提取为共享函数/方法 |
| **L2 - 结构重复** | 相同控制流/模式，内容不同 | >= 10 行 | 提取为模板/基类/策略模式 |
| **L3 - 语义重复** | 不同实现但相同功能 | 任意 | 合并为单一实现 |
| **L4 - 模式重复** | 相似的文件结构/类层次 | 3+ 文件 | 评估是否需要抽象 |

## 规则 3：重构后自检（Post-Refactor Self-Check）

**每次重构完成后，必须执行以下检查：**

### 3.1 新增重复检查
```powershell
# 运行重复检测脚本
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/" -Threshold 6
```

### 3.2 死代码检查
```powershell
# 检查是否有未引用的新文件
rg -i "#include.*<新文件名>" "Source/" --include="*.cpp" --include="*.h" -c
```

### 3.3 接口一致性检查
- 新函数签名是否与已有函数签名高度相似（参数类型相同，仅函数名不同）
- 新类是否与已有类职责重叠

## 规则 4：DRY 强制规则

### 4.1 禁止事项
- 禁止复制粘贴超过 3 行的代码块
- 禁止创建与已有函数签名相似度 > 80% 的新函数
- 禁止在多个文件中定义相同的常量/配置值
- 禁止创建职责与已有类重叠的新类

### 4.2 必须事项
- 相同逻辑出现 2 次 → 提取为函数
- 相同模式出现 3 次 → 提取为基类/模板
- 相同配置出现 2 处 → 提取为 DataAsset/配置文件

## 规则 5：AI 修改影响范围评估

**每次 AI 修改前，评估影响范围：**

| 修改类型 | 影响范围 | 检查要求 |
|---------|---------|---------|
| 新增文件 | 全局 | 搜索是否已有类似文件 |
| 修改现有函数 | 该函数所有调用点 | 检查调用点是否有重复逻辑 |
| 新增函数 | 同类/同模块 | 检查是否与已有函数重复 |
| 重构 | 涉及的所有文件 | 重构后运行完整重复检测 |
| 删除代码 | 引用该代码的所有位置 | 确认无残留引用 |

## 规则 6：重复检测报告格式

```markdown
## Duplication Report

**Scan Time:** YYYY-MM-DD HH:mm
**Scope:** Source/ + Plugins/
**Threshold:** >= 6 lines

### Findings

| # | Level | File1 | File2 | Lines | Description | Action |
|---|:-----:|-------|-------|:-----:|-------------|--------|
| 1 | L1 | Foo.cpp:45-52 | Bar.cpp:120-127 | 8 | Identical error handling | Extract to ErrorUtils |
| 2 | L2 | AComp.h:10-25 | BComp.h:15-30 | 16 | Same property pattern | Extract base class |

### Summary
- L1 (完全重复): N 处
- L2 (结构重复): N 处
- L3 (语义重复): N 处
- L4 (模式重复): N 处
```

## 规则 7：UE5 特定重复模式

| 模式 | 检测方法 | 处理 |
|------|---------|------|
| 重复的 UPROPERTY 配置 | 搜索相同 UFUNCTION/UPROPERTY 签名 | 提取到公共基类 |
| 重复的 GameplayAbility 逻辑 | 搜索相同 GA 生命周期模式 | 提取到 AbilityTask 或基类 GA |
| 重复的 Component 初始化 | 搜索相同 BeginPlay/Setup 模式 | 提取到 Component 基类 |
| 重复的 DataAsset 字段 | 搜索相同 UPROPERTY 集合 | 合并或创建层级结构 |
| 重复的 Blueprint 节点图 | 手动检查 | 提取到 Function Library 或 Macro |
| 重复的 Build.cs 依赖 | 搜索相同模块依赖列表 | 提取到公共 Build.cs 或 ModuleRules 扩展 |

## 规则 8：与现有防线集成

| 现有防线 | 本 Skill 增强 |
|---------|-------------|
| `anti-degradation` 规则 1（修复循环中断） | 修复循环中每次重试前检查是否产生重复 |
| `code-simplifier` | 简化后运行重复检测，防止简化引入新重复 |
| `FailSafe-AntiBloat.md` 规则 5（搜索先于创建） | 强化为 AI 行为规则，加入具体搜索命令 |
| `FailSafe-AntiBloat.md` 规则 6（死代码检测） | 扩展为包含重复检测的死代码扫描 |
| `verification-before-completion` | 完成验证中加入重复检测步骤 |

## 规则 9：渐进式清理策略

**不要一次性清理所有历史重复**——这会导致巨大的、不可审查的 PR。

| 策略 | 说明 |
|------|------|
| **新代码零容忍** | 新增代码不允许引入任何 L1/L2 重复 |
| **修改文件连带清理** | 修改一个文件时，清理该文件内的 L1 重复 |
| **历史重复渐进清理** | 每次迭代清理 1-2 处历史 L1 重复 |
| **重构窗口集中清理** | 在专门的重构 PR 中批量清理 |

## 规则 10：自动化集成

### 10.1 手动扫描
```powershell
# 扫描 C++ 源码
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/" -Threshold 6 -Format "markdown"

# 扫描指定模块
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/RTS/" -Threshold 8
```

### 10.2 Review 阶段自动触发
Agent 在 Review 阶段必须：
1. 运行 `detect-duplicates.ps1`
2. 将报告附在 review 输出中
3. 对 L1 重复标记为 blocking issue

### 10.3 未来 CI 集成（可选）
```yaml
# .github/workflows/duplication-check.yml
- name: Run duplication check
  run: pwsh .trae/scripts/detect-duplicates.ps1 -Path Source/ -Threshold 6 -CI
```

## 禁止事项

- 不搜索就直接创建新类/函数
- 复制粘贴超过 3 行代码而不提取
- 重构后不运行重复检测
- 忽略 L1 级别的重复
- 在同一个 PR 中混合功能开发和重复清理
- 跳过 Git 快照直接开始清理

## 集成到工作流

- **Plan 阶段**：评估是否可复用现有实现，而非新建
- **Implement 阶段**：每完成 3 个 task 后运行重复检测
- **Review 阶段**：全量扫描，L1 重复 = blocking
- **Verify 阶段**：独立 subagent 运行重复检测，确认无新增重复
