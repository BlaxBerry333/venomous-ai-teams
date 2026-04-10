#!/usr/bin/env bash
# design-lint.sh — 设计文档确定性校验（design-team）
# 用法: design-lint.sh <任务目录路径>
# 兼容 bash 3.2+
set -euo pipefail

TASK_DIR="${1:?用法: design-lint.sh <任务目录路径>}"

# 去除末尾斜杠
TASK_DIR="${TASK_DIR%/}"

if [ ! -d "$TASK_DIR" ]; then
  echo "[ERROR] 任务目录不存在: $TASK_DIR"
  exit 1
fi

WARN_COUNT=0

warn() {
  echo "[WARN] $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

info() {
  echo "[INFO] $1"
}

# === 检查 1: prototype-tasks.md 引用的 HTML 文件是否存在 ===
PROTO_TASKS="$TASK_DIR/prototype-tasks.md"
if [ -f "$PROTO_TASKS" ]; then
  # 提取 .html 文件引用（反引号内或裸路径）
  HTML_REFS=$(grep -oE '[a-zA-Z0-9_-]+\.html' "$PROTO_TASKS" 2>/dev/null | sort -u || true)
  if [ -n "$HTML_REFS" ]; then
    while IFS= read -r html_file; do
      [ -z "$html_file" ] && continue
      if [ ! -f "$TASK_DIR/$html_file" ]; then
        warn "prototype-tasks.md 引用了 $html_file 但文件不存在于任务目录"
      fi
    done <<< "$HTML_REFS"
  fi
fi

# === 检查 2: HTML 原型中硬编码颜色值（未使用 CSS custom properties） ===
HTML_FILES=$(find "$TASK_DIR" -maxdepth 1 -name '*.html' 2>/dev/null || true)
if [ -n "$HTML_FILES" ]; then
  while IFS= read -r html_file; do
    [ -z "$html_file" ] && continue
    BASENAME=$(basename "$html_file")

    # 在 :root 块之外查找硬编码的 hex 颜色
    # 先提取 <style> 内容（排除 :root 块），再搜索 #hex
    # 注意：sed 范围匹配逐行工作，/^[[:space:]]*}/ 能匹配 :root 块的闭合行
    HARDCODED_COLORS=$(sed -n '/<style>/,/<\/style>/p' "$html_file" 2>/dev/null | \
      sed '/:root[[:space:]]*{/,/^[[:space:]]*}/d' | \
      grep -oE '#[0-9a-fA-F]{3,8}' 2>/dev/null | \
      grep -cvE '^$' 2>/dev/null || echo 0)

    if [ "$HARDCODED_COLORS" -gt 0 ]; then
      warn "$BASENAME 中有 $HARDCODED_COLORS 处硬编码颜色值，建议使用 var(--color-*)"
    fi

    # === 检查 3: 响应式断点数量 ===
    MEDIA_COUNT=$(grep -cE '@media' "$html_file" 2>/dev/null || echo 0)
    if [ "$MEDIA_COUNT" -lt 2 ]; then
      warn "$BASENAME 中 @media 断点不足 2 个（当前 $MEDIA_COUNT 个），响应式覆盖不足"
    fi

    # === 检查 4: 语义化 HTML ===
    HAS_MAIN=$(grep -c '<main' "$html_file" 2>/dev/null || echo 0)
    if [ "$HAS_MAIN" -eq 0 ]; then
      warn "$BASENAME 缺少 <main> 元素"
    fi

    HAS_NAV=$(grep -c '<nav' "$html_file" 2>/dev/null || echo 0)
    HAS_ROLE=$(grep -c 'role=' "$html_file" 2>/dev/null || echo 0)
    if [ "$HAS_NAV" -eq 0 ] && [ "$HAS_ROLE" -eq 0 ]; then
      warn "$BASENAME 缺少 <nav> 和 role= 属性，可访问性不足"
    fi

  done <<< "$HTML_FILES"
else
  info "任务目录中暂无 HTML 原型文件"
fi

# === 检查 5: design-spec.md 关键章节完整性 ===
DESIGN_SPEC="$TASK_DIR/design-spec.md"
if [ -f "$DESIGN_SPEC" ]; then
  # 检查用户流程章节（## 5）
  HAS_USER_FLOW=$(grep -cE '^##[[:space:]]+5[^0-9]' "$DESIGN_SPEC" 2>/dev/null || echo 0)
  if [ "$HAS_USER_FLOW" -eq 0 ]; then
    warn "design-spec.md 缺少用户流程章节（## 5）"
  fi

  # 检查响应式策略章节（## 7）
  HAS_RESPONSIVE=$(grep -cE '^##[[:space:]]+7[^0-9]' "$DESIGN_SPEC" 2>/dev/null || echo 0)
  if [ "$HAS_RESPONSIVE" -eq 0 ]; then
    warn "design-spec.md 缺少响应式策略章节（## 7）"
  fi

  # 检查设计令牌定义章节（## 8）
  HAS_TOKENS=$(grep -cE '^##[[:space:]]+8[^0-9]' "$DESIGN_SPEC" 2>/dev/null || echo 0)
  if [ "$HAS_TOKENS" -eq 0 ]; then
    warn "design-spec.md 缺少设计令牌定义章节（## 8）"
  fi

  # 检查可访问性要求章节（## 9）
  HAS_A11Y=$(grep -cE '^##[[:space:]]+9[^0-9]' "$DESIGN_SPEC" 2>/dev/null || echo 0)
  if [ "$HAS_A11Y" -eq 0 ]; then
    warn "design-spec.md 缺少可访问性要求章节（## 9）"
  fi
fi

# === 汇总 ===
echo "---"
echo "[INFO] design-lint 检查完成: $WARN_COUNT warnings"
