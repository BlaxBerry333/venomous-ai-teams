#!/usr/bin/env bash
# path-guard.sh — 路径禁区守卫（design-team）
# PreToolUse hook: Edit|Write 前检查目标路径是否落在 design-team 禁区
#
# 设计说明：
# design-team 重构后走 Command 注入模型（/设计师 在主对话直接执行），
# 主对话 hook 拿不到 agent_type。沿用 docs-team 的 path-based denylist 模式：
# 不问谁在改，只看改的路径是不是其他团队的领地或应用代码范围。命中即拒绝。
#
# 例外：spawn 出去的「设计审查」SubAgent 是只读的（无 Write/Edit 工具），
# 所以即使 hook 在 SubAgent 上下文中也不会被触发到 Edit/Write。
#
# 兼容 bash 3.2+
set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# 转为相对路径（相对于 cwd）
if [ "${FILE_PATH#/}" != "$FILE_PATH" ]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || pwd)
  FILE_PATH="${FILE_PATH#"$CWD"/}"
fi

# --- 禁区规则（denylist）---
# 只挡明确属于其他团队 / 应用代码的路径。
# src/** 不挡（不同项目 src/ 含义差异大），由角色 prompt 自觉避免。
DENY_RULES=$(cat <<'EOF'
.claude/**
__ai__/dev-team/**
__ai__/docs-team/**
app/**
EOF
)

glob_to_regex() {
  echo "$1" | \
    sed 's/\./\\./g; s/\+/\\+/g; s/\^/\\^/g; s/\$/\\$/g; s/\[/\\[/g; s/\]/\\]/g' | \
    sed 's/[(]/\\(/g; s/[)]/\\)/g' | \
    sed 's/{/\\{/g; s/}/\\}/g' | \
    sed 's/\*\*/DOUBLESTAR/g' | \
    sed 's/\*/[^\/]*/g' | \
    sed 's/DOUBLESTAR/.*/g' | \
    sed 's/^/^/;s/$/$/'
}

match_glob() {
  local regex; regex=$(glob_to_regex "$2")
  echo "$1" | grep -qE "$regex"
}

deny_write() {
  local reason="$1"
  cat <<EOJSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[design-team 权限拦截] 禁止修改: ${FILE_PATH} — ${reason}。design-team 仅负责 __ai__/design-team/ 下的设计产出。如需修改应用代码请切换到 /项目经理 或 /程序员（dev-team），修改文档请切换到 /编程专家（docs-team）。"}}
EOJSON
  exit 0
}

# 命中任一 deny 规则 → 拒绝
while IFS= read -r rule; do
  [ -z "$rule" ] && continue
  if match_glob "$FILE_PATH" "$rule"; then
    case "$rule" in
      ".claude/"*)             deny_write "框架配置目录" ;;
      "__ai__/dev-team/"*)     deny_write "dev-team 领地" ;;
      "__ai__/docs-team/"*)    deny_write "docs-team 领地" ;;
      "app/"*)                 deny_write "应用代码目录（dev-team 负责）" ;;
      *)                       deny_write "design-team 禁区" ;;
    esac
  fi
done <<< "$DENY_RULES"

# 未命中任何禁区 → 放行
exit 0
