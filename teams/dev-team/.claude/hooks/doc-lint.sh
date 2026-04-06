#!/usr/bin/env bash
# doc-lint.sh — design.md / dev-tasks.md 确定性校验
# 用法: doc-lint.sh <任务目录路径>
# 输出: [WARN] / [INFO] 行，exit 0
# 兼容 bash 3.2+（macOS 默认）
# 注意: 本脚本由调度器通过 Bash 调用，不是 Claude PreToolUse hook
set -euo pipefail

TASK_DIR="${1:?用法: doc-lint.sh <任务目录路径>}"
DESIGN="$TASK_DIR/design.md"
DEVTASKS="$TASK_DIR/dev-tasks.md"
WARN_COUNT=0

# 项目根目录 = 脚本所在位置向上三级（hooks → .claude → dev-team → teams → 项目根）
# 但实际运行时 cwd 就是项目根，所以用 pwd
PROJECT_ROOT="$(pwd)"

warn() { echo "[WARN] $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
info() { echo "[INFO] $1"; }

# ============================================================
# 检查 1: design.md 中「需要修改的部分」引用的文件是否存在
# ============================================================
check_file_existence() {
  [ -f "$DESIGN" ] || return 0

  local in_section=0
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # 进入 "2.3 需要修改的部分" 章节
    if echo "$line" | grep -qE '^#{2,3}.*2\.3'; then
      in_section=1; continue
    fi
    # 遇到下一个 ## 或 ### 则离开
    if [ "$in_section" = "1" ] && echo "$line" | grep -qE '^#{2,3} '; then
      in_section=0; continue
    fi

    [ "$in_section" = "1" ] || continue

    # 提取看起来像文件路径的内容
    # 优先匹配反引号包裹的路径，否则匹配裸路径
    local has_backtick_paths=""
    has_backtick_paths=$(echo "$line" | grep -oE '`[^`]+\.[a-zA-Z]{1,6}`' | tr -d '`' || true)
    if [ -n "$has_backtick_paths" ]; then
      paths="$has_backtick_paths"
    else
      paths=$(echo "$line" | grep -oE '[a-zA-Z0-9_./-]+/[a-zA-Z0-9_./-]+\.[a-zA-Z]{1,6}' || true)
    fi

    for p in $paths; do
      # 跳过明显不是文件路径的（如版本号 1.0.0）
      echo "$p" | grep -qE '/' || continue
      if [ ! -f "$PROJECT_ROOT/$p" ] && [ ! -d "$PROJECT_ROOT/$p" ]; then
        warn "design.md:$line_num: 文件 \"$p\" 在项目中不存在"
      fi
    done
  done < "$DESIGN"
}

# ============================================================
# 检查 2: API 端点计数对比
# ============================================================
check_api_endpoints() {
  [ -f "$DESIGN" ] || return 0

  # 提取 design.md ## 5 章节中的 HTTP 方法行
  local in_section=0
  local doc_count=0
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^#{1,3}.*5\.(1|2)?[[:space:]]'; then
      in_section=1; continue
    fi
    if [ "$in_section" = "1" ] && echo "$line" | grep -qE '^#{1,2} '; then
      in_section=0; continue
    fi
    [ "$in_section" = "1" ] || continue
    if echo "$line" | grep -qiE '(GET|POST|PUT|DELETE|PATCH)[[:space:]]+[/`]'; then
      doc_count=$((doc_count + 1))
    fi
  done < "$DESIGN"

  [ "$doc_count" -gt 0 ] || return 0

  # 在项目中搜索 router/route 文件中的端点定义
  local code_count=0
  local route_files=""
  route_files=$(find "$PROJECT_ROOT" \
    -not -path '*/__ai__/*' \
    -not -path '*/.claude/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    \( -name '*.route.*' -o -name '*.routes.*' -o -name '*.router.*' -o -name 'route.ts' -o -name 'route.js' \) \
    2>/dev/null || true)

  if [ -n "$route_files" ]; then
    code_count=$(echo "$route_files" | xargs grep -cEi '(\.get|\.post|\.put|\.delete|\.patch|router\.|app\.)[[:space:]]*\(' 2>/dev/null | awk -F: '{s+=$2}END{print s+0}' || echo 0)
  fi

  # 也搜索 Next.js App Router / tRPC 等
  if [ "$code_count" = "0" ]; then
    local trpc_files=""
    trpc_files=$(find "$PROJECT_ROOT" \
      -not -path '*/__ai__/*' \
      -not -path '*/.claude/*' \
      -not -path '*/node_modules/*' \
      -not -path '*/.git/*' \
      \( -name '*.trpc.*' -o -name 'trpc.*' -o -path '*/api/*/route.*' \) \
      2>/dev/null || true)
    if [ -n "$trpc_files" ]; then
      code_count=$(echo "$trpc_files" | xargs grep -cE '\.(query|mutation|subscription)\(' 2>/dev/null | awk -F: '{s+=$2}END{print s+0}' || echo 0)
    fi
  fi

  if [ "$code_count" = "0" ]; then
    info "API 端点检查: design.md 列出 $doc_count 个端点，未在项目中找到 router 文件（可能是新增 API 或框架不在检测范围内）"
    return 0
  fi

  # 如果 design.md 列出的端点数大幅超过实际存在的，发出警告
  local diff=$((doc_count - code_count))
  if [ "$diff" -gt 5 ]; then
    warn "design.md: API 章节列出 $doc_count 个端点，但项目 router 文件中仅发现 $code_count 个定义（差异 $diff，请确认是否有新增端点未标注为新增）"
  fi
}

# ============================================================
# 检查 3: 影响分析 → dev-tasks.md 覆盖检查
# ============================================================
check_impact_coverage() {
  [ -f "$DESIGN" ] && [ -f "$DEVTASKS" ] || return 0

  # 提取 design.md ## 7 章节中的影响条目
  local in_section=0
  local impacts=""
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^#{2,3}.*7\.(1|2|3)?[[:space:]]'; then
      in_section=1; continue
    fi
    if [ "$in_section" = "1" ] && echo "$line" | grep -qE '^#{1,2} '; then
      in_section=0; continue
    fi
    [ "$in_section" = "1" ] || continue

    # 提取列表项（- 或 * 开头的行）中的关键词
    if echo "$line" | grep -qE '^[[:space:]]*[-*]'; then
      # 取第一个有意义的短语（去掉 markdown 标记）
      local item=""
      item=$(echo "$line" | sed 's/^[[:space:]]*[-*][[:space:]]*//' | sed 's/[`*_]//g' | sed 's/^[[:space:]]*//' | head -c 40)
      [ -n "$item" ] && impacts="$impacts|$item"
    fi
  done < "$DESIGN"

  [ -n "$impacts" ] || return 0

  # 对每个影响条目，检查 dev-tasks.md 中是否有对应的任务或回归验证项
  IFS='|'
  for item in $impacts; do
    [ -z "$item" ] && continue
    # 取前 10 个字符作为搜索关键词（避免过长的行匹配问题）
    local keyword=""
    keyword=$(echo "$item" | head -c 15)
    if ! grep -q "$keyword" "$DEVTASKS" 2>/dev/null; then
      warn "dev-tasks.md: 影响分析条目 \"$item\" 在任务清单中未找到对应任务或回归验证项"
    fi
  done
  unset IFS
}

# ============================================================
# 检查 4: dev-tasks.md 中涉及文件路径是否存在
# ============================================================
check_task_files() {
  [ -f "$DEVTASKS" ] || return 0

  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # 匹配「涉及文件」下的文件路径行
    paths=$(echo "$line" | grep -oE '`[^`]+\.[a-zA-Z]{1,6}`' | tr -d '`' || true)
    for p in $paths; do
      echo "$p" | grep -qE '/' || continue
      # 跳过明显是新建文件的描述（包含"新增""创建""新建"）
      echo "$line" | grep -qE '新增|创建|新建|new' && continue
      if [ ! -f "$PROJECT_ROOT/$p" ] && [ ! -d "$PROJECT_ROOT/$p" ]; then
        warn "dev-tasks.md:$line_num: 文件 \"$p\" 在项目中不存在（如为新建文件请忽略）"
      fi
    done
  done < "$DEVTASKS"
}

# ============================================================
# 执行所有检查
# ============================================================
if [ ! -f "$DESIGN" ] && [ ! -f "$DEVTASKS" ]; then
  info "doc-lint: design.md 和 dev-tasks.md 均不存在，跳过检查"
  exit 0
fi

info "doc-lint: 开始校验 $TASK_DIR"

check_file_existence
check_api_endpoints
check_impact_coverage
check_task_files

echo ""
info "doc-lint: 校验完成，共 $WARN_COUNT 个警告"
exit 0
