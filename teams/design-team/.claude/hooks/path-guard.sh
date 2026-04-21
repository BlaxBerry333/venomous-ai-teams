#!/usr/bin/env bash
# path-guard.sh — 路径禁区守卫（design-team）
# PreToolUse hook: Edit|Write 前基于路径硬拦截，与角色身份无关。
# 命中 DENY_RULES 即返回 deny JSON，否则放行。
#
# 例外：spawn 出去的「设计审查」SubAgent 是只读的（无 Write/Edit 工具），
# hook 即便触发也不会被 Edit/Write 调用到。
#
# 兼容 bash 3.2+
set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# --- 控制字符先拒（防换行/Tab 让 grep 按行匹配漏掉 deny）---
case "$FILE_PATH" in
  *$'\n'*|*$'\r'*|*$'\t'*) cat <<'EOJSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[design-team 权限拦截] 路径含控制字符（换行/Tab 等），禁止。请用规范文件名。"}}
EOJSON
    exit 0 ;;
esac

# --- 绝对路径：先归一化 cwd（去尾斜杠 + 合并 //），剥不掉前缀 → deny（项目外） ---
if [ "${FILE_PATH#/}" != "$FILE_PATH" ]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || pwd)
  [ -z "$CWD" ] && CWD="${PWD:-/}"
  CWD="${CWD%/}"
  while [ "${CWD#*//}" != "$CWD" ]; do CWD="${CWD%%//*}/${CWD#*//}"; done
  # 同步规范化 file_path 中的 //（防 cwd=/tmp file=/tmp//x 剥失败）
  while [ "${FILE_PATH#*//}" != "$FILE_PATH" ]; do
    FILE_PATH="${FILE_PATH%%//*}/${FILE_PATH#*//}"
  done
  STRIPPED="${FILE_PATH#"$CWD"/}"
  if [ "$STRIPPED" = "$FILE_PATH" ] && [ "$FILE_PATH" != "$CWD" ]; then
    cat <<'EOJSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[design-team 权限拦截] 绝对路径在项目外，禁止跨项目修改。请用相对路径或当前项目内的绝对路径。"}}
EOJSON
    exit 0
  fi
  FILE_PATH="$STRIPPED"
fi

# --- 相对路径规范化：去 ./、合并 //、拒 ../ ---
while [ "${FILE_PATH#./}" != "$FILE_PATH" ]; do FILE_PATH="${FILE_PATH#./}"; done
while [ "${FILE_PATH#*//}" != "$FILE_PATH" ]; do
  FILE_PATH="${FILE_PATH%%//*}/${FILE_PATH#*//}"
done
# 归一化后空串（如传入 "./" 或 "/"）放行——写入空路径本来就会在 OS 层失败
[ -z "$FILE_PATH" ] && exit 0
case "/$FILE_PATH/" in
  */../*) cat <<'EOJSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[design-team 权限拦截] 路径含 ../，禁止 traversal。请用规范的相对路径或绝对路径。"}}
EOJSON
    exit 0 ;;
esac

# --- 禁区规则（denylist）---
# src/** 不硬拦（不同项目含义差异大），由角色 prompt 自觉。
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

# JSON 字符串转义：\ 和 " 必须转义。控制字符 \t \r 作为 defense-in-depth
# 也转义（正常情况下前面的 case 已拒绝，但留着防未来 case 被误改）。
json_escape() {
  printf '%s' "$1" | awk '
    BEGIN { ORS="" }
    {
      n = length($0)
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        if (c == "\\") printf "\\\\"
        else if (c == "\"") printf "\\\""
        else if (c == "\t") printf "\\t"
        else if (c == "\r") printf "\\r"
        else printf "%s", c
      }
    }
  '
}

deny_write() {
  local reason="$1"
  local esc_path
  esc_path=$(json_escape "$FILE_PATH")
  cat <<EOJSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[design-team 权限拦截] 禁止修改: ${esc_path} — ${reason}。当前项目装的是 design-team，只负责 __ai__/design-team/ 下的设计产出。如需修改其他范围：请告知用户「这需要切换 team，请你到 venomous-ai-teams 仓库根目录跑 bash setup.sh 选对应 team；如已删仓库需先重新 git clone」。Claude 不要自己跑 setup.sh（交互式脚本），也不要变通改其他路径。"}}
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
      "app/"*)                 deny_write "应用代码目录" ;;
      *)                       deny_write "design-team 禁区" ;;
    esac
  fi
done <<< "$DENY_RULES"

# 未命中任何禁区 → 放行
exit 0
