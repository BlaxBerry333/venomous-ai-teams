#!/usr/bin/env bash
# design-lint.sh — 设计原型确定性校验（design-team）
# 用法: design-lint.sh <任务目录路径>
# 输出: [WARN] / [INFO] 行，exit 0
# 兼容 bash 3.2+（macOS 默认），严格遵守根 CLAUDE.md 的 bash 约束
#
# 由 /设计师 在场景二/三完成后通过 Bash 调用，不是 PreToolUse hook。
# 检查项：
#   1. design-brief.md 关键章节完整性
#   2. prototype*.html 文件存在性
#   3. 硬编码颜色（:root 块外）
#   4. 硬编码字号 / 间距
#   5. 响应式断点数量
#   6. 语义化 HTML（main / nav / role）
#   7. ARIA / 焦点状态
#   8. <title> / <html lang> / viewport meta
#   9. <img> alt 属性
#  10. 反 AI 烂模板信号（紫色渐变 / 彩虹渐变）
#  11. 占位文案（Lorem ipsum / Sample Text 等）
#  12. Tokens link 存在性（软提示 INFO，非强制 WARN）
#  13. Typography 成对（font-size 出现处必须伴随 line-height）
set -euo pipefail

TASK_DIR="${1:?用法: design-lint.sh <任务目录路径>}"
TASK_DIR="${TASK_DIR%/}"

if [ ! -d "$TASK_DIR" ]; then
  echo "[INFO] design-lint: 目标 $TASK_DIR 不存在，跳过检查"
  exit 0
fi

# 临时文件做计数器，避免管道子 shell 中 WARN_COUNT 丢失
WARN_FILE=$(mktemp)
echo 0 > "$WARN_FILE"
trap 'rm -f "$WARN_FILE"' EXIT

warn() {
  echo "[WARN] $1"
  local c; c=$(cat "$WARN_FILE"); echo $((c + 1)) > "$WARN_FILE"
}
info() { echo "[INFO] $1"; }

# count_lines <pattern> <file>            （模式 + 文件）
# count_lines_pipe <stdin> <pattern>       （从管道读输入）
# count_lines_pipev <stdin> <pattern>      （从管道读输入 + 反向 -v）
# 替代 `grep -c PAT FILE 2>/dev/null || echo 0` 模式 ——
# set -euo pipefail 下后者无匹配会输出 "0\n0"，让 [ "$VAR" -eq 0 ] 报 "integer expression expected"。
# wc -l 始终输出单行整数（带前导空格用 tr 去掉）。
count_lines() {
  local n
  # set -euo pipefail 下 grep 无匹配 exit 1 让管道失败 → 整段 || true 吃掉，
  # wc -l 在 grep 失败时虽然没收到输入也已经输出了 "0"，所以无需再 echo 0（叠加会得 "00"）。
  n=$( { grep -E "$1" "$2" 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
  echo "${n:-0}"
}
count_lines_i() {
  local n
  n=$( { grep -iE "$1" "$2" 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
  echo "${n:-0}"
}

# 提取 <style> 块内容，删除所有 :root 开头的规则块，并把压缩单行 CSS 规范化成多行。
# 输入：HTML 文件路径
# 输出：规范化后的 CSS（每个声明 / 每个规则块约独占一行），供硬编码检查使用
#
# 两步：
#   1. 规范化：sed -n 提 <style>；tr 把 ; 替换成换行；sed 把 { } 前后加换行
#      —— 让压缩单行 CSS 也变成多行，后续检查不被绕过
#   2. 用 awk 状态机跳过所有 :root 开头的规则块（不管是 :root / :root.dark / :root[x]）
#      起始条件：行首 whitespace 后是 ":root"，且紧接字符是 {、空白、. : [ 之一（selector 合法延伸）
#      这避免误杀 .ghost-root / .my:root-xxx 这类"包含 root 字串但不是 :root selector"的规则
#      结束条件：遇到独占一行的 }（匹配当前 :root 块的 close）
extract_non_root_css() {
  local html_file="$1"
  sed -n '/<style>/,/<\/style>/p' "$html_file" 2>/dev/null | \
    tr ';' '\n' | \
    sed 's/{/{\'$'\n''/g; s/}/\'$'\n''}\'$'\n''/g' | \
    sed 's/<style>/<style>\'$'\n''/g; s/<\/style>/\'$'\n''<\/style>/g' | \
    awk '
      BEGIN { in_root = 0 }
      {
        if (in_root == 0) {
          # 是否是 :root 规则块的起始行？
          # match ":root" 紧跟合法 selector 延伸字符（或直接 {）
          if (match($0, /^[[:space:]]*:root[[:space:]{.:\[]/)) {
            in_root = 1
            next
          }
          print
        } else {
          # 已在 :root 块中，跳过行直到独占一行的 }
          if (match($0, /^[[:space:]]*\}[[:space:]]*$/)) {
            in_root = 0
          }
          next
        }
      }
    '
}

# ============================================================
# 检查 1: design-brief.md 关键章节完整性
# ============================================================
BRIEF="$TASK_DIR/design-brief.md"
if [ -f "$BRIEF" ]; then
  # 必备章节关键字（中文 / 英文容错）
  for section in "目标用户" "风格锚" "信息架构" "用户流程" "组件" "响应式" "可访问性" "设计令牌"; do
    if ! grep -qE "$section" "$BRIEF" 2>/dev/null; then
      warn "design-brief.md 缺少关键章节: $section"
    fi
  done
else
  info "未发现 design-brief.md（可能尚未创建）"
fi

# ============================================================
# 检查 2: prototype*.html 文件存在
# ============================================================
HTML_FILES=$(find "$TASK_DIR" -maxdepth 1 -name '*.html' 2>/dev/null || true)
if [ -z "$HTML_FILES" ]; then
  info "任务目录中暂无 HTML 原型文件（可能尚未制作）"
fi

# tokens 文件存在性（检查 12/13 要用）
TOKENS_CSS="$TASK_DIR/design-tokens.css"

# ============================================================
# 检查 3-11: 对每个 HTML 文件做实际校验
# ============================================================
if [ -n "$HTML_FILES" ]; then
  while IFS= read -r html_file; do
    [ -z "$html_file" ] && continue
    BASENAME=$(basename "$html_file")

    # 预先提取规范化后的非-:root CSS（只算一次，下面 3 项硬编码检查共用）
    # 这样既能稳定删除 :root 块，又不会被单行压缩 CSS 绕过检测。
    NON_ROOT_CSS=$(extract_non_root_css "$html_file")

    # ----- 检查 3: 硬编码颜色（:root 块外） -----
    HARDCODED_COLORS=$( { echo "$NON_ROOT_CSS" | \
      grep -E '(#[0-9a-fA-F]{3,8}|rgb[a]?\(|hsl[a]?\()' 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    HARDCODED_COLORS=${HARDCODED_COLORS:-0}
    if [ "$HARDCODED_COLORS" -gt 0 ]; then
      warn "$BASENAME 中有 $HARDCODED_COLORS 处硬编码颜色值（:root 外），应改为 var(--color-*)"
    fi

    # ----- 检查 4a: 硬编码字号 -----
    HARDCODED_FONT_SIZE=$( { echo "$NON_ROOT_CSS" | \
      grep -E 'font-size:[[:space:]]*[0-9]' 2>/dev/null | \
      grep -vE 'var\(' 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    HARDCODED_FONT_SIZE=${HARDCODED_FONT_SIZE:-0}
    if [ "$HARDCODED_FONT_SIZE" -gt 0 ]; then
      warn "$BASENAME 中有 $HARDCODED_FONT_SIZE 处硬编码 font-size，应改为 var(--font-size-*)"
    fi

    # ----- 检查 4b: 硬编码 padding/margin/gap（粗略） -----
    # 排除 0、auto、% 等合理值，只挡明显的 px/rem 数值
    HARDCODED_SPACING=$( { echo "$NON_ROOT_CSS" | \
      grep -E '(padding|margin|gap):[[:space:]]*[0-9]+(\.[0-9]+)?(px|rem)' 2>/dev/null | \
      grep -vE 'var\(' 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    HARDCODED_SPACING=${HARDCODED_SPACING:-0}
    if [ "$HARDCODED_SPACING" -gt 0 ]; then
      warn "$BASENAME 中有 $HARDCODED_SPACING 处硬编码 padding/margin/gap，应改为 var(--spacing-*)"
    fi

    # ----- 检查 5: 响应式断点数量 -----
    # 用 grep -o 计"出现次数"（每次 @media 算 1），避免同行多个 @media 只算 1 的 bug
    MEDIA_COUNT=$( { grep -oE '@media' "$html_file" 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    MEDIA_COUNT=${MEDIA_COUNT:-0}
    if [ "$MEDIA_COUNT" -lt 2 ]; then
      warn "$BASENAME 中 @media 断点不足 2 个（当前 $MEDIA_COUNT 个），响应式覆盖不足"
    fi

    # ----- 检查 6: 语义化 HTML -----
    HAS_MAIN=$(count_lines '<main' "$html_file")
    if [ "$HAS_MAIN" -eq 0 ]; then
      warn "$BASENAME 缺少 <main> 元素"
    fi

    HAS_NAV=$(count_lines '<nav' "$html_file")
    HAS_ROLE=$(count_lines 'role=' "$html_file")
    if [ "$HAS_NAV" -eq 0 ] && [ "$HAS_ROLE" -eq 0 ]; then
      warn "$BASENAME 缺少 <nav> 和 role= 属性，可访问性不足"
    fi

    # ----- 检查 7: ARIA + 焦点状态 -----
    HAS_FOCUS=$(count_lines ':focus(-visible)?' "$html_file")
    if [ "$HAS_FOCUS" -eq 0 ]; then
      warn "$BASENAME 缺少 :focus 或 :focus-visible 样式，键盘导航不可见"
    fi

    # 有交互组件（button / a）但没 aria-* 属性
    HAS_INTERACTIVE=$(count_lines '<(button|a )' "$html_file")
    HAS_ARIA=$(count_lines 'aria-' "$html_file")
    if [ "$HAS_INTERACTIVE" -gt 3 ] && [ "$HAS_ARIA" -eq 0 ]; then
      warn "$BASENAME 有 $HAS_INTERACTIVE 个交互元素但无 aria-* 属性"
    fi

    # ----- 检查 8: <title> / lang / viewport -----
    HAS_TITLE=$(count_lines '<title>' "$html_file")
    if [ "$HAS_TITLE" -eq 0 ]; then
      warn "$BASENAME 缺少 <title> 标签"
    fi

    HAS_LANG=$(count_lines '<html[^>]*lang=' "$html_file")
    if [ "$HAS_LANG" -eq 0 ]; then
      warn "$BASENAME <html> 缺少 lang= 属性"
    fi

    HAS_VIEWPORT=$(count_lines 'name=["'\'']viewport["'\'']' "$html_file")
    if [ "$HAS_VIEWPORT" -eq 0 ]; then
      warn "$BASENAME 缺少 viewport meta，移动端无法正确缩放"
    fi

    # ----- 检查 9: <img> alt 属性 -----
    IMG_TOTAL=$(count_lines '<img[[:space:]]' "$html_file")
    IMG_WITH_ALT=$(count_lines '<img[^>]*alt=' "$html_file")
    if [ "$IMG_TOTAL" -gt "$IMG_WITH_ALT" ]; then
      MISSING=$((IMG_TOTAL - IMG_WITH_ALT))
      warn "$BASENAME 中有 $MISSING 个 <img> 缺少 alt= 属性"
    fi

    # ----- 检查 10: 反 AI 烂模板信号 -----
    # 紫色渐变（典型 Tailwind purple / Material Indigo / 经典 AI 配色）
    PURPLE_HITS=$(count_lines_i '(#8b5cf6|#a78bfa|#7c3aed|#6366f1|#818cf8|purple.*pink|indigo|violet)' "$html_file")
    if [ "$PURPLE_HITS" -gt 2 ]; then
      warn "$BASENAME 命中紫色 / Indigo 配色信号 $PURPLE_HITS 次，疑似 AI 默认烂模板（除非用户明确要紫色 / 科技感）"
    fi

    # 彩虹渐变
    RAINBOW=$(count_lines 'linear-gradient.*,.*,.*,.*,' "$html_file")
    if [ "$RAINBOW" -gt 0 ]; then
      warn "$BASENAME 有 $RAINBOW 处 5+ 色 linear-gradient，疑似彩虹渐变烂模板"
    fi

    # ----- 检查 11: 占位文案 -----
    LOREM=$(count_lines_i '(lorem[[:space:]]+ipsum|lorem ipsum|sample[[:space:]]+text|placeholder text|this is a description)' "$html_file")
    if [ "$LOREM" -gt 0 ]; then
      warn "$BASENAME 含有占位文案（Lorem ipsum / Sample Text 等），$LOREM 处，应替换为符合业务场景的真实文案"
    fi

    # ----- 检查 12: tokens link 存在性（软提示） -----
    # 仅在 design-tokens.css 与 prototype 同目录共存时检查：tokens 文件存在但 prototype 未引用
    # 降级为 INFO（不是 WARN）—— 用户可能选择内联 tokens 的轻量方案，这不是错误
    if [ -f "$TOKENS_CSS" ]; then
      HAS_TOKENS_LINK=$(count_lines '<link[^>]*design-tokens\.css' "$html_file")
      if [ "$HAS_TOKENS_LINK" -eq 0 ]; then
        info "$BASENAME 同目录有 design-tokens.css 但未通过 <link> 引用（内联 :root 也可以，但多文件 prototype 时建议用 <link> 避免二重管理）"
      fi
    fi

    # 检查 13/14 已删除：
    #   13 (禁止内联 :root) —— 内联是合理的轻量场景
    #   14 (primitive token 名硬编码检查) —— 用户项目变量名体系各异，机械 lint 无法判断

    # ----- 检查 13: Typography 成对（font-size 必伴 line-height）-----
    # 粗略策略：数 <style>（:root 外）里 font-size: 出现次数 vs line-height 出现次数
    # font-size 严格多于 line-height 时 → 提示成对不一致
    # 注意：这是粗略估计，允许 body 兜底 line-height。只在差值 ≥ 2 时触发，减少误报
    FONT_SIZE_CNT=$( { echo "$NON_ROOT_CSS" | grep -E 'font-size:' 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    LINE_HEIGHT_CNT=$( { echo "$NON_ROOT_CSS" | grep -E 'line-height:' 2>/dev/null | wc -l | tr -d '[:space:]'; } || true )
    FONT_SIZE_CNT=${FONT_SIZE_CNT:-0}
    LINE_HEIGHT_CNT=${LINE_HEIGHT_CNT:-0}
    if [ "$FONT_SIZE_CNT" -ge 2 ] && [ $((FONT_SIZE_CNT - LINE_HEIGHT_CNT)) -ge 2 ]; then
      warn "$BASENAME font-size 出现 $FONT_SIZE_CNT 次但 line-height 只 $LINE_HEIGHT_CNT 次，Typography 未成对使用（应配 --text-*-size + --text-*-line + --text-*-tracking 三元组，font-weight 按场景单独搭配）"
    fi

  done <<< "$HTML_FILES"
fi

# ============================================================
# 汇总
# ============================================================
WARN_COUNT=$(cat "$WARN_FILE")
echo "---"
info "design-lint 检查完成: $WARN_COUNT warnings"
exit 0
