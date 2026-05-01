#!/usr/bin/env bash
# path-guard.sh — 拦截 web-dev-team 写到别 team 目录或 .claude/ 的尝试
# 仅在用户用过 web-dev-team（__ai__/web-dev-team/ 已存在）时启用，避免阻断未用 team 的用户手敲 .claude/
# PreToolUse on Write/Edit. Claude Code: exit 0 通过 / exit 2 阻断（stderr 给 LLM）/ exit 1 不阻断仅显示通知
# 兼容 macOS bash 3.2+
set -euo pipefail

TEAM="web-dev-team"
proj="${CLAUDE_PROJECT_DIR:-.}"
# 规范化路径，防 CLAUDE_PROJECT_DIR 含 ../ 导致 case 字符串匹配穿透
proj="$(cd "$proj" 2>/dev/null && pwd)" || proj="${CLAUDE_PROJECT_DIR:-.}"
team_dir="$proj/__ai__/$TEAM"

# 读 stdin JSON，提 file_path 字段（不依赖 jq，用 grep + sed）
input="$(cat)"
fp="$(printf '%s' "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -e 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' -e 's/"$//')"

# 没解到 file_path 直接放过（不是本 hook 该拦的场景）
[ -z "$fp" ] && exit 0

# 用户从未用过 web-dev-team → 静默放过（避免阻断手敲 .claude/ 等正常操作）
[ -d "$team_dir" ] || exit 0

# 转绝对路径（为 case 模式匹配做基准）
case "$fp" in
  /*) abs="$fp" ;;
  *)  abs="$proj/$fp" ;;
esac

# 1. 拦写 .claude/（防误改 team 自身配置）
case "$abs" in
  "$proj"/.claude/*|"$proj"/.claude)
    printf '[path-guard] web-dev-team 禁止写入 .claude/：%s\n' "$fp" >&2
    exit 2
    ;;
esac

# 2. 拦写 __ai__/<别 team>/
# 真相源：__ai__/__teams__.txt（每行一 team），不在表里且不是本 team 目录的一律拦
case "$abs" in
  "$proj"/__ai__/*)
    rel="${abs#"$proj"/__ai__/}"
    # 提第一段目录名
    sub="${rel%%/*}"
    # __teams__.txt 本身可写（teams.sh 会维护）
    [ "$sub" = "__teams__.txt" ] && exit 0
    # 本 team 自己的目录放过
    [ "$sub" = "$TEAM" ] && exit 0
    # 其他 __ai__/<x>/ 一律拦
    printf '[path-guard] web-dev-team 禁止写入别 team 目录 __ai__/%s/：%s\n' "$sub" "$fp" >&2
    exit 2
    ;;
esac

exit 0
