#!/usr/bin/env bash
# role-guard.sh — 角色权限引擎
# PreToolUse hook: Edit|Write 调用前检查角色是否有权限修改目标文件
# 兼容 bash 3.2+
set -euo pipefail

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null || echo "")
[ -z "$AGENT_TYPE" ] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# 转为相对路径
if [ "${FILE_PATH#/}" != "$FILE_PATH" ]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || pwd)
  FILE_PATH="${FILE_PATH#"$CWD"/}"
fi

# --- 权限规则（内嵌） ---
get_rules() {
  case "$1" in
    "项目经理")   echo "__ai__/dev-team/**" ;;
    "程序员")     echo "__ai__/dev-team/tasks/*/dev-plan.md | __ai__/dev-team/tasks/*/dev-tasks.md | __ai__/dev-team/tasks/*/status.md | !__ai__/** | !.claude/**" ;;
    "代码审查员") echo "__ai__/dev-team/tasks/*/review.md" ;;
    "测试员")     echo "__ai__/dev-team/tasks/*/test-report.md | !__ai__/** | !.claude/**" ;;
    *)            return 1 ;;
  esac
}

RULE_STR=$(get_rules "$AGENT_TYPE") || exit 0  # 未知角色 → 放行
RULES=$(echo "$RULE_STR" | tr '|' '\n' | sed 's/^ *//;s/ *$//')

ALLOW_PATTERNS="" DENY_PATTERNS="" HAS_DENY=0
while IFS= read -r rule; do
  [ -z "$rule" ] && continue
  if [ "${rule#!}" != "$rule" ]; then
    DENY_PATTERNS="${DENY_PATTERNS}${rule#!}"$'\n'; HAS_DENY=1
  else
    ALLOW_PATTERNS="${ALLOW_PATTERNS}${rule}"$'\n'
  fi
done <<< "$RULES"

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
  cat <<EOJSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[权限拦截] ${AGENT_TYPE} 不允许修改: ${FILE_PATH}"}}
EOJSON
  exit 0
}

# 1. allow 命中 → 放行
while IFS= read -r p; do
  [ -n "$p" ] && match_glob "$FILE_PATH" "$p" && exit 0
done <<< "$ALLOW_PATTERNS"

# 2. deny 命中 → 拒绝
while IFS= read -r p; do
  [ -n "$p" ] && match_glob "$FILE_PATH" "$p" && deny_write
done <<< "$DENY_PATTERNS"

# 3. 有 deny 但未命中 → 放行
[ "$HAS_DENY" = "1" ] && exit 0

# 4. 无 deny 且不在 allow → 拒绝
deny_write
