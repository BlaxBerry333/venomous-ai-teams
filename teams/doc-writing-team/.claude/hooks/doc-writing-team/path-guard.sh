#!/usr/bin/env bash
# PreToolUse Edit/Write: 拦 sub-agent 写 .claude/。多 team 共存安全（不跨 team 拦截）。
set -euo pipefail

TEAM="doc-writing-team"
proj="${CLAUDE_PROJECT_DIR:-.}"
# 规范化路径，防 CLAUDE_PROJECT_DIR 含 ../ 导致 case 字符串匹配穿透
proj="$(cd "$proj" 2>/dev/null && pwd)" || proj="${CLAUDE_PROJECT_DIR:-.}"
team_dir="$proj/__ai__/$TEAM"

input="$(cat)"
# `|| true` 包住：set -e 下 grep 无匹配会非零退出（CLAUDE.md Bash 兼容节）
fp="$({ printf '%s' "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -e 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' -e 's/"$//'; } || true)"

[ -z "$fp" ] && exit 0
# team 未初始化 → 静默放过（避免阻断未用 team 的用户手敲 .claude/）
[ -d "$team_dir" ] || exit 0

case "$fp" in
  /*) abs="$fp" ;;
  *)  abs="$proj/$fp" ;;
esac

case "$abs" in
  "$proj"/.claude/*|"$proj"/.claude)
    printf '[path-guard] doc-writing-team 禁止写入 .claude/：%s\n' "$fp" >&2
    exit 2
    ;;
esac

exit 0
