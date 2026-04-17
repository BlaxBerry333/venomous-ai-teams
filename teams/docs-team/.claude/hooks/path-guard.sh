#!/usr/bin/env bash
# path-guard.sh — 路径禁区守卫（docs-team）
# PreToolUse hook: Edit|Write 前检查目标路径是否落在 docs-team 禁区
#
# 设计说明：
# docs-team 走 Command 注入模型，hook 拿不到 agent_type（主对话执行，非子进程）。
# dev-team/design-team 的 role-guard.sh 依赖 agent_type 做角色白名单，在此不可用。
# 本 hook 改为"基于路径的 denylist"：不问谁在改，只看改的路径是不是其他团队的领地
# 或明显属于 dev-team 代码/配置范围。命中即拒绝。
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
# 只挡明确属于其他团队的路径。不写 src/** 等用户项目结构差异大的路径，
# 避免误伤（不同项目 src/ 下放什么天差地别，应由用户在 conventions.md 约定，
# 而非框架层硬编码）。
DENY_RULES=$(cat <<'EOF'
.claude/**
__ai__/dev-team/**
__ai__/design-team/**
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
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[docs-team 权限拦截] 禁止修改: ${FILE_PATH} — ${reason}。该路径属于其他团队或应用代码范围，docs-team 仅负责文档相关文件。如需修改，请切换到 /项目经理（dev-team）或 /设计师（design-team）。"}}
EOJSON
  exit 0
}

# 命中任一 deny 规则 → 拒绝
while IFS= read -r rule; do
  [ -z "$rule" ] && continue
  if match_glob "$FILE_PATH" "$rule"; then
    case "$rule" in
      ".claude/"*)            deny_write "框架配置目录" ;;
      "__ai__/dev-team/"*)    deny_write "dev-team 领地" ;;
      "__ai__/design-team/"*) deny_write "design-team 领地" ;;
      "app/"*)                deny_write "应用代码目录（dev-team 负责）" ;;
      *)                      deny_write "docs-team 禁区" ;;
    esac
  fi
done <<< "$DENY_RULES"

# 未命中任何禁区 → 放行
exit 0
