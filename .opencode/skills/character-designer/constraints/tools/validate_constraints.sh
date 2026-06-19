#!/bin/bash
# Character Designer 约束文件格式校验脚本
# 检查每个约束文件是否符合 _TEMPLATE.md 标准格式

cd "$(dirname "$0")/.."

MUST_SECTIONS=("视觉符号" "MUST" "SHOULD" "FORBID" "配色约束" "低像素适配" "SYNERGY")
TOTAL=0
PASS=0
FAIL=0
WARN=0

echo "=== Character Designer 约束文件格式校验 ==="
echo ""

for file in */**.md; do
    # 跳过系统文件和非约束文件
    case "$file" in
        _TEMPLATE.md|_rules.md|_public.md|alias.md|README.md|*/README.md|tools/*) continue ;;
    esac

    ((TOTAL++))
    ISSUES=""

    # 检查是否有元数据行
    if ! grep -q "^>.*|.*等级:" "$file" 2>/dev/null && ! grep -q "^>.*约束等级" "$file" 2>/dev/null; then
        ISSUES="$ISSUES  [缺元数据]"
    fi

    # 检查每个必须段
    for section in "${MUST_SECTIONS[@]}"; do
        if ! grep -q "^## $section" "$file" 2>/dev/null; then
            ISSUES="$ISSUES  [缺段:$section]"
        fi
    done

    # 检查等级与内容一致性（有 MUST 则等级应为硬约束）
    if grep -q "^## MUST" "$file" 2>/dev/null; then
        has_must_items=$(sed -n '/^## MUST/,/^##/{/^- /p}' "$file" | wc -l)
        if [ "$has_must_items" -gt 0 ]; then
            if grep -q "软约束" "$file" 2>/dev/null; then
                ISSUES="$ISSUES  [软约束但含MUST]"
            fi
        fi
    fi

    # 检查 FORBID 中是否有冲突标记（建议有，非强制）
    if grep -q "^## FORBID" "$file" 2>/dev/null; then
        has_forbid_items=$(sed -n '/^## FORBID/,/^##/{/^- /p}' "$file" | wc -l)
        if [ "$has_forbid_items" -gt 0 ]; then
            if ! sed -n '/^## FORBID/,/^##/p' "$file" | grep -q "冲突:" 2>/dev/null; then
                ISSUES="$ISSUES  [FORBID缺冲突标记:建议]"
                ((WARN++))
            fi
        fi
    fi

    if [ -z "$ISSUES" ]; then
        ((PASS++))
        echo "  PASS  $file"
    else
        ((FAIL++))
        echo "  FAIL  $file$ISSUES"
    fi
done

echo ""
echo "=== 结果: $PASS 通过 / $FAIL 失败 / $WARN 警告 / 共 $TOTAL 文件 ==="

if [ $FAIL -gt 0 ]; then
    exit 1
else
    exit 0
fi
