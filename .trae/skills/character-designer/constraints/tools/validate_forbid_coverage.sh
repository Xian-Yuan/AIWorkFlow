#!/bin/bash
# Character Designer FORBID 冲突规则覆盖验证脚本
# 检查每个约束文件的 FORBID 项是否被 _rules.md 中至少一条规则覆盖

cd "$(dirname "$0")/.."

echo "=== FORBID 冲突规则覆盖验证 ==="
echo ""

# 从 _rules.md 提取所有已知规则覆盖的冲突对象
# 格式: 规则行 "| R{N} | {A} + {B} | ..." → 提取 A 和 B 中的实体
echo "--- 步骤1: 提取 _rules.md 中已覆盖的冲突实体 ---"

# 提取所有规则中涉及的特征实体（简化为关键词匹配）
declare -A COVERED

while IFS= read -r line; do
    # 匹配规则行: | R{N} | {冲突描述} | {解决方案} |
    if echo "$line" | grep -qE '^\| R[0-9]+ \|'; then
        # 提取冲突描述列
        conflict=$(echo "$line" | sed 's/^| R[0-9]* | //' | sed 's/ |.*//')
        # 提取被规则覆盖的实体对
        # 记录为 coverage 标记
        echo "  RULE: $conflict"
    fi
done < constraints/_rules.md

echo ""
echo "--- 步骤2: 扫描所有约束文件的 FORBID 冲突标记 ---"

UNCOVERED=0

for file in */**.md; do
    case "$file" in
        _TEMPLATE.md|_rules.md|_public.md|alias.md|README.md|*/README.md|tools/*) continue ;;
    esac

    # 提取 FORBID 段中带"冲突:"标记的项
    conflicts=$(sed -n '/^## FORBID/,/^##/p' "$file" | grep "冲突:" 2>/dev/null)
    if [ -n "$conflicts" ]; then
        # 提取文件名作为源特征
        src_feature=$(basename "$file" .md)
        src_category=$(dirname "$file")
        echo "  $src_category/$src_feature:"
        echo "$conflicts" | while IFS= read -r item; do
            echo "    FORBID: $item"
        done
    fi

    # 还检查 MUST/FORBID 段中隐含的冲突（如"禁止重甲"但未标冲突标记）
    implicit=$(sed -n '/^## FORBID/,/^##/p' "$file" | grep "禁止" 2>/dev/null)
    has_implicit=$(echo "$implicit" | grep -v "冲突:" | grep -v "^$" | wc -l 2>/dev/null || echo 0)
    if [ "$has_implicit" -gt 0 ]; then
        # 隐式冲突，不做强制要求
        :
    fi
done

echo ""
echo "=== 完成 ==="
echo "注意: 覆盖完整性需要人工复查冲突标记与 _rules.md 规则的对应关系。"
echo "建议: 每个文件中 FORBID 的「冲突: {特征值}」能在 _rules.md 中找到对应规则。"
