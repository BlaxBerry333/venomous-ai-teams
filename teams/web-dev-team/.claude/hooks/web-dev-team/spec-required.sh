#!/usr/bin/env bash
# spec-required.sh — 跨 ≥3 文件改动且无近 24h spec 时 warn 提醒走流程
# 仅在用户用过 web-dev-team（__ai__/web-dev-team/ 已存在）时启用，避免骚扰未用 team 的用户
# PreToolUse on Write/Edit. Claude Code: exit 0 通过 / exit 2 阻断（stderr 给 LLM）/ exit 1 不阻断仅显示通知
# 兼容 macOS bash 3.2+
set -euo pipefail

proj="${CLAUDE_PROJECT_DIR:-.}"
# 规范化路径，与 path-guard 对称
proj="$(cd "$proj" 2>/dev/null && pwd)" || proj="${CLAUDE_PROJECT_DIR:-.}"
team_dir="$proj/__ai__/web-dev-team"
specs_dir="$team_dir/specs"

# 读 stdin（不解析具体 file_path，本 hook 看 git 总体改动）
cat >/dev/null

# 用户从未用过 web-dev-team → 静默放过（避免骚扰）
[ -d "$team_dir" ] || exit 0

# 非 git 仓库放过
[ -d "$proj/.git" ] || exit 0

# 数已改动文件（含未提交 + 暂存 + 未跟踪）
# --untracked-files=all 让 untracked 目录展开为每文件一行，否则目录级 untracked 只占 1 行会低估
count="$({ cd "$proj" && git status --porcelain --untracked-files=all 2>/dev/null || true; } | wc -l | tr -d '[:space:]')"

# < 3 文件改动放过
[ "${count:-0}" -lt 3 ] && exit 0

# 检查近 24h 内是否有 spec
if [ -d "$specs_dir" ]; then
  recent="$({ find "$specs_dir" -maxdepth 1 -name '*.md' -mtime -1 2>/dev/null || true; } | head -n1)"
  [ -n "$recent" ] && exit 0
fi

# 跨 ≥3 文件 + 无近 24h spec → warn
printf '[spec-required] 当前已改动 %s 个文件且 24h 内无 web-dev-team spec。\n' "$count" >&2
printf '建议：用 /web-dev-team:架构者 出 spec 再继续，或 /web-dev-team <需求> 走全流程。\n' >&2
exit 1
