# 失败清理与反冗余机制（Fail-Safe & Anti-Bloat）

## 概述

本文件定义两套强制机制：
1. **失败清理机制** — 方案失败时自动回退，防止残留代码
2. **反冗余机制** — 搜索先于创建，防止重复造轮子


3. **重复检测机制** — 自动化扫描重复代码块，AI 修改后验证（详见 skills/anti-duplication/SKILL.md）
---

## 失败清理机制

### 规则 1：实现前快照

**每次开始新实现前（新建/修改文件），必须执行：**

```bash
# 声明实现范围（记录到日志）
echo "[IMPLEMENT] $(Get-Date -Format 'yyyy-MM-dd HH:mm') — 方案: <方案名> — 涉及文件: <文件列表>" >> MLGuide/implementation-log.md

# 安全快照（git stash，可恢复）
git stash push -m "SNAPSHOT: <方案名> — $(Get-Date -Format 'yyyy-MM-dd_HH-mm')" -- <涉及文件>
```

> **Agent 规则**：实现前不允许跳过快照。快照是回退的唯一保障。

### 规则 2：失败阈值与降级

| 连续失败次数 | 触发动作 |
|:---:|------|
| 1-2 次 | 按 ErrorKnowledgeBase 修复，继续编译 |
| **3 次** | **触发降级**：停止修补，回退到快照，请求用户决策 |
| 3 次以上 | 视为方案根本错误，废弃当前方案 |

降级选项（Agent 必须列出供用户选择）：
- a) **回退到快照**，换方案 B
- b) **保留代码但注释掉**，标记 `// TODO: [方案名] 待定 — YYYY-MM-DD`
- c) **用户手动介入**

### 规则 3：清理协议

**方案被放弃时必须执行：**

```
1. git stash pop (恢复快照)  或  手动 revert
2. 删除本次方案新增的 .h/.cpp 文件
3. Build.cs 修改 → 恢复原行（从 git diff 中还原）
4. 在 implementation-log.md 记录失败原因
5. ErrorKnowledgeBase 新增条目（如适用）
```

**方案被注释保留时必须：**
```
1. 所有相关代码用 #if 0 ... #endif 或 // TODO: 包裹
2. 标记日期和方案名
3. 30天内未被激活 → 自动删除规则提醒
```

### 规则 4：失败记录

```markdown
## implementation-log.md 格式

### YYYY-MM-DD HH:mm — 方案A: <描述>
- **状态**: 成功 | 失败
- **涉及文件**: file1.cpp, file2.h
- **失败原因**: (如适用)
- **残留清理**: 已清理 | 已注释保留 | 未清理（说明）
- **知识库条目**: E0XX (如适用)
```

---

## 反冗余机制

### 规则 5：搜索先于创建

**创建任何新类/函数/DataAsset 前，必须执行：**

```bash
# 搜索项目中是否存在类似实现
rg -i "<关键词>" "Source/" "Plugins/" --include="*.h" --include="*.cpp" -l
rg -i "<关键词>" "Content/" --include="*.uasset" -l  # 蓝图/资产

# 搜索 Docs/ 中是否已有相关文档
rg -i "<关键词>" "Docs/" --include="*.md" -l

# 搜索已有 Skill 中是否覆盖
rg -i "<关键词>" ".trae/skills/" --include="SKILL.md" -l
```

**Agent 规则**：搜索结果必须记录在 implementation-log.md 中。如果找到类似实现，必须先评估是否可复用，不可复用的理由必须记录。

### 规则 6：死代码检测

**Scripts/check-dead-code.ps1 扫描以下模式：**

| 检测项 | 说明 |
|--------|------|
| `#if 0 ... #endif` | 失效代码块，超过30天未激活 → 标记删除 |
| `// TODO: [...] 待定` | 超过30天的 TODO → 提醒清理 |
| 未被 include 的 .h 文件 | 可能为废弃头文件 |
| 已注释的 Build.cs 依赖 | 废弃模块依赖 |
| 重复的函数实现 | 两个文件中的相同函数签名 |


### 规则 6.1：重复代码块检测

**使用 detect-duplicates.ps1 扫描重复代码块：**

```powershell
# 扫描 C++ 源码中的重复代码块（默认阈值 >= 6 行）
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/" -Threshold 6

# 扫描指定模块
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/RTS/" -Threshold 8 -Format markdown

# CI 模式：发现 L1 重复时失败退出
& ".trae/scripts/detect-duplicates.ps1" -Path "Source/" -Threshold 6 -CI
```

**检测分级：**

| 级别 | 定义 | 阈值 | 动作 |
|:----:|------|:----:|------|
| L1 | 完全重复（相同代码块，仅变量名/空格不同） | >= 6 行 | 立即提取为共享函数/方法 |
| L2 | 结构重复（相同控制流/模式，内容不同） | >= 10 行 | 提取为模板/基类/策略模式 |
| L3 | 语义重复（不同实现但相同功能） | 任意 | 合并为单一实现 |
| L4 | 模式重复（相似的文件结构/类层次） | 3+ 文件 | 评估是否需要抽象 |

**Agent 规则：**
- 每次重构完成后必须运行重复检测
- Review 阶段 L1 重复 = blocking issue
- 新增代码不允许引入 L1/L2 重复
- 详细规则见 `skills/anti-duplication/SKILL.md`

### 规则 7：单一真相源

```
规则优先级（冲突时向上服从）：
  Docs/AI/         > Docs/* > .trae/skills/ > .opencode/agents/
  （工作流规则）     （领域知识） （Skill定义）   （Agent行为）

禁止：
- Skill 中重复定义 Docs/ 已有的概念
- Agent 中重复定义 Skill 已有的流程
- 同一概念出现在多个 Skill 中（应引用，不重复）
- 同一功能在多个文件中重复实现（应提取，不复制）
```

### 规则 8：引用而非重述

**Agent 输出规范**：
```
✅ 正确：按 Docs/GAS/03-GameplayAbility.md §2 中的模式创建能力类
❌ 错误：重新解释 GameplayAbility 的生命周期...
```

**Validator 检查**：如果 Agent 输出中有超过 50 字的重复解释，标记违规。

### 规则 9：文档生命周期

```
新文档：创建时标注创建日期和版本
旧文档：每年审查一次，标注状态：
  - Active（活跃使用中）
  - Stable（稳定但非频繁更新）
  - Deprecated（已过时，指向替代文档）
  - Archive（仅保留作历史参考）
废弃文档：标记 Deprecated 3个月后删除
```

---

## git 安全使用规则

### 操作分级

| 级别 | 操作 | 许可 |
|:---:|------|:---:|
| 🟢 **默认允许** | `git add` | 无需许可 — 暂存文件 |
| 🟢 **默认允许** | `git commit -m "..."` | 无需许可 — 本地提交，可用 `git revert` 撤回 |
| 🟢 **默认允许** | `git stash push/pop/list` | 无需许可 — 纯本地快照 |
| 🟢 **默认允许** | `git diff / status / log` | 无需许可 — 只读 |
| 🟢 **默认允许** | `git checkout -- <file>` | 无需许可 — 单文件恢复 |
| 🟡 询问 | `git push` | **需要** — 影响远程 |
| 🟡 询问 | `git branch -d / merge` | **需要** — 修改分支 |
| 🔴 禁止 | `git reset --hard / clean -fd` | 不可逆，绝对禁止 |
| 🔴 禁止 | `git push --force / rebase / commit --amend` | 破坏历史，绝对禁止 |

### 默认行为

Agent 创建或修改文件后，**自动暂存并提交**：
```bash
git add <修改的文件>
git commit -m "<简短描述>"
```

用户可以随时 `git log` 查看历史，`git revert <commit>` 撤回任意提交。

---

## 集成到 Agent

所有 Agent 必须绑定以下规则：

1. **实现前**：git stash 快照 + implementation-log.md 记录
2. **实现中**：编译失败 → ErrorKB 查询 → 第3次失败触发降级
3. **方案放弃**：执行清理协议
4. **创建前**：grep 搜索现有实现
5. **输出时**：引用 Docs/ 路径，不重述概念

6. **重构后**：运行 detect-duplicates.ps1 验证无新增重复
7. **Review 时**：L1 重复 = blocking，必须清理后重新提交
